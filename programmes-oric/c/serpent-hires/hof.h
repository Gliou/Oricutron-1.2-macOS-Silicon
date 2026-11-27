/* hof.h - Hall of Fame (10 meilleurs scores), réglage du volume, records.
** Créé le 2026-11-24 by GliouCNR©70 - modifié le 2026-11-27 : difficulté
*/
#ifndef HOF_H
#define HOF_H

extern unsigned char volume;                 /* 0 à 64, pas de 4 */

void hof_raz(void);                          /* le Hall of Fame livré (ORIC) */
void hof_charge(void);                       /* relu de la disquette (si démarré d'elle) */
unsigned int hof_meilleur(void);
void hof_ecran(void);                        /* affiche, règle difficulté et volume, attend Espace */
void hof_record(unsigned int score, unsigned int pommes);  /* demande le nom si record */

#endif
