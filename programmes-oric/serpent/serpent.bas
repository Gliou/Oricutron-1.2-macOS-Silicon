# SERPENT — petit jeu en BASIC pour Oric Atmos
# Créé le 2026-11-21 by GliouCNR©70 — Hall of Fame ajouté le 2026-11-22,
# 5 niveaux, porte et murs ajoutés le 2026-11-22 by GliouCNR©70
# Modifié le 2026-11-23 by GliouCNR©70 — serpent vert (encre 2), bord magenta
# Flèches du clavier pour diriger le serpent, mange les @ : 10 points au
# niveau 1, 20 au niveau 2... 50 au niveau 5.
# Perdu si le serpent touche le bord (briques), un mur (pavé blanc) ou sa queue (O).
# Couleurs (ajoutées le 2026-11-22, refaites le 2026-11-22 by GliouCNR©70) :
# AUCUNE case couleur (attribut) dans le terrain - une case attribut s'affiche
# comme une case vide et faussait les collisions (mort devant le bord gauche,
# @ mangé sans le toucher). On se sert de la vidéo inverse (bit 7), qui affiche
# la couleur complémentaire : encre verte (2) posée en colonne 1 de chaque ligne,
# donc serpent vert (comme sur l'image titre) ; caractère 127 redéfini en
# briques (ligne 32) en inverse = CHR$(255) pour le bord : joints magenta,
# briques blanches (modifié le 2026-11-23 by GliouCNR©70 : le bord était un
# bloc magenta plein, comme la pomme) ; espace inverse CHR$(160) =
# blanc plein pour les murs intérieurs. La nourriture est le caractère @
# redessiné en pomme (ligne 34, DATA 996) ; « @ = 10 » de la barre de statut
# montre donc aussi la pomme. Modifié le 2026-11-23 by GliouCNR©70 : la pomme
# verte se perdait dans un long serpent vert ; elle est posée en vidéo inverse
# (F$ = CHR$(192)) : grosse pomme magenta, un peu de blanc dans les coins - une
# pomme magenta sur noir est impossible sans case couleur. SCRN rend ces
# codes : 255 bord, 160 mur, 118-121 queue du serpent, 122 corps, 123-126
# tête, 192 pomme.
# Serpent dessiné (2026-11-22) : à chaque pas, l'ancienne tête devient un
# anneau du corps et la nouvelle tête est tournée dans le sens de la marche
# (lignes 145-147 et 171 : HC = 123 droite, 124 gauche, 125 bas, 126 haut ;
# H$ n'est recalculé que quand on change de direction).
# Bord - colonnes 2 et 37, lignes 1 et 24 ; terrain - colonnes 3-36, lignes
# 2-23. Une porte = 3 espaces dans le bord. Ligne 26 : SCORE cyan, NIV blanc,
# HI-SCORE jaune. CAPS est effacé de la barre de statut (ligne 670).
# Modifié le 2026-11-23 by GliouCNR©70 : bord du bas remonté de la ligne 25 à
# la 24 (ligne 26 = dernière ligne de l'écran, on ne peut pas descendre le
# score) : une ligne vide sépare le mur du bas du score ; HI-SCORE en jaune.
# Niveaux : 5 tableaux. Aux niveaux 1 à 4, après 5 @ mangés, une porte s'ouvre
# dans le bord droit (colonne 37), sur 3 cases tirées au hasard (lignes PY à PY+2, PY de 3
# à 20 : il reste au moins un * du bord droit au-dessus et en dessous, en plus
# des coins) : y entrer fait passer au
# niveau suivant : le serpent garde sa longueur et son score.
# Entrée dans un tableau : la tête apparaît à gauche (colonne 3) et
# le corps sort du mur derrière elle : GR anneaux restent à faire sortir, la
# queue n'avance pas tant que GR > 0 (lignes 166-167). N = longueur du serpent.
# Le niveau 5 n'a pas de porte vers la droite : on y joue jusqu'au bout.
# Retour : les niveaux 2 à 5 ont aussi une porte à gauche, toujours ouverte,
# à la même hauteur que la porte de droite du tableau précédent (lignes LY-1
# à LY+1, LY = PD(L-1)+1 ; niveau 1 - LY = 13), qui ramène au tableau précédent ; le serpent y ressort par
# la porte de droite (colonne 36) en allant vers la gauche.
# Modifié le 2026-11-23 by GliouCNR©70 : la tête ressort à la hauteur exacte
# où elle a passé la porte (haut, milieu ou bas), et non plus toujours au
# milieu : EY = ligne de passage, notée aux lignes 151-152, utilisée ligne 475.
# Tableaux mémorisés : chaque tableau est tiré au hasard la première fois
# (CR(L) = 1 ensuite) ; sa porte PD(L), ses NW(L) murs (extrémités XA,YA-XB,YB)
# et ses @ mangés EL(L) sont gardés. En y revenant, on le redessine à
# l'identique (ligne 472), porte de droite ouverte si OP(L) = 1 (ligne 474).
# Tout est remis à zéro au début de chaque partie (ligne 80). EN = côté
# d'entrée (0 gauche, 1 droite).
# Murs : niveau L = 5+2*L murs droits tirés au hasard (7, 9, 11, 13, 15 ;
# Modifié le 2026-11-23 by GliouCNR©70 : 3*L avant, trop peu au début), de 2 à L+3 cases, en
# ligne ou en colonne. Un mur n'en touche aucun autre, ni le bord, même en
# diagonale (lignes 450-460 : tout le cadre autour du mur doit être vide) :
# il reste toujours un passage, et tout le tableau, porte comprise, est
# accessible. La zone de départ du serpent (colonnes 3 à 24, lignes LY-2 à LY+2)
# et le devant de la porte (colonnes 32 à 36, lignes PY-1 à PY+3) restent
# libres (lignes 445-447).
# Écran de présentation (ajouté le 2026-11-22 by GliouCNR©70) : image HIRES
# dessinée par titre_serpent.py (serpent-titre.hir), mise sur la disquette par
# oric_dsk.py et chargée en $6000 au démarrage (boot_etage2.s). La ligne 14 passe
# en HIRES et la recopie dans l'écran ($A000) avec la routine de titre_copie.s
# (DATA 990-995, en $0460, CALL #460), puis attend une touche (ligne 980).
# Le curseur et CAPS sont éteints dès le démarrage par boot_etage2.s (CAPS :
# majuscules non verrouillées, $020C = $7F) - TEXT n'a donc plus de CAPS à
# réafficher. Le clavier donne alors des minuscules : le nom du Hall of Fame
# est remis en majuscules (ligne 833). En cassette
# (pas de marque 68 en $04FF), pas d'image : on va droit au Hall of Fame.
# Les DATA 990-995 sont lues avant celles du Hall of Fame (lignes 12 puis 40).
# Hall of Fame : les 10 meilleurs scores avec leur nom ; le premier est le
# HI-SCORE affiché pendant la partie. Sur la disquette (serpent.dsk), il est
# sauvegardé sur la piste 0, secteur 18, par la routine machine de
# hof_disque.s (lignes DATA 1000+, chargée en $0400) : CALL #400 lit le secteur
# dans $9800-$98FF, CALL #403 l'écrit. Le démarrage de la disquette met 68 ("D")
# en $04FF : sans cette marque (cassette), le Hall of Fame reste en mémoire.
# Secteur : octet 0 = 72 ("H"), puis 10 fois (nom sur 8 lettres, score haut, bas).
# Modifié le 2026-11-23 by GliouCNR©70 : pommes mangées dans la partie (PM,
# compté ligne 185) gardées pour chaque record (NP()) et affichées à droite du
# score ; sur la disquette, octets 101 à 120 (haut, bas pour chacun des 10),
# libres jusque-là : un ancien record (0) affiche « - ».
# Clavier : on lit la dernière touche mémorisée par la ROM (PEEK(735), bit 7 =
# nouvelle touche) plutôt que KEY$, qui rate les appuis brefs (clavier virtuel,
# écran tactile) quand la boucle est lente.
# Variables : X(),Y() positions (tampon circulaire), H tête, T queue,
# DX/DY direction, S score, L niveau, E @ mangés dans le niveau,
# FX/FY nourriture, N$(),SC() Hall of Fame, D = disquette présente,
# M$ texte écrit au centre de la barre de statut (ligne du haut, celle de
# CAPS, mémoire écran $BB80) : « NIVEAU 2 - @ = 20 - RESTE 3 » (lignes
# 660-688). Modifié le 2026-11-23 by GliouCNR©70 : la barre dit combien de @
# il reste à manger - avant l'ouverture de la porte aux niveaux 1 à 4 (puis
# « PORTE OUVERTE »), et au niveau 5 avant que le serpent atteigne 256
# anneaux, le plus long que X(255),Y(255) peuvent garder : à 0, la partie est
# GAGNEE (ligne 191 -> 330). La barre entière n'est écrite qu'en entrant
# dans un tableau (680), avec une zone de 13 cases à l'adresse RA ; à chaque
# pomme, seul le nombre change (691 : 3 POKE), et à l'ouverture de la porte
# seules ces 13 cases (690, lettres de « PORTE OUVERTE » préparées dans PZ()
# ligne 37) - réécrire toute la barre ralentissait trop le jeu. C'est fait AVANT de poser
# la nouvelle pomme (ligne 185) : la pomme reste la dernière chose tracée
# avant la lecture du clavier.
# Modifié le 2026-11-24 by GliouCNR©70 : CD = décompte des anneaux (posé
# ligne 400 en entrant dans un tableau). Au niveau 5, et en REVENANT sur un
# tableau dont la porte est déjà ouverte, la barre compte les anneaux qui
# manquent pour 256 (« RESTE 140 ») au lieu de « PORTE OUVERTE » ; ce texte
# ne reste que jusqu'à la pomme suivante : à la 6e pomme, la ligne 689 passe
# au décompte (CD=-1) et réécrit les 13 cases une fois.
# Murs : V vertical (U = 1-V), Q longueur, X1,Y1-X2,Y2 extrémités, G = place libre.
# La queue est effacée AVANT d'avancer la tête : la case qu'elle quitte est libre
# (ligne 156), sinon le serpent mourait en suivant sa queue de près.
# Vitesse (2026-11-22) : la boucle 100-195 est écrite pour aller vite - une
# case vide (le cas le plus fréquent) est traitée d'abord (ligne 150), la tête
# n'est recalculée qu'au changement de direction, la queue n'est redessinée
# que quand elle avance (TM), et les nombres répétés sont dans des variables
# (M = 255, KB = 735, SP = 32 : le BASIC de l'Oric relit et convertit chaque
# nombre écrit en clair à chaque passage). Pause WT = 5-L centièmes de
# seconde (ligne 400) : 4 au niveau 1, 0 au niveau 5.
# Modifié le 2026-11-23 by GliouCNR©70 : WAIT 0 ne veut pas dire « pas de
# pause » - le compteur part de 0, repasse à 65535 et le jeu se fige 655 s
# (près de 11 minutes) au niveau 5. La ligne 182 ne fait donc WAIT que si WT>0.
# Modifié le 2026-11-24 by GliouCNR©70 : sons au VOLUME réglable. PING, ZAP et
# EXPLODE de la ROM sont trop forts et ne se règlent pas (enveloppe de la puce
# toujours partie de 15) : ils sont remplacés par le moteur son.s (en $5400,
# au-dessus de HIMEM abaissé ligne 5) - CALL PG, ZP, XP, et SN pour le tic-tac
# des pas. Le joueur règle le volume de 0 à 64 avec les flèches sur l'écran du
# Hall of Fame (lignes 73-79 et 760-765) ; 64 = 15, le maximum de la puce. Le
# volume est gardé sur la disquette avec le Hall of Fame (octet $98F0).
5 HIMEM #5400
# Modifié le 2026-11-24 by GliouCNR©70 : « CHARGEMENT EN COURS » clignotant (encre
# cyan 6, attribut 12 = clignotant) au milieu de l'écran noir, comme le fait
# déjà le démarrage de la disquette ; il reste jusqu'à l'image titre.
6 M$=CHR$(6)+CHR$(12)+"CHARGEMENT EN COURS":FOR I=1 TO 21:POKE #BD90+I,ASC(MID$(M$,I,1)):NEXT
10 NX=0:NY=0:C=0:H=0:T=0:DX=0:DY=0:K=0:GR=0:TM=0:TC=0:M=255:SP=32:KB=735:I=0:SN=#5403
11 PG=#5406:ZP=#5409:XP=#540C:SR=#5400:VO=#540F:MU=#5410:CH=#5413:VU=32:VS=-1
# Modifié le 2026-11-24 by GliouCNR©70 : X() et Y() sont dimensionnés en premier -
# le BASIC les trouve plus vite dans la boucle du jeu.
13 DIM X(255),Y(255),N$(10),SC(10),NP(10),PZ(12)
12 FOR I=0 TO 43:READ B:POKE #460+I,B:NEXT
# Modifié le 2026-11-23 by GliouCNR©70 : la disquette a maintenant 2 images ;
# l'image titre est lue en $5800 (et non plus $6000) : on donne à la routine
# de copie (#460) la page de départ (#461) et celle des 64 derniers octets (#482).
# Modifié le 2026-11-24 by GliouCNR©70 : démarrage réorganisé. AVANT l'image
# titre (970-973) : dessins des caractères posés directement en $B400 (HIRES
# les range en $9800 et TEXT les remet), routine disque, Hall of Fame par
# défaut, puis lecture du Hall of Fame et du VOLUME sur la disquette (ligne 14)
# - puis le moteur de son et les chaînes (974-978). La musique (CALL MU, jouée
# en boucle par l'interruption) démarre avec l'image titre et tourne jusqu'au
# début de la partie (CALL SR ligne 80) : elle sert aussi à régler le volume
# sur l'écran du Hall of Fame. À l'appui sur ESPACE (986), le message s'efface.
# HIMEM est à $5400, SOUS l'image titre ($5800-$773F) : les noms du Hall of
# Fame lus avant l'image ne peuvent plus l'abîmer (ils étaient rangés sous
# l'ancien HIMEM $7600, dans le tampon de l'image - d'où des défauts).
14 D=(PEEK(#4FF)=68):GOSUB 970:IF D THEN CALL #400:IF PEEK(#4FE)=0 AND PEEK(#9800)=72 THEN GOSUB 950
15 GOSUB 974:POKE CH,0:IF D=0 THEN CALL MU:GOTO 20
16 PAPER 0:INK 6:HIRES:POKE 618,10:POKE #461,#58:POKE #482,#77:CALL #460:CALL MU:PRINT:PRINT "           APPUIE SUR ESPACE";:POKE 618,10:POKE 735,0
17 GOSUB 986:FOR I=#BF68 TO #BFDF:POKE I,32:NEXT:TEXT
20 CLS:PAPER 0:INK 2:POKE 618,10
35 DIM CR(5),OP(5),EL(5),PD(5),NW(5),XA(5,15),YA(5,15),XB(5,15),YB(5,15)
# Modifié le 2026-11-24 by GliouCNR©70 : Hall of Fame par défaut (celui de la
# disquette et de la cassette distribuées) - que des ORIC. De la 10e à la 7e
# place, le score minimum pour ouvrir la porte du niveau 1, 2, 3, 4 (5 pommes
# par niveau : 50, 150, 300, 500) ; de la 6e à la 1re, des pommes en plus au
# niveau 5 (50 points chacune) : 750, 1000, 1250, 1500, 2000, 2500. Le nombre
# de pommes affiché est le minimum pour faire ce score (DATA 1050-1060).
# Moteur de son (son.s, DATA 1070+, 769 octets posés en $5400 par la ligne 974) :
# installé sur l'interruption de l'horloge (CALL SR). V1$/V2$ = cases pleines/vides
# de la barre du volume.
70 GOSUB 700:PLOT 12,22,"ESPACE = JOUER"
73 GOSUB 760
74 K=PEEK(KB):IF K<128 THEN 74
75 POKE KB,0:K=K-128:IF K=32 THEN 79
76 IF K=8 AND VU>0 THEN VU=VU-4
77 IF K=9 AND VU<64 THEN VU=VU+4
78 IF K=8 OR K=9 THEN GOSUB 760:CALL PG
79 IF K<>32 THEN 74
80 CALL SR:IF D AND VU<>VS THEN VS=VU:QS=1:GOSUB 900:QS=0
81 S=0:PM=0:L=1:N=4:EN=0:EY=13:FOR I=1 TO 5:CR(I)=0:OP(I)=0:EL(I)=0:NEXT:GOSUB 400
100 K=PEEK(KB):IF K<128 THEN 150
105 POKE KB,0:K=K-128
110 IF K=8 AND DX=0 THEN DX=-1:DY=0
120 IF K=9 AND DX=0 THEN DX=1:DY=0
130 IF K=10 AND DY=0 THEN DX=0:DY=1
140 IF K=11 AND DY=0 THEN DX=0:DY=-1
145 HC=123-(DX<0):IF DY THEN HC=125-(DY<0)
147 H$=CHR$(HC)
150 NX=X(H)+DX:NY=Y(H)+DY:C=SCRN(NX,NY):IF C<>SP THEN 155
151 IF NX=37 THEN N=((H-T) AND M)+1+GR:EL(L)=E:L=L+1:EN=0:EY=NY:CALL PG:GOSUB 400:GOTO 100
152 IF NX=2 THEN N=((H-T) AND M)+1+GR:EL(L)=E:L=L-1:EN=1:EY=NY:CALL PG:GOSUB 400:GOTO 100
153 GOTO 166
155 IF C=192 THEN 170
156 IF C>117 AND C<127 AND NX=X(T) AND NY=Y(T) AND GR=0 THEN 167
157 GOTO 300
166 IF GR THEN GR=GR-1:GOTO 170
167 PLOT X(T),Y(T)," ":T=(T+1) AND M:TM=1
170 IF T=H THEN TM=1
171 PLOT X(H),Y(H),Z$:H=(H+1) AND M:X(H)=NX:Y(H)=NY:PLOT NX,NY,H$:CALL SN
175 IF TM THEN TM=0:I=(T+1) AND M:TX=X(I)-X(T):TC=118-(TX<0):IF TX=0 THEN TC=120-(Y(I)<Y(T))
176 IF TC THEN PLOT X(T),Y(T),CHR$(TC):TC=0
180 IF C=192 THEN 185
182 IF WT THEN WAIT WT
183 GOTO 100
185 S=S+L*10:E=E+1:PM=PM+1:CALL PG:GOSUB 600:GOSUB 689:GOSUB 697:GOSUB 500
190 IF E=5 AND L<5 THEN GOSUB 650
# Modifié le 2026-11-23 by GliouCNR©70 : 256 anneaux = gagné sur TOUS les
# niveaux (le joueur peut redescendre aux niveaux 1 à 4 et y finir), plus
# seulement au niveau 5. Le tampon X(255)-Y(255) ne dépasse donc jamais 256.
191 IF ((H-T) AND M)+1+GR>255 THEN 330
195 GOTO 100
# Modifié le 2026-11-24 by GliouCNR©70 : en revenant au Hall of Fame, une musique
# - « perdu » (morceau 1, lente, la mineur) après une défaite, la comptine (0)
# après une victoire ; elle tourne jusqu'à la partie suivante (CALL SR, ligne 80).
300 CALL XP:POKE CH,1:PLOT 15,12,"  PERDU !  ":WAIT 250
310 IF S>SC(10) THEN GOSUB 800
320 CALL MU:GOTO 70
# Gagné (2026-11-23 by GliouCNR©70) : on reste 3 s sur le tableau avec
# « GAGNE ! », puis, sur disquette, l'écran de victoire en HIRES (lignes
# 340-352) : l'image est en mémoire depuis le démarrage ($7800, au-dessus de
# HIMEM), la routine #460 la recopie à l'écran. Score et pommes sont écrits
# dans les 3 lignes de texte sous l'image (ESC + lettre = couleur), une
# fanfare joue, et on attend une touche avant le Hall of Fame.
330 CALL ZP:POKE CH,0:PLOT 14,12,"  GAGNE !  ":WAIT 300:IF D THEN GOSUB 340
335 GOTO 310
340 PAPER 0:INK 6:HIRES:POKE 618,10:POKE #461,#78:POKE #482,#97:CALL #460
342 Q$=CHR$(27):PRINT Q$;"C   SCORE";S;Q$;"E";PM;"POMMES MANGEES"
344 PLAY -(VL>0),0,0,0:FOR I=1 TO 6:MUSIC 1,VAL(MID$("344444",I,1)),VAL(MID$("080105080508",I*2-1,2)),VL-(VL=0)
346 WAIT VAL(MID$("151515301570",I*2-1,2)):NEXT:PLAY 0,0,0,0
348 PRINT:PRINT "         APPUIE SUR UNE TOUCHE";:POKE 618,10:POKE 735,0:GOSUB 980
350 TEXT:PAPER 0:INK 2:POKE 618,10:RETURN
400 CLS:H=0:T=0:GR=N-1:E=EL(L):WT=5-L:CD=(L=5)OR(E>4):LY=13:IF L>1 THEN LY=PD(L-1)+1
405 FOR I=1 TO 24:PLOT 1,I,2:PLOT 2,I,B$:PLOT 37,I,B$:NEXT
410 FOR I=3 TO 36:PLOT I,1,B$:PLOT I,24,B$:NEXT
# Modifié le 2026-11-24 by GliouCNR©70 : en bas, à la place de « NIV 2 », la
# pomme magenta (attribut 2 + F$ en inverse) et le nombre TOTAL de pommes
# qu'il reste à manger pour gagner (256 - longueur), colorié comme le
# décompte de la barre du haut (lignes 697-698).
415 PLOT 2,26,6:PLOT 3,26,"SCORE":PLOT 14,26,2:PLOT 15,26,F$:PLOT 21,26,3:PLOT 22,26,"HI-SCORE":GOSUB 697
412 IF L>1 THEN FOR I=LY-1 TO LY+1:PLOT 2,I," ":NEXT
417 PLOT 30,26,STR$(SC(1)):GOSUB 600
420 GOSUB 680
422 IF CR(L) THEN 472
423 CR(L)=1:PD(L)=3+INT(RND(1)*18):PY=PD(L):NW(L)=0
425 FOR W=1 TO 5+2*L:FOR A=1 TO 30
430 V=INT(RND(1)*2):U=1-V:Q=2+INT(RND(1)*(L+2))
435 X1=4+INT(RND(1)*(33-Q*U-V)):Y1=3+INT(RND(1)*(21-Q*V-U))
440 X2=X1+(Q-1)*U:Y2=Y1+(Q-1)*V:G=1
445 IF X1<25 AND Y1<LY+3 AND Y2>LY-3 THEN G=0:GOTO 465
447 IF X2>31 AND Y1<PY+4 AND Y2>PY-2 THEN G=0:GOTO 465
450 FOR I=X1-1 TO X2+1:FOR J=Y1-1 TO Y2+1
455 IF SCRN(I,J)<>32 THEN G=0:I=X2+1:J=Y2+1
460 NEXT J,I
465 IF G=0 THEN 470
466 FOR I=X1 TO X2:FOR J=Y1 TO Y2:PLOT I,J,W$:NEXT J,I:A=30
467 K=NW(L)+1:NW(L)=K:XA(L,K)=X1:YA(L,K)=Y1:XB(L,K)=X2:YB(L,K)=Y2
470 NEXT A,W:GOTO 474
472 PY=PD(L):FOR K=1 TO NW(L):FOR I=XA(L,K) TO XB(L,K):FOR J=YA(L,K) TO YB(L,K)
473 PLOT I,J,W$:NEXT J,I,K
474 IF OP(L) THEN FOR I=PY TO PY+2:PLOT 37,I," ":NEXT
475 X(0)=3:Y(0)=EY:DX=1:DY=0:IF EN THEN X(0)=36:Y(0)=EY:DX=-1
477 H$=CHR$(123-(DX<0)):PLOT X(0),Y(0),H$:TM=0:TC=0
480 WAIT 100:POKE 735,0
490 GOSUB 500:RETURN
500 FX=INT(RND(1)*34)+3:FY=INT(RND(1)*22)+2
510 IF SCRN(FX,FY)<>32 THEN 500
520 PLOT FX,FY,F$:RETURN
600 PLOT 8,26,STR$(S):IF S>SC(1) THEN PLOT 30,26,STR$(S)
610 RETURN
650 OP(L)=1:FOR I=PY TO PY+2:PLOT 37,I," ":NEXT:CALL ZP:RETURN
660 GOSUB 670:A=#BB80+INT((40-LEN(M$))/2)
665 FOR I=1 TO LEN(M$):POKE A+I-1,ASC(MID$(M$,I,1)):NEXT:RETURN
670 FOR I=#BB82 TO #BBA7:POKE I,32:NEXT:RETURN
# Pomme de la barre en magenta comme dans le jeu (2026-11-24 by GliouCNR©70) :
# les espaces autour du @ deviennent des attributs - 2 (encre verte) avant
# la pomme posée en inverse (CHR$(192) = magenta, coins blancs, comme F$),
# 7 (encre blanche) après. Même longueur qu'avant.
680 GOSUB 692:M$="NIVEAU"+STR$(L)+" -"+CHR$(2)+F$+CHR$(7)+"="+STR$(L*10)+" - "
684 T$="RESTE "+R$+"    ":IF CD=0 AND E>4 THEN T$="PORTE OUVERTE"
# Couleurs de la barre (2026-11-24 by GliouCNR©70) : un attribut d'encre posé
# dans une case blanche - avant la zone (RA-1) : 1 = rouge pour « PORTE
# OUVERTE » ; ou entre RESTE et le nombre (RA+5) pour le décompte des
# anneaux : CO = rouge (plus de 120), cyan (61-120), jaune (21-60), vert
# (20 et moins, ligne 693) - rouge et vert inversés le 2026-11-24. La ligne du haut repart en blanc au début de chaque
# ligne d'écran ; une case attribut s'affiche vide.
686 M$=M$+T$:GOSUB 660:RA=A+LEN(M$)-13
687 IF CD=0 AND E>4 THEN POKE RA-1,1
688 POKE RA+5,32+(CD<>0)*(32-CO):RETURN
689 IF CD=0 AND E>5 THEN CD=-1:GOSUB 692:T$="RESTE "+R$+"    ":FOR I=0 TO 12:POKE RA+I,ASC(MID$(T$,I+1,1)):NEXT:POKE RA-1,32:POKE RA+5,CO:RETURN
690 IF CD=0 AND E>4 THEN FOR I=0 TO 12:POKE RA+I,PZ(I):NEXT:POKE RA-1,1:RETURN
691 GOSUB 692:POKE RA+6,ASC(R$):POKE RA+7,ASC(MID$(R$,2)):POKE RA+8,ASC(RIGHT$(R$,1)):POKE RA+5,32+(CD<>0)*(32-CO):RETURN
692 R=5-E:IF CD THEN R=256-(((H-T) AND M)+1+GR)
693 CO=1:IF R<121 THEN CO=6:IF R<61 THEN CO=3:IF R<21 THEN CO=2
695 R$=LEFT$(MID$(STR$(R),2)+"  ",3):RETURN
697 RT=256-(((H-T) AND M)+1+GR):CT=1:IF RT<121 THEN CT=6:IF RT<61 THEN CT=3:IF RT<21 THEN CT=2
698 PLOT 16,26,CT:PLOT 17,26,LEFT$(MID$(STR$(RT),2)+"  ",3):RETURN
700 CLS:GOSUB 670:PLOT 11,2,6:PLOT 13,2,"S E R P E N T"
705 PLOT 11,5,3:PLOT 13,5,"HALL OF FAME"
710 FOR I=1 TO 10:R=7+I
715 PLOT 5,R,7:PLOT 6,R,RIGHT$(" "+STR$(I),3)+". "+N$(I)
720 PLOT 20,R,3:PLOT 21,R,RIGHT$("    "+STR$(SC(I)),6):PLOT 27,R,2
722 IF NP(I) THEN PLOT 28,R,RIGHT$("   "+STR$(NP(I)),4)+" "+F$
723 IF NP(I)=0 THEN PLOT 31,R,"-"
725 NEXT:POKE 735,0:RETURN
# Barre du volume : VU de 0 à 64 (pas de 4) ; VL = volume de la puce (0-15)
760 VL=INT(VU*15/64+.5):POKE VO,VL:B=VU/4:PLOT 4,19,"VOLUME"
762 PLOT 11,19,LEFT$(V1$,B)+LEFT$(V2$,16-B):PLOT 28,19,RIGHT$("  "+STR$(VU),3)+"/64"
764 PLOT 12,20,"(FLECHES <- ->)":RETURN
800 P=11:FOR I=10 TO 1 STEP -1
805 IF S>SC(I) THEN P=I
810 NEXT
815 CLS:POKE 618,11:PRINT:PRINT:PRINT "   BRAVO ! NOUVEAU RECORD :";S
820 PRINT:PRINT "   HALL OF FAME, PLACE";P
825 PRINT:INPUT "   TON NOM (8 LETTRES)";NM$
830 POKE 618,10:IF NM$="" THEN NM$="?"
833 U$="":FOR I=1 TO LEN(NM$):J=ASC(MID$(NM$,I,1)):IF J>96 AND J<123 THEN J=J-32
834 U$=U$+CHR$(J):NEXT:NM$=U$
835 NM$=LEFT$(NM$+"        ",8)
840 IF P<10 THEN FOR I=10 TO P+1 STEP -1:N$(I)=N$(I-1):SC(I)=SC(I-1):NP(I)=NP(I-1):NEXT
845 N$(P)=NM$:SC(P)=S:NP(P)=PM
850 IF D THEN GOSUB 900
855 RETURN
900 POKE #9800,72:FOR I=1 TO 10:A=#9800+I*10-9
905 FOR J=0 TO 7:POKE A+J,ASC(MID$(N$(I),J+1,1)):NEXT
910 POKE A+8,INT(SC(I)/256):POKE A+9,SC(I) AND 255
912 POKE #9863+I*2,INT(NP(I)/256):POKE #9864+I*2,NP(I) AND 255:NEXT:POKE #98F0,VU+1
915 IF QS=0 THEN PRINT:PRINT "   SAUVEGARDE..."
917 CALL #403
920 IF PEEK(#4FE) THEN PRINT "   ERREUR DISQUE";PEEK(#4FE):WAIT 300
925 RETURN
950 FOR I=1 TO 10:A=#9800+I*10-9:N$(I)=""
955 FOR J=0 TO 7:N$(I)=N$(I)+CHR$(PEEK(A+J)):NEXT
960 SC(I)=PEEK(A+8)*256+PEEK(A+9):NP(I)=PEEK(#9863+I*2)*256+PEEK(#9864+I*2):NEXT
965 B=PEEK(#98F0):IF B>0 AND B<66 THEN VU=B-1:VS=VU
967 RETURN
# Attente d'une touche sans GET (GET rallume le curseur) : bit 7 de PEEK(735)
# CHARGEMENT des DATA, dans leur ordre, tout avant l'image (970-978) : dessins de la
# pomme (@, $B600) et du serpent (118-126, $B7B0), brique du bord (127),
# routine disque du Hall of Fame ($0400), Hall of Fame par défaut, puis moteur
# de son ($5400, installé, réglé au volume du joueur), chaînes et tableaux du jeu.
970 FOR I=0 TO 7:READ B:POKE #B600+I,B:NEXT:FOR I=0 TO 71:READ B:POKE #B7B0+I,B:NEXT
971 FOR I=0 TO 7:POKE #B7F8+I,63:NEXT:FOR I=1 TO 3:POKE #B7F8+I,4:POKE #B7FC+I,32:NEXT
972 FOR I=0 TO 92:READ B:POKE #400+I,B:NEXT
973 FOR I=1 TO 10:N$(I)="ORIC    ":READ SC(I),NP(I):NEXT:RETURN
974 FOR I=0 TO 768:READ B:POKE #5400+I,B:NEXT:CALL SR:POKE VO,INT(VU*15/64+.5)
976 W$=CHR$(160):B$=CHR$(255):F$=CHR$(192):Z$=CHR$(122):FOR I=0 TO 12:PZ(I)=ASC(MID$("PORTE OUVERTE",I+1,1)):NEXT
978 V1$="":V2$="":FOR I=1 TO 16:V1$=V1$+W$:V2$=V2$+"-":NEXT:RETURN
980 IF PEEK(735)<128 THEN 980
985 POKE 735,0:RETURN
# Attente de la barre d'espace seule (écran titre)
986 IF PEEK(735)<>160 THEN 986
988 POKE 735,0:RETURN
# Routine machine de titre_copie.s (xa -o titre_copie.bin titre_copie.s)
990 DATA 169,96,141,112,4,169,160,141,115,4,162,31,160,0,185,0,96,153,0,160,200,208
995 DATA 247,238,112,4,238,115,4,202,208,238,185,0,127,153,0,191,200,192,64,208,245,96
# Dessin de la pomme (caractère @ redéfini, ligne 34) : 6 points par ligne
996 DATA 6,12,59,63,63,63,63,30
# Queue (ligne 36, ajoutée le 2026-11-22) : caractères 118 = corps à droite
# (pointe vers la gauche), 119 = corps à gauche, 120 = corps en dessous (pointe
# vers le haut), 121 = corps au-dessus ; redessinée quand elle avance (175-176).
997 DATA 3,7,15,63,63,15,7,3,48,56,60,63,63,60,56,48,12,12,30,30,30,63,63,30,30,63,63,30,30,30,12,12
# Dessin du serpent (ligne 36) : caractères 122 = corps (anneau à écailles),
# 123/124/125/126 = tête vers la droite/gauche/le bas/le haut (yeux, museau)
998 DATA 30,51,45,45,51,63,63,30,28,62,58,63,63,58,62,28,14,31,23,63
999 DATA 63,23,31,14,30,63,63,63,45,63,30,12,12,30,63,45,63,63,63,30
# Routine machine de hof_disque.s (xa -o hof_disque.bin hof_disque.s)
1000 DATA 76,6,4,76,43,4,120,169,18,141,18,3,169,128,141,16,3,32,87,4
1010 DATA 160,0,173,16,3,74,144,52,173,24,3,48,245,173,19,3,153,0,152,200
1020 DATA 76,28,4,120,169,18,141,18,3,169,160,141,16,3,32,87,4,160,0,173
1030 DATA 16,3,74,144,15,173,24,3,48,245,185,0,152,141,19,3,200,76,65,4
1040 DATA 41,46,141,254,4,88,96,160,4,136,208,253,96
# Hall of Fame par défaut (ligne 972) : score, pommes, de la 1re à la 10e place
1050 DATA 2500,60,2000,50,1500,40,1250,35,1000,30
1060 DATA 750,25,500,20,300,15,150,10,50,5
# Moteur de son son.s (xa -o son.bin son.s), 769 octets en $5400
1070 DATA 76,20,84,76,94,84,76,124,84,76,155,84,76,176,84,15,76,195,84,0
1072 DATA 120,169,122,141,69,2,169,85,141,70,2,88,169,7,162,28,32,144,245,169
1074 DATA 6,162,31,32,144,245,162,0,169,1,32,144,245,162,0,169,3,32,144,245
1076 DATA 160,8,152,162,0,32,144,245,200,192,11,208,245,169,0,141,54,86,141,55
1078 DATA 86,141,57,86,141,59,86,141,61,86,141,255,86,96,169,0,174,53,86,32
1080 DATA 144,245,173,53,86,73,48,141,53,86,169,8,174,15,84,32,144,245,169,3
1082 DATA 141,54,86,96,169,0,141,57,86,169,2,162,24,32,144,245,173,15,84,141
1084 DATA 55,86,169,6,141,56,86,169,9,174,15,84,76,144,245,169,0,141,55,86
1086 DATA 141,58,86,169,28,141,57,86,169,9,174,15,84,76,144,245,173,15,84,141
1088 DATA 59,86,169,10,141,60,86,169,10,174,15,84,76,144,245,120,174,19,84,189
1090 DATA 63,86,141,12,85,141,44,85,189,65,86,141,13,85,141,45,85,189,67,86
1092 DATA 141,66,85,141,81,85,141,95,85,189,69,86,141,67,85,141,82,85,141,96
1094 DATA 85,169,7,162,56,32,144,245,169,0,141,62,86,141,0,87,32,8,85,32
1096 DATA 62,85,88,96,172,62,86,185,71,86,240,40,201,1,240,12,170,169,0,32
1098 DATA 144,245,174,15,84,76,34,85,162,0,169,8,32,144,245,172,62,86,200,185
1100 DATA 71,86,141,61,86,136,200,200,140,62,86,96,141,62,86,76,8,85,172,0
1102 DATA 87,185,154,86,240,46,170,169,4,32,144,245,172,0,87,200,185,154,86,170
1104 DATA 169,5,32,144,245,172,0,87,200,200,185,154,86,141,255,86,136,136,200,200
1106 DATA 200,140,0,87,169,10,174,15,84,76,144,245,141,0,87,76,62,85,72,173
1108 DATA 13,3,41,64,208,3,76,49,86,138,72,152,72,173,54,86,240,12,206,54
1110 DATA 86,208,7,169,8,162,0,32,144,245,173,61,86,240,25,206,61,86,173,61
1112 DATA 86,201,3,208,7,169,8,162,0,32,144,245,173,61,86,208,3,32,8,85
1114 DATA 173,255,86,240,25,206,255,86,173,255,86,201,10,208,7,169,10,162,0,32
1116 DATA 144,245,173,255,86,208,3,32,62,85,173,57,86,240,30,173,58,86,24,105
1118 DATA 4,141,58,86,170,169,2,32,144,245,206,57,86,208,36,169,9,162,0,32
1120 DATA 144,245,76,19,86,173,55,86,240,21,206,56,86,208,16,169,6,141,56,86
1122 DATA 206,55,86,174,55,86,169,9,32,144,245,173,59,86,240,21,206,60,86,208
1124 DATA 16,169,10,141,60,86,206,59,86,174,59,86,169,10,32,144,245,104,168,104
1126 DATA 170,104,76,34,238,96,0,0,0,0,0,0,0,0,0,71,203,86,86,154
1128 DATA 230,86,86,119,24,189,12,159,12,119,24,95,24,106,12,119,12,127,12,142
1130 DATA 12,159,48,179,24,142,12,119,12,90,24,95,24,106,12,95,12,106,12,127
1132 DATA 12,119,48,95,12,95,12,106,12,106,12,119,24,159,24,142,12,127,12,119
1134 DATA 12,142,12,159,48,119,24,189,12,159,12,119,24,95,24,106,12,127,12,159
1136 DATA 12,127,12,119,48,0,221,1,48,126,2,48,126,2,48,169,1,48,204,2
1138 DATA 48,221,1,48,126,2,48,221,1,48,221,1,48,126,2,48,204,2,48,221
1140 DATA 1,48,221,1,48,126,2,48,126,2,48,221,1,48,0,95,30,106,30,119
1142 DATA 30,127,30,142,30,127,30,119,60,106,30,119,30,127,30,159,30,142,90,1
1144 DATA 30,0,56,2,60,246,2,60,56,2,60,221,1,60,126,2,60,246,2,60
1146 DATA 56,2,60,56,2,60,0,0,0
