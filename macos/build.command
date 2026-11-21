#!/bin/bash
# Double-clique ce fichier dans le Finder pour compiler Oricutron.app
cd "$(dirname "$0")/.."
mkdir -p build/macos
{ bash macos/build_app.sh; echo "EXIT=$?"; } 2>&1 | tee build/macos/build.log
if grep -q "^EXIT=0" build/macos/build.log; then
  open -R build/macos/Oricutron.app
fi
echo
read -n 1 -s -r -p "Appuie sur une touche pour fermer…"
