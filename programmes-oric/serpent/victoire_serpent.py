#!/usr/bin/env python3
"""
victoire_serpent.py — dessine l'écran de victoire du jeu SERPENT (« GAGNÉ ! »,
une coupe, des pommes, le serpent complet) au format HIRES de l'Oric Atmos.
Créé le 2026-11-23 by GliouCNR©70

  python3 victoire_serpent.py         (il faut Pillow : pip install pillow)

Produit :
  serpent-victoire.hir            les 8 000 octets de l'écran HIRES
  captures/serpent-victoire.png   aperçu recalculé à partir des octets, x3

Même format et mêmes règles que titre_serpent.py (dont on reprend la palette,
la conversion et l'aperçu) : une seule couleur d'encre à la fois sur une ligne,
il faut une case vide de 6 pixels pour en changer. Les trois lignes de texte
sous l'image (score, pommes) sont écrites par le jeu lui-même.
"""
import math
import os

from PIL import Image, ImageDraw

from titre_serpent import (W, H, PALETTE, NOIR, ROUGE, VERT, JAUNE, BLEU, MAGENTA,
                           CYAN, BLANC, FONT_TITRE, FONT_TEXTE, police, vers_hires, apercu)

HERE = os.path.dirname(os.path.abspath(__file__))


def pomme(d, x, y):
    """Petite pomme magenta (14 x 16) avec queue et feuille vertes : la queue
    est sur des lignes à part (une seule encre par ligne)."""
    d.ellipse((x, y + 4, x + 9, y + 15), fill=MAGENTA)
    d.ellipse((x + 5, y + 4, x + 14, y + 15), fill=MAGENTA)
    d.polygon([(x + 5, y + 4), (x + 7, y + 6), (x + 9, y + 4)], fill=NOIR)
    d.point((x + 3, y + 8), NOIR)
    d.point((x + 3, y + 9), NOIR)
    d.line((x + 7, y + 3, x + 7, y), fill=VERT)
    d.line((x + 8, y + 1, x + 11, y), fill=VERT)


def dessiner():
    img = Image.new("P", (W, H), 0)
    img.putpalette(sum(PALETTE, ()))
    d = ImageDraw.Draw(img)

    # Étoiles (bleu) et étincelles (blanc), loin du reste
    for x, y in [(14, 4), (64, 2), (176, 3), (226, 6), (8, 60), (232, 58),
                 (4, 140), (236, 96), (12, 186), (230, 190)]:
        d.point((x, y), BLEU)

    # ---- GAGNÉ ! : grandes lettres, dégradé jaune -> rouge (comme le titre) ----
    texte = "GAGNÉ !"
    taille = 48
    while True:
        f = police(FONT_TITRE, taille)
        x0, y0, x1, y1 = d.textbbox((0, 0), texte, font=f)
        if x1 - x0 <= 210:
            break
        taille -= 1
    tw, th = x1 - x0, y1 - y0
    masque = Image.new("1", (W, H), 0)
    ImageDraw.Draw(masque).text(((W - tw) // 2 - x0 + 6, 6 - y0), texte, font=f, fill=1)
    haut, bas = 6, 6 + th
    for y in range(haut, bas + 1):
        t = (y - haut) / max(1, bas - haut)
        coul = ROUGE if (y * 7 % 10) / 10 < t else JAUNE
        for x in range(W):
            if masque.getpixel((x, y)):
                img.putpixel((x, y), coul)
    gauche = (W - tw) // 2 + 6
    d.rectangle((gauche + 6, bas + 5, gauche + tw - 6, bas + 6), fill=CYAN)

    # ---- La coupe (jaune), « 256 » gravé dessus ----
    cx = 126                                   # milieu de la coupe
    ht = bas + 16                              # haut de la coupe
    for s in (-1, 1):                                                      # anses
        ax = cx + s * 27
        d.ellipse((ax - 9, ht + 3, ax + 9, ht + 25), outline=JAUNE, width=3)
    d.rectangle((cx - 26, ht, cx + 26, ht + 3), fill=JAUNE)               # rebord
    d.chord((cx - 26, ht - 26, cx + 26, ht + 46), 0, 180, fill=JAUNE)     # coupe
    d.rectangle((cx - 4, ht + 46, cx + 4, ht + 58), fill=JAUNE)           # pied
    d.polygon([(cx - 10, ht + 58), (cx + 10, ht + 58), (cx + 18, ht + 66),
               (cx - 18, ht + 66)], fill=JAUNE)                            # socle
    d.rectangle((cx - 20, ht + 66, cx + 20, ht + 70), fill=JAUNE)
    fc = police(FONT_TITRE, 17)
    bx0, by0, bx1, by1 = d.textbbox((0, 0), "256", font=fc)
    d.text((cx - (bx1 - bx0) // 2 - bx0, ht + 12 - by0), "256", font=fc, fill=NOIR)
    d.arc((cx - 20, ht + 6, cx + 4, ht + 42), 150, 200, fill=NOIR)        # reflet

    # ---- Pommes de part et d'autre (magenta), assez loin des anses ----
    for x, y in [(18, ht + 2), (50, ht + 24), (22, ht + 48),
                 (190, ht + 4), (206, ht + 30), (178, ht + 50)]:
        pomme(d, x, y)

    # ---- Le serpent complet, sous la coupe : corps ondulé vert, tête à droite ----
    cy = ht + 88
    pts = [(24 + i, cy + 5 * math.sin(i / 170 * 4 * math.pi)) for i in range(170)]
    for i, (x, y) in enumerate(pts):
        r = 2 + 3 * min(1, i / 40)
        d.ellipse((x - r, y - r, x + r, y + r), fill=VERT)
    for i in range(46, 166, 6):                 # anneaux : petits creux noirs
        x, y = pts[i]
        d.point((x, y), NOIR)
    hx, hy = pts[-1]
    d.ellipse((hx - 3, hy - 7, hx + 13, hy + 7), fill=VERT)               # tête
    d.rectangle((hx + 6, hy - 4, hx + 8, hy - 2), fill=NOIR)              # œil
    lx = (int(hx + 13) // 6 + 2) * 6            # case vide avant la langue rouge
    d.line((lx, hy, lx + 8, hy), fill=ROUGE)
    d.line((lx + 8, hy, lx + 11, hy - 3), fill=ROUGE)
    d.line((lx + 8, hy, lx + 11, hy + 3), fill=ROUGE)

    # ---- Texte ----
    ft = police(FONT_TEXTE, 13)
    for txt, y, c in (("LE SERPENT EST COMPLET", cy + 14, CYAN),
                      ("256 ANNEAUX !", cy + 28, BLANC)):
        bx0, _, bx1, _ = d.textbbox((0, 0), txt, font=ft)
        d.text(((W - (bx1 - bx0)) // 2 + 6, y), txt, font=ft, fill=c)
    return img


def main():
    hires, conflits = vers_hires(dessiner())
    open(os.path.join(HERE, "serpent-victoire.hir"), "wb").write(hires)
    os.makedirs(os.path.join(HERE, "captures"), exist_ok=True)
    apercu(hires).save(os.path.join(HERE, "captures", "serpent-victoire.png"))
    print(f"serpent-victoire.hir : {len(hires)} octets, {conflits} case(s) de couleur approchée")


if __name__ == "__main__":
    main()
