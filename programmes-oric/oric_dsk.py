#!/usr/bin/env python3
"""
oric_dsk.py — fabrique une disquette .dsk (Microdisc) qui démarre toute seule
sur un programme BASIC, pour l'Oric Atmos.
Créé le 2026-11-21 by GliouCNR©70 — secteur de données ajouté le 2026-11-22

  python3 oric_dsk.py  programme.bas  sortie.dsk

Le programme est tokenisé par oric_tap.py, puis rangé sur la piste 0 à partir
du secteur 4 (17 au plus). Le secteur 18 est laissé vide : le programme peut
y garder ses données (le Hall of Fame du serpent). Le secteur 2 reçoit le code de démarrage (boot_microdisc.s,
assemblé avec xa) et le secteur 3 le répertoire où la ROM du Microdisc cherche
SYSTEM.DOS. Dans Oricutron :

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
FIRST_PROG_SECTOR = 4
DATA_SECTOR = SECTORS                                  # secteur 18 : données du programme
MAX_PROG_SECTORS = DATA_SECTOR - FIRST_PROG_SECTOR     # 14 secteurs = 3584 octets
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


def boot_sector(nsect, pend):
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "boot.bin")
        subprocess.run(["xa", f"-DNSECT={nsect}", f"-DPEND=${pend:04X}", "-o", out,
                        os.path.join(HERE, "boot_microdisc.s")], check=True)
        code = open(out, "rb").read()
    # La ROM du Microdisc ne charge pas la fin du secteur : au-delà de l'octet
    # $F7 le code est perdu (constaté le 2026-11-22, la disquette plantait).
    if len(code) > BOOT_MAX:
        sys.exit(f"code de démarrage trop long : {len(code)} octets ({BOOT_MAX} au plus)")
    return code + bytes(256 - len(code))


def main(argv):
    if len(argv) != 3:
        print(__doc__); return 1
    src, dst = argv[1], argv[2]
    prog = basic_program(open(src, encoding="utf-8").read())
    nsect = (len(prog) + 255) // 256
    if nsect > MAX_PROG_SECTORS:
        sys.exit(f"programme trop long : {len(prog)} octets ({MAX_PROG_SECTORS * 256} au plus)")
    sectors0 = {1: SECTOR1_HEADER + bytes(256 - len(SECTOR1_HEADER)),
                2: boot_sector(nsect, BASIC_START + len(prog)),
                3: DIRECTORY + bytes(256 - len(DIRECTORY))}
    padded = prog + bytes(nsect * 256 - len(prog))
    for i in range(nsect):
        sectors0[FIRST_PROG_SECTOR + i] = padded[i * 256:(i + 1) * 256]

    header = b"MFM_DISK" + SIDES.to_bytes(4, "little") + TRACKS.to_bytes(4, "little") + (1).to_bytes(4, "little")
    image = bytearray(header + bytes(256 - len(header)))
    for side in range(SIDES):
        for t in range(TRACKS):
            image += track(t, side, sectors0 if (t, side) == (0, 0) else {})
    open(dst, "wb").write(image)
    print(f"{dst} : programme BASIC de {len(prog)} octets sur {nsect} secteurs, démarrage automatique")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
