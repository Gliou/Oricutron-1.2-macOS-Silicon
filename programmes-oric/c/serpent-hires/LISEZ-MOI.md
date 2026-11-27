# Serpent en C et en HIRES

*Créé le 2026-11-24 by GliouCNR©70 — modifié le 2026-11-24 : écran titre et écran de victoire en HIRES, barres de statut centrées ; le jeu s'appelle `serpent-c.tap` partout — modifié le 2026-11-26 : **disquette** (Hall of Fame sauvegardé), moteur de son et musiques **en C**, Pastorale et Ode à la joie — modifié le 2026-11-27 by GliouCNR©70 : **difficulté** 1 à 5, difficulté de chaque record (colonne DIF), plus de PING au réglage du volume*

Le jeu du [Serpent BASIC](../../serpent/) refait en **C** (cc65) et dessiné en
**HIRES** (240 x 200 points). Mêmes règles : on dirige le serpent avec les
flèches ; chaque pomme vaut 10 points au niveau 1, 20 au niveau 2… 50 au
niveau 5 ; après 5 pommes, une porte s'ouvre à droite vers le niveau suivant,
et la porte de gauche ramène au précédent ; perdu contre le bord, un mur ou la
queue ; **gagné à 256 anneaux**.

## Ce qui change avec le C et le HIRES

- **Cases de 6 x 6 points** au lieu des caractères 6 x 8 : terrain de 36 x 31
  cases au lieu de 34 x 22, avec des dessins faits pour le HIRES : briques du
  bord, pavés blancs, serpent vert dont la tête et la pointe de la queue sont
  tournées dans le sens de la marche, **pomme jaune** sur fond noir.
- La pomme jaune : en HIRES, la couleur des points vient de l'encre réglée
  plus tôt sur la ligne (et chaque ligne commence en vert, pour le serpent).
  La case à gauche de la pomme porte donc l'attribut « encre jaune » et celle
  à droite « encre verte » : deux cases noires, et la pomme n'est posée
  qu'avec une case libre de chaque côté. Si le serpent passe dans l'une de ces
  cases, les attributs sont enlevés et la pomme devient verte (jamais de
  blanc).
- Le C est **bien plus rapide** que le BASIC : la vitesse du serpent est réglée
  par l'horloge de l'Oric, sans pause quand il mange.
- **Difficulté 1 à 5** (depuis le 2026-11-27, comme le Serpent BASIC), réglée
  sur l'écran du Hall of Fame avec les flèches **HAUT** (+1) et **BAS** (-1),
  sans son, 3 au départ. Elle fixe la pause d'un pas (centièmes de seconde) ;
  la difficulté 5 est l'ancienne vitesse, la 1 est deux fois plus lente au
  niveau 1, et à chaque difficulté les niveaux suivants vont plus vite :

  | Difficulté | Niv. 1 | 2 | 3 | 4 | 5 |
  |---|---|---|---|---|---|
  | 1 | 32 | 28 | 24 | 22 | 20 |
  | 2 | 27 | 24 | 20 | 19 | 17 |
  | 3 | 23 | 20 | 17 | 16 | 14 |
  | 4 | 19 | 17 | 14 | 13 | 12 |
  | 5 | 16 | 14 | 12 | 11 | 10 |
- Deux flèches peuvent être tapées d'avance (virage rapide).
- Barres de statut dans les 3 lignes de texte sous l'image HIRES, centrées
  sous le terrain : `NIVEAU 1 - @=10 - RESTE 5` (puis `PORTE OUVERTE`, puis
  le compte des anneaux qui manquent), et `SCORE`, la tête et la taille du
  serpent, `HI-SCORE`.
- **Écran titre et écran de victoire** : les deux images HIRES du Serpent
  BASIC (`serpent-titre.hir`, `serpent-victoire.hir`), rangées dans le
  programme. Le titre s'affiche au démarrage avec la Pastorale et « APPUIE
  SUR ESPACE » ; « Version C » y est écrit en petit, en cyan, centré sous la
  barre cyan du titre ; l'image de victoire avec l'Ode à la joie (seulement
  sur elle), le score et les pommes mangées dessous.
