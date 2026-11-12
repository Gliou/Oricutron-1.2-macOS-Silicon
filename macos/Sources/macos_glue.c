/*
**  macos_glue.c — pont entre les commandes macOS (menu natif, glisser-déposer,
**  « Ouvrir avec » du Finder) et les fonctions d'Oricutron.
**
**  Principe : on « présélectionne » le fichier, puis on appelle les fonctions
**  d'origine inserttape()/insertdisk(). Leur appel à filerequester() (Swift)
**  récupère ce fichier sans afficher de dialogue : toute la logique d'origine
**  (détection du type d'image, changement de machine…) est ainsi conservée.
*/

#include <string.h>
#include <strings.h>

#include "system.h"
#include "6502.h"
#include "via.h"
#include "8912.h"
#include "gui.h"
#include "disk.h"
#include "monitor.h"
#include "6551.h"
#include "machine.h"
#include "snapshot.h"
#include "msgbox.h"

extern SDL_bool microdiscrom_valid, jasminrom_valid;

void inserttape(struct machine *oric, struct osdmenuitem *mitem, int dummy);
void insertdisk(struct machine *oric, struct osdmenuitem *mitem, int drive);

/* Codes des commandes du menu natif (doivent correspondre à PlatformCocoa.swift) */
enum { MACOS_CMD_TAPE = 1, MACOS_CMD_DISK0 = 2, MACOS_CMD_DISK1 = 3,
       MACOS_CMD_RESET = 4, MACOS_CMD_CLOAD = 5,
       MACOS_CMD_MENU = 6 /* menu d'Oricutron (équivalent de F1) */,
       MACOS_CMD_MACHINE = 0x100 /* + numéro de machine (MACH_ATMOS…) */ };

void resetoric(struct machine *oric, struct osdmenuitem *mitem, int dummy);

static char preset_file[4096 + 512];

/* Appelée par filerequester() (Swift) : renvoie 1 et remplit path/fname si un fichier est présélectionné. */
int macos_take_preset(char *path, char *fname)
{
  char *slash;
  if (!preset_file[0]) return 0;

  slash = strrchr(preset_file, '/');
  if (slash)
  {
    size_t dirlen = (size_t)(slash - preset_file);
    if (dirlen > 4095) dirlen = 4095;
    memcpy(path, preset_file, dirlen);
    path[dirlen] = 0;
    strncpy(fname, slash + 1, 511);
  }
  else
  {
    strcpy(path, ".");
    strncpy(fname, preset_file, 511);
  }
  fname[511] = 0;
  preset_file[0] = 0;
  return 1;
}

/* Les disquettes ont besoin de la ROM du contrôleur (Microdisc ou Jasmin) :
   sans elle, l'insertion échoue silencieusement. On prévient clairement. */
static int disk_roms_ok(struct machine *oric)
{
  if (microdiscrom_valid || jasminrom_valid) return 1;
  msgbox(oric, MSGBOX_OK,
         "Impossible de lire les disquettes : la ROM du contrôleur de disque est absente.\n\n"
         "Copie microdis.rom (Microdisc, la plupart des .dsk) et/ou jasmin.rom dans le "
         "dossier roms (menu Fichier > Ouvrir le dossier de données), puis relance Oricutron.");
  return 0;
}

static const char *extension_of(const char *file)
{
  const char *dot = strrchr(file, '.');
  const char *slash = strrchr(file, '/');
  if (!dot || (slash && dot < slash)) return "";
  return dot + 1;
}

void macos_open_file(struct machine *oric, const char *file)
{
  const char *ext;
  if (!file || !file[0]) return;
  ext = extension_of(file);

  if (!strcasecmp(ext, "sna"))
  {
    load_snapshot(oric, (char *)file);
    return;
  }

  strncpy(preset_file, file, sizeof(preset_file) - 1);
  preset_file[sizeof(preset_file) - 1] = 0;

  if (!strcasecmp(ext, "dsk"))
  {
    if (disk_roms_ok(oric)) insertdisk(oric, NULL, 0);
  }
  else
    inserttape(oric, NULL, 0);   /* .tap, .ort, .wav… (inserttape détecte aussi les disquettes) */

  preset_file[0] = 0;
}

void macos_menu_command(struct machine *oric, int code)
{
  preset_file[0] = 0;
  switch (code)
  {
    case MACOS_CMD_TAPE:     inserttape(oric, NULL, 0); break;
    case MACOS_CMD_DISK0:    if (disk_roms_ok(oric)) insertdisk(oric, NULL, 0); break;
    case MACOS_CMD_DISK1:    if (disk_roms_ok(oric)) insertdisk(oric, NULL, 1); break;
    case MACOS_CMD_RESET:    resetoric(oric, NULL, 0); break;
    case MACOS_CMD_CLOAD:    queuekeys("CLOAD\"\"\x0d"); break;
    case MACOS_CMD_MENU:
      if (oric->emu_mode == EM_RUNNING)
        setemumode(oric, NULL, EM_MENU);
      break;
    default:
      if (code >= MACOS_CMD_MACHINE && code < MACOS_CMD_MACHINE + MACH_LAST)
      {
        /* 0xffff dans les 16 bits hauts = garder le lecteur de disquettes actuel */
        swapmach(oric, NULL, (int)(0xffff0000u | (unsigned)(code - MACOS_CMD_MACHINE)));
        setemumode(oric, NULL, EM_RUNNING);
      }
      break;
  }
}

