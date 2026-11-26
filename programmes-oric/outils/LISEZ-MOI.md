# Outils — cassettes et disquettes pour l'Oric Atmos

*Créé le 2026-11-24 by GliouCNR©70 (repris du LISEZ-MOI commun de `programmes-oric/`) — modifié le 2026-11-24 : programme lu directement en `$0501` ; le 2026-11-26 : options `--binaire` et `--sans-lignes` (disquettes), `--ajoute` (cassettes) ; programme `.tap` déjà compilé sur disquette (Serpent en C)*

Outils communs à tous les programmes de `programmes-oric/`.

| Fichier | Rôle |
|---|---|
| `oric_tap.py` | fabrique une cassette `.tap` à partir d'un programme BASIC texte ou d'un binaire 6502 |
| `oric_dsk.py` | fabrique une disquette `.dsk` (Microdisc) qui démarre toute seule sur un programme BASIC (ou un programme C de cc65 en `.tap`), avec une ou deux images HIRES facultatives |
| `boot_microdisc.s` | 1re étape du démarrage de la disquette (piste 0, secteur 2) |
| `boot_etage2.s` | 2e étape : lit le programme et les images, lance le BASIC |

## Cassettes : `oric_tap.py`

```
python3 oric_tap.py basic programme.bas programme.tap NOM
python3 oric_tap.py bin programme.bin programme.tap 0x0800 NOM
```

- `basic` : transforme un programme BASIC texte en cassette, avec les codes des
  mots-clés relus dans la ROM de l'Atmos. Les lignes qui commencent par `#`
  sont des commentaires, retirés à la conversion.
- `bin` : transforme un binaire 6502 en cassette qui se charge à l'adresse
  donnée et se lance toute seule.
- `--ajoute fichier@HHHH:NOM` (ajouté le 2026-11-26 by GliouCNR©70, autant de
  fois qu'il faut) : met d'autres fichiers binaires à la suite sur la même
  cassette, sans lancement automatique ; le programme les charge lui-même par
  `CLOAD"NOM"`, qui les pose à leur adresse et continue le programme. Le
  serpent y range son moteur de son et ses deux images HIRES :

  ```
  python3 oric_tap.py basic serpent.bas serpent.tap SERPENT \
          --ajoute son.bin@5000:SON --ajoute serpent-titre-basic.hir@5800:TITRE \
          --ajoute serpent-victoire.hir@7800:VICTOIRE
  ```

## Disquettes : `oric_dsk.py`

```
python3 oric_dsk.py programme.bas sortie.dsk [image.hir [image2.hir]] \
        [--binaire fichier.bin@5000] [--sans-lignes 1070-1999]
```

Options ajoutées le 2026-11-26 by GliouCNR©70 :

- `--binaire f@HHHH` : la 2e étape lit aussi `f` en `$HHHH` (début de page),
  après les images et **avant** de lancer le BASIC. Le serpent y met son
  moteur de son (`son.bin` en `$5000`), qui peut ainsi jouer la musique dès la
  1re ligne du programme, pendant « CHARGEMENT EN COURS ». Le programme doit
  finir sous cette adresse ; le binaire ne doit pas recouvrir une image.
- `--sans-lignes A-B` : retire les lignes A à B du programme mis sur la
  disquette (le serpent y retire les DATA du moteur, qui ne servent qu'à la
  version cassette) : programme plus court, démarrage plus rapide.

Programme déjà compilé (ajouté le 2026-11-26 by GliouCNR©70) :

```
python3 oric_dsk.py programme.tap sortie.dsk
```

Si le programme est une cassette `.tap` chargée en `$0501` (un programme C de
cc65, cible `atmos` : une ligne BASIC « CALL » suivie du code machine), son
contenu est mis **tel quel** sur la disquette, sans tokenisation. Le même
chargeur le lit en `$0501`, démarre le BASIC, qui exécute la ligne et lance le
programme C. C'est ainsi qu'est faite la disquette du
[Serpent en C](../c/serpent-hires/).

Il faut l'assembleur `xa` (Homebrew : `brew install xa`). Le programme est
tokenisé et compacté (espaces retirés). Pour lancer la disquette, il faut la
ROM `microdis.rom` dans le dossier `roms` d'Oricutron, et le lecteur Microdisc :

`/Applications/Oricutron.app/Contents/MacOS/Oricutron -k m -d "$PWD/sortie.dsk"`

### Rangement de la disquette (depuis le 2026-11-22)

| Piste | Secteurs | Contenu |
|---|---|---|
| 0 | 1 | en-tête lu par la ROM du Microdisc |
| 0 | 2 | 1re étape du démarrage, `boot_microdisc.s` |
| 0 | 3 | répertoire (`SYSTEM.DOS`) |
| 0 | 4-5 | 2e étape, `boot_etage2.s` |
| 0 | 18 | données du programme (laissé vide ; le serpent y garde son Hall of Fame) |
| 1, 2… | à partir de 1 | programme BASIC (jusqu'au début de l'image en mémoire : ~21 Ko), puis l'image et la 2e image (32 secteurs chacune), puis le binaire de `--binaire` |

### Démarrage

Au reset, la ROM du Microdisc lit le secteur 1, puis le répertoire, où elle
trouve `SYSTEM.DOS`, et exécute le code du secteur 2. Cette 1re étape charge la
2e en `$9900` ; la 2e déplace la tête (commande SEEK du contrôleur WD1793),
lit le programme et les images, ramène la tête sur la piste 0, démarre le BASIC
comme un vrai reset (sans le test mémoire, qui effacerait tout), puis fait
`RUN` dès que le BASIC affiche `Ready`, en posant 68 (« D ») en `$04FF` pour
dire au programme qu'il a démarré de la disquette. Le message de la ROM et
`Ready` sont effacés, le curseur et CAPS éteints. Pendant le chargement, « CHARGEMENT EN
COURS » clignote au milieu de l'écran (encre cyan, attribut 12 = clignotant ;
ajouté le 2026-11-24 by GliouCNR©70).

