/* disque.h - lecture et écriture d'un secteur de la disquette Microdisc, en C.
** Créé le 2026-11-26 by GliouCNR©70
*/
#ifndef DISQUE_H
#define DISQUE_H

extern unsigned char secteur[256];      /* tampon d'un secteur */

unsigned char disque_present(void);     /* 1 si le jeu a démarré de la disquette */
unsigned char disque_lit(void);         /* piste 0, secteur 18 -> secteur[] ; 0 = bon */
unsigned char disque_ecrit(void);       /* secteur[] -> piste 0, secteur 18 ; 0 = bon */

#endif
