/* ecran.h - écran HIRES (cases 6 x 6), lignes de texte, écran texte.
** Créé le 2026-11-24 by GliouCNR©70
*/
#ifndef ECRAN_H
#define ECRAN_H

/* Dessins des cases (6 lignes de 6 points chacun) */
enum {
    D_VIDE, D_BORD, D_MUR, D_POMME, D_CORPS,
    D_TETE_D, D_TETE_G, D_TETE_B, D_TETE_H,     /* tête vers droite, gauche, bas, haut */
    D_QUEUE_D, D_QUEUE_G, D_QUEUE_B, D_QUEUE_H, /* pointe de la queue vers ...         */
    D_NOMBRE
};

void ecran_prepare(void);       /* dessins calculés (rotations) - une fois */
void ecran_hires(void);         /* passe en HIRES, terrain noir, encre verte */
void ecran_texte(void);         /* revient en mode texte, écran vidé        */

void case_dessine(unsigned char x, unsigned char y, unsigned char dessin);
void terrain_vide(void);        /* toutes les cases vides (noir) */

/* Lignes de texte sous l'image HIRES (ligne 0, 1 ou 2) */
void hires_efface_ligne(unsigned char l);
void hires_ecrit(unsigned char x, unsigned char l, const char* s);
void hires_octet(unsigned char x, unsigned char l, unsigned char c);

/* Écran texte (mode TEXT) */
void texte_efface(void);
void texte_ecrit(unsigned char x, unsigned char y, const char* s);
void texte_octet(unsigned char x, unsigned char y, unsigned char c);

/* Nombre écrit dans un tampon, calé à droite sur « largeur » cases */
char* nombre(unsigned int n, unsigned char largeur);

#endif
