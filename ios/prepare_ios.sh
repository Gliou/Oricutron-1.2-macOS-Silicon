#!/bin/bash
#
# prepare_ios.sh — prépare et ouvre le projet Xcode iOS d'Oricutron
#
#   1. vérifie Xcode et la plateforme iOS
#   2. télécharge et compile SDL2 pour iPhone (une seule fois)
#   3. prépare les données (images, symboles, oricutron.cfg) et l'icône
#   4. télécharge XcodeGen et génère ios/Oricutron.xcodeproj
#   5. ouvre le projet dans Xcode
#
# Les éléments compilés/téléchargés vont dans ~/Library/Caches/Oricutron-iOS,
# hors du Bureau synchronisé par iCloud (qui gêne la signature des apps).
#
set -euo pipefail

SDL_VERSION="2.32.10"
XCODEGEN_VERSION="2.42.0"

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DEPS="$HOME/Library/Caches/Oricutron-iOS"
mkdir -p "$DEPS"
cd "$ROOT"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mERREUR : %s\033[0m\n' "$*"; exit 1; }

# --- 1. Xcode ----------------------------------------------------------------
step "Vérification de Xcode"
DEVDIR="$(xcode-select -p 2>/dev/null || true)"
if [[ "$DEVDIR" != *".app/Contents/Developer"* ]]; then
  if [[ -d /Applications/Xcode.app ]]; then
    fail "Xcode est installé mais pas sélectionné. Dans le Terminal, tape :
  sudo xcode-select -s /Applications/Xcode.app
puis relance ce script."
  fi
  fail "L'application Xcode est introuvable. Installe-la depuis le Mac App Store, lance-la une fois, puis relance ce script."
fi
xcodebuild -version | head -1
if ! xcodebuild -showsdks 2>/dev/null | grep -q -- "-sdk iphoneos"; then
  step "Téléchargement de la plateforme iOS pour Xcode (plusieurs Go, patience…)"
  xcodebuild -downloadPlatform iOS
fi

# --- 2. SDL2 pour iOS -----------------------------------------------------------
if [[ ! -d "$DEPS/SDL2.framework" ]]; then
  if [[ ! -f "$DEPS/SDL2-src/Xcode/SDL/SDL.xcodeproj/project.pbxproj" ]]; then
    step "Téléchargement de SDL2 $SDL_VERSION"
    curl -fL --retry 3 -o "$DEPS/SDL2.tar.gz" \
      "https://github.com/libsdl-org/SDL/releases/download/release-$SDL_VERSION/SDL2-$SDL_VERSION.tar.gz"
    rm -rf "$DEPS/SDL2-src"; mkdir -p "$DEPS/SDL2-src"
    tar xzf "$DEPS/SDL2.tar.gz" -C "$DEPS/SDL2-src" --strip-components 1
    rm -f "$DEPS/SDL2.tar.gz"
  fi

  step "Compilation de SDL2 pour iPhone (quelques minutes)"
  # Les shaders Metal sont fournis précompilés par SDL (SDL_shaders_metal_ios.h) :
  # on exclut le .metal, ce qui évite d'installer la « Metal Toolchain » d'Xcode.
  xcodebuild -project "$DEPS/SDL2-src/Xcode/SDL/SDL.xcodeproj" \
    -target Framework-iOS -configuration Release -sdk iphoneos \
    ARCHS=arm64 ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0 \
    EXCLUDED_SOURCE_FILE_NAMES="SDL_shaders_metal.metal" \
    SYMROOT="$DEPS/SDL2-build" -quiet build
  ditto --norsrc --noextattr "$DEPS/SDL2-build/Release-iphoneos/SDL2.framework" "$DEPS/SDL2.framework"
fi
echo "SDL2 : $DEPS/SDL2.framework"

# --- 3. Données et icône ----------------------------------------------------------
step "Préparation des données de l'app"
DATA="$DEPS/OricData"
rm -rf "$DATA"; mkdir -p "$DATA"
for d in roms images disks tapes teledisks pravdisks snapshots usbdrive; do
  [[ -d "$d" ]] && ditto --norsrc --noextattr "$d" "$DATA/$d"
done
sed 's/^rendermode = opengl/rendermode = soft/' oricutron.cfg > "$DATA/oricutron.cfg"
mkdir -p "$DATA/plugins/twilighte_board"
cp plugins/twilighte_board/twilighte.cfg "$DATA/plugins/twilighte_board/"
find "$DATA" -name .DS_Store -delete

ASSETS="$DEPS/Assets.xcassets"
rm -rf "$ASSETS"; mkdir -p "$ASSETS/AppIcon.appiconset"
printf '{ "info" : { "author" : "xcode", "version" : 1 } }\n' > "$ASSETS/Contents.json"
sips -s format png -z 1024 1024 \
  "XCode/Oricutron/Oricutron/Images.xcassets/AppIcon.appiconset/logo1024.png" \
  --out "$ASSETS/AppIcon.appiconset/icon.png" >/dev/null
cat > "$ASSETS/AppIcon.appiconset/Contents.json" <<'JSON'
{
  "images" : [ { "filename" : "icon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

# --- 4. XcodeGen + projet -----------------------------------------------------------
XG="$DEPS/xcodegen/bin/xcodegen"
if [[ ! -x "$XG" ]]; then
  step "Téléchargement de XcodeGen $XCODEGEN_VERSION"
  curl -fL --retry 3 -o "$DEPS/xcodegen.zip" \
    "https://github.com/yonaskolb/XcodeGen/releases/download/$XCODEGEN_VERSION/xcodegen.zip"
  rm -rf "$DEPS/xcodegen"
  ditto -x -k "$DEPS/xcodegen.zip" "$DEPS"
  rm -f "$DEPS/xcodegen.zip"
  codesign --verify "$XG" 2>/dev/null || codesign --force --sign - "$XG"
fi

# Identifiant d'app unique (exigé par les comptes Apple gratuits)
USER_ID="$(id -un | tr -cd 'A-Za-z0-9-' | tr 'A-Z' 'a-z')"
export ORIC_BUNDLE_ID="${ORIC_BUNDLE_ID:-fr.cnr70.oricutron.$USER_ID}"

# Équipe de signature : détectée depuis le certificat « Apple Development » s'il existe
TEAM=""
if CERT="$(security find-certificate -c "Apple Development" -p 2>/dev/null)"; then
  TEAM="$(printf '%s' "$CERT" | openssl x509 -noout -subject 2>/dev/null \
          | sed -n 's/.*OU *= *\([A-Z0-9]\{10\}\).*/\1/p' | head -1)"
fi
export ORIC_TEAM_ID="${ORIC_TEAM_ID:-$TEAM}"
export ORIC_IOS_DEPS="$DEPS"

step "Génération du projet Xcode"
"$XG" generate --spec "$HERE/project.yml" --project "$HERE" --quiet
echo "Identifiant de l'app : $ORIC_BUNDLE_ID"
if [[ -n "$ORIC_TEAM_ID" ]]; then
  echo "Équipe de signature : $ORIC_TEAM_ID"
else
  echo "Équipe de signature : à choisir dans Xcode (Signing & Capabilities > Team)"
fi

# --- 5. Ouverture ---------------------------------------------------------------------
step "Terminé — ouverture dans Xcode"
open "$HERE/Oricutron.xcodeproj"
