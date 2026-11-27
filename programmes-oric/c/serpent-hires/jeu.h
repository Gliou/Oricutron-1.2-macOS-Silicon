/* jeu.h - une partie de Serpent en HIRES.
** Créé le 2026-11-24 by GliouCNR©70 - modifié le 2026-11-27 : difficulté
*/
#ifndef JEU_H
#define JEU_H

#define PERDU 0
#define GAGNE 1

/* Difficulté 1 à 5 (réglée sur le Hall of Fame) : vitesse du serpent */
extern unsigned char difficulte;

/* Résultat de la dernière partie */
extern unsigned int  score;
extern unsigned int  pommes_mangees;

/* Joue une partie ; meilleur = meilleur score du Hall of Fame (HI-SCORE) */
unsigned char partie(unsigned int meilleur);

#endif
