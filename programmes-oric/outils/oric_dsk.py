#!/usr/bin/env python3
"""
oric_dsk.py — fabrique une disquette .dsk (Microdisc) qui démarre toute seule
sur un programme BASIC, pour l'Oric Atmos.
Créé le 2026-11-21 by GliouCNR©70 — secteur de données ajouté le 2026-11-22,
programme compacté (espaces retirés, oric_tap.compact) et chargement sur
plusieurs pistes avec image de présentation le 2026-11-22, 2e image (écran de
victoire) le 2026-11-23 by GliouCNR©70, programme lu directement en $0501
(plus de limite à 6 Ko) le 2026-11-24 by GliouCNR©70

  python3 oric_dsk.py  programme.bas  sortie.dsk  [image.hir [image2.hir]]

Piste 0 : secteur 1 = en-tête lu par la ROM du Microdisc, secteur 2 = 1re étape
du démarrage (boot_microdisc.s), secteur 3 = répertoire où la ROM cherche
SYSTEM.DOS, secteurs 4-5 = 2e étape (boot_etage2.s), secteur 18 = laissé vide
pour les données du programme (le Hall of Fame du serpent).
Pistes 1, 2... (depuis le 2026-11-22) : le programme BASIC tokenisé par
oric_tap.py, lu directement à sa place en $0501 (jusqu'au début de l'image :
~22 Ko avec une image, ~21 Ko avec deux), puis l'image HIRES facultative
(8 000 octets, lue en $6000, que le programme affiche lui-même).
Avec une 2e image : image en $5800, 2e image en $7800,
gardée sous HIMEM abaissé à $7800 jusqu'à ce que le programme l'affiche.
Les deux étapes sont assemblées avec xa. Dans Oricutron :

  Oricutron -k m -d sortie.dsk

Format .dsk (« MFM_DISK », celui d'Oricutron et des émulateurs Oric) : en-tête
de 256 octets (signature, faces, pistes, géométrie 1), puis chaque piste brute
de 6400 octets : marques A1 A1 A1 FE + identifiant (piste, face, secteur,
taille) puis A1 A1 A1 FB + 256 octets de données, chacun suivi de son CRC.
"""
import os
import subprocess
import sys
import tempfile

from oric_tap import basic_program, BASIC_START

SIDES, TRACKS, SECTORS = 1, 40, 18
TRACK_SIZE = 6400
DATA_SECTOR = SECTORS                                  # secteur 18 : données du programme
ETAGE2_SECTOR, ETAGE2_MAX = 4, 2                       # 2e étape : secteurs 4-5, piste 0
IMAGE_SECTORS = 32                                     # $6000-$7FFF
# Ordre des secteurs sur la piste (entrelacement 3), comme les disquettes Sedoric.
ORDER = [s for start in (1, 2, 3) for s in range(start, SECTORS + 1, 3)]

# Répertoire façon OricDOS (piste 0, secteur 3) : la ROM du Microdisc y cherche
# SYSTEM.DOS, dont le descripteur est le secteur 2.
DIRECTORY = (bytes([0x00, 0x00, 0x02]) + b"SYSTEMDOS" + bytes([0x01, 0x00, 0x02, 0x00, 0x02, 0x00, 0x00])
             + b"BOOTUPCOM" + bytes(7))

# En-tête du secteur 1 (piste 0) : la ROM du Microdisc y lit, entre autres, où se
# trouve le répertoire (octet $12 = secteur 3). Le reste du secteur est vide.
SECTOR1_HEADER = (bytes([0x4C, 0x40, 0x04, 0, 0, 0, 0, 0]) + b" " * 8
                  + bytes([0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00]) + b"SEDORIC " + b" " * 32)

BOOT_MAX = 0xF7                                       # octets utiles du secteur 2

HERE = os.path.dirname(os.path.abspath(__file__))


def crc16(data, crc=0xFFFF):
    """CRC-CCITT du contrôleur WD1793 (marques A1 comprises)."""
    for b in data:
        crc ^= b << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) if crc & 0x8000 else (crc << 1)
            crc &= 0xFFFF
    return crc


def track(num, side, sectors):
    t = bytearray(b"\x4e" * 40)
    for s in ORDER:
        ident = bytes([0xA1, 0xA1, 0xA1, 0xFE, num, side, s, 0x01])
        data = bytes([0xA1, 0xA1, 0xA1, 0xFB]) + sectors.get(s, bytes(256))
        t += bytes(12) + ident + crc16(ident).to_bytes(2, "big")
        t += b"\x4e" * 22 + bytes(12) + data + crc16(data).to_bytes(2, "big")
        t += b"\x4e" * 22
    assert len(t) <= TRACK_SIZE
    return bytes(t + b"\x4e" * (TRACK_SIZE - len(t)))


