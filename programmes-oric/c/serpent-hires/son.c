/* son.c - moteur de son du Serpent, écrit en C.
** Créé le 2026-11-24 by GliouCNR©70 - réécrit en C le 2026-11-26 by
** GliouCNR©70 (il réutilisait jusque-là le moteur 6502 du Serpent BASIC).
**
** Même principe que le moteur 6502 (../../serpent/son.s) : une fonction C
** branchée sur l'interruption de l'horloge de l'Oric (VIA, 100 fois par
** seconde, set_irq de cc65) fait baisser elle-même le volume des sons, au
** VOLUME choisi par le joueur (les sons de la ROM partent toujours de 15) :
**   canal A - tic-tac des pas, « pip » d'une nouvelle pomme, mélodie ;
**   canal B - PING (pomme mangée), ZAP (porte, victoire) ;
**   canal C - EXPLODE (bruit), basse des musiques.
** Puce son AY-3-8912 : on l'écrit par le port A du VIA ($030F) et le registre
** PCR ($030C), comme la routine WriteToAY de la ROM ($F590).
**
** L'interruption ne lit les tables que par simple indexation (indices d'un
** octet, tableaux de musiques.c) : sans pointeur, elle ne touche pas aux cases
** de page zéro du C (ptr1, tmp1...) que le programme principal peut être en
** train d'utiliser. Le programme principal, lui, coupe les interruptions
** (SEI) le temps d'écrire dans la puce.
*/
#include <6502.h>
#include "config.h"
#include "son.h"
#include "musiques.h"

#define VIA_PCR  0x030C
#define VIA_IFR  0x030D
#define VIA_ORA  0x030F

static unsigned char pile_irq[96];      /* pile du C pendant l'interruption */

static unsigned char vol = 8;           /* 0 à 15 */
static unsigned char ton = 0x60;        /* hauteur du tic-tac */
static unsigned char ga;                /* tops restants du tic (canal A) */
static unsigned char lb, cb;            /* PING : volume, tops avant baisse */
static unsigned char rb, pb;            /* ZAP : tops restants, période */
static unsigned char lc, cc;            /* EXPLODE : volume, tops avant baisse */
static unsigned char chanson;           /* morceau en cours */
static unsigned char mt, mi;            /* mélodie : tops restants (0 = rien), note */
static unsigned char bt, bi;            /* basse : tops restants, note */

/* ----- Écriture d'un registre de la puce (comme $F590) ----- */
static void ay(unsigned char reg, unsigned char val)
{
    unsigned char pcr;
    if (reg == 7) val |= 0x40;          /* port A en sortie : le clavier */
    POKE(VIA_ORA, reg);
    pcr = PEEK(VIA_PCR) | 0xEE;         /* choisit le registre */
    POKE(VIA_PCR, pcr);
    pcr = (pcr & 0x11) | 0xCC;          /* puis repos */
    POKE(VIA_PCR, pcr);
    POKE(VIA_ORA, val);
    POKE(VIA_PCR, pcr | 0xEC);          /* écrit la valeur */
    POKE(VIA_PCR, pcr);
}

/* SEI() et CLI() : macros de <6502.h> (coupe / rétablit les interruptions) */

/* ----- Musique : note suivante de la mélodie (canal A) et de la basse (C) -----
** Variables globales seulement (pas de variables locales ni de comparaison
** d'entiers) : le code produit n'appelle aucune routine de cc65 qui se
** servirait de la page zéro. */
static unsigned char nmel, nbas;        /* notes du morceau en cours */
static unsigned char np, nd, nh;        /* période (et partie haute), durée */

static void note(void)
{
    if (mi == nmel) mi = 0;             /* fin : on reprend au début */
    if (chanson == MUS_PERDU)         { np = perd_per[mi]; nd = perd_dur[mi]; }
    else if (chanson == MUS_VICTOIRE) { np = joie_per[mi]; nd = joie_dur[mi]; }
    else                              { np = past_per[mi]; nd = past_dur[mi]; }
    ++mi;
    if (np == 1) ay(8, 0);              /* silence */
    else { ay(0, np); ay(8, vol); }
    mt = nd;
}

