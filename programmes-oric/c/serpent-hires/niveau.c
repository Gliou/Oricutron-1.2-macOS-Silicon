/* niveau.c - les 5 tableaux : bord, portes, murs, pommes.
** Créé le 2026-11-24 by GliouCNR©70
**
** Mêmes règles que le Serpent BASIC (lignes 400-520), sur un terrain plus
** grand (36 x 31 cases au lieu de 34 x 22) : murs tirés au hasard la première
** fois qu'on entre dans un tableau, puis gardés ; ils ne touchent rien (une case
** libre tout autour) et laissent libres l'entrée à gauche et la porte à droite.
** Au niveau 1 on entre au milieu de la hauteur ; ensuite, par la porte de
** gauche, en face de la porte de droite du tableau précédent.
*/
#include <stdlib.h>
#include <string.h>
#include "config.h"
#include "ecran.h"
#include "niveau.h"

unsigned char grille[HAUTEUR][LARGEUR];
Niveau niveaux[NIVEAUX + 1];
unsigned char pomme_x, pomme_y;

void niveaux_raz(void)
{
    memset(niveaux, 0, sizeof niveaux);
}

unsigned char entree_gauche(unsigned char l)
{
    return l > 1 ? niveaux[l - 1].porte + 1 : HAUTEUR / 2;
}

void case_pose(unsigned char x, unsigned char y, unsigned char type, unsigned char dessin)
{
    grille[y][x] = type;
    case_dessine(x, y, dessin);
}

static unsigned char zone_libre(unsigned char x1, unsigned char y1,
                                unsigned char x2, unsigned char y2)
{
    unsigned char i, j;
    for (j = y1 - 1; j <= y2 + 1; ++j)
        for (i = x1 - 1; i <= x2 + 1; ++i)
            if (grille[j][i] != VIDE) return 0;
    return 1;
}

static void murs_tire(unsigned char l)
{
    Niveau* n = &niveaux[l];
    unsigned char w, a, q, x1, y1, x2, y2, ly = entree_gauche(l), py;
    n->porte = py = 2 + rand() % 27;          /* porte en py..py+2 (lignes 2 à 30) */
    n->nmurs = 0;
    for (w = 0; w < 7 + 3 * l && n->nmurs < MAXMURS; ++w)
        for (a = 0; a < 30; ++a) {
            q = 2 + rand() % (l + 3);
            if (rand() & 1) {                 /* horizontal */
                x1 = 3 + rand() % (33 - q);  y1 = 2 + rand() % 29;
                x2 = x1 + q - 1;             y2 = y1;
            } else {                          /* vertical */
                x1 = 3 + rand() % 32;        y1 = 2 + rand() % (30 - q);
                x2 = x1;                     y2 = y1 + q - 1;
            }
            if (x1 < 28 && y1 <= ly + 2 && y2 + 2 >= ly) continue;   /* entrée  */
            if (x2 > 30 && y1 <= py + 4 && y2 + 2 >= py) continue;   /* porte   */
            if (!zone_libre(x1, y1, x2, y2)) continue;
            n->x1[n->nmurs] = x1; n->y1[n->nmurs] = y1;
            n->x2[n->nmurs] = x2; n->y2[n->nmurs] = y2;
            ++n->nmurs;
            for (; y1 <= y2; ++y1)
                for (q = x1; q <= x2; ++q) grille[y1][q] = MUR;
            break;
        }
    n->cree = 1;
}

void niveau_dessine(unsigned char l)
{
    Niveau* n = &niveaux[l];
    unsigned char x, y, k, ly = entree_gauche(l);
    memset(grille, VIDE, sizeof grille);
    terrain_vide();
    for (x = 0; x < LARGEUR; ++x) {
        case_pose(x, 0, BORD, D_BORD);
        case_pose(x, HAUTEUR - 1, BORD, D_BORD);
    }
    for (y = 1; y < HAUTEUR - 1; ++y) {
        case_pose(0, y, BORD, D_BORD);
        case_pose(LARGEUR - 1, y, BORD, D_BORD);
    }
    if (l > 1)                               /* porte de gauche : retour */
        for (y = ly - 1; y <= ly + 1; ++y) case_pose(0, y, VIDE, D_VIDE);
    if (!n->cree) {
        murs_tire(l);
    } else {
        for (k = 0; k < n->nmurs; ++k)
            for (y = n->y1[k]; y <= n->y2[k]; ++y)
                for (x = n->x1[k]; x <= n->x2[k]; ++x) grille[y][x] = MUR;
    }
    for (y = 1; y < HAUTEUR - 1; ++y)
        for (x = 1; x < LARGEUR - 1; ++x)
            if (grille[y][x] == MUR) case_dessine(x, y, D_MUR);
    if (n->ouverte) porte_ouvre(l);
}

void porte_ouvre(unsigned char l)
{
    unsigned char y;
    niveaux[l].ouverte = 1;
    for (y = niveaux[l].porte; y < niveaux[l].porte + 3; ++y)
        case_pose(LARGEUR - 1, y, VIDE, D_VIDE);
}

void pomme_pose(void)
{
    unsigned char x, y;
    do {                                     /* avec une case libre de chaque côté */
        x = 2 + rand() % (LARGEUR - 4);      /* (pour les attributs de couleur)    */
        y = 1 + rand() % (HAUTEUR - 2);
    } while (grille[y][x] != VIDE || grille[y][x - 1] != VIDE || grille[y][x + 1] != VIDE);
    pomme_x = x;
    pomme_y = y;
    grille[y][x] = POMME;
    pomme_jaune(x, y);
}
