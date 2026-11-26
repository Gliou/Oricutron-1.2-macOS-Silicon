/* disque.c - lecture et écriture d'un secteur de la disquette Microdisc, en C.
** Créé le 2026-11-26 by GliouCNR©70
**
** Le contrôleur de disquette WD1793 du Microdisc est piloté directement, comme
** le fait la routine 6502 du Serpent BASIC (../../serpent/hof_disque.s) :
**   $0310 commande (en écriture) / état (en lecture, bit 0 = occupé)
**   $0312 secteur    $0313 données    $0318 bit 7 à 0 = un octet est prêt
** Le secteur passe octet par octet toutes les 32 microsecondes : la boucle est
** écrite pour être courte (indice d'un octet, tableau à adresse fixe) et les
** interruptions sont coupées pendant le transfert.
** La tête est déjà sur la piste 0 : le démarrage y a fini sa lecture, et le
** jeu ne la déplace jamais. Le jeu démarré de la disquette le sait par la
** marque 68 que le chargeur pose en $04FF (comme pour le Serpent BASIC).
*/
#include <6502.h>
#include "config.h"
#include "disque.h"

#define FDC_CMD  0x0310
#define FDC_SEC  0x0312
#define FDC_DAT  0x0313
#define MD_DRQ   0x0318
#define SECTEUR  18
#define LIRE     0x80
#define ECRIRE   0xA0

unsigned char secteur[256];
static unsigned char i, etat;

unsigned char disque_present(void)
{
    return PEEK(0x04FF) == 68;
}

static void commande(unsigned char c)
{
    POKE(FDC_SEC, SECTEUR);
    POKE(FDC_CMD, c);
    for (i = 0; i < 8; ++i) ;            /* le contrôleur met l'état à jour */
    i = 0;
}

unsigned char disque_lit(void)
{
    SEI();
    commande(LIRE);
    for (;;) {
        while ((signed char)PEEK(MD_DRQ) < 0)   /* pas d'octet prêt (bit 7) ... */
            if (!((etat = PEEK(FDC_CMD)) & 1)) goto fini;   /* ... et fini */
        secteur[i] = PEEK(FDC_DAT);
        ++i;
    }
fini:
    CLI();
    return etat & 0x2E;                  /* protégée, introuvable, CRC, perdu */
}

unsigned char disque_ecrit(void)
{
    SEI();
    commande(ECRIRE);
    for (;;) {
        while ((signed char)PEEK(MD_DRQ) < 0)
            if (!((etat = PEEK(FDC_CMD)) & 1)) goto fini;
        POKE(FDC_DAT, secteur[i]);
        ++i;
    }
fini:
    CLI();
    return etat & 0x2E;
}
