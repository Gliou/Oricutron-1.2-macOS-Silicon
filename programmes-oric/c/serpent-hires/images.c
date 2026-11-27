/* images.c - écran titre et écran de victoire en HIRES.
** Créé le 2026-11-24 by GliouCNR©70 - modifié le 2026-11-27 by GliouCNR©70 :
** la version de test (pilote) n'a pas l'image titre, faute de mémoire.
**
** Comme dans le Serpent BASIC : l'image titre s'affiche avec la comptine et
** « APPUIE SUR ESPACE » (effacé à l'appui) ; l'image de victoire avec la
** fanfare (seulement sur cette image), le score et les pommes dans les lignes
** de texte dessous, puis une touche mène au Hall of Fame.
*/
#include <string.h>
#include "config.h"
#include "ecran.h"
#include "clavier.h"
#include "son.h"
#include "images.h"
#include "images_bin.h"         /* titre_bin[] et victoire_bin[] (faire.sh) */

static void affiche(const unsigned char* image)
{
    ecran_hires_seul();
    memcpy((unsigned char*)HIRES_ECRAN, image, 8000);
}

/* Texte en caractères de l'Oric (6 x 8 points, jeu de caractères du mode
** HIRES en $9800) écrit dans l'image : un octet par lettre, 8 lignes, entre
** un attribut d'encre avant et le retour à l'encre d'origine après. */
static void ecrit_image(unsigned char col, unsigned char ligne, const char* s,
                        unsigned char encre, unsigned char encre_apres)
{
    unsigned char r, i;
    unsigned char* p = (unsigned char*)HIRES_ECRAN + ligne * 40 + col;
    for (r = 0; r < 8; ++r) {
        p[-1] = encre;
        for (i = 0; s[i]; ++i)
            p[i] = 0x40 | PEEK(JEU_HIRES + (unsigned char)s[i] * 8 + r);
        p[i] = encre_apres;
        p += 40;
    }
}

void ecran_titre(void)
{
#ifdef PILOTE
    ecran_hires();                  /* version de test : pas d'image titre */
#else
    affiche(titre_bin);
#endif
    /* « Version C » centré sous la barre cyan du titre (lignes 55-56, octets
    ** 4 à 37) : lignes 59 à 66, octets 16 à 24, en cyan ; ces lignes
    ** reprennent ensuite l'encre verte de l'image. 2026-11-24 by GliouCNR©70 */
    ecrit_image(16, 59, "Version C", 6, 2);
    son_musique(MUS_TITRE);
    ligne_car(6);                                    /* encre cyan */
    ligne_texte("APPUIE SUR ESPACE");
    ligne_pose(2);
    POKE(TOUCHE, 0);
    while (attend_touche() != T_ESPACE) ;
    hires_efface_ligne(2);
}

void ecran_victoire(unsigned int score, unsigned int pommes)
{
    affiche(victoire_bin);
    son_musique(MUS_VICTOIRE);
    ligne_car(3);                                    /* jaune */
    ligne_texte("SCORE ");
    ligne_nombre(score, 1);
    ligne_car(5);                                    /* magenta */
    ligne_nombre(pommes, 1);
    ligne_texte(" POMMES MANGEES");
    ligne_pose(0);
    ligne_car(6);
    ligne_texte("APPUIE SUR UNE TOUCHE");
    ligne_pose(2);
    POKE(TOUCHE, 0);
    attend_touche();
    son_stop();                                      /* la fanfare s'arrête */
}
