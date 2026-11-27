#!/bin/bash
#
# package_dmg.sh — fabrique un .dmg d'Oricutron à partager avec des testeurs
#   - application universelle (Apple Silicon + Intel)
#   - glisser l'app dans Applications + fichier LISEZ-MOI
# Créé le 2026-11-04 by GliouCNR©70
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
BUILD="$ROOT/build/macos"
APP_VERSION="$(grep -m1 '^APP_VERSION=' "$HERE/build_app.sh" | cut -d'"' -f2)"
DMG="$BUILD/Oricutron-$APP_VERSION-macOS.dmg"
STAGE="$BUILD/dmg-stage"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

step "Compilation universelle"
# Les objets d'une seule architecture ne doivent pas être réutilisés
UNIVERSAL=1 bash "$HERE/build_app.sh"

step "Préparation du contenu du DMG"
rm -rf "$STAGE"; mkdir -p "$STAGE"
ditto "$BUILD/Oricutron.app" "$STAGE/Oricutron.app"
ln -s /Applications "$STAGE/Applications"
cp "$HERE/LISEZ-MOI.txt" "$STAGE/LISEZ-MOI.txt"

step "Création du DMG"
rm -f "$DMG"
hdiutil create -volname "Oricutron $APP_VERSION" -srcfolder "$STAGE" \
  -fs HFS+ -format UDZO -imagekey zlib-level=9 -ov "$DMG" >/dev/null
codesign --force --sign - "$DMG"
rm -rf "$STAGE"

step "Terminé"
ls -lh "$DMG"
echo "DMG=$DMG"
