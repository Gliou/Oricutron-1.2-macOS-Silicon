ORICUTRON pour macOS — version de test
======================================
Compilé avec ClaudeAI
=====================

Émulateur Oric-1 / Oric Atmos / Telestrat / Pravetz 8D.
Cœur d'émulation : Oricutron (Peter Gordon, licence GPL v2).
Couche macOS réécrite en Swift.

Compatible macOS 11 (Big Sur) ou plus récent, Mac Apple Silicon (M1, M2, M3, M4…) uniquement.
Cette version ne fonctionne pas sur les Mac Intel.


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