| Images | Programme lu en | Taille max. du programme | Image en | 2e image en | HIMEM |
|---|---|---|---|---|---|
| aucune | `$0501` | ~30 Ko (6 Ko laissés aux variables) | — | — | `$9800` |
| une | `$0501` | ~22 Ko (jusqu'à `$5FFF`) | `$6000` | — | `$9800` |
| deux (2026-11-23) | `$0501` | ~21 Ko (jusqu'à `$57FF`) | `$5800` | `$7800`, gardée pour plus tard | `$7800` |

Depuis le 2026-11-24, le programme est lu **directement à sa place** (`$0501`,
`$0601`…), sans tampon ni recopie : il n'est plus limité à 6 Ko. Le démarrage
du BASIC (`NEW`) remet à zéro les 2 premiers octets du programme
(`$0501-$0502`) : la 2e étape les garde de côté et les remet juste avant le
`RUN`. Les images, elles, ne servent qu'au début (titre) ou sont au-dessus de
HIMEM (victoire) : les variables du BASIC peuvent ensuite occuper la place de
l'image titre.

Le programme affiche lui-même ses images (après `HIRES`, une petite routine
les recopie en `$A000`, voir `serpent/titre_copie.s`).

Pas de DOS sur la disquette : `SAVE`/`DIR` n'y marchent pas. Un programme qui
veut écrire sur la disquette apporte sa propre routine (voir
`serpent/hof_disque.s`).

### Pièges du Microdisc

- La ROM refuse la disquette (« No operating system on disc ») si le secteur 1
  de la piste 0 est vide. Il doit contenir en `$12` le numéro du secteur du
  répertoire (3).
- Le code du secteur 2 doit **finir avant l'octet `$F7`** du secteur : la ROM
  ne charge pas la fin, et un code plus long plante au démarrage (écran plein
  de caractères au hasard). `oric_dsk.py` le vérifie. C'est pour cela que le
  démarrage se fait en deux étapes.
- Avec `xa`, un `:` est un séparateur d'instructions, même dans un
  commentaire, et une adresse qui commence par `(` est lue comme un adressage
  indirect.
