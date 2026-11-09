#!/bin/bash
# Double-clique : compile l'app iOS sans iPhone ni signature, pour vérifier qu'il n'y a pas d'erreur
cd "$(dirname "$0")/.."
mkdir -p build/ios
{ xcodebuild -project ios/Oricutron.xcodeproj -scheme Oricutron -configuration Debug \
    -sdk iphoneos -destination 'generic/platform=iOS' \
    CODE_SIGNING_ALLOWED=NO -derivedDataPath "$HOME/Library/Caches/Oricutron-iOS/DerivedData" build 2>&1 \
  | grep -E "error:|warning: .*(Swift|swift)|BUILD (SUCCEEDED|FAILED)|\*\*" ; echo "EXIT=${PIPESTATUS[0]}"; } | tee build/ios/check.log
echo
read -n 1 -s -r -p "Appuie sur une touche pour fermer…"
