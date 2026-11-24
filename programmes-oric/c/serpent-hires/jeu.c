/* jeu.c - une partie de Serpent en HIRES.
** Créé le 2026-11-24 by GliouCNR©70
**
** Mêmes règles que le Serpent BASIC : flèches pour diriger, une pomme vaut
** 10 points au niveau 1 ... 50 au niveau 5, la porte de droite s'ouvre après
** 5 pommes (niveaux 1 à 4), la porte de gauche ramène au tableau précédent ;
** perdu contre le bord, un mur ou la queue ; gagné à 256 anneaux.
** Le serpent est rangé dans un anneau de 256 positions (sx, sy) : h = tête,
** t = queue, gr = anneaux encore à pousser.
*/
#include <string.h>
#include "config.h"
#include "ecran.h"
#include "clavier.h"
#include "son.h"
#include "niveau.h"
#include "jeu.h"
#include "pilote.h"

unsigned int score;
unsigned int pommes_mangees;

static unsigned char sx[256], sy[256];
static unsigned char h, t, gr;
static signed char dx, dy;
static unsigned char niv, compte;            /* niveau, compte à rebours actif */
static unsigned int hi;

/* Pas du serpent en centièmes de seconde, par niveau */
static const unsigned char delai[NIVEAUX + 1] = { 0, 16, 14, 12, 11, 10 };

/* Flèches tapées d'avance (2 au plus) : un virage rapide n'est pas perdu */
static unsigned char file[2], nfile;

static unsigned int taille(void)
{
    return (unsigned char)(h - t) + 1 + gr;
}

static unsigned char couleur(unsigned int reste)
{
    if (reste < 21) return 2;                /* vert   */
    if (reste < 61) return 3;                /* jaune  */
    if (reste < 121) return 6;               /* cyan   */
    return 1;                                /* rouge  */
}

/* ----- Barre du haut : NIVEAU 2 - @=20 - RESTE 3 / PORTE OUVERTE -----
** Lignes construites en entier puis centrées (2026-11-24 by GliouCNR©70),
** recentrées à chaque mise à jour (nombres sans espaces autour). */
static void barre_haut(void)
{
    unsigned char e = niveaux[niv].pommes;
    unsigned int r;
    ligne_texte("NIVEAU ");
    ligne_nombre(niv, 1);
    ligne_texte(" - ");
    ligne_car(3);                            /* pomme jaune */
    ligne_car('@');
    ligne_car(7);
    ligne_texte("=");
    ligne_nombre(niv * 10, 1);
    ligne_texte(" - ");
    if (!compte && e >= POMMES_PORTE) {
        ligne_car(1);                        /* rouge */
        ligne_texte("PORTE OUVERTE");
    } else {
        if (compte) {
            r = GAGNE_LONG - taille();
            ligne_car(couleur(r));
        } else {
            r = POMMES_PORTE - e;
            ligne_car(7);
        }
        ligne_texte("RESTE ");
        ligne_nombre(r, 1);
    }
    ligne_pose(0);
}

/* ----- Barre du bas : SCORE, tête + taille, HI-SCORE ----- */
static void barre_bas(void)
{
    unsigned int n = taille();
    ligne_car(6);                            /* cyan */
    ligne_texte("SCORE ");
    ligne_nombre(score, 1);
    ligne_car(' ');
    ligne_car(2);
    ligne_car(123);                          /* tête du serpent */
    ligne_car(couleur(GAGNE_LONG - n));
    ligne_nombre(n, 1);
    ligne_car(' ');
    ligne_car(3);                            /* jaune */
    ligne_texte("HI-SCORE ");
    ligne_nombre(score > hi ? score : hi, 1);
    ligne_pose(2);
}

static void message(const char* s)
{
    ligne_car(7);
    ligne_texte(s);
    ligne_pose(1);
}

static unsigned char dessin_tete(void)
{
    if (dx > 0) return D_TETE_D;
    if (dx < 0) return D_TETE_G;
    return dy > 0 ? D_TETE_B : D_TETE_H;
}

static void dessine_queue(void)
{
    unsigned char s = t + 1;                 /* l'anneau qui suit la queue */
    unsigned char d;
    if (t == h) return;
    if (sx[s] > sx[t]) d = D_QUEUE_G;        /* corps à droite : pointe à gauche */
    else if (sx[s] < sx[t]) d = D_QUEUE_D;
    else if (sy[s] > sy[t]) d = D_QUEUE_H;
    else d = D_QUEUE_B;
    case_dessine(sx[t], sy[t], d);
}

