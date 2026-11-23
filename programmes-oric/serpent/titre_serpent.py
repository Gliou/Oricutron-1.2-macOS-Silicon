#!/usr/bin/env python3
"""
titre_serpent.py — dessine l'écran de présentation du jeu SERPENT au format
HIRES de l'Oric Atmos (240 x 200 pixels, 8 000 octets, adresse $A000).
Créé le 2026-11-22 by GliouCNR©70

  python3 titre_serpent.py            (il faut Pillow : pip install pillow)

Produit :
  serpent-titre.hir            les 8 000 octets de l'écran HIRES ($A000-$BF3F)
  captures/serpent-titre.png   aperçu, recalculé À PARTIR des octets HIRES
                               (donc tel que l'Oric l'affichera), agrandi x3

Rappel du format HIRES : 200 lignes de 40 octets. Un octet dont le bit 6 est à
1 contient 6 pixels (bit 5 = pixel de gauche) ; bit 6 à 0 = attribut : 0-7
couleur d'encre, 16-23 couleur du fond, pour la suite de la ligne (la case de
l'attribut s'affiche en couleur de fond). Chaque ligne commence en encre
blanche sur fond noir. Il n'y a donc qu'UNE couleur d'encre à la fois sur une
ligne : pour changer de couleur, il faut une case vide de 6 pixels où poser
l'attribut. Le dessin laisse ces trous ; le convertisseur les utilise.
"""
import math
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 240, 200
# Couleurs de l'Oric : numéro d'attribut -> RVB
PALETTE = [(0, 0, 0), (255, 0, 0), (0, 255, 0), (255, 255, 0),
           (0, 0, 255), (255, 0, 255), (0, 255, 255), (255, 255, 255)]
NOIR, ROUGE, VERT, JAUNE, BLEU, MAGENTA, CYAN, BLANC = range(8)
FONT_TITRE = ("/System/Library/Fonts/Avenir Next.ttc", 8)      # Heavy
FONT_TEXTE = ("/System/Library/Fonts/Avenir Next.ttc", 0)      # Bold


def police(spec, taille):
    return ImageFont.truetype(spec[0], taille, index=spec[1])


