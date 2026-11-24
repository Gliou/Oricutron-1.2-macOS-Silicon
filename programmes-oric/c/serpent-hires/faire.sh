#!/bin/sh
# faire.sh - construit serpent-c.tap (SERPENT en C et en HIRES) avec cc65.
# Créé le 2026-11-24 by GliouCNR©70 - modifié le 2026-11-24 : le jeu s'appelle
# serpent-c.tap partout (dépôt et dossier tapes d'Oricutron).
#
# 1. réassemble le moteur de son du Serpent BASIC (../../serpent/son.s) en
#    $8B00 avec xa, et le range dans son_bin.h (tableau C) ;
#    range aussi les images HIRES titre et victoire du Serpent BASIC dans
#    images_bin.h (modifié le 2026-11-24 by GliouCNR©70) ;
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
xa -o $TMP/son_c.bin -l $TMP/son_c.lab $TMP/son_c.s
python3 - "$SON_ADR" "$TMP/son_c.bin" "$TMP/son_c.lab" <<'EOF'
import sys
b = open(sys.argv[2], 'rb').read()
lab = dict((l.split(',')[0], l.split(',')[1].strip()) for l in open(sys.argv[3]))
with open('son_bin.h', 'w', encoding='utf-8') as f:
    f.write('/* son_bin.h - FABRIQUÉ par faire.sh (ne pas modifier) : le moteur de son\n')
    f.write('** ../../serpent/son.s assemblé en $%s, %d octets. by GliouCNR©70 */\n' % (sys.argv[1], len(b)))
    f.write('#define SON_ADR 0x%s\n' % sys.argv[1])
    f.write('#define SON_TON %s      /* hauteur du tic-tac */\n' % lab['ton'])
    f.write('static const unsigned char son_bin[%d] = {\n' % len(b))
    for i in range(0, len(b), 16):
        f.write('    ' + ', '.join('0x%02X' % x for x in b[i:i+16]) + ',\n')
    f.write('};\n')
print('moteur de son :', len(b), 'octets en $' + sys.argv[1])
EOF

# images HIRES du Serpent BASIC (titre, victoire) -> images_bin.h
python3 - <<'EOF'
with open('images_bin.h', 'w', encoding='utf-8') as f:
    f.write('/* images_bin.h - FABRIQUÉ par faire.sh (ne pas modifier) : les images HIRES\n')
    f.write('** ../../serpent/serpent-titre.hir et serpent-victoire.hir. by GliouCNR©70 */\n')
    for nom, fichier in (('titre_bin', 'serpent-titre.hir'), ('victoire_bin', 'serpent-victoire.hir')):
        b = open('../../serpent/' + fichier, 'rb').read()
        f.write('static const unsigned char %s[%d] = {\n' % (nom, len(b)))
        for i in range(0, len(b), 20):
            f.write('    ' + ','.join(str(x) for x in b[i:i+20]) + ',\n')
        f.write('};\n')
print('images : titre et victoire, 2 x 8000 octets')
EOF

# ./faire.sh test : version de test (serpent-c-test.tap) - pilote automatique,
# porte ouverte après 1 pomme, victoire à 40 anneaux.
# (pile du C réduite à 1,5 Ko pour la version de test, qui a le pilote en plus)
SORTIE=serpent-c
OPTIONS=
PILE=0800
if [ "$1" = test ]; then
    SORTIE=serpent-c-test
    OPTIONS="-DPILOTE -DPOMMES_PORTE=1 -DGAGNE_LONG=40"
    PILE=0600
fi
cl65 -t atmos -O $OPTIONS -o $SORTIE.tap -m $SORTIE.map \
     --ld-args -D,__RAMEND__=\$$SON_ADR,-D,__AUTORUN__=\$C7,-D,__STACKSIZE__=\$$PILE \
     main.c ecran.c son.c clavier.c niveau.c jeu.c hof.c images.c pilote.c
rm -f *.o
ls -l $SORTIE.tap

# Copie dans le dossier des cassettes d'Oricutron (ajouté le 2026-11-24 by
# GliouCNR©70) ; le nom serpent-c.tap n'écrase pas le serpent.tap du BASIC.
BANDES="$HOME/Library/Application Support/Oricutron/tapes"
if [ "$SORTIE" = serpent-c ] && [ -d "$BANDES" ]; then
    cp serpent-c.tap "$BANDES/serpent-c.tap"
    echo "copié dans $BANDES/serpent-c.tap"
fi
