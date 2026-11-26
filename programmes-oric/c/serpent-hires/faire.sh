#!/bin/sh
# faire.sh - construit serpent-c.tap et serpent-c.dsk (SERPENT en C et en
# HIRES) avec cc65.
# Créé le 2026-11-24 by GliouCNR©70 - modifié le 2026-11-24 : le jeu s'appelle
# serpent-c.tap partout (dépôt et dossier tapes d'Oricutron).
#
# 1. range les images HIRES titre et victoire du Serpent BASIC dans
#    images_bin.h ;
# 2. compile et relie tous les modules .c (cl65 -t atmos) :
#    - __RAMEND__ = $9000 : le C (programme, variables, pile de 2 Ko) reste
#      sous le jeu de caractères du mode HIRES ($9800) ; la version de test
#      range les tableaux de son pilote en $9000-$96FF ;
#    - __AUTORUN__ = $C7 : le programme démarre tout seul après CLOAD"".
# Modifié le 2026-11-26 by GliouCNR©70 : le moteur de son est en C (son.c,
# musiques.c) ; le son.s du Serpent BASIC n'est plus réassemblé ici.
set -e
cd "$(dirname "$0")"
RAMEND=9000

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
# (pile du C réduite à 1 Ko pour la version de test, qui a le pilote en plus)
SORTIE=serpent-c
OPTIONS=
PILE=0800
if [ "$1" = test ]; then
    SORTIE=serpent-c-test
    OPTIONS="-DPILOTE -DPOMMES_PORTE=1 -DGAGNE_LONG=40"
    PILE=0400
fi
cl65 -t atmos -O $OPTIONS -o $SORTIE.tap -m $SORTIE.map \
     --ld-args -D,__RAMEND__=\$$RAMEND,-D,__AUTORUN__=\$C7,-D,__STACKSIZE__=\$$PILE \
     main.c ecran.c son.c musiques.c disque.c clavier.c niveau.c jeu.c hof.c images.c pilote.c
rm -f *.o
ls -l $SORTIE.tap

# Copie dans le dossier des cassettes d'Oricutron (ajouté le 2026-11-24 by
# GliouCNR©70) ; le nom serpent-c.tap n'écrase pas le serpent.tap du BASIC.
BANDES="$HOME/Library/Application Support/Oricutron/tapes"
if [ "$SORTIE" = serpent-c ] && [ -d "$BANDES" ]; then
    cp serpent-c.tap "$BANDES/serpent-c.tap"
    echo "copié dans $BANDES/serpent-c.tap"
fi

# Disquette Microdisc (ajoutée le 2026-11-26 by GliouCNR©70) : le programme de
# la cassette, mis tel quel sur la disquette par oric_dsk.py ; elle démarre
# toute seule et le jeu y sauvegarde son Hall of Fame (piste 0, secteur 18).
python3 ../../outils/oric_dsk.py $SORTIE.tap $SORTIE.dsk

# Copie dans le dossier des disquettes d'Oricutron, en gardant le Hall of Fame
# déjà sauvegardé sur la copie précédente (secteur 18 de la piste 0).
DISQUES="$HOME/Library/Application Support/Oricutron/disks"
if [ "$SORTIE" = serpent-c ] && [ -d "$DISQUES" ]; then
    PYTHONPATH=../../outils python3 - "$DISQUES/serpent-c.dsk" <<'PYEOF'
import os, re, sys
from oric_dsk import crc16
cible = sys.argv[1]
def sec18(d):
    """position des données du secteur 18 de la piste 0 (après A1 A1 A1 FB)"""
    t = d[256:256 + 6400]
    for m in re.finditer(rb'\xa1\xa1\xa1\xfe(.)(.)(.)(.)', t, re.S):
        if m.group(3)[0] == 18:
            return 256 + t.find(b'\xa1\xa1\xa1\xfb', m.end())
neuf = bytearray(open('serpent-c.dsk', 'rb').read())
if os.path.exists(cible):
    ancien = open(cible, 'rb').read()
    pa, pn = sec18(ancien), sec18(neuf)
    neuf[pn + 4:pn + 260] = ancien[pa + 4:pa + 260]
    neuf[pn + 260:pn + 262] = crc16(bytes(neuf[pn:pn + 260])).to_bytes(2, 'big')
    print('Hall of Fame gardé :', bytes(ancien[pa + 4:pa + 14]))
open(cible, 'wb').write(neuf)
print('copié dans', cible)
PYEOF
fi
