/* main.c - SERPENT en C et en HIRES pour Oric Atmos (cc65).
** Créé le 2026-11-24 by GliouCNR©70
**
** Le programme est découpé en modules, importés ici par leurs fichiers .h :
**   config.h    constantes (grille, types de case, adresses de l'Atmos)
**   ecran.c/h   HIRES, dessins des cases 6 x 6, lignes de texte, écran texte
**   son.c/h     moteur de son en C, sur l'interruption de l'horloge
**   clavier.c/h touches lues par la ROM, attentes
**   niveau.c/h  les 5 tableaux : bord, portes, murs, pommes
**   jeu.c/h     une partie
**   hof.c/h     Hall of Fame, volume, records (sauvegardés sur disquette)
**   disque.c/h  lecture / écriture d'un secteur de la disquette (WD1793)
**   musiques.c/h les trois morceaux (tables de notes)
**   images.c/h  écran titre et écran de victoire en HIRES (images du BASIC)
** Compilation : ./faire.sh (voir LISEZ-MOI.md).
*/
#include <stdlib.h>
#include "config.h"
#include "ecran.h"
#include "clavier.h"
#include "son.h"
#include "jeu.h"
#include "hof.h"
#include "images.h"

int main(void)
{
    ecran_prepare();
    son_installe();
    hof_raz();
    hof_charge();                       /* Hall of Fame et volume de la disquette */
    son_volume(volume);
    ecran_titre();                      /* la comptine démarre avec l'image */
    ecran_texte();
    for (;;) {
        hof_ecran();                    /* la musique joue déjà, volume réglé */
        son_stop();
        srand(DEEK(HORLOGE));
        if (partie(hof_meilleur()) == GAGNE) {
            ecran_victoire(score, pommes_mangees);   /* fanfare sur l'image seulement */
            ecran_texte();
            hof_record(score, pommes_mangees);
            son_musique(MUS_TITRE);
        } else {
            ecran_texte();
            hof_record(score, pommes_mangees);
            son_musique(MUS_PERDU);     /* air « perdu » sur le Hall of Fame */
        }
    }
    return 0;
}
