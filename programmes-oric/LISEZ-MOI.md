# Programmes Oric (Atmos) testés dans Oricutron

Trois programmes, chacun en source et en cassette `.tap` prête à charger.
Les `.tap` sont aussi copiés dans `~/Library/Application Support/Oricutron/tapes`.

| Programme | Fichiers | Langage | Ce qu'il fait |
|---|---|---|---|
| Démo graphique | `demo-hires.bas` → `demo-hires.tap` | BASIC | Mode HIRES : bandes de couleur, cercles, rayons, texte, son (ZAP, PING). Une touche revient au mode texte. |
| Serpent | `serpent.bas` → `serpent.tap` | BASIC | Petit jeu : flèches pour diriger, mange les `@` (+10), perdu si on touche le bord ou sa queue. Espace pour commencer / rejouer. |
| Écran titre | `titre.s` → `titre.tap` | Assembleur 6502 | Titre double hauteur, arc-en-ciel animé, texte défilant. Une touche rend l'écran BASIC d'avant. |

Le serpent existe aussi en **disquette** `serpent.dsk` (lecteur Microdisc), qui
démarre toute seule sur le jeu (copiée aussi dans `~/Library/Application Support/Oricutron/disks`).

Captures d'écran prises dans Oricutron : dossier `captures/`.

## Lancer un programme

- Glisser le `.tap` sur la fenêtre d'Oricutron (ou Fichier › Insérer une cassette, puis taper `CLOAD""`).
  Les trois programmes démarrent tout seuls après le chargement.
- Depuis le Terminal :
  `/Applications/Oricutron.app/Contents/MacOS/Oricutron "$PWD/serpent.tap"`

## Lancer une disquette

Il faut la ROM `microdis.rom` dans le dossier `roms` d'Oricutron, et choisir le
lecteur Microdisc :
`/Applications/Oricutron.app/Contents/MacOS/Oricutron -k m -d "$PWD/serpent.dsk"`
(ou, dans Oricutron, choisir le lecteur Microdisc puis insérer la disquette, et faire un reset).

## Refaire la disquette

```
python3 oric_dsk.py serpent.bas serpent.dsk
```

`oric_dsk.py` range le programme BASIC tokenisé sur la piste 0 (secteurs 4 et
suivants, 3840 octets au plus) et y ajoute le code de démarrage
`boot_microdisc.s` (assemblé par `xa`). Au reset, la ROM du Microdisc lit le
secteur 1, puis le répertoire (secteur 3), où elle trouve `SYSTEM.DOS`, et exécute
le code du secteur 2. Ce code charge le programme, démarre le BASIC comme un
vrai reset (sans le test mémoire, qui effacerait tout), puis fait `RUN` dès que
le BASIC affiche `Ready`. Pas de DOS sur la disquette : `SAVE`/`DIR` n'y marchent pas.

## Refaire les cassettes

```
python3 oric_tap.py basic demo-hires.bas demo-hires.tap DEMO
python3 oric_tap.py basic serpent.bas serpent.tap SERPENT
xa -o titre.bin titre.s && python3 oric_tap.py bin titre.bin titre.tap 0x0800 TITRE
```

`oric_tap.py` transforme un programme BASIC texte en cassette, avec les codes des
mots-clés relus dans la ROM de l'Atmos. Il transforme aussi un binaire 6502 en
cassette qui se lance toute seule. `xa` est l'assembleur 6502 (Homebrew : `brew install xa`).

## Pièges rencontrés (utile pour écrire d'autres programmes)

- **Clavier** : `KEY$` ne voit une touche que si elle est encore enfoncée au moment
  où il est lu. Dans une boucle lente, un appui bref (clavier virtuel, écran tactile)
  passe inaperçu. Lire plutôt la dernière touche mémorisée par la ROM :
  `K=PEEK(735):IF K>127 THEN POKE 735,0:K=K-128` (flèches : 8 gauche, 9 droite,
  10 bas, 11 haut).
- **Noms de variables BASIC** : la ROM reconnaît les mots-clés partout, même au milieu
  d'un nom. Éviter les noms qui contiennent `TO`, `ON`, `OR`, `FN`, `IF`, `PI`, etc.
- **Mode HIRES** : la zone de texte du bas ne fait que 3 lignes ; un `PRINT` de trop
  fait défiler le texte et le fait disparaître.
- **Écran texte en assembleur** : le début de chaque ligne contient des attributs de
  couleur posés par la ROM. Les effacer change les couleurs du BASIC ; il vaut mieux
  sauvegarder l'écran et le remettre en sortant.
- **Disquette Microdisc** : la ROM refuse la disquette (« No operating system on
  disc ») si le secteur 1 de la piste 0 est vide. Il doit contenir en `$12` le
  numéro du secteur du répertoire (3). Le code du secteur 2 doit tenir dans les
  195 octets qui suivent l'en-tête et le prologue.
- **Assembleur xa** : un `:` est un séparateur d'instructions, même dans un commentaire,
  et une adresse qui commence par `(` est lue comme un adressage indirect.
