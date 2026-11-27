// Bridge.h — fonctions C du cœur Oricutron visibles depuis Swift
// Créé le 2026-11-04 by GliouCNR©70
#ifndef ORICUTRON_SWIFT_BRIDGE_H
#define ORICUTRON_SWIFT_BRIDGE_H

/// main() de main.c, renommé à la compilation (-Dmain=oricutron_main)
int oricutron_main(int argc, char *argv[]);

/// File de touches clavier simulées (8912.c)
void queuekeys(char *str);

/// macos_glue.c : fichier présélectionné (menu, glisser-déposer) pour filerequester()
int macos_take_preset(char *path, char *fname);

/// macos_glue.c : poste une commande du menu natif dans la boucle d'événements SDL
void macos_push_command(int code);

/// macos_glue.c : mode clavier par position (1) ou par caractère d'origine (0)
void macos_set_keyboard_positional(int on);
int macos_keyboard_positional(void);

/// macos_glue.c : ouvre un fichier (.tap/.ort/.wav/.dsk/.sna) comme s'il était déposé sur la fenêtre
void macos_push_open_file(const char *path);

/// macos_glue.c : oricutron.cfg à utiliser à la place de celui du dossier de données
void macos_set_config_path(const char *path);

#endif
