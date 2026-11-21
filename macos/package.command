#!/bin/bash
# Double-clique ce fichier dans le Finder pour fabriquer le .dmg de test
cd "$(dirname "$0")/.."
mkdir -p build/macos
{ bash macos/package_dmg.sh; echo "EXIT=$?"; } 2>&1 | tee build/macos/package.log
if grep -q "^EXIT=0" build/macos/package.log; then
  open -R build/macos/Oricutron-*-macOS.dmg
fi
echo
read -n 1 -s -r -p "Appuie sur une touche pour fermer…"
