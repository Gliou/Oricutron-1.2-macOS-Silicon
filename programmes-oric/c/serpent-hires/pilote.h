/* pilote.h - pilote automatique, pour la version de test seulement.
** Créé le 2026-11-24 by GliouCNR©70
**
** ./faire.sh test : compile avec -DPILOTE (et une porte après 1 pomme, la
** victoire à 40 anneaux) pour vérifier portes, niveaux et victoire sans jouer.
*/
#ifndef PILOTE_H
#define PILOTE_H

/* Flèche à « taper » pour aller vers la pomme (ou la porte ouverte), 0 = rien */
unsigned char pilote_choix(unsigned char x, unsigned char y,
                           signed char dx, signed char dy, unsigned char niv);

#endif
