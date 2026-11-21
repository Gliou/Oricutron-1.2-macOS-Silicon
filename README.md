ORICUTRON pour macOS — version de test
======================================
Compilé avec ClaudeAI
=====================

Émulateur Oric-1 / Oric Atmos / Telestrat / Pravetz 8D.
Cœur d'émulation : Oricutron (Peter Gordon https://github.com/pete-gordon/oricutron , licence GPL v2).
Couche macOS réécrite en Swift.

Compatible macOS 11 (Big Sur) ou plus récent, Mac Apple Silicon (M1, M2, M3, M4…) uniquement.
Cette version ne fonctionne pas sur les Mac Intel.


ORIGINE ET CRÉDITS
------------------
Oricutron est l'œuvre de **Peter Gordon** et de ses contributeurs :
https://github.com/pete-gordon/oricutron

Il est distribué sous licence GNU GPL v2 (voir LICENSE.txt), tout comme ce portage.
Un grand merci à eux pour cet émulateur.

Organisation du dépôt :

- **à la racine** : les sources d'Oricutron, rangées comme dans le dépôt d'origine
  (cœur C, roms/, disks/, tapes/, fichiers de compilation Windows, Linux, Amiga…) ;
- **macos/** : couche native macOS (Swift) et scripts de compilation ;
- **ios/** : version iPhone / iPad (Swift, projet XcodeGen) ;
- **releases/** : applications compilées (sans la ROM basic11b, pour les droits d'auteur).

Fichiers d'Oricutron modifiés pour ce portage (par rapport au dépôt d'origine) :

- **main.c** : branchement des couches Swift (menus natifs, glisser-déposer, clavier
  par position), lecture d'un oricutron.cfg placé à côté de l'app, et correction du
  blocage lors du passage entre rendu OpenGL et rendu logiciel ;
- **keyboard.c / keyboard.h** : un clic bref sur le clavier virtuel est maintenu au
  moins 3 images, pour que la ROM de l'Oric voie la touche ;
- **gui.c** : retour au rendu logiciel si OpenGL est indisponible, lien vers ce dépôt
  dans le menu ;
- **system_sdl.c** : création du contexte OpenGL compatible avec les macOS récents,
  rattachement de la fenêtre SDL à l'app sur iPhone / iPad.

Les autres fichiers du cœur n'ont pas été modifiés.


1. INSTALLATION
---------------
Décompresse le fichier .zip, puis glisse « Oricutron » dans le dossier « Applications ».

Premier lancement : l'app n'est pas notariée par Apple, macOS va donc
la bloquer (« Oricutron ne peut pas être ouvert… »). Pour l'autoriser :

  • Clic droit (ou ctrl-clic) sur Oricutron > Ouvrir > Ouvrir
  • ou : Réglages Système > Confidentialité et sécurité >
    en bas, « Oricutron a été bloqué » > Ouvrir quand même

  Si macOS dit que l'app est « endommagée », ouvre le Terminal et tape :
    xattr -dr com.apple.quarantine /Applications/Oricutron.app

Il suffit de le faire une seule fois.


2. LES ROMs (OBLIGATOIRE)
-------------------------
Les ROMs de l'Oric ne sont PAS incluses (droits d'auteur).
Au démarrage, une fenêtre indique celles qui manquent.

Copie les fichiers .rom d'une distribution officielle d'Oricutron dans :
  ~/Library/Application Support/Oricutron/roms
(menu Fichier > Ouvrir le dossier de données, puis dossier « roms »)

  basic11b.rom  Oric Atmos                  — indispensable
  basic10.rom   Oric-1                      — indispensable
  microdis.rom  lecteur Microdisc (.dsk)    — pour les disquettes
  jasmin.rom    lecteur Jasmin (.dsk)
  telmon24.rom, teleass.rom, hyperbas.rom   — Telestrat
  pravetzt.rom, 8dos2.rom                   — Pravetz 8D

Menu Fichier > Vérifier les ROMs… pour revoir la liste à tout moment.


3. UTILISATION
--------------
  Fichier > Insérer une cassette…           ⌘T   (.tap, .ort, .wav)
  Fichier > Insérer une disquette…          ⌘O   (.dsk)
  Glisser-déposer un fichier sur la fenêtre       (.tap, .dsk, .sna)
  Clic droit sur un fichier > Ouvrir avec > Oricutron

  Cassette : tape  CLOAD""  puis Entrée dans l'Oric.

  Clavier : par défaut, chaque touche du Mac actionne la touche située
  au même endroit sur le clavier de l'Oric (QWERTY). Sur un clavier
  AZERTY, A donne Q, Z donne W, M donne ; etc.
  Menu Clavier > « Par caractère » pour revenir au comportement d'origine.
  F1 : menu de l'émulateur (machine, vidéo, son, clavier…)


4. SIGNALER UN PROBLÈME
-----------------------
Merci d'indiquer :
  • ton modèle de Mac et ta version de macOS ( > À propos de ce Mac)
  • ce que tu as fait, ce que tu attendais, ce qui s'est passé
  • le fichier .tap / .dsk utilisé
  • en cas de plantage : le rapport affiché par macOS
    (ou Console.app > Rapports de plantage > Oricutron)
