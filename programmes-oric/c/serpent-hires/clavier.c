/* clavier.c - lecture du clavier par la ROM (sans attendre).
** Créé le 2026-11-24 by GliouCNR©70
**
** L'interruption de la ROM range la dernière touche en $02DF, bit 7 = touche
** nouvelle (comme PEEK(735) dans le Serpent BASIC). On remet 0 après lecture.
*/
#include "config.h"
#include "clavier.h"

unsigned char touche(void)
{
    unsigned char k = PEEK(TOUCHE);
    if (k < 128) return 0;
    POKE(TOUCHE, 0);
    return k & 0x7F;
}

unsigned char attend_touche(void)
{
    unsigned char k;
    while ((k = touche()) == 0) ;
    return k;
}

void attend(unsigned char centiemes)
{
    unsigned int t0 = DEEK(HORLOGE);
    while ((unsigned int)(t0 - DEEK(HORLOGE)) < centiemes) ;
}