/* ----- Entrée dans un tableau (par la gauche, ou par la droite au retour) ----- */
static void entre(unsigned char longueur, unsigned char par_droite, unsigned char y)
{
    Niveau* n = &niveaux[niv];
    niveau_dessine(niv);
    compte = (niv == NIVEAUX) || (n->pommes >= POMMES_PORTE);
    h = t = 0;
    gr = longueur - 1;
    sx[0] = par_droite ? LARGEUR - 2 : 1;
    sy[0] = y;
    dx = par_droite ? -1 : 1;
    dy = 0;
    case_pose(sx[0], y, CORPS, dessin_tete());
    pomme_pose();
    son_pomme();
    hires_efface_ligne(1);
    barre_haut();
    barre_bas();
    attend(100);
    nfile = 0;
    POKE(TOUCHE, 0);
}

static void lit_clavier(void)
{
    unsigned char k = touche();
    if (k >= T_GAUCHE && k <= T_HAUT && nfile < 2) file[nfile++] = k;
}

static void tourne(void)
{
    unsigned char k;
    if (!nfile) return;
    k = file[0];
    file[0] = file[1];
    --nfile;
    if (k == T_GAUCHE && dx == 0) { dx = -1; dy = 0; }
    else if (k == T_DROITE && dx == 0) { dx = 1; dy = 0; }
    else if (k == T_BAS && dy == 0) { dx = 0; dy = 1; }
    else if (k == T_HAUT && dy == 0) { dx = 0; dy = -1; }
}

unsigned char partie(unsigned int meilleur)
{
    unsigned char nx, ny, c, mange;
    unsigned int t0;

    hi = meilleur;
    score = 0;
    pommes_mangees = 0;
    niveaux_raz();
    ecran_hires();
    niv = 1;
    entre(4, 0, entree_gauche(1));

    /* Les pas sont réglés sur l'horloge (t0 = moment du pas suivant) et non
    ** « attente après le travail » : le temps pris par une pomme (barres,
    ** nouvelle pomme, ~8 centièmes) est pris sur l'attente, sans à-coup. */
    t0 = DEEK(HORLOGE);
    for (;;) {
        t0 -= delai[niv];                    /* l'horloge descend */
        if ((signed int)(DEEK(HORLOGE) - t0) < 0) t0 = DEEK(HORLOGE);   /* en retard */
        while ((signed int)(DEEK(HORLOGE) - t0) > 0) lit_clavier();
#ifdef PILOTE
        if (!nfile && (c = pilote_choix(sx[h], sy[h], dx, dy, niv)) != 0) file[nfile++] = c;
#endif
        tourne();

        nx = sx[h] + dx;
        ny = sy[h] + dy;
        c = grille[ny][nx];
        mange = 0;
        if (c == VIDE) {
            if (nx == LARGEUR - 1 || nx == 0) {      /* une porte */
                c = taille();
                son_ping();
                if (nx) ++niv; else --niv;
                entre(c, nx == 0, ny);
                t0 = DEEK(HORLOGE);
                continue;
            }
        } else if (c == POMME) {
            mange = 1;
        } else if (!(c == CORPS && nx == sx[t] && ny == sy[t] && gr == 0)) {
            son_boum();
            message("PERDU !");
            attend(250);
            return PERDU;
        }

        if (!mange) {
            if (gr) --gr;
            else { case_pose(sx[t], sy[t], VIDE, D_VIDE); ++t; }
        }
        case_dessine(sx[h], sy[h], D_CORPS);         /* l'ancienne tête */
        ++h;
        sx[h] = nx;
        sy[h] = ny;
        case_pose(nx, ny, CORPS, dessin_tete());
        dessine_queue();
        son_pas();

        if (mange) {
#ifdef PILOTE
            unsigned int m0 = DEEK(HORLOGE);     /* mesure : le jeu seul, sans le pilote */
#endif
            score += niv * 10;
            ++pommes_mangees;
            ++niveaux[niv].pommes;
            son_ping();
            if (niveaux[niv].pommes == POMMES_PORTE && niv < NIVEAUX) {
                porte_ouvre(niv);
                son_zap();
            }
            if (niveaux[niv].pommes > POMMES_PORTE) compte = 1;
            if (taille() >= GAGNE_LONG) {
                barre_haut();
                barre_bas();
                son_zap();
                message("GAGNE !");
                attend(250);
                attend(50);
                return GAGNE;
            }
            pomme_pose();
            son_pomme();
            barre_haut();
            barre_bas();
#ifdef PILOTE
            hires_ecrit(2, 1, "POMME :");
            hires_ecrit(10, 1, nombre(m0 - DEEK(HORLOGE), 3));
            hires_ecrit(14, 1, "CENTIEMES");
#endif
        }
    }
}
