#!/usr/bin/env python3
"""
titre_basic.py — image titre de la version BASIC du SERPENT : l'image commune
serpent-titre.hir (faite par titre_serpent.py, lue aussi par la version en C)
plus « Version BASIC » en cyan, centré sous la barre cyan du titre.
Créé le 2026-11-24 by GliouCNR©70

  python3 titre_basic.py              (il faut Pillow pour l'aperçu)

Produit :
  serpent-titre-basic.hir            l'image mise sur la disquette BASIC
  captures/serpent-titre-basic.png   aperçu, tel que l'Oric l'affichera

Pourquoi un fichier à part : la version en C reprend serpent-titre.hir et
écrit elle-même « Version C » au même endroit (../c/serpent-hires/images.c).
Le texte est mis dans l'image une fois pour toutes : rien à dessiner pendant
que le BASIC tourne, l'image titre s'affiche aussi vite qu'avant.

Les lettres sont celles de l'Oric (ROM BASIC 1.1, jeu de caractères en $FC78,
6 x 8 points, recopié en $9800 en mode HIRES), une lettre par octet HIRES.
Comme pour « Version C » : lignes 59 à 66, juste sous la barre (lignes 55-56,
octets 4 à 37) ; attribut d'encre cyan (6) dans l'octet vide avant le texte,
retour à l'encre verte (2) de ces lignes juste après.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
TEXTE = "Version BASIC"
LIGNE = 59                       # première des 8 lignes de points
COL = 14                         # octet de la 1re lettre (centré comme « Version C »)
CYAN, VERT = 6, 2

# Dessins des lettres, copiés de la ROM BASIC 1.1 ($FC78 + (code - 32) x 8)
LETTRES = {
    ' ': [0, 0, 0, 0, 0, 0, 0, 0],
    'A': [8, 20, 34, 34, 62, 34, 34, 0],
    'B': [60, 34, 34, 60, 34, 34, 60, 0],
    'C': [28, 34, 32, 32, 32, 34, 28, 0],
    'I': [28, 8, 8, 8, 8, 8, 28, 0],
    'S': [28, 34, 32, 28, 2, 34, 28, 0],
    'V': [34, 34, 34, 34, 34, 20, 8, 0],
    'e': [0, 0, 28, 34, 62, 32, 30, 0],
    'i': [8, 0, 24, 8, 8, 8, 28, 0],
    'n': [0, 0, 60, 34, 34, 34, 34, 0],
    'o': [0, 0, 28, 34, 34, 34, 28, 0],
    'r': [0, 0, 46, 48, 32, 32, 32, 0],
    's': [0, 0, 30, 32, 28, 2, 60, 0],
}


def ajoute_texte(hires):
    img = bytearray(hires)
    for r in range(8):
        p = (LIGNE + r) * 40 + COL
        # la zone doit être vide (0x40) pour ne rien abîmer de l'image
        assert all(b == 0x40 for b in img[p - 1:p + len(TEXTE) + 1]), "zone occupée"
        img[p - 1] = CYAN
        for i, ch in enumerate(TEXTE):
            img[p + i] = 0x40 | LETTRES[ch][r]
        img[p + len(TEXTE)] = VERT
    return bytes(img)


def main():
    src = open(os.path.join(HERE, "serpent-titre.hir"), "rb").read()
    img = ajoute_texte(src)
    open(os.path.join(HERE, "serpent-titre-basic.hir"), "wb").write(img)
    print(f"serpent-titre-basic.hir : {len(img)} octets, « {TEXTE} » octets "
          f"{COL}-{COL + len(TEXTE) - 1}, lignes {LIGNE}-{LIGNE + 7}")
    try:
        from titre_serpent import apercu
        os.makedirs(os.path.join(HERE, "captures"), exist_ok=True)
        apercu(img).save(os.path.join(HERE, "captures", "serpent-titre-basic.png"))
    except ImportError:
        print("(Pillow absent : pas d'aperçu)")


if __name__ == "__main__":
    main()
