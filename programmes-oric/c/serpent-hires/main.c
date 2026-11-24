/* main.c - SERPENT en C et en HIRES pour Oric Atmos (cc65).
** Créé le 2026-11-24 by GliouCNR©70
**
** Le programme est découpé en modules, importés ici par leurs fichiers .h :
**   config.h    constantes (grille, types de case, adresses de l'Atmos)
**   ecran.c/h   HIRES, dessins des cases 6 x 6, lignes de texte, écran texte
**   son.c/h     le moteur de son du Serpent BASIC (son.s), réutilisé
**   clavier.c/h touches lues par la ROM, attentes
**   niveau.c/h  les 5 tableaux : bord, portes, murs, pommes
**   jeu.c/h     une partie
**   hof.c/h     Hall of Fame, volume, records, écran de victoire
** Compilation : ./faire.sh (voir LISEZ-MOI.md).
*/
#include <stdlib.h>
#include "config.h"
#include "ecran.h"
#include "clavier.h"
#include "son.h"
#include "jeu.h"
#include "hof.h"

int main(void)
{
    unsigned char musique = MUS_COMPTINE;

    ecran_prepare();
    son_installe();
    hof_raz();
    ecran_texte();
    for (;;) {
        son_volume(volume);
        son_musique(musique);
        hof_ecran();
        son_stop();
        srand(DEEK(HORLOGE));
        if (partie(hof_meilleur()) == GAGNE) {
            ecran_texte();
            victoire(score, pommes_mangees);
            musique = MUS_COMPTINE;
        } else {
            ecran_texte();
            musique = MUS_PERDU;
        }
        hof_record(score, pommes_mangees);
        texte_efface();
    }
    return 0;
}
