/* musiques.h - les trois morceaux du Serpent (tableaux de musiques.c).
** Créé le 2026-11-26 by GliouCNR©70
*/
#ifndef MUSIQUES_H
#define MUSIQUES_H

/* la Pastorale de Beethoven (Symphonie n° 6, 1er mouvement) : titre et Hall of Fame */
#define PAST_NOTES 241
#define PAST_BASSES 67
extern const unsigned char past_per[241];
extern const unsigned char past_dur[241];
extern const unsigned char past_blo[67];
extern const unsigned char past_bhi[67];
extern const unsigned char past_bdur[67];

/* « perdu », air lent en la mineur : Hall of Fame après une défaite */
#define PERD_NOTES 13
#define PERD_BASSES 8
extern const unsigned char perd_per[13];
extern const unsigned char perd_dur[13];
extern const unsigned char perd_blo[8];
extern const unsigned char perd_bhi[8];
extern const unsigned char perd_bdur[8];

/* l'Ode à la joie de Beethoven (Symphonie n° 9) : écran de victoire */
#define JOIE_NOTES 63
#define JOIE_BASSES 33
extern const unsigned char joie_per[63];
extern const unsigned char joie_dur[63];
extern const unsigned char joie_blo[33];
extern const unsigned char joie_bhi[33];
extern const unsigned char joie_bdur[33];

#endif
