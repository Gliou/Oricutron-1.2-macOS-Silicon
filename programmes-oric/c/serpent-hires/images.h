/* images.h - écran titre et écran de victoire en HIRES.
** Créé le 2026-11-24 by GliouCNR©70
**
** Les deux images du Serpent BASIC (../../serpent/serpent-titre.hir et
** serpent-victoire.hir, 8 000 octets chacune) sont rangées dans images_bin.h
** par faire.sh, puis recopiées dans l'écran HIRES ($A000).
*/
#ifndef IMAGES_H
#define IMAGES_H

void ecran_titre(void);                        /* image titre + comptine, attend Espace */
void ecran_victoire(unsigned int score, unsigned int pommes); /* image + fanfare */

#endif
