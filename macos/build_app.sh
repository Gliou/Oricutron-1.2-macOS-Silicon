#!/bin/bash
#
# build_app.sh — compile Oricutron (cœur C + couche Swift) en Oricutron.app pour macOS
# Créé le 2026-11-04 by GliouCNR©70
#
# Usage :  macos/build_app.sh            (architecture de ce Mac)
#          UNIVERSAL=1 macos/build_app.sh  (Apple Silicon + Intel)
#
# Prérequis : Xcode ou les Command Line Tools (xcode-select --install).
# SDL2 est téléchargé automatiquement (framework officiel) et embarqué dans l'app.
#
set -euo pipefail

SDL_VERSION="2.30.9"
MACOS_MIN="11.0"
APP_VERSION="1.2.0"

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
BUILD="$ROOT/build/macos"
DEPS="$BUILD/deps"
APP="$BUILD/Oricutron.app"
cd "$ROOT"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# --- Outils ---------------------------------------------------------------
step "Vérification des outils"
for tool in clang swiftc codesign hdiutil curl; do
  command -v "$tool" >/dev/null || { echo "Outil manquant : $tool (installe Xcode ou lance : xcode-select --install)"; exit 1; }
done
swiftc --version | head -1

if [[ "${UNIVERSAL:-0}" == "1" ]]; then ARCHS=(arm64 x86_64); else ARCHS=("$(uname -m)"); fi
echo "Architectures : ${ARCHS[*]}"

# --- SDL2 -----------------------------------------------------------------
mkdir -p "$DEPS"
if [[ ! -d "$DEPS/SDL2.framework" ]]; then
  step "Téléchargement de SDL2 $SDL_VERSION"
  DMG="$DEPS/SDL2-$SDL_VERSION.dmg"
  curl -fL --retry 3 -o "$DMG" \
    "https://github.com/libsdl-org/SDL/releases/download/release-$SDL_VERSION/SDL2-$SDL_VERSION.dmg"
  MNT="$(mktemp -d)"
  hdiutil attach -nobrowse -readonly -mountpoint "$MNT" "$DMG" >/dev/null
  if [[ -d "$MNT/SDL2.framework" ]]; then
    ditto "$MNT/SDL2.framework" "$DEPS/SDL2.framework"
  else
    FW="$(find "$MNT" -path '*macos*' -name SDL2.framework -type d | head -1)"
    [[ -n "$FW" ]] || { echo "SDL2.framework introuvable dans le DMG"; ls -R "$MNT" | head -40; hdiutil detach "$MNT"; exit 1; }
    ditto "$FW" "$DEPS/SDL2.framework"
  fi
  hdiutil detach "$MNT" >/dev/null
  rm -f "$DMG"
fi
SDL_HEADERS="$DEPS/SDL2.framework/Headers"

