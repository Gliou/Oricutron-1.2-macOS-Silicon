/*
**  clipboard_shim.c — copie de l'écran texte Oric vers le presse-papiers macOS.
**  Seule partie qui doit lire la structure `machine` : le reste est en Swift.
*/

#include <string.h>

#include "system.h"
#include "6502.h"
#include "via.h"
#include "8912.h"
#include "gui.h"
#include "disk.h"
#include "monitor.h"
#include "6551.h"
#include "machine.h"

/* Implémentée en Swift (PlatformCocoa.swift) */
void oricutron_pasteboard_set_text(const char *text);

static void copy_text_screen(struct machine *oric)
{
  unsigned char *vidmem = &oric->mem[oric->vid_addr];
  /* 28 lignes de 40 colonnes + retours ligne ; "©" UTF-8 = 2 octets */
  char text[28 * (40 * 2 + 1) + 1];
  int pos = 0, line, col;

  for (line = 0; line < 28; line++)
  {
    for (col = 0; col < 40; col++)
    {
      unsigned char c = vidmem[line * 40 + col];
      if (c > 127) c -= 128;               /* vidéo inverse */
      if (c < ' ' || c == 127)
        text[pos++] = ' ';
      else if (c == 0x60)
      {
        text[pos++] = (char)0xC2;          /* © */
        text[pos++] = (char)0xA9;
      }
      else
        text[pos++] = (char)c;
    }
    text[pos++] = '\n';
  }
  text[pos] = 0;
  oricutron_pasteboard_set_text(text);
}

SDL_bool clipboard_copy(struct machine *oric)
{
  if (oric->vid_addr == oric->vidbases[2])   /* mode TEXT */
    copy_text_screen(oric);
  /* mode HIRES : non géré (comme la version Objective-C d'origine) */
  return SDL_TRUE;
}
