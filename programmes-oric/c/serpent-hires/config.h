/* config.h - constantes communes du Serpent en C (HIRES) pour Oric Atmos.
** Créé le 2026-11-24 by GliouCNR©70
**
** Le terrain est une grille de cases de 6 x 6 points : une case = 1 octet de
** large (6 points) sur 6 lignes de l'écran HIRES. 38 colonnes (octets 2 à 39 ;
** les octets 0 et 1 de chaque ligne sont réservés aux attributs de couleur)
** et 33 lignes (lignes HIRES 0 à 197).
*/
#ifndef CONFIG_H
#define CONFIG_H

#define LARGEUR     38          /* colonnes de cases : 0 et 37 = bord      */
#define HAUTEUR     33          /* lignes de cases : 0 et 32 = bord        */
#define COTE        6           /* une case = 6 x 6 points                 */

/* Contenu d'une case (tableau grille[][] : sert aux collisions) */
#define VIDE        0
#define BORD        1
#define MUR         2
#define POMME       3
#define CORPS       4

#define NIVEAUX     5
#ifndef GAGNE_LONG                  /* (la version de test peut les changer) */
#define GAGNE_LONG  256         /* longueur qui gagne la partie            */
#endif
#ifndef POMMES_PORTE
#define POMMES_PORTE 5          /* pommes à manger pour ouvrir la porte    */
#endif

/* Mémoire et ROM de l'Atmos (ROM 1.1) */
#define PEEK(a)     (*(volatile unsigned char*)(a))
#define POKE(a,v)   (*(volatile unsigned char*)(a) = (v))
#define DEEK(a)     (*(volatile unsigned int*)(a))

#define HIRES_ECRAN 0xA000      /* 200 lignes de 40 octets                 */
#define TEXTE_HIRES 0xBF68      /* 3 lignes de texte sous l'image HIRES    */
#define TEXTE_ECRAN 0xBB80      /* écran texte, 28 lignes de 40            */
#define JEU_HIRES   0x9800      /* jeu de caractères quand HIRES est actif */
#define JEU_TEXTE   0xB400      /* jeu de caractères en mode texte         */
#define TOUCHE      0x02DF      /* dernière touche lue par la ROM (bit 7)  */
#define HORLOGE     0x0276      /* compteur de la ROM, -1 tous les 1/100 s */

#endif