static void basse(void)
{
    if (bi == nbas) bi = 0;
    if (chanson == MUS_PERDU)         { np = perd_blo[bi]; nh = perd_bhi[bi]; nd = perd_bdur[bi]; }
    else if (chanson == MUS_VICTOIRE) { np = joie_blo[bi]; nh = joie_bhi[bi]; nd = joie_bdur[bi]; }
    else                              { np = past_blo[bi]; nh = past_bhi[bi]; nd = past_bdur[bi]; }
    ++bi;
    if (np == 1) ay(10, 0);
    else { ay(4, np); ay(5, nh); ay(10, vol); }
    bt = nd;
}

/* ----- L'interruption : 100 fois par seconde ----- */
static unsigned char tic(void)
{
    if (!(PEEK(VIA_IFR) & 0x40)) return IRQ_NOT_HANDLED;   /* pas l'horloge */
    if (ga && --ga == 0) ay(8, 0);                         /* fin du tic */
    if (mt) {                                              /* mélodie */
        if (--mt == 3) ay(8, 0);                           /* notes détachées */
        if (mt == 0) note();
    }
    if (bt) {                                              /* basse */
        if (--bt == 10) ay(10, 0);
        if (bt == 0) basse();
    }
    if (rb) {                                              /* ZAP : balayage */
        pb += 4;
        ay(2, pb);
        if (--rb == 0) ay(9, 0);
    } else if (lb && --cb == 0) {                          /* PING qui s'éteint */
        cb = 6;
        ay(9, --lb);
    }
    if (lc && --cc == 0) {                                 /* EXPLODE qui s'éteint */
        cc = 10;
        ay(10, --lc);
    }
    return IRQ_NOT_HANDLED;             /* la ROM fait ensuite son travail (clavier) */
}

/* ----- Fonctions appelées par le jeu ----- */
void son_stop(void)
{
    unsigned char r;
    SEI();
    ay(7, 0x1C);                        /* sons A et B, bruit sur C */
    ay(6, 0x1F);                        /* hauteur du bruit (comme EXPLODE) */
    ay(1, 0);
    ay(3, 0);
    for (r = 8; r < 11; ++r) ay(r, 0);
    ga = lb = rb = lc = mt = bt = 0;
    CLI();
}

void son_installe(void)
{
    son_stop();
    set_irq(tic, pile_irq, sizeof pile_irq);
}

void son_volume(unsigned char vu)
{
    vol = (vu * 15 + 32) / 64;
}

static void tic_tac(unsigned char hauteur)
{
    SEI();
    ay(0, hauteur);
    ay(8, vol);
    ga = 3;
    CLI();
}

void son_pas(void)
{
    tic_tac(ton);
    ton ^= 0x30;                        /* tic <-> tac */
}

void son_pomme(void)
{
    tic_tac(0x1C);                      /* « pip » aigu, ~2 200 Hz */
}

void son_ping(void)
{
    SEI();
    rb = 0;                             /* arrête un ZAP */
    ay(2, 0x18);
    lb = vol;
    cb = 6;
    ay(9, vol);
    CLI();
}

void son_zap(void)
{
    SEI();
    lb = 0;
    pb = 0;
    rb = 28;
    ay(9, vol);
    CLI();
}

void son_boum(void)
{
    SEI();
    lc = vol;
    cc = 10;
    ay(10, vol);
    CLI();
}

void son_musique(unsigned char morceau)
{
    SEI();
    chanson = morceau;
    if (morceau == MUS_PERDU)         { nmel = PERD_NOTES; nbas = PERD_BASSES; }
    else if (morceau == MUS_VICTOIRE) { nmel = JOIE_NOTES; nbas = JOIE_BASSES; }
    else                              { nmel = PAST_NOTES; nbas = PAST_BASSES; }
    ay(7, 0x38);                        /* sons A, B et C, pas de bruit */
    mi = bi = 0;
    note();
    basse();
    CLI();
}