/* oricutron.cfg placé à côté d'Oricutron.app (comportement d'origine d'Oricutron).
   Vide = celui du dossier de données (~/Library/Application Support/Oricutron). */
static char config_override[4096];

void macos_set_config_path(const char *path)
{
  if (!path) { config_override[0] = 0; return; }
  strncpy(config_override, path, sizeof(config_override) - 1);
  config_override[sizeof(config_override) - 1] = 0;
}

const char *macos_config_path(void) { return config_override; }

/* Appelée depuis Swift (Fichier > Ouvrir…) : poste le fichier comme un glisser-déposer. */
void macos_push_open_file(const char *path)
{
  SDL_Event ev;
  if (!path || !path[0]) return;
  memset(&ev, 0, sizeof(ev));
  ev.type = SDL_DROPFILE;
  ev.drop.file = SDL_strdup(path);   /* libéré par la boucle principale (SDL_free) */
  if (SDL_PushEvent(&ev) <= 0) SDL_free(ev.drop.file);
}

/* Appelée depuis Swift (actions du menu) : poste une commande dans la file d'événements SDL. */
void macos_push_command(int code)
{
  SDL_Event ev;
  memset(&ev, 0, sizeof(ev));
  ev.type = SDL_USEREVENT;
  ev.user.code = code;
  SDL_PushEvent(&ev);
}

/* ------------------------------------------------------------------------
**  Clavier « par position »
**
**  Le cœur d'Oricutron lit le *caractère* de la touche (keysym.sym), pensé pour
**  un clavier QWERTY anglais : sur un AZERTY/QWERTZ macOS, la ponctuation
**  (" : ; , . = - ' / etc.) arrive sur les mauvaises touches de l'Oric.
**
**  En mode position, on se base sur le *scancode* (emplacement physique de la
**  touche) : chaque touche du Mac actionne la touche située au même endroit sur
**  le clavier de l'Oric. Seules les touches de caractères sont converties ;
**  Entrée, flèches, Ctrl, Maj, Alt (FUNCT), Esc, F1… ne changent pas.
** ------------------------------------------------------------------------ */

static int keyboard_positional = 1;

void macos_set_keyboard_positional(int on) { keyboard_positional = on ? 1 : 0; }
int  macos_keyboard_positional(void)       { return keyboard_positional; }

SDL_Keycode macos_map_key(struct machine *oric, SDL_Scancode sc, SDL_Keycode sym)
{
  SDL_Keycode k = 0;

  if (!keyboard_positional) return sym;

  if (sc >= SDL_SCANCODE_A && sc <= SDL_SCANCODE_Z)
    k = 'a' + (sc - SDL_SCANCODE_A);
  else if (sc >= SDL_SCANCODE_1 && sc <= SDL_SCANCODE_9)
    k = '1' + (sc - SDL_SCANCODE_1);
  else switch (sc)
  {
    case SDL_SCANCODE_0:            k = '0';  break;
    case SDL_SCANCODE_MINUS:        k = '-';  break;
    case SDL_SCANCODE_EQUALS:       k = '=';  break;
    case SDL_SCANCODE_LEFTBRACKET:  k = '[';  break;
    case SDL_SCANCODE_RIGHTBRACKET: k = ']';  break;
    case SDL_SCANCODE_BACKSLASH:
    case SDL_SCANCODE_NONUSHASH:
    case SDL_SCANCODE_NONUSBACKSLASH: k = '\\'; break;
    case SDL_SCANCODE_SEMICOLON:    k = ';';  break;
    case SDL_SCANCODE_APOSTROPHE:   k = '\''; break;
    case SDL_SCANCODE_COMMA:        k = ',';  break;
    case SDL_SCANCODE_PERIOD:       k = '.';  break;
    case SDL_SCANCODE_SLASH:        k = '/';  break;
    default:                        return sym;   /* touches spéciales : inchangées */
  }

  /* La table de l'émulateur dépend de l'option « keymap » : on lui donne le nom
     de touche qu'elle attend pour cette position (QWERTY par défaut). */
  if (oric->keymap == KMAP_AZERTY)
  {
    if      (k == 'q') k = 'a'; else if (k == 'a') k = 'q';
    else if (k == 'w') k = 'z'; else if (k == 'z') k = 'w';
  }
  else if (oric->keymap == KMAP_QWERTZ)
  {
    if      (k == 'y') k = 'z'; else if (k == 'z') k = 'y';
  }
  return k;
}
