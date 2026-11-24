/* niveau.h - les 5 tableaux : bord, portes, murs, pommes.
** Créé le 2026-11-24 by GliouCNR©70
*/
#ifndef NIVEAU_H
#define NIVEAU_H

#include "config.h"

#define MAXMURS 24

typedef struct {
    unsigned char cree;          /* murs déjà tirés (on les retrouve au retour) */
    unsigned char ouverte;       /* porte de droite ouverte                     */
    unsigned char pommes;        /* pommes mangées dans ce tableau              */
    unsigned char porte;         /* hauteur de la porte de droite (3 cases)     */
    unsigned char nmurs;
    unsigned char x1[MAXMURS], y1[MAXMURS], x2[MAXMURS], y2[MAXMURS];
} Niveau;

extern unsigned char grille[HAUTEUR][LARGEUR];
extern Niveau niveaux[NIVEAUX + 1];          /* 1 à 5 */
extern unsigned char pomme_x, pomme_y;       /* la pomme posée */

void niveaux_raz(void);
unsigned char entree_gauche(unsigned char l); /* milieu de la porte de gauche */
void niveau_dessine(unsigned char l);
void porte_ouvre(unsigned char l);
void case_pose(unsigned char x, unsigned char y, unsigned char type, unsigned char dessin);
void pomme_pose(void);

#endif
