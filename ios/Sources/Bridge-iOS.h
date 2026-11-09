// Bridge-iOS.h — fonctions C visibles depuis Swift (version iOS)
#ifndef ORICUTRON_IOS_BRIDGE_H
#define ORICUTRON_IOS_BRIDGE_H

/// main() de main.c, renommé à la compilation (-Dmain=oricutron_main)
int oricutron_main(int argc, char *argv[]);

/// File de touches clavier simulées (8912.c)
void queuekeys(char *str);

/// SDL2 (SDL_main.h) : lance UIKit puis appelle mainFunction
int SDL_UIKitRunApp(int argc, char *argv[], int (*mainFunction)(int argc, char *argv[]));

/// macos/Sources/macos_glue.c (partagé avec la version Mac)
int macos_take_preset(char *path, char *fname);
void macos_push_command(int code);
void macos_push_open_file(const char *path);

#endif
