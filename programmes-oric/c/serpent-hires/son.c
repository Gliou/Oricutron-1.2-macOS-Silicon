/* son.c - le moteur de son du Serpent BASIC, réutilisé depuis le C.
** Créé le 2026-11-24 by GliouCNR©70
*/
#include <string.h>
#include "config.h"
#include "son.h"
#include "son_bin.h"            /* SON_ADR et son_bin[] (fabriqués par faire.sh) */

typedef void (*routine)(void);
#define APPEL(dec) ((routine)(SON_ADR + (dec)))()

void son_installe(void)
{
    memcpy((void*)SON_ADR, son_bin, sizeof son_bin);
    APPEL(0x00);                        /* INIT */
}

void son_volume(unsigned char vu)
{
    POKE(SON_ADR + 0x0F, (vu * 15 + 32) / 64);
}

void son_pas(void)  { APPEL(0x03); }
void son_ping(void) { APPEL(0x06); }
void son_zap(void)  { APPEL(0x09); }
void son_boum(void) { APPEL(0x0C); }

void son_musique(unsigned char morceau)
{
    POKE(SON_ADR + 0x13, morceau);
    APPEL(0x10);
}

void son_stop(void) { APPEL(0x00); }
