# Programmes Oric (Atmos) testés dans Oricutron

*Créé le 2026-11-21 by GliouCNR©70 — mis à jour le 2026-11-24 (une documentation par programme)*

Un dossier par programme, chacun avec sa propre documentation (`LISEZ-MOI.md`)
et ses captures d'écran (`captures/`) :

| Dossier | Langage | Contenu | Documentation |
|---|---|---|---|
| `serpent/` | BASIC | jeu du serpent : 5 niveaux, Hall of Fame, cassette et disquette, écrans titre et victoire en HIRES, robot joueur | [serpent/LISEZ-MOI.md](serpent/LISEZ-MOI.md) |
| `demo-hires/` | BASIC | démo graphique HIRES : bandes de couleur, cercles, rayons, texte, son | [demo-hires/LISEZ-MOI.md](demo-hires/LISEZ-MOI.md) |
| `titre/` | assembleur 6502 | écran titre animé : double hauteur, arc-en-ciel, texte défilant | [titre/LISEZ-MOI.md](titre/LISEZ-MOI.md) |
| `outils/` | Python, 6502 | outils communs : cassettes (`oric_tap.py`), disquettes (`oric_dsk.py`) et leur démarrage Microdisc | [outils/LISEZ-MOI.md](outils/LISEZ-MOI.md) |

Chaque programme existe en cassette `.tap` prête à charger ; le serpent aussi en
disquette `.dsk`. Les `.tap` et `.dsk` sont aussi copiés dans
`~/Library/Application Support/Oricutron/tapes` et `.../disks`.

## Lancer un programme

- Cassette : glisser le `.tap` sur la fenêtre d'Oricutron (ou Fichier › Insérer
  une cassette, puis taper `CLOAD""`). Les programmes démarrent tout seuls
  après le chargement. Depuis le Terminal :
  `/Applications/Oricutron.app/Contents/MacOS/Oricutron "$PWD/serpent/serpent.tap"`
- Disquette : il faut la ROM `microdis.rom` dans le dossier `roms` d'Oricutron,
  et le lecteur Microdisc :
  `/Applications/Oricutron.app/Contents/MacOS/Oricutron -k m -d "$PWD/serpent/serpent.dsk"`
  (ou, dans Oricutron, choisir le lecteur Microdisc puis insérer la disquette,
  et faire un reset).

La façon de refaire chaque cassette ou disquette est dans la documentation du
programme.

## Pièges rencontrés (utile pour écrire d'autres programmes)

- **Clavier** : `KEY$` ne voit une touche que si elle est encore enfoncée au moment
  où il est lu. Dans une boucle lente, un appui bref (clavier virtuel, écran tactile)
  passe inaperçu. Lire plutôt la dernière touche mémorisée par la ROM :
  `K=PEEK(735):IF K>127 THEN POKE 735,0:K=K-128` (flèches : 8 gauche, 9 droite,
  10 bas, 11 haut).
- **Noms de variables BASIC** : la ROM reconnaît les mots-clés partout, même au milieu
  d'un nom. Éviter les noms qui contiennent `TO`, `ON`, `OR`, `FN`, `IF`, `PI`, etc.
- **`WAIT 0`** (2026-11-23 by GliouCNR©70) : ce n'est pas « pas de pause ». Le
  compteur peut repasser de 0 à 65535 et le programme se fige 655 s (près de
  11 minutes). Le serpent se bloquait ainsi au niveau 5 (`WAIT WT` avec WT = 0) ;
  écrire `IF WT THEN WAIT WT`.
- **Mode HIRES** : la zone de texte du bas ne fait que 3 lignes ; un `PRINT` de trop
  fait défiler le texte et le fait disparaître.
- **Écran texte en assembleur** : le début de chaque ligne contient des attributs de
  couleur posés par la ROM. Les effacer change les couleurs du BASIC ; il vaut mieux
  sauvegarder l'écran et le remettre en sortant.
- **Cases couleur dans un jeu** : un attribut de couleur occupe une case et
  s'affiche comme une case vide ; un jeu qui teste les cases avec `SCRN` le
  prend pour du vide. Le serpent utilise plutôt la vidéo inverse (voir
  [serpent/LISEZ-MOI.md](serpent/LISEZ-MOI.md)).
- **HIRES et la mémoire** : la commande `HIRES` déplace le jeu de caractères en
  `$9800-$9FFF` ; tout ce qui est rangé là (2e étape du démarrage, tampon du
  Hall of Fame) est écrasé. L'image est donc copiée par une routine en `$0460`,
  et le Hall of Fame n'est lu qu'après le retour en `TEXT`.
- **Disquette Microdisc** et **assembleur xa** : voir
  [outils/LISEZ-MOI.md](outils/LISEZ-MOI.md).
