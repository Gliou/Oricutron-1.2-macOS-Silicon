/* hof.c - Hall of Fame (10 meilleurs scores), réglage du volume, records.
** Créé le 2026-11-24 by GliouCNR©70
**
** Même écran que le Serpent BASIC (lignes 700-764 et 800-855) : rang, nom,
** score, longueur atteinte (pommes + 4) suivie de la tête, pommes mangées
** suivies de la pomme ; barre du volume réglée avec les flèches, un PING à
** chaque réglage. Le Hall of Fame livré est fait d'« ORIC » aux scores
** minimum des portes. L'écran de victoire est passé dans images.c (image
** HIRES, 2026-11-24).
** Modifié le 2026-11-26 by GliouCNR©70 : sur la disquette, le Hall of Fame et
** le volume sont SAUVEGARDÉS (piste 0, secteur 18, module disque.c), dans le
** même format que le Serpent BASIC :
**   octet 0 = 72 (« H ») ; 10 fois : nom (8 lettres), score (haut, bas) ;
**   octets 101 à 120 : pommes de chaque record (haut, bas) ;
**   octet 240 : volume + 1 (0 = pas encore réglé).
** Le secteur est relu au démarrage, réécrit après chaque record, et quand le
** volume a changé (au début de la partie, sans rien afficher).
*/
#include <string.h>
#include "config.h"
#include "ecran.h"
#include "clavier.h"
#include "son.h"
#include "hof.h"
#include "disque.h"

unsigned char volume = 32;
static unsigned char volume_sauve = 255;   /* volume déjà sur la disquette */

static char noms[10][9];
static unsigned int scores[10];
static unsigned int pommes[10];

static const unsigned int score_livre[10] = { 2500, 2000, 1500, 1250, 1000, 750, 500, 300, 150, 50 };
static const unsigned int pommes_livre[10] = { 60, 50, 40, 35, 30, 25, 20, 15, 10, 5 };

void hof_raz(void)
{
    unsigned char i;
    for (i = 0; i < 10; ++i) {
        strcpy(noms[i], "ORIC    ");
        scores[i] = score_livre[i];
        pommes[i] = pommes_livre[i];
    }
}

/* ----- Sauvegarde sur la disquette ----- */
void hof_charge(void)
{
    unsigned char i, k;
    if (!disque_present() || disque_lit() || secteur[0] != 72) return;
    for (i = 0; i < 10; ++i) {
        k = 1 + i * 10;
        memcpy(noms[i], secteur + k, 8);
        noms[i][8] = 0;
        scores[i] = secteur[k + 8] * 256 + secteur[k + 9];
        pommes[i] = secteur[0x65 + i * 2] * 256 + secteur[0x66 + i * 2];
    }
    k = secteur[0xF0];
    if (k > 0 && k < 66) volume = k - 1;
    volume_sauve = volume;
}

static void sauve(void)
{
    unsigned char i, k;
    if (!disque_present()) return;
    memset(secteur, 0, sizeof secteur);
    secteur[0] = 72;
    for (i = 0; i < 10; ++i) {
        k = 1 + i * 10;
        memcpy(secteur + k, noms[i], 8);
        secteur[k + 8] = scores[i] >> 8;
        secteur[k + 9] = scores[i] & 255;
        secteur[0x65 + i * 2] = pommes[i] >> 8;
        secteur[0x66 + i * 2] = pommes[i] & 255;
    }
    secteur[0xF0] = volume + 1;
    volume_sauve = volume;
    if (disque_ecrit()) {
        texte_ecrit(3, 25, "ERREUR DISQUE");
        attend(250);
    }
}

unsigned int hof_meilleur(void)
{
    return scores[0];
}