# --- Sources --------------------------------------------------------------
C_SOURCES=(
  6502.c 6551.c 6551_com.c 6551_loopback.c 6551_modem.c 8912.c avi.c
  disk.c disk_pravetz.c font.c gui.c joystick.c keyboard.c machine.c main.c
  monitor.c render_gl.c render_null.c render_sw.c render_sw8.c snapshot.c
  system_sdl.c tape.c ula.c via.c
  plugins/ch376/ch376.c plugins/ch376/oric_ch376_plugin.c
  plugins/twilighte_board/oric_twilighte_board_plugin.c
  macos/Sources/clipboard_shim.c macos/Sources/macos_glue.c
)
SWIFT_SOURCES=(macos/Sources/*.swift)

CFLAGS=(
  -O2 -std=gnu99 -w
  -DSDL_MAJOR_VERSION=2 -D__OPENGL_AVAILABLE__ -D__CBCOPY__ -D__CBPASTE__
  -DGL_SILENCE_DEPRECATION -DORICUTRON_SWIFT_HOST
  "-DAPP_YEAR=\"2019\""
  "-DVERSION_COPYRIGHTS=\"Oricutron $APP_VERSION (c)2019 Peter Gordon (pete@gordon.plus)\""
  -I"$ROOT" -I"$ROOT/plugins/ch376" -I"$ROOT/plugins/twilighte_board"
  -I"$SDL_HEADERS" -F"$DEPS"
)

BINARIES=()
for ARCH in "${ARCHS[@]}"; do
  OBJ="$BUILD/obj-$ARCH"
  mkdir -p "$OBJ"
  # Titre de la fenêtre selon l'architecture compilée
  case "$ARCH" in
    arm64)  ARCH_LABEL="Apple Silicon" ;;
    x86_64) ARCH_LABEL="Intel" ;;
    *)      ARCH_LABEL="$ARCH" ;;
  esac
  ARCH_CFLAGS=("-DAPP_NAME_FULL=\"Oricutron 1.2 $ARCH_LABEL\"")
  # Si les options de compilation ont changé, on recompile tout
  STAMP="$(printf '%s\n' "${CFLAGS[@]}" "${ARCH_CFLAGS[@]}" | shasum | cut -d' ' -f1)"
  if [[ "$(cat "$OBJ/.flags" 2>/dev/null)" != "$STAMP" ]]; then
    rm -f "$OBJ"/*.o
    echo "$STAMP" > "$OBJ/.flags"
  fi
  step "Compilation du cœur C ($ARCH)"
  for src in "${C_SOURCES[@]}"; do
    out="$OBJ/$(basename "${src%.c}").o"
    extra=()
    [[ "$src" == "main.c" ]] && extra=(-Dmain=oricutron_main)
    if [[ ! -f "$out" || "$src" -nt "$out" ]]; then
      echo "  CC  $src"
      clang -arch "$ARCH" -mmacosx-version-min="$MACOS_MIN" "${CFLAGS[@]}" "${ARCH_CFLAGS[@]}" "${extra[@]+"${extra[@]}"}" -c "$src" -o "$out"
    fi
  done

  step "Compilation Swift + édition de liens ($ARCH)"
  swiftc -O -swift-version 5 \
    -target "$ARCH-apple-macos$MACOS_MIN" \
    -import-objc-header macos/Sources/Bridge.h \
    "${SWIFT_SOURCES[@]}" "$OBJ"/*.o \
    -F "$DEPS" -framework SDL2 -framework OpenGL -framework AppKit \
    -framework CoreFoundation -framework UniformTypeIdentifiers \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    -o "$BUILD/Oricutron-$ARCH"
  BINARIES+=("$BUILD/Oricutron-$ARCH")
done

# --- Bundle .app ----------------------------------------------------------
step "Assemblage de Oricutron.app"
# L'app est assemblée et signée dans un dossier temporaire hors iCloud :
# le Bureau/Documents synchronisés ajoutent des attributs étendus (FinderInfo,
# fileprovider…) que codesign refuse (« resource fork… detritus not allowed »).
FINAL_APP="$APP"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/oricutron-build.XXXXXX")"
APP="$WORK/Oricutron.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks" "$APP/Contents/Resources/OricData"
lipo -create "${BINARIES[@]}" -output "$APP/Contents/MacOS/Oricutron"
ditto "$DEPS/SDL2.framework" "$APP/Contents/Frameworks/SDL2.framework"
sed "s/@@VERSION@@/$APP_VERSION/g" macos/Info.plist > "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Données par défaut (recopiées dans ~/Library/Application Support/Oricutron au 1er lancement)
DATA="$APP/Contents/Resources/OricData"
for d in roms images disks tapes teledisks pravdisks snapshots usbdrive; do
  [[ -d "$d" ]] && ditto "$d" "$DATA/$d"
done
# Rendu logiciel par défaut (SDL -> Metal) : OpenGL est déprécié sur macOS
sed 's/^rendermode = opengl/rendermode = soft/' oricutron.cfg > "$DATA/oricutron.cfg"
mkdir -p "$DATA/plugins/twilighte_board"
cp plugins/twilighte_board/twilighte.cfg "$DATA/plugins/twilighte_board/"
find "$DATA" -name .DS_Store -delete

# Icône : générée depuis le logo 1024 px, sinon l'ancienne icône
LOGO="XCode/Oricutron/Oricutron/Images.xcassets/AppIcon.appiconset/logo1024.png"
ICONSET="$BUILD/Oricutron.iconset"
if [[ -f "$LOGO" ]] && command -v iconutil >/dev/null; then
  rm -rf "$ICONSET"; mkdir -p "$ICONSET"
  for s in 16 32 128 256 512; do
    sips -z $s $s "$LOGO" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) "$LOGO" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Oricutron.icns"
else
  cp XCode/Oricutron/Oricutron/winicon.icns "$APP/Contents/Resources/Oricutron.icns"
fi

# --- Signature ad hoc (indispensable sur Apple Silicon) --------------------
step "Signature"
xattr -cr "$APP" 2>/dev/null || true
codesign --force --sign - "$APP/Contents/Frameworks/SDL2.framework"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
echo "Signature OK"

# Copie de l'app signée dans build/macos (sans attributs étendus)
rm -rf "$FINAL_APP"
ditto --norsrc --noextattr "$APP" "$FINAL_APP"
rm -rf "$WORK"
APP="$FINAL_APP"

# Enregistre l'app auprès du Finder (types .dsk/.tap/.sna pour « Ouvrir avec »)
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
[[ -x "$LSREG" ]] && "$LSREG" -f "$APP" || true

step "Terminé"
echo "Application : $APP"
lipo -info "$APP/Contents/MacOS/Oricutron"
