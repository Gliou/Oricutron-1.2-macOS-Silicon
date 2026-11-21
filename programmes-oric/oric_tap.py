#!/usr/bin/env python3
"""
oric_tap.py — fabrique des fichiers cassette .tap pour l'Oric Atmos.

  python3 oric_tap.py basic  programme.bas  sortie.tap  [NOM]
      Programme BASIC texte (une ligne = numéro + instructions, mots-clés en
      MAJUSCULES) -> tokenisé comme le ferait la ROM Atmos, lancé
      automatiquement après CLOAD"".

  python3 oric_tap.py bin  programme.bin  sortie.tap  ADRESSE  [NOM]
      Code machine chargé à ADRESSE (ex. 0x0600 ou '$600'), exécuté
      automatiquement à cette adresse après CLOAD"".

Format .tap : 16 16 16 16 24 | 00 00 type autorun fin(hi,lo) début(hi,lo) 00 |
nom 00 | données.
"""
import sys

# Mots-clés de l'Oric Atmos (BASIC 1.1), dans l'ordre de la ROM : code 0x80 + rang.
# (Table relue dans basic11b.rom, adresse $C0EA.)
KEYWORDS = (
    "END EDIT STORE RECALL TRON TROFF POP PLOT PULL LORES DOKE REPEAT UNTIL FOR "
    "LLIST LPRINT NEXT DATA INPUT DIM CLS READ LET GOTO RUN IF RESTORE GOSUB "
    "RETURN REM HIMEM GRAB RELEASE TEXT HIRES SHOOT EXPLODE ZAP PING SOUND MUSIC "
    "PLAY CURSET CURMOV DRAW CIRCLE PATTERN FILL CHAR PAPER INK STOP ON WAIT "
    "CLOAD CSAVE DEF POKE PRINT CONT LIST CLEAR GET CALL ! NEW TAB( TO FN SPC( @ "
    "AUTO ELSE THEN NOT STEP + - * / ^ AND OR > = < SGN INT ABS USR FRE POS HEX$ "
    "& SQR RND LN EXP COS SIN TAN ATN PEEK DEEK LOG LEN STR$ VAL ASC CHR$ PI TRUE "
    "FALSE KEY$ SCRN POINT LEFT$ RIGHT$ MID$"
).split()
assert len(KEYWORDS) == 0xF7 - 0x80, len(KEYWORDS)
TOK_REM, TOK_DATA = 0x80 + KEYWORDS.index("REM"), 0x80 + KEYWORDS.index("DATA")

BASIC_START = 0x0501


def crunch(text):
    """Tokenise une ligne BASIC comme la routine de la ROM (premier mot-clé trouvé
    dans l'ordre de la table ; rien n'est tokenisé entre guillemets, après REM,
    ni dans un DATA jusqu'au prochain ':')."""
    out = bytearray()
    i, in_quote, in_data = 0, False, False
    while i < len(text):
        c = text[i]
        if c == '"':
            in_quote = not in_quote
            out.append(ord(c)); i += 1; continue
        if in_quote:
            out.append(ord(c)); i += 1; continue
        if in_data:
            if c == ':':
                in_data = False
            out.append(ord(c)); i += 1; continue
        if c == ' ' or ('0' <= c <= ';'):        # chiffres, ':' et ';' copiés tels quels
            out.append(ord(c)); i += 1; continue
        for n, kw in enumerate(KEYWORDS):
            if text.startswith(kw, i):
                tok = 0x80 + n
                out.append(tok); i += len(kw)
                if tok == TOK_REM:                # le reste de la ligne reste du texte
                    out += text[i:].encode("ascii"); i = len(text)
                elif tok == TOK_DATA:
                    in_data = True
                break
        else:
            out.append(ord(c)); i += 1
    return bytes(out)


def basic_program(source):
    lines = []
    for raw in source.splitlines():
        raw = raw.rstrip()
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue                              # lignes vides et commentaires du fichier source
        num, _, body = raw.strip().partition(" ")
        lines.append((int(num), crunch(body.lstrip())))
    lines.sort()
    data, addr = bytearray(), BASIC_START
    for num, body in lines:
        nxt = addr + 4 + len(body) + 1
        data += nxt.to_bytes(2, "little") + num.to_bytes(2, "little") + body + b"\x00"
        addr = nxt
    data += b"\x00\x00"                           # fin du programme
    return bytes(data)


def tap(data, start, name, basic, autorun):
    data = data + b"\x00"                         # octet de marge (fin = début + taille)
    end = start + len(data) - 1
    header = bytes([0x16] * 4 + [0x24, 0x00, 0x00,
                    0x00 if basic else 0x80,
                    (0x80 if basic else 0xC7) if autorun else 0x00,
                    end >> 8, end & 0xFF, start >> 8, start & 0xFF, 0x00])
    return header + name.upper().encode("ascii")[:15] + b"\x00" + data


def main(argv):
    if len(argv) < 4 or argv[1] not in ("basic", "bin"):
        print(__doc__); return 1
    mode, src, dst = argv[1], argv[2], argv[3]
    if mode == "basic":
        name = argv[4] if len(argv) > 4 else "PROG"
        prog = basic_program(open(src, encoding="utf-8").read())
        out = tap(prog, BASIC_START, name, basic=True, autorun=True)
        print(f"{dst} : programme BASIC de {len(prog)} octets")
    else:
        start = int(argv[4].replace("$", "0x"), 0)
        name = argv[5] if len(argv) > 5 else "PROG"
        code = open(src, "rb").read()
        out = tap(code, start, name, basic=False, autorun=True)
        print(f"{dst} : {len(code)} octets de code à ${start:04X}")
    open(dst, "wb").write(out)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
