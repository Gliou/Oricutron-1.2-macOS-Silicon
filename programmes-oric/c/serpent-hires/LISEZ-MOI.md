# Serpent en C et en HIRES

*Créé le 2026-11-24 by GliouCNR©70 — modifié le 2026-11-24 : écran titre et écran de victoire en HIRES, barres de statut centrées ; le jeu s'appelle `serpent-c.tap` partout*

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
  par l'horloge de l'Oric (16 centièmes de seconde par pas au niveau 1,
  10 au niveau 5), sans pause quand il mange.
- Deux flèches peuvent être tapées d'avance (virage rapide).
- Barres de statut dans les 3 lignes de texte sous l'image HIRES, centrées
  sous le terrain : `NIVEAU 1 - @=10 - RESTE 5` (puis `PORTE OUVERTE`, puis
  le compte des anneaux qui manquent), et `SCORE`, la tête et la taille du
  serpent, `HI-SCORE`.
- **Écran titre et écran de victoire** : les deux images HIRES du Serpent
  BASIC (`serpent-titre.hir`, `serpent-victoire.hir`), rangées dans le
  programme. Le titre s'affiche au démarrage avec la comptine et « APPUIE SUR
  ESPACE » ; « Version C » y est écrit en petit, en cyan, centré sous la barre
  cyan du titre ; l'image de victoire avec la fanfare (seulement sur elle), le score
  et les pommes mangées dessous.
- Hall of Fame et réglage du volume comme dans le Serpent BASIC (avec la
  longueur atteinte), en mode texte. **Pas encore sauvegardé** : il repart
  du Hall of Fame livré à chaque chargement.
- Sons et musiques : le **même moteur 6502** que le Serpent BASIC
  ([`../../serpent/son.s`](../../serpent/son.s)), réassemblé en `$8B00` :
  tic-tac à chaque pas, « pip » aigu quand une pomme apparaît, PING quand le
  serpent la mange, ZAP quand la porte s'ouvre, EXPLODE contre un mur.
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
| `son.c` / `.h` | le moteur de son du Serpent BASIC, appelé depuis le C |
| `son_bin.h` | le moteur assemblé (fabriqué par `faire.sh`) |
| `clavier.c` / `.h` | touches lues par la ROM (`$02DF`), attentes |
| `niveau.c` / `.h` | les 5 tableaux : bord, portes, murs tirés au hasard et gardés, pommes |
| `jeu.c` / `.h` | une partie |
| `hof.c` / `.h` | Hall of Fame, volume, saisie du nom |
| `images.c` / `.h` | écran titre et écran de victoire en HIRES |
| `images_bin.h` | les deux images (fabriqué par `faire.sh`) |
| `pilote.c` / `.h` | pilote automatique, seulement dans la version de test |
| `faire.sh` | construit `serpent-c.tap` (ou `serpent-c-test.tap`) |
| `serpent-c.tap` | le jeu, prêt à charger |

## Construire et jouer

```bash
./faire.sh
```

```bash
/Applications/Oricutron.app/Contents/MacOS/Oricutron -m atmos --turbotape on -t "$PWD/serpent-c.tap"
```

Le jeu démarre tout seul après le chargement. `faire.sh` copie aussi le jeu
dans le dossier des cassettes d'Oricutron
(`~/Library/Application Support/Oricutron/tapes/serpent-c.tap`), sous le même
nom : il n'écrase pas le `serpent.tap` du Serpent BASIC.

`./faire.sh test` construit `serpent-c-test.tap` : un pilote automatique joue
seul, la porte s'ouvre après 1 pomme et la partie est gagnée à 40 anneaux. Il
sert à vérifier les portes, les niveaux et la victoire sans jouer.

## Mémoire

| Adresses | Contenu |
|---|---|
| `$0501-$78D9` | programme C (dont les 2 images, 16 000 octets) et ses variables |
| `$8300-$8AFF` | pile du C (2 Ko) |
| `$8B00-$8FCE` | moteur de son |
| `$9800-$9FFF` | jeu de caractères du mode HIRES |
| `$A000-$BF3F` | écran HIRES, puis les 3 lignes de texte jusqu'à `$BFDF` |

Routines de la ROM appelées directement : `$F920` (passe en HIRES) et `$F967`
(revient au texte). L'entrée de la commande HIRES (`$EC33`) n'est pas utilisée,
car elle teste un drapeau et peut sortir en erreur BASIC.
