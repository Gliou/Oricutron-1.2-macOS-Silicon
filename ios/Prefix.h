/*
**  Prefix.h — options de compilation du cœur C d'Oricutron pour iOS
**  (équivalent des -D… de macos/build_app.sh). Inclus avant chaque fichier C.
**  Créé le 2026-11-06 by GliouCNR©70
*/
#ifndef ORICUTRON_IOS_PREFIX_H
#define ORICUTRON_IOS_PREFIX_H

#define SDL_MAJOR_VERSION 2
#define SDL_MAIN_HANDLED 1          /* main() est lancé par SDL_UIKitRunApp (main.swift) */
#define ORICUTRON_SWIFT_HOST 1      /* couche native en Swift */
#define __CBCOPY__ 1
#define __CBPASTE__ 1
/* Pas d'OpenGL sur iOS : rendu logiciel (SDL -> Metal) */

#define APP_NAME_FULL "Oricutron 1.2 iOS"
#define APP_YEAR "2019"
#define VERSION_COPYRIGHTS "Oricutron 1.2.0 (c)2019 Peter Gordon (pete@gordon.plus)"

#endif
