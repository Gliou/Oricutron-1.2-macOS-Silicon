/* pilote.c - pilote automatique, pour la version de test seulement.
** Créé le 2026-11-24 by GliouCNR©70
**
** Parcours en largeur depuis la cible (pomme, ou porte de droite ouverte) :
** chaque case sans mur reçoit sa distance à la cible ; la tête prend la case
** voisine libre la plus proche, sans faire demi-tour. Le parcours (lent sur
** le 6502) n'est refait que quand la cible change ; le corps du serpent n'y
** compte pas (il bouge), seulement au moment de choisir la case.
*/
#ifdef PILOTE
#include <string.h>
#include "config.h"
#include "clavier.h"
#include "niveau.h"
#include "pilote.h"

#define NCASES (LARGEUR * HAUTEUR)

static unsigned char dist[NCASES];
static unsigned int file[NCASES];
static unsigned char der_x = 255, der_y, der_niv;

static const signed char ddx[4] = { -1, 1, 0, 0 };
static const signed char ddy[4] = { 0, 0, 1, -1 };
static const unsigned char tch[4] = { T_GAUCHE, T_DROITE, T_BAS, T_HAUT };

static void parcours(unsigned int cible)
{
    const unsigned char* g = &grille[0][0];
    unsigned int deb = 0, fin = 0, c, v;
    unsigned char d;
    memset(dist, 255, NCASES);
    dist[cible] = 0;
    file[fin++] = cible;
    while (deb < fin) {
        c = file[deb++];
        d = dist[c] + 1;
        if (d > 250) continue;
        /* bord et murs ne sont jamais au bord de l'écran : pas de débordement,
        ** sauf aux portes (colonnes 0 et 37) - on s'arrête à la ligne */
        v = c - 1;        if ((c % LARGEUR) && dist[v] == 255 && (g[v] == VIDE || g[v] == POMME || g[v] == CORPS)) { dist[v] = d; file[fin++] = v; }
        v = c + 1;        if ((v % LARGEUR) && dist[v] == 255 && (g[v] == VIDE || g[v] == POMME || g[v] == CORPS)) { dist[v] = d; file[fin++] = v; }
        v = c + LARGEUR;  if (v < NCASES && dist[v] == 255 && (g[v] == VIDE || g[v] == POMME || g[v] == CORPS)) { dist[v] = d; file[fin++] = v; }
        if (c >= LARGEUR) { v = c - LARGEUR; if (dist[v] == 255 && (g[v] == VIDE || g[v] == POMME || g[v] == CORPS)) { dist[v] = d; file[fin++] = v; } }
    }
}

unsigned char pilote_choix(unsigned char x, unsigned char y,
                           signed char dx, signed char dy, unsigned char niv)
{
    unsigned char cx, cy, nx, ny, i, c, meilleur = 255, choix = 4;
    unsigned int k;

    if (niv < NIVEAUX && niveaux[niv].ouverte) { cx = LARGEUR - 1; cy = niveaux[niv].porte + 1; }
    else { cx = pomme_x; cy = pomme_y; }
    if (cx != der_x || cy != der_y || niv != der_niv) {
        parcours((unsigned int)cy * LARGEUR + cx);
        der_x = cx; der_y = cy; der_niv = niv;
    }
    for (i = 0; i < 4; ++i) {
        if (ddx[i] == -dx && ddy[i] == -dy) continue;        /* pas de demi-tour */
        nx = x + ddx[i]; ny = y + ddy[i];
        c = grille[ny][nx];
        if (c != VIDE && c != POMME) continue;
        k = (unsigned int)ny * LARGEUR + nx;
        if (choix == 4 || dist[k] < meilleur) { meilleur = dist[k]; choix = i; }
    }
    if (choix == 4 || (ddx[choix] == dx && ddy[choix] == dy)) return 0;
    return tch[choix];
}
#endif
