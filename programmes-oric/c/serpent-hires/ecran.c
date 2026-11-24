/* ecran.c - écran HIRES (cases 6 x 6), lignes de texte, écran texte.
** Créé le 2026-11-24 by GliouCNR©70
**
** HIRES de l'Oric : 200 lignes de 40 octets en $A000. Un octet >= 64 donne
** 6 points (bits 5 à 0, bit 5 à gauche) ; avec le bit 7 (vidéo inverse), les
** couleurs sont les complémentaires : encre verte -> magenta, fond noir ->
** blanc. Un octet < 32 est un attribut (0-7 encre, 16-23 fond), affiché comme
** une case de fond. Chaque ligne commence par l'encre verte (octet 0) et le
** fond noir (octet 1) : serpent vert ; pomme, briques et murs en inverse
** (magenta et blanc), comme dans le Serpent en BASIC.
*/
#include <string.h>
#include "config.h"
#include "ecran.h"

/* Dessins de base, une ligne de 6 points par octet (bit 5 = point de gauche) */
static const unsigned char tete_d[6]  = { 0x1C, 0x3E, 0x37, 0x3F, 0x3E, 0x1C };
static const unsigned char queue_g[6] = { 0x03, 0x0F, 0x3F, 0x3F, 0x0F, 0x03 };
static const unsigned char corps[6]   = { 0x1E, 0x33, 0x2D, 0x2D, 0x33, 0x1E };
static const unsigned char pomme[6]   = { 0x06, 0x1E, 0x3F, 0x3F, 0x3F, 0x1E }; /* en inverse */
static const unsigned char brique[6]  = { 0x3F, 0x04, 0x04, 0x3F, 0x20, 0x20 }; /* joints, en inverse */

/* Les mêmes en caractères 6 x 8 pour les lignes de texte (repris du BASIC) */
static const unsigned char car_pomme[8] = { 6, 12, 59, 63, 63, 63, 63, 30 };
static const unsigned char car_tete[8]  = { 28, 62, 58, 63, 63, 58, 62, 28 };

static unsigned char dessins[D_NOMBRE][6];
static unsigned char inverse[D_NOMBRE];       /* 0x40 normal, 0xC0 inverse */
static unsigned char* adr_case[HAUTEUR];       /* 1re ligne de chaque rangée */
static char tampon[7];

typedef void (*routine)(void);
#define ROM_HIRES ((routine)0xF920)   /* passe en HIRES (sans le test de $EC33) */
#define ROM_TEXTE ((routine)0xF967)   /* revient en mode texte                */

static void miroir(const unsigned char* a, unsigned char* b)
{
    unsigned char i, j, v;
    for (i = 0; i < 6; ++i) {
        v = 0;
        for (j = 0; j < 6; ++j)
            if (a[i] & (1 << j)) v |= 0x20 >> j;
        b[i] = v;
    }
}

/* Rotation d'un quart de tour : sens = 1 horaire, 0 antihoraire */
static void tourne(const unsigned char* a, unsigned char* b, unsigned char sens)
{
    unsigned char r, c, src;
    for (r = 0; r < 6; ++r) {
        b[r] = 0;
        for (c = 0; c < 6; ++c) {
            src = sens ? (a[5 - c] & (0x20 >> r)) : (a[c] & (0x20 >> (5 - r)));
            if (src) b[r] |= 0x20 >> c;
        }
    }
}

void ecran_prepare(void)
{
    unsigned char i;
    memset(dessins[D_VIDE], 0, 6);
    memcpy(dessins[D_BORD], brique, 6);
    memset(dessins[D_MUR], 0, 6);            /* inverse vide = pavé blanc */
    memcpy(dessins[D_POMME], pomme, 6);
    memcpy(dessins[D_CORPS], corps, 6);
    memcpy(dessins[D_TETE_D], tete_d, 6);
    miroir(tete_d, dessins[D_TETE_G]);
    tourne(tete_d, dessins[D_TETE_B], 1);
    tourne(tete_d, dessins[D_TETE_H], 0);
    memcpy(dessins[D_QUEUE_G], queue_g, 6);
    miroir(queue_g, dessins[D_QUEUE_D]);
    tourne(queue_g, dessins[D_QUEUE_H], 1);
    tourne(queue_g, dessins[D_QUEUE_B], 0);
    for (i = 0; i < D_NOMBRE; ++i) inverse[i] = 0x40;
    inverse[D_BORD] = inverse[D_MUR] = inverse[D_POMME] = 0xC0;
    for (i = 0; i < HAUTEUR; ++i)
        adr_case[i] = (unsigned char*)HIRES_ECRAN + (unsigned int)i * (COTE * 40) + 2;
    POKE(0x020C, 0x7F);                      /* CAPS éteint (rien en haut) */
    /* pomme (@) et tête ({) dans le jeu de caractères du mode texte */
    memcpy((unsigned char*)JEU_TEXTE + '@' * 8, car_pomme, 8);
    memcpy((unsigned char*)JEU_TEXTE + 123 * 8, car_tete, 8);
}

