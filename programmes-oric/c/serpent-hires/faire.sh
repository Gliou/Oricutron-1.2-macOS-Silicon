#!/bin/sh
# faire.sh - construit serpent.tap (SERPENT en C et en HIRES) avec cc65.
# Créé le 2026-11-24 by GliouCNR©70
#
# 1. réassemble le moteur de son du Serpent BASIC (../../serpent/son.s) en
#    $8B00 avec xa, et le range dans son_bin.h (tableau C) ;
# 2. compile et relie tous les modules .c (cl65 -t atmos) :
#    - __RAMEND__ = $8B00 : le C (programme, variables, pile de 2 Ko) reste
#      sous le moteur de son ($8B00-$8FCE) et sous le jeu de caractères du
#      mode HIRES ($9800) ;
#    - __AUTORUN__ = $C7 : le programme démarre tout seul après CLOAD"".
set -e
cd "$(dirname "$0")"
SON_ADR=8B00
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

sed "s/^        \* = \$5300/        * = \$$SON_ADR/" ../../serpent/son.s > $TMP/son_c.s
xa -o $TMP/son_c.bin $TMP/son_c.s
python3 - "$SON_ADR" "$TMP/son_c.bin" <<'EOF'
import sys
b = open(sys.argv[2], 'rb').read()
with open('son_bin.h', 'w', encoding='utf-8') as f:
    f.write('/* son_bin.h - FABRIQUÉ par faire.sh (ne pas modifier) : le moteur de son\n')
    f.write('** ../../serpent/son.s assemblé en $%s, %d octets. by GliouCNR©70 */\n' % (sys.argv[1], len(b)))
    f.write('#define SON_ADR 0x%s\n' % sys.argv[1])
    f.write('static const unsigned char son_bin[%d] = {\n' % len(b))
    for i in range(0, len(b), 16):
        f.write('    ' + ', '.join('0x%02X' % x for x in b[i:i+16]) + ',\n')
    f.write('};\n')
print('moteur de son :', len(b), 'octets en $' + sys.argv[1])
EOF

# ./faire.sh test : version de test (serpent-test.tap) - pilote automatique,
# porte ouverte après 1 pomme, victoire à 40 anneaux.
SORTIE=serpent
OPTIONS=
if [ "$1" = test ]; then
    SORTIE=serpent-test
    OPTIONS="-DPILOTE -DPOMMES_PORTE=1 -DGAGNE_LONG=40"
fi
cl65 -t atmos -O $OPTIONS -o $SORTIE.tap -m $SORTIE.map \
     --ld-args -D,__RAMEND__=\$$SON_ADR,-D,__AUTORUN__=\$C7 \
     main.c ecran.c son.c clavier.c niveau.c jeu.c hof.c pilote.c
rm -f *.o
ls -l $SORTIE.tap
