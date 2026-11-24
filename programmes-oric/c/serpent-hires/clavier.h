/* clavier.h - lecture du clavier par la ROM (sans attendre).
** Créé le 2026-11-24 by GliouCNR©70
*/
#ifndef CLAVIER_H
#define CLAVIER_H

#define T_GAUCHE  8
#define T_DROITE  9
#define T_BAS     10
#define T_HAUT    11
#define T_RETOUR  13
#define T_ESPACE  32
#define T_EFFACE  127

unsigned char touche(void);          /* 0 si aucune nouvelle touche */
unsigned char attend_touche(void);
void attend(unsigned char centiemes);

#endif
