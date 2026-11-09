#!/bin/bash
# Double-clique ce fichier dans le Finder pour préparer et ouvrir le projet iOS
cd "$(dirname "$0")/.."
mkdir -p build/ios
{ bash ios/prepare_ios.sh; echo "EXIT=$?"; } 2>&1 | tee build/ios/prepare.log
echo
read -n 1 -s -r -p "Appuie sur une touche pour fermer…"
