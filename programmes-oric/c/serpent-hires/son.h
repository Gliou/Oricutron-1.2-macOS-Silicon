/* son.h - le moteur de son du Serpent BASIC (../../serpent/son.s), réutilisé.
** Créé le 2026-11-24 by GliouCNR©70
**
** Le même moteur 6502 (volume réglable, tic-tac, PING, ZAP, EXPLODE, trois
** musiques à 2 voix) est réassemblé en $8B00 par faire.sh, rangé dans
** son_bin.h, et recopié à sa place au démarrage.
*/
#ifndef SON_H
#define SON_H

#define MUS_COMPTINE 0
#define MUS_PERDU    1
#define MUS_FANFARE  2

void son_installe(void);              /* recopie et branche le moteur  */
void son_volume(unsigned char vu);    /* 0 à 64, comme la barre du jeu */
void son_pas(void);
void son_pomme(void);                 /* « pip » aigu : une pomme apparaît */
void son_ping(void);
void son_zap(void);
void son_boum(void);
void son_musique(unsigned char morceau);
void son_stop(void);                  /* coupe la musique              */

#endif
