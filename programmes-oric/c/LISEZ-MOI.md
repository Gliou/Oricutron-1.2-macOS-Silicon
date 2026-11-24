# Programmes Oric en C

*Créé le 2026-11-24 by GliouCNR©70*

Programmes pour Oric Atmos écrits en **C**, compilés sur le Mac avec
**cc65** (compilateur C pour 6502, cible `atmos`).

| Dossier | Contenu |
|---|---|
| [`serpent-hires/`](serpent-hires/) | le jeu du Serpent refait en C, en mode HIRES |

## Installer cc65

```bash
brew install cc65
```

L'assembleur `xa` (déjà utilisé par les programmes BASIC) sert aussi :

```bash
brew install xa
```

## Compiler un programme C pour l'Oric

```bash
cl65 -t atmos -O -o prog.tap prog.c
```

- `-t atmos` : cible Oric Atmos. Le `.tap` produit commence par une petite
  ligne BASIC qui lance le code machine.
- `--ld-args -D,__AUTORUN__=\$C7` : le programme démarre tout seul après
  `CLOAD""`.
- `--ld-args -D,__RAMEND__=\$xxxx` : limite haute du C (programme, variables
  et pile de 2 Ko), pour garder de la place au-dessus (moteur de son, HIRES).

Dans Oricutron :

```bash
/Applications/Oricutron.app/Contents/MacOS/Oricutron -m atmos --turbotape on -t "$PWD/prog.tap"
```

Oricutron tape lui-même `CLOAD""` au démarrage.

## L'OSDK

L'OSDK (Oric Software Development Kit, <https://osdk.org>) est l'autre outil
classique pour programmer l'Oric en C. Sa page de téléchargement n'a pas pu
être lue (vérification anti-robot du site) ; cc65, déjà installé, fait le même
travail sur le Mac Apple Silicon.
