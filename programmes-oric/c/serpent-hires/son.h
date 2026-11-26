/* son.h - moteur de son du Serpent, en C (son.c), musiques dans musiques.c.
** Créé le 2026-11-24 by GliouCNR©70 - réécrit en C le 2026-11-26 by
** GliouCNR©70 (il réutilisait jusque-là le moteur 6502 du Serpent BASIC).
*/
#ifndef SON_H
#define SON_H

#define MUS_TITRE    0                /* Pastorale (titre, Hall of Fame)   */
#define MUS_PERDU    1                /* « perdu » (Hall of Fame)          */
#define MUS_VICTOIRE 2                /* Ode à la joie (image de victoire) */

void son_installe(void);              /* branche le moteur sur l'horloge */
void son_volume(unsigned char vu);    /* 0 à 64, comme la barre du jeu   */
void son_pas(void);                   /* tic-tac d'un pas                */
void son_pomme(void);                 /* « pip » aigu : une pomme apparaît */
void son_ping(void);                  /* pomme mangée                    */
void son_zap(void);                   /* porte, victoire                 */
void son_boum(void);                  /* EXPLODE : perdu                 */
void son_musique(unsigned char morceau);
void son_stop(void);                  /* coupe la musique et les sons    */

#endif