def dessiner():
    """Image 240x200 où chaque pixel vaut un numéro de couleur Oric (0 = noir)."""
    img = Image.new("P", (W, H), 0)
    img.putpalette(sum(PALETTE, ()))
    d = ImageDraw.Draw(img)

    # Étoiles discrètes (bleu), loin de tout le reste
    for x, y in [(20, 6), (60, 3), (110, 8), (170, 4), (215, 9), (228, 70),
                 (225, 100), (30, 150), (222, 160), (200, 190), (40, 192)]:
        d.point((x, y), BLEU)

    # ---- Titre SERPENT : grandes lettres, dégradé jaune -> rouge par lignes ----
    texte = "SERPENT"
    taille = 50
    while True:                                   # le plus grand qui tient en 216 pixels
        f = police(FONT_TITRE, taille)
        x0, y0, x1, y1 = d.textbbox((0, 0), texte, font=f)
        if x1 - x0 <= 216:
            break
        taille -= 1
    tw, th = x1 - x0, y1 - y0
    masque = Image.new("1", (W, H), 0)
    ImageDraw.Draw(masque).text(((W - tw) // 2 - x0 + 6, 16 - y0), texte, font=f, fill=1)
    haut, bas = 16, 16 + th
    for y in range(haut, bas + 1):
        t = (y - haut) / max(1, bas - haut)
        # trame : de plus en plus de lignes rouges en descendant
        coul = ROUGE if (y * 7 % 10) / 10 < t else JAUNE
        for x in range(W):
            if masque.getpixel((x, y)):
                img.putpixel((x, y), coul)
    # Soulignement cyan sous le titre
    gauche = (W - tw) // 2 + 6
    d.rectangle((gauche + 10, bas + 6, gauche + tw - 10, bas + 7), fill=CYAN)

    # ---- Le serpent : corps sinueux vert, tête à droite, langue rouge ----
    cy, amp = 118, 14
    pts = []
    for i in range(0, 150):
        x = 30 + i
        y = cy + amp * math.sin(i / 150 * 2.6 * math.pi)
        pts.append((x, y))
    for i, (x, y) in enumerate(pts):
        r = 3 + 4 * min(1, i / 60)                 # la queue est plus fine
        d.ellipse((x - r, y - r, x + r, y + r), fill=VERT)
    hx, hy = pts[-1]
    d.ellipse((hx - 4, hy - 9, hx + 16, hy + 9), fill=VERT)        # tête
    d.rectangle((hx + 7, hy - 5, hx + 9, hy - 3), fill=NOIR)       # œil
    # écailles : petits trous noirs le long du dos
    for i in range(70, 145, 7):
        x, y = pts[i]
        d.point((x, y - 2), NOIR)
    # langue fourchue rouge (après une case vide pour changer d'encre)
    lx = (int(hx + 16) // 6 + 2) * 6            # une case vide entre tête et langue
    d.line((lx, hy, lx + 10, hy), fill=ROUGE)
    d.line((lx + 10, hy, lx + 14, hy - 3), fill=ROUGE)
    d.line((lx + 10, hy, lx + 14, hy + 3), fill=ROUGE)
    # la pomme @ jaune, au-dessus de la queue
    fa = police(("/System/Library/Fonts/Helvetica.ttc", 1), 30)
    d.text((40, 70), "@", font=fa, fill=JAUNE)

    # ---- Développeur ----
    ft = police(FONT_TEXTE, 13)
    for txt, y, c in (("un jeu de", 150, CYAN), ("GliouCNR©70", 164, BLANC)):
        bx0, _, bx1, _ = d.textbbox((0, 0), txt, font=ft)
        d.text(((W - (bx1 - bx0)) // 2 + 6, y), txt, font=ft, fill=c)
    fs = police(FONT_TEXTE, 10)
    txt = "ORIC ATMOS  -  2026"
    bx0, _, bx1, _ = d.textbbox((0, 0), txt, font=fs)
    d.text(((W - (bx1 - bx0)) // 2 + 6, 184), txt, font=fs, fill=MAGENTA)
    return img


def vers_hires(img):
    """Convertit l'image (numéros de couleur) en 8 000 octets HIRES."""
    out = bytearray()
    conflits = 0
    for y in range(H):
        cases = []
        for c in range(40):
            px = [img.getpixel((c * 6 + k, y)) for k in range(6)]
            coul = [p for p in px if p]
            cases.append((px, max(set(coul), key=coul.count) if coul else None))
        encre = BLANC
        for c, (px, coul) in enumerate(cases):
            if c < 2 and coul is not None:       # les 2 premières cases restent libres
                coul = None
                px = [0] * 6
            if coul is None:
                suivante = next((k for _, k in cases[c + 1:] if k is not None), None)
                if suivante is not None and suivante != encre:
                    out.append(suivante)          # attribut d'encre dans la case vide
                    encre = suivante
                else:
                    out.append(0x40)
            else:
                if coul != encre:
                    conflits += 1                 # pas de case vide avant : couleur fausse
                b = 0x40
                for k, p in enumerate(px):
                    if p:
                        b |= 0x20 >> k
                out.append(b)
    assert len(out) == 8000
    return bytes(out), conflits


def apercu(hires):
    """Rend les octets HIRES comme l'Oric (bit 7 = inverse vidéo)."""
    img = Image.new("RGB", (W, H))
    for y in range(H):
        encre, fond = BLANC, NOIR
        for c in range(40):
            b = hires[y * 40 + c]
            if b & 0x40:
                bits = b & 0x3F
                e, f = (encre ^ 7, fond ^ 7) if b & 0x80 else (encre, fond)
                for k in range(6):
                    img.putpixel((c * 6 + k, y), PALETTE[e if bits & (0x20 >> k) else f])
            else:
                a = b & 0x1F
                if a < 8:
                    encre = a
                elif 16 <= a < 24:
                    fond = a - 16
                for k in range(6):
                    img.putpixel((c * 6 + k, y), PALETTE[fond])
    return img.resize((W * 3, H * 3), Image.NEAREST)


def main():
    hires, conflits = vers_hires(dessiner())
    open(os.path.join(HERE, "serpent-titre.hir"), "wb").write(hires)
    os.makedirs(os.path.join(HERE, "captures"), exist_ok=True)
    apercu(hires).save(os.path.join(HERE, "captures", "serpent-titre.png"))
    print(f"serpent-titre.hir : {len(hires)} octets, {conflits} case(s) de couleur approchée")


if __name__ == "__main__":
    main()