- Hall of Fame comme dans le Serpent BASIC, en mode texte, sous une ligne
  d'en-tête `NOM DIF SCORE LONG POMMES` : rang, nom, **difficulté** du record
  (« - » si elle est inconnue, comme pour les records livrés), score, longueur
  atteinte suivie de la tête, pommes mangées suivies de la pomme. Dessous, les
  barres `DIFFICULTE` (3 cases par cran, `n/5`) et `VOLUME` (flèches gauche
  et droite, sans PING depuis le 2026-11-27 : on l'entend sur la musique).
  Sur la **disquette**, tout est **sauvegardé** (piste 0, secteur 18, même
  format que le Serpent BASIC ; octets 129 à 138 = difficulté de chaque
  record, 240 = volume + 1, 241 = difficulté) : relu au démarrage, réécrit
  après chaque record et quand le volume ou la difficulté changent.
  En cassette, le Hall of Fame repart du classement livré à chaque chargement.
- **Sons et musiques en C** (`son.c`, `musiques.c`, depuis le 2026-11-26) :
  une fonction C branchée sur l'interruption de l'horloge (100 fois par
  seconde, `set_irq` de cc65) joue les sons au volume choisi et les musiques
  à 2 voix : tic-tac à chaque pas, « pip » aigu quand une pomme apparaît, PING
  quand le serpent la mange, ZAP quand la porte s'ouvre, EXPLODE contre un
  mur ; la Pastorale de Beethoven (titre, Hall of Fame), « perdu » (Hall of
  Fame après une défaite), l'Ode à la joie (victoire). Les tables de notes
  viennent des arrangements du Serpent BASIC. L'interruption ne lit les tables
  que par indices d'un octet (tableaux de moins de 256 cases) : elle ne touche
  pas aux cases de page zéro du C que le programme principal utilise.
- **Clic du clavier coupé** (bit 3 de `$026A`, comme `POKE 618,10` dans le
  BASIC) : le clic de la ROM recharge tous les registres de la puce son, dont
  le mélangeur, et rendait muets PING, ZAP et EXPLODE (corrigé le 2026-11-24).

## Les fichiers

Le programme est découpé en modules, que `main.c` importe par leurs `.h` :

| Fichier | Rôle |
|---|---|
| `main.c` | boucle générale : Hall of Fame, partie, victoire, record |
| `config.h` | constantes : grille, types de case, adresses de l'Atmos |
| `ecran.c` / `.h` | HIRES (appel des routines de la ROM), dessins 6 x 6, lignes de texte |
| `son.c` / `.h` | moteur de son en C, sur l'interruption de l'horloge |
| `musiques.c` / `.h` | les trois morceaux (périodes et durées des notes) |
| `disque.c` / `.h` | lecture / écriture d'un secteur de la disquette (contrôleur WD1793) |
| `clavier.c` / `.h` | touches lues par la ROM (`$02DF`), attentes |
| `niveau.c` / `.h` | les 5 tableaux : bord, portes, murs tirés au hasard et gardés, pommes |
| `jeu.c` / `.h` | une partie |
| `hof.c` / `.h` | Hall of Fame, volume, saisie du nom, sauvegarde sur disquette |
| `images.c` / `.h` | écran titre et écran de victoire en HIRES |
| `images_bin.h` | les deux images (fabriqué par `faire.sh`) |
| `pilote.c` / `.h` | pilote automatique, seulement dans la version de test |
| `faire.sh` | construit `serpent-c.tap` et `serpent-c.dsk` (ou `serpent-c-test.*`) |
| `serpent-c.tap` | le jeu en cassette |
| `serpent-c.dsk` | le jeu en disquette Microdisc (Hall of Fame sauvegardé) |

## Construire et jouer

```bash
./faire.sh
```

Disquette (le Hall of Fame y est sauvegardé) :

```bash
/Applications/Oricutron.app/Contents/MacOS/Oricutron -k m -d "$PWD/serpent-c.dsk"
```

Cassette :

```bash
/Applications/Oricutron.app/Contents/MacOS/Oricutron -m atmos --turbotape on -t "$PWD/serpent-c.tap"
```

Le jeu démarre tout seul dans les deux cas. `faire.sh` copie aussi la
cassette et la disquette dans les dossiers d'Oricutron
(`~/Library/Application Support/Oricutron/tapes/serpent-c.tap` et
`.../disks/serpent-c.dsk`), sous ces noms : ils n'écrasent pas le `serpent.tap`
et le `serpent.dsk` du Serpent BASIC. La disquette copiée **garde le Hall of
Fame** déjà sauvegardé sur la précédente (secteur 18 recopié).

La disquette est faite par [`../../outils/oric_dsk.py`](../../outils/oric_dsk.py),
qui accepte une cassette `.tap` déjà compilée : le programme de cc65 est une
ligne BASIC « CALL » suivie du code machine ; le chargeur Microdisc commun
(les deux étapes de démarrage en 6502, partagées avec les programmes BASIC) le
lit en `$0501`, démarre le BASIC, qui exécute la ligne et lance le C.

`./faire.sh test` construit `serpent-c-test.tap` et `serpent-c-test.dsk` : un pilote automatique joue
seul, la porte s'ouvre après 1 pomme et la partie est gagnée à 40 anneaux. Il
sert à vérifier les portes, les niveaux et la victoire sans jouer. Il n'a pas
l'image titre : avec le pilote, elle ne tiendrait plus en mémoire.

## Mémoire

| Adresses | Contenu |
|---|---|
| `$0501-$864B` | programme C (dont les 2 images, 16 000 octets) et ses variables |
| `$8800-$8FFF` | pile du C (2 Ko) |
| `$9000-$96FF` | tableaux du pilote (version de test seulement) |
| `$9800-$9FFF` | jeu de caractères du mode HIRES |
| `$A000-$BF3F` | écran HIRES, puis les 3 lignes de texte jusqu'à `$BFDF` |

Routines de la ROM appelées directement : `$F920` (passe en HIRES) et `$F967`
(revient au texte). L'entrée de la commande HIRES (`$EC33`) n'est pas utilisée,
car elle teste un drapeau et peut sortir en erreur BASIC.