static void curseur_cache(void)
{
    POKE(0x026A, PEEK(0x026A) & 0xFE);
}

void ecran_hires(void)
{
    unsigned char l;
    unsigned char* p = (unsigned char*)HIRES_ECRAN;
    ROM_HIRES();
    POKE(0x02C0, PEEK(0x02C0) | 1);          /* « HIRES actif » pour la ROM */
    curseur_cache();
    for (l = 0; l < 200; ++l) {
        p[0] = 2;                            /* encre verte */
        p[1] = 16;                           /* fond noir   */
        memset(p + 2, 0x40, 38);
        p += 40;
    }
    for (l = 0; l < 3; ++l) hires_efface_ligne(l);
    memcpy((unsigned char*)JEU_HIRES + '@' * 8, car_pomme, 8);
    memcpy((unsigned char*)JEU_HIRES + 123 * 8, car_tete, 8);
}

void ecran_texte(void)
{
    /* La ROM recopie alors le jeu de caractères de $9800 vers $B400 : à ne
    ** faire qu'en sortant du HIRES (au démarrage, $9800 n'en contient pas). */
    if (PEEK(0x02C0) & 1) ROM_TEXTE();
    POKE(0x02C0, PEEK(0x02C0) & 0xFE);
    curseur_cache();
    texte_efface();
}

void case_dessine(unsigned char x, unsigned char y, unsigned char d)
{
    unsigned char* p = adr_case[y] + x;
    const unsigned char* m = dessins[d];
    unsigned char inv = inverse[d];
    p[0]   = m[0] | inv;
    p[40]  = m[1] | inv;
    p[80]  = m[2] | inv;
    p[120] = m[3] | inv;
    p[160] = m[4] | inv;
    p[200] = m[5] | inv;
}

void terrain_vide(void)
{
    unsigned char l;
    unsigned char* p = (unsigned char*)HIRES_ECRAN + 2;
    for (l = 0; l < HAUTEUR * COTE; ++l) {
        memset(p, 0x40, LARGEUR);
        p += 40;
    }
}

void hires_efface_ligne(unsigned char l)
{
    /* le dernier octet ($BFDF) garde l'attribut « mode HIRES » */
    memset((unsigned char*)TEXTE_HIRES + l * 40, ' ', l == 2 ? 39 : 40);
}

void hires_ecrit(unsigned char x, unsigned char l, const char* s)
{
    unsigned char* p = (unsigned char*)TEXTE_HIRES + l * 40 + x;
    while (*s) *p++ = *s++;
}

void hires_octet(unsigned char x, unsigned char l, unsigned char c)
{
    POKE(TEXTE_HIRES + l * 40 + x, c);
}

void texte_efface(void)
{
    memset((unsigned char*)TEXTE_ECRAN, ' ', 28 * 40);
}

void texte_ecrit(unsigned char x, unsigned char y, const char* s)
{
    unsigned char* p = (unsigned char*)TEXTE_ECRAN + y * 40 + x;
    while (*s) *p++ = *s++;
}

void texte_octet(unsigned char x, unsigned char y, unsigned char c)
{
    POKE(TEXTE_ECRAN + y * 40 + x, c);
}

char* nombre(unsigned int n, unsigned char largeur)
{
    unsigned char i = 6;
    tampon[6] = 0;
    do { tampon[--i] = '0' + n % 10; n /= 10; } while (n && i);
    while (i > 6 - largeur) tampon[--i] = ' ';
    return tampon + i;
}