def assembler(source, *defs):
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "code.bin")
        subprocess.run(["xa", *[f"-D{d}" for d in defs], "-o", out,
                        os.path.join(HERE, source)], check=True)
        return open(out, "rb").read()


def boot_sector():
    code = assembler("boot_microdisc.s")
    # La ROM du Microdisc ne charge pas la fin du secteur : au-delà de l'octet
    # $F7 le code est perdu (constaté le 2026-11-22, la disquette plantait).
    if len(code) > BOOT_MAX:
        sys.exit(f"code de démarrage trop long : {len(code)} octets ({BOOT_MAX} au plus)")
    return code + bytes(256 - len(code))


def position(n):
    """n-ième secteur à partir de la piste 1, secteur 1 -> (piste, secteur)."""
    return 1 + n // SECTORS, 1 + n % SECTORS


def main(argv):
    if len(argv) not in (3, 4, 5):
        print(__doc__); return 1
    src, dst = argv[1], argv[2]
    prog = basic_program(open(src, encoding="utf-8").read(), compacter=True)   # sans espaces
    nsect = (len(prog) + 255) // 256
    images = []
    for nom in argv[3:]:
        im = open(nom, "rb").read()
        if len(im) != 8000:
            sys.exit(f"{nom} : une image HIRES fait 8000 octets, pas {len(im)}")
        images.append(im + bytes(IMAGE_SECTORS * 256 - len(im)))
    image = b"".join(images)
    isect = IMAGE_SECTORS if images else 0
    jsect = IMAGE_SECTORS if len(images) == 2 else 0
    # deux images : le programme reste en $0501 (jusqu'à $57FF),
    # l'image en $5800 et la 2e en $7800-$97FF, au-dessus de HIMEM ($7800)
    imgh, img2h, himemh = (0x58, 0x78, 0x78) if jsect else (0x60, 0x78, 0x98)
    # le programme est lu en $0501, $0601... : son dernier secteur doit finir
    # avant l'image (ou, sans image, laisser 6 Ko aux variables sous HIMEM)
    haut = imgh * 256 if images else 0x8000
    max_sect = (haut - BASIC_START) // 256
    if nsect > max_sect:
        sys.exit(f"programme trop long : {len(prog)} octets ({max_sect * 256} au plus)")
    ptrk, psec = position(0)
    itrk, isec = position(nsect)
    jtrk, jsec = position(nsect + IMAGE_SECTORS)
    etage2 = assembler("boot_etage2.s", f"PTRK={ptrk}", f"PSEC={psec}", f"NSECT={nsect}",
                       f"ITRK={itrk}", f"ISEC={isec}", f"ISECT={isect}",
                       f"JTRK={jtrk}", f"JSEC={jsec}", f"JSECT={jsect}",
                       f"IMGH={imgh}", f"IMG2H={img2h}", f"HIMEMH={himemh}",
                       f"PEND=${BASIC_START + len(prog):04X}")
    if len(etage2) > ETAGE2_MAX * 256:
        sys.exit(f"2e étape trop longue : {len(etage2)} octets")
    etage2 += bytes(ETAGE2_MAX * 256 - len(etage2))

    pistes = {0: {1: SECTOR1_HEADER + bytes(256 - len(SECTOR1_HEADER)),
                  2: boot_sector(),
                  3: DIRECTORY + bytes(256 - len(DIRECTORY))}}
    for i in range(ETAGE2_MAX):
        pistes[0][ETAGE2_SECTOR + i] = etage2[i * 256:(i + 1) * 256]
    donnees = prog + bytes(nsect * 256 - len(prog)) + image
    for n in range(len(donnees) // 256):
        t, s_ = position(n)
        pistes.setdefault(t, {})[s_] = donnees[n * 256:(n + 1) * 256]

    header = b"MFM_DISK" + SIDES.to_bytes(4, "little") + TRACKS.to_bytes(4, "little") + (1).to_bytes(4, "little")
    out = bytearray(header + bytes(256 - len(header)))
    for side in range(SIDES):
        for t in range(TRACKS):
            out += track(t, side, pistes.get(t, {}) if side == 0 else {})
    open(dst, "wb").write(out)
    print(f"{dst} : programme BASIC de {len(prog)} octets ({nsect} secteurs, piste {ptrk})"
          + (f", image HIRES (piste {itrk} secteur {isec})" if image else "")
          + (f", 2e image (piste {jtrk} secteur {jsec})" if jsect else "") + ", démarrage automatique")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