static void barre_volume(void)
{
    unsigned char i, b = volume / 4;
    son_volume(volume);
    texte_ecrit(4, 20, "VOLUME");
    for (i = 0; i < 16; ++i) texte_octet(11 + i, 20, i < b ? 160 : '-');
    texte_ecrit(28, 20, nombre(volume, 3));
    texte_ecrit(31, 20, "/64");
    texte_ecrit(12, 21, "(FLECHES <- ->)");
}

void hof_ecran(void)
{
    unsigned char i, r, k;
    texte_efface();
    texte_octet(11, 3, 6);
    texte_ecrit(13, 3, "S E R P E N T");
    texte_octet(11, 6, 3);
    texte_ecrit(13, 6, "HALL OF FAME");
    for (i = 0; i < 10; ++i) {
        r = 8 + i;
        texte_octet(3, r, 7);
        texte_ecrit(4, r, nombre(i + 1, 3));
        texte_ecrit(7, r, ". ");
        texte_ecrit(9, r, noms[i]);
        texte_octet(18, r, 3);
        texte_ecrit(19, r, nombre(scores[i], 6));
        texte_octet(25, r, 2);
        if (pommes[i]) {
            texte_ecrit(26, r, nombre(pommes[i] + 4, 4));
            texte_octet(31, r, 123);
            texte_ecrit(32, r, nombre(pommes[i], 4));
            texte_octet(36, r, 3);           /* pomme jaune */
            texte_octet(37, r, '@');
        } else {
            texte_ecrit(29, r, "-");
            texte_ecrit(35, r, "-");
        }
    }
    barre_volume();
    texte_ecrit(12, 23, "ESPACE = JOUER");
    POKE(TOUCHE, 0);
    for (;;) {
        k = attend_touche();
        if (k == T_ESPACE) {
            if (volume != volume_sauve) sauve();   /* volume gardé sur la disquette */
            return;
        }
        if (k == T_GAUCHE && volume > 0) volume -= 4;
        else if (k == T_DROITE && volume < 64) volume += 4;
        else continue;
        barre_volume();
        son_ping();
    }
}

static void lit_nom(char* nom, unsigned char x, unsigned char y)
{
    unsigned char n = 0, k;
    memset(nom, ' ', 8);
    nom[8] = 0;
    for (;;) {
        texte_ecrit(x, y, nom);
        texte_octet(x + n, y, n < 8 ? (nom[n] | 0x80) : ' ');   /* curseur */
        k = attend_touche();
        if (k == T_RETOUR) break;
        if ((k == T_EFFACE || k == T_GAUCHE) && n > 0) { nom[--n] = ' '; continue; }
        if (k >= 'a' && k <= 'z') k -= 32;
        if (n < 8 && ((k >= 'A' && k <= 'Z') || (k >= '0' && k <= '9') || k == ' ' || k == '-'))
            nom[n++] = k;
    }
    if (n == 0) nom[0] = '?';
    texte_ecrit(x, y, nom);
    texte_octet(x + 8, y, ' ');
}

void hof_record(unsigned int score, unsigned int nb_pommes)
{
    unsigned char p, i;
    char nom[9];
    if (score <= scores[9]) return;
    for (p = 0; p < 10 && score <= scores[p]; ++p) ;
    texte_efface();
    texte_ecrit(3, 3, "BRAVO ! NOUVEAU RECORD :");
    texte_ecrit(28, 3, nombre(score, 5));
    texte_ecrit(3, 5, "HALL OF FAME, PLACE");
    texte_ecrit(23, 5, nombre(p + 1, 2));
    texte_ecrit(3, 7, "TON NOM (8 LETTRES) :");
    lit_nom(nom, 25, 7);
    for (i = 9; i > p; --i) {
        strcpy(noms[i], noms[i - 1]);
        scores[i] = scores[i - 1];
        pommes[i] = pommes[i - 1];
    }
    strcpy(noms[p], nom);
    scores[p] = score;
    pommes[p] = nb_pommes;
    if (disque_present()) {
        texte_ecrit(3, 9, "SAUVEGARDE...");
        sauve();
    }
}
