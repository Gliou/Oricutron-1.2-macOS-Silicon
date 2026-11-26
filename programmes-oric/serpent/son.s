; son.s — moteur de son du serpent, avec un VOLUME réglable (0 à 15), qui
; remplace PING, ZAP et EXPLODE de la ROM (trop forts) et le tic-tac des pas.
; Créé le 2026-11-24 by GliouCNR©70 (remplace son_pas.s)
; Modifié le 2026-11-24 by GliouCNR©70 - petite musique de l'écran titre (MUSIQUE),
; jouée en boucle par l'interruption, de l'image titre au début de la partie
; (elle sert aussi à régler le volume sur l'écran du Hall of Fame). Corrigé - le
; saut « pas de tic en cours » sautait aussi la musique (une seule note tenue).
; Modifié le 2026-11-24 by GliouCNR©70 - vraie petite musique - 4 phrases (~10 s)
; sur le canal A et une basse sur le canal C (2 voix), moteur déplacé en $5400
; (puis en $5300 le 2026-11-24 soir, et en $5000 le 2026-11-26, by GliouCNR©70).
; Modifié le 2026-11-24 by GliouCNR©70 - plusieurs morceaux (CHANSON, en $5013) -
; 0 = comptine de l'écran titre, 1 = « perdu » sur le Hall of Fame, 2 = fanfare
; de victoire (ajoutée le 2026-11-24 by GliouCNR©70). La musique
; en la mineur est rangée dans ../musiques/la-mineur-2-voix.s.
; Modifié le 2026-11-24 by GliouCNR©70 - NOMBRE et POMME - la barre de statut
; est écrite en 6502 (plus de pause du serpent à chaque pomme) ; le moteur,
; devenu plus gros qu'1 Ko, descend en $5300 (HIMEM #5300).
;
;   xa -o son.bin son.s
;   (sur la disquette, son.bin est lu en $5000 par le démarrage, avant le
;    BASIC - oric_dsk.py --binaire son.bin@5000 ; sur la cassette, c'est le
;    fichier SON rangé après le programme (oric_tap.py --ajoute), chargé par
;    CLOAD"SON" ligne 7. Plus de lignes DATA depuis le 2026-11-26. HIMEM est
;    abaissé à $5000, juste SOUS l'image titre ($5800-$773F) - le BASIC range
;    ses chaînes sous HIMEM, jamais dans l'image ni dans le moteur.
;    Avant le 2026-11-24 soir, le moteur était en $7600, dans la fin du tampon
;    de l'image - les noms du Hall of Fame lus avant l'image l'abîmaient.)
;   CALL #5000  INIT   installe le moteur sur l'interruption de l'horloge
;                      (100 fois par seconde) et règle le mélangeur
;   CALL #5003  PAS    tic-tac du pas (canal A, 30 ms)
;   CALL #5006  PING   PING au volume choisi (canal B, ~1 s)
;   CALL #5009  ZAP    ZAP au volume choisi (canal B, balayage de 0,3 s)
;   CALL #500C  BOUM   EXPLODE au volume choisi (canal C, bruit, ~1,5 s)
;   POKE #500F,v       le volume, 0 (muet) à 15 (le maximum de la puce)
;   POKE #5013,n       morceau - 0 Pastorale de Beethoven (chargement, titre,
;                      Hall of Fame), 1 « perdu » (Hall of Fame),
;                      2 Ode à la joie de Beethoven (écran de victoire,
;                      depuis le 2026-11-26 ; c'était une fanfare)
;   CALL #5010  MUSIQUE le morceau choisi, en boucle (mélodie canal A, basse
;                      canal C), au volume choisi ;
;                      INIT l'arrête
;   DOKE #5014,n       nombre à écrire (0 à 65535)
;   DOKE #5016,a       adresse écran de son premier chiffre
;   CALL #5018 / #501B NOMBRE sur 5 / 3 cases (calé à gauche, puis espaces)
;   CALL #501E  POMME  le serpent a mangé - score + points, taille + 1, et
;                      la barre de statut réécrite (score, hi-score, taille,
;                      décompte du haut)
;   CALL #5021 / #5024 réécrit le score / la taille (début d'un tableau)
;   DOKE #5027,s  score   DOKE #5029,h  meilleur score   POKE #502B,p  points
;   POKE #502C,r  anneaux qui manquent pour 256
;   POKE #502D,m  décompte du haut (0 rien, 1 pommes avant la porte, 2 anneaux)
;   POKE #502E,n  pommes avant la porte   DOKE #502F,a  case couleur du décompte
;
; Pourquoi - dans la ROM, PING et EXPLODE mettent le volume sur l'ENVELOPPE de
; la puce AY-3-8912 (registre 8 = 16), qui part toujours de 15, le maximum ; ZAP
; joue au volume 15 fixe. Impossible de les baisser. Ici, la baisse du volume
; (« enveloppe ») est faite par le 6502 à chaque interruption de l'horloge
; (VIA, toutes les 10 ms) - le son part du volume choisi et s'éteint seul,
; sans que le BASIC attende. Le moteur se glisse devant la routine
; d'interruption de la ROM ($EE22, vecteur $0244-$0246) et lui rend la main.
; Écriture d'un registre - WriteToAY de la ROM ($F590), A = registre, X =
; valeur ; elle garde le bit 6 du mélangeur (clavier) et bloque les
; interruptions pendant l'écriture.
; Modifié le 2026-11-26 by GliouCNR©70 - la Pastorale de Beethoven remplace la
; comptine (morceau 0, rangée dans ../musiques/comptine-serpent.s) ; tables
; lues sur 16 bits ; moteur en $5000, lu sur la disquette par le démarrage
; (oric_dsk.py --binaire) - la musique part dès « CHARGEMENT EN COURS ».
; Modifié le 2026-11-26 by GliouCNR©70 - l'Ode à la joie de Beethoven remplace
; la fanfare de victoire (morceau 2, rangée dans ../musiques/fanfare-serpent.s).
; Attention avec xa - un deux-points est un séparateur, même dans un commentaire.

AY       = $F590      ; WriteToAY
VIA_IFR  = $030D      ; bit 6 = interruption de l'horloge (timer 1)
IRQV     = $0245      ; adresse sautée par l'interruption (JMP $EE22)
ROMIRQ   = $EE22

        * = $5000

        jmp init
        jmp pas
        jmp ping
        jmp zap
        jmp boum
vol     .byt 15               ; $500F - volume choisi (0-15)
        jmp musique           ; $5010
chanson .byt 0                ; $5013 - morceau à jouer
nval    .word 0               ; $5014 - nombre à afficher (DOKE)
nadr    .word $BB80           ; $5016 - adresse écran du 1er chiffre (DOKE)
        jmp nomb5             ; $5018 - écrit nval sur 5 cases
        jmp nomb3             ; $501B - écrit nval sur 3 cases
        jmp pomme             ; $501E - POMME - tout ce qui change quand le serpent mange
        jmp affsc             ; $5021 - écrit le score (et le hi-score s'il est battu)
        jmp afftai            ; $5024 - écrit la taille du serpent, en couleur
sco     .word 0               ; $5027 - score (DOKE au début de chaque tableau)
hisc    .word 0               ; $5029 - meilleur score du Hall of Fame (DOKE)
pts     .byt 10               ; $502B - points d'une pomme (10 x niveau)
reste   .byt 252              ; $502C - anneaux qui manquent pour 256 (0 = gagné)
hmode   .byt 0                ; $502D - décompte du haut - 0 rien (PORTE OUVERTE),
                              ;   1 pommes avant la porte (hreste), 2 anneaux (reste, en couleur)
hreste  .byt 5                ; $502E - pommes avant la porte
hadr    .word $BB80           ; $502F - case couleur du décompte du haut (chiffres juste après)

; ----- POMME (2026-11-24 by GliouCNR©70) - appelée par le BASIC à chaque pomme
; mangée (ligne 185), à la place de 4 sous-programmes BASIC (score, hi-score,
; taille, décompte du haut) - le serpent ne marque plus de pause.
pomme   clc                   ; score + points de la pomme
        lda sco
        adc pts
        sta sco
        bcc p1
        inc sco+1
p1      jsr affsc
        dec reste             ; un anneau de plus
        jsr afftai
        lda hmode             ; décompte de la barre du haut
        beq pfin
        lsr                   ; 1 -> retenue, 2 -> pas de retenue
        bcc ph2
        dec hreste            ; pommes avant la porte (sans couleur)
        lda hreste
        jmp phw
ph2     lda hadr              ; anneaux qui manquent, en couleur
        sta phc+1
        lda hadr+1
        sta phc+2
        lda reste
        jsr coul
phc     sta $BB80             ; (adresse posée plus haut)
        lda reste
phw     sta nval
        lda #0
        sta nval+1
        clc
        lda hadr
        adc #1
        sta nadr
        lda hadr+1
        adc #0
        sta nadr+1
        jmp nomb3
pfin    rts

; ----- Score à la colonne 9 de la ligne 26 de PLOT (ligne 27 de l'écran, qui
; commence en $BFB8 - la ligne 0 de PLOT est sous la ligne de statut) ($BFC1) ; s'il dépasse le meilleur
; score, il est aussi écrit à la place du HI-SCORE (colonne 31, $BFD7).
affsc   lda sco
        sta nval
        lda sco+1
        sta nval+1
        lda #<$BFC1
        sta nadr
        lda #>$BFC1
        sta nadr+1
        jsr nomb5
        lda hisc              ; hisc < sco ?
        cmp sco
        lda hisc+1
        sbc sco+1
        bcs afin
        lda #<$BFD7
        sta nadr              ; (même octet haut $BF)
        jmp nomb5
afin    rts

; ----- Taille du serpent (256 - reste) à la colonne 17 ($BFC9), précédée de
; sa couleur (colonne 16) - rouge, cyan, jaune, puis vert pour la fin.
afftai  lda reste
        jsr coul
        sta $BFC8
        sec
        lda #0
        sbc reste
        sta nval
        lda #1
        sbc #0
        sta nval+1
        lda #<$BFC9
        sta nadr
        lda #>$BFC9
        sta nadr+1
        jmp nomb3

; ----- Couleur d'un décompte (A = ce qui manque) - 1 rouge (121 et plus),
; 6 cyan (61-120), 3 jaune (21-60), 2 vert (20 et moins).
coul    cmp #21
        bcc c2
        cmp #61
        bcc c3
        cmp #121
        bcc c6
        lda #1
        rts
c2      lda #2
        rts
c3      lda #3
        rts
c6      lda #6
        rts

; ----- NOMBRE - écrit nval en décimal à l'adresse nadr, calé à gauche,
; complété par des espaces jusqu'à la largeur (5 ou 3 cases). Remplace
; STR$/MID$/LEFT$ du BASIC dans la barre de statut - bien plus rapide, et
; aucune chaîne créée (pas de « ménage » des chaînes en pleine partie).
; nval n'est pas modifié - on peut l'écrire à deux endroits de suite.
nomb5   lda #5
        bne nomb
nomb3   lda #3
nomb    sta nlar
        lda nadr
        sta nsto+1
        sta nsp+1
        lda nadr+1
        sta nsto+2
        sta nsp+2
        lda nval
        sta nw
        lda nval+1
        sta nw+1
        ldx #0                ; puissance de 10 (10000, 1000, 100, 10, 1)
        ldy #0                ; cases écrites
ncif    lda #$30              ; chiffre = « 0 »
        sta nc
nsub    lda nw                ; on retire la puissance tant qu'on peut
        sec
        sbc ptl,x
        sta nt
        lda nw+1
        sbc pth,x
        bcc nfin
        sta nw+1
        lda nt
        sta nw
        inc nc
        jmp nsub
nfin    lda nc
        cpy #0                ; zéros de tête sautés,
        bne necr
        cpx #4                ; sauf le chiffre des unités
        beq necr
        cmp #$30
        beq nsaut
necr
nsto    sta $BB80,y           ; (adresse posée plus haut)
        iny
nsaut   inx
        cpx #5
        bne ncif
        lda #$20              ; espaces jusqu'à la largeur
npad    cpy nlar
        bcs nret
nsp     sta $BB80,y
        iny
        jmp npad
nret    rts
ptl     .byt <10000, <1000, <100, <10, <1
pth     .byt >10000, >1000, >100, >10, >1
nw      .word 0
nt      .byt 0
nc      .byt 0
nlar    .byt 0

; ----- Installation (peut être appelée plusieurs fois) -----
init    sei
        lda #<tick
        sta IRQV
        lda #>tick
        sta IRQV+1
        cli
        lda #7                ; mélangeur - son A et B, bruit C
        ldx #$1C
        jsr AY
        lda #6                ; hauteur du bruit (comme EXPLODE)
        ldx #$1F
        jsr AY
        ldx #0                ; parties hautes des périodes A et B à 0
        lda #1
        jsr AY
        ldx #0
        lda #3
        jsr AY
        ldy #8                ; volumes A, B, C à 0
coupe   tya
        ldx #0
        jsr AY
        iny
        cpy #11
        bne coupe
        lda #0
        sta ga
        sta lb
        sta rb
        sta lc
        sta mt                ; plus de musique
        sta bt
        rts

; ----- Tic-tac du pas - canal A, 3 tops d'horloge -----
pas     lda #0
        ldx ton
        jsr AY
        lda ton               ; tic <-> tac (651 / 781 Hz)
        eor #$30
        sta ton
        lda #8
        ldx vol
        jsr AY
        lda #3
        sta ga
        rts

; ----- PING - canal B, période $18 comme la ROM, -1 de volume tous les 6 tops -----
ping    lda #0
        sta rb                ; arrête un ZAP en cours
        lda #2
        ldx #$18
        jsr AY
        lda vol
        sta lb
        lda #6
        sta cb
        lda #9
        ldx vol
        jmp AY

; ----- ZAP - canal B, période qui monte de 4 à chaque top, 28 tops -----
zap     lda #0
        sta lb
        sta pb
        lda #28
        sta rb
        lda #9
        ldx vol
        jmp AY

; ----- EXPLODE - bruit sur le canal C, -1 de volume tous les 10 tops -----
boum    lda vol
        sta lc
        lda #10
        sta cc
        lda #10
        ldx vol
        jmp AY

; ----- MUSIQUE - lance la mélodie depuis le début -----
; Modifié le 2026-11-26 by GliouCNR©70 - les tables sont lues avec une adresse
; sur 16 bits (posée dans les instructions nm1/nm2, bm1/bm2/bm3, puis avancée
; de 2 ou 3 octets à chaque note) - un morceau n'est plus limité à 255 octets
; (la Pastorale de Beethoven en fait 483 pour la mélodie).
musique sei
        ldx chanson           ; adresses des tables du morceau choisi
        lda tmel,x
        sta mdeb
        lda tmeh,x
        sta mdeb+1
        lda tbal,x
        sta bdeb
        lda tbah,x
        sta bdeb+1
        lda #7                ; mélangeur - sons A, B et C, pas de bruit
        ldx #$38
        jsr AY
        jsr mrep
        jsr brep
        jsr note
        jsr basse
        cli
        rts

; Remet la mélodie / la basse au début du morceau
mrep    lda mdeb
        sta nm1+1
        sta nm2+1
        lda mdeb+1
        sta nm1+2
        sta nm2+2
        rts
brep    lda bdeb
        sta bm1+1
        sta bm2+1
        sta bm3+1
        lda bdeb+1
        sta bm1+2
        sta bm2+2
        sta bm3+2
        rts

; Joue la note suivante de la mélodie (période, durée en tops), 0 = fin
note    ldy #0
nm1     lda pastor,y          ; période (adresse posée par MUSIQUE)
        beq mfin
        cmp #1                ; période 1 = silence
        beq nsil
        tax
        lda #0                ; période du canal A
        jsr AY
        ldx vol
        jmp ndur
nsil    ldx #0
ndur    lda #8                ; volume du canal A (X)
        jsr AY
        ldy #1
nm2     lda pastor,y          ; durée
        sta mt
        clc                   ; note suivante - adresse + 2
        lda nm1+1
        adc #2
        sta nm1+1
        sta nm2+1
        bcc nok
        inc nm1+2
        inc nm2+2
nok     rts
mfin    jsr mrep              ; fin de la mélodie - on la reprend au début
        jmp note              ; (elle tourne jusqu'à INIT)

; Joue la note de basse suivante (période sur 2 octets, durée), 0 = fin
basse   ldy #0
bm1     lda pbas6,y           ; (adresse posée par MUSIQUE)
        beq bfin
        cmp #1                ; période 1 = silence
        bne bson
        lda #10
        ldx #0
        jsr AY
        jmp bdur
bson    tax
        lda #4                ; période du canal C, partie basse...
        jsr AY
        ldy #1
bm2     lda pbas6,y
        tax
        lda #5                ; ... et partie haute
        jsr AY
        lda #10               ; volume du canal C
        ldx vol
        jsr AY
bdur    ldy #2
bm3     lda pbas6,y           ; durée
        sta bt
        clc                   ; note suivante - adresse + 3
        lda bm1+1
        adc #3
        sta bm1+1
        sta bm2+1
        sta bm3+1
        bcc bok
        inc bm1+2
        inc bm2+2
        inc bm3+2
bok     rts
bfin    jsr brep
        jmp basse

; ----- Interruption - 100 fois par seconde -----
tick    pha
        lda VIA_IFR
        and #$40
        bne horloge
        jmp rom               ; pas l'horloge - rien à faire ici
horloge txa
        pha
        tya
        pha
        lda ga                ; canal A - fin du tic
        beq tmu
        dec ga
        bne tmu
        lda #8
        ldx #0
        jsr AY
tmu     lda mt                ; canal A - musique en cours ?
        beq tbas
        dec mt
        lda mt
        cmp #3                ; 3 tops de silence avant la note suivante
        bne tm2
        lda #8
        ldx #0
        jsr AY
tm2     lda mt
        bne tbas
        jsr note
tbas    lda bt                ; canal C - basse en cours ?
        beq tb
        dec bt
        lda bt
        cmp #10               ; basse détachée - 10 tops de silence
        bne tb2
        lda #10
        ldx #0
        jsr AY
tb2     lda bt
        bne tb
        jsr basse
tb      lda rb                ; canal B - ZAP en cours ?
        beq pg
        lda pb
        clc
        adc #4
        sta pb
        tax
        lda #2
        jsr AY
        dec rb
        bne tc
        lda #9
        ldx #0
        jsr AY
        jmp tc
pg      lda lb                ; canal B - PING qui s'éteint
        beq tc
        dec cb
        bne tc
        lda #6
        sta cb
        dec lb
        ldx lb
        lda #9
        jsr AY
tc      lda lc                ; canal C - EXPLODE qui s'éteint
        beq fin
        dec cc
        bne fin
        lda #10
        sta cc
        dec lc
        ldx lc
        lda #10
        jsr AY
fin     pla
        tay
        pla
        tax
rom     pla
        jmp ROMIRQ

ton     .byt $60
ga      .byt 0                ; tops restants du tic (canal A)
lb      .byt 0                ; volume du PING (canal B)
cb      .byt 0                ; tops avant la prochaine baisse du PING
rb      .byt 0                ; tops restants du ZAP (canal B)
pb      .byt 0                ; période du ZAP
lc      .byt 0                ; volume de l'EXPLODE (canal C)
cc      .byt 0                ; tops avant la prochaine baisse
mt      .byt 0                ; tops restants de la note de musique (0 = pas de musique)
mdeb    .word 0               ; début de la mélodie du morceau en cours

; Adresses des tables de chaque morceau (0 Pastorale, 1 perdu, 2 Ode à la joie)
tmel    .byt <pastor, <perdu, <joie
tmeh    .byt >pastor, >perdu, >joie
tbal    .byt <pbas6, <pbasse, <jbasse
tbah    .byt >pbas6, >pbasse, >jbasse

; Format - mélodie - période AY sur 1 octet (1 MHz / 16 / fréquence), durée en
; centièmes de seconde, période 1 = silence, 0 = fin (reprise au début) ;
; basse - période sur 2 octets (bas, haut), durée, 0 = fin.
; Notes - sol4 159, la4 142, si4 127, do5 119, ré5 106, mi5 95, fa5 90, sol5 80,
; do4 239, mi4 189, fa4 179 ; basse - do3 477, sol2 638, fa2 716, ré3 425,
; la2 568, mi2 758, mi3 379.

; PASTORALE (écran de chargement, titre et Hall of Fame) - Beethoven,
; Symphonie n° 6 en fa majeur, op. 68, 1er mouvement (« Éveil d'impressions
; joyeuses en arrivant à la campagne », Allegro ma non troppo), arrangée pour
; 2 voix le 2026-11-26 by GliouCNR©70 - mélodie des premiers violons (complétée
; par le hautbois, la clarinette ou les seconds violons quand ils se taisent),
; basse des violoncelles (le bourdon fa-do en notes tenues). Noire = 44
; centièmes, ~47 s en boucle - le thème et son point d'orgue, la phrase des
; violons, la montée « sol la si bémol si do » répétée, les arpèges et le
; tutti jusqu'à l'accord de fa. Copie de ../musiques/pastorale-beethoven-6.s
; (branche Musique-Oric), qui explique comment les tables sont faites.
pastor  .byt 179,22,142,22,134,22,106,22,119,22,134,11,142,11,159,66,239,22,179,22
        .byt 159,22,142,22,134,11,142,11,159,132,1,22,142,22,134,22,106,22,119,22
        .byt 159,11,142,11,134,22,159,22,142,22,142,22,134,22,134,22,159,22,159,11
        .byt 142,11,134,22,159,22,142,44,119,44,134,66,142,22,106,44,119,44,159,22
        .byt 159,11,142,11,134,22,159,22,142,44,119,44,134,66,142,22,106,44,119,44
        .byt 159,22,159,11,142,11,134,22,127,22,119,22,159,11,142,11,134,22,127,22
        .byt 119,22,159,11,142,11,134,22,127,22,119,22,159,11,142,11,134,22,127,22
        .byt 119,22,159,11,142,11,134,22,127,22,119,22,159,11,142,11,134,22,127,22
        .byt 119,22,159,11,142,11,134,22,127,22,119,22,159,11,142,11,134,22,127,22
        .byt 119,22,159,11,142,11,134,22,127,22,119,22,159,11,142,11,134,22,127,22
        .byt 119,22,142,11,134,11,119,22,113,22,106,22,134,11,119,11,106,22,95,22
        .byt 89,22,106,11,95,11,89,22,80,22,71,22,71,22,67,22,53,22,60,22
        .byt 67,11,71,11,80,22,119,22,89,22,80,22,71,22,67,11,71,11,80,22
        .byt 71,22,67,22,60,11,67,11,71,22,179,11,142,11,60,22,159,11,134,11
        .byt 60,22,142,11,119,11,60,22,159,11,95,11,60,22,142,11,89,11,60,22
        .byt 142,11,89,11,60,22,95,11,80,11,60,22,95,11,80,11,71,22,71,22
        .byt 67,22,53,22,60,22,67,11,71,11,80,22,119,22,89,22,80,22,71,22
        .byt 67,11,71,11,80,22,71,22,67,22,60,11,67,11,71,22,60,22,60,22
        .byt 60,22,60,44,67,11,71,11,80,11,89,11,95,22,89,22,80,22,71,11
        .byt 80,11,89,22,80,22,71,22,67,11,71,11,80,22,67,22,67,22,67,22
        .byt 67,44,60,11,67,11,71,11,80,11,71,22,67,22,60,22,53,11,60,11
        .byt 67,22,60,11,67,11,80,22,60,11,67,11,71,22,67,22,60,22,53,11
        .byt 60,11,67,22,60,11,67,11,80,22,60,11,67,11,71,22,60,11,67,11
        .byt 80,22,60,11,67,11,71,22,60,11,67,11,80,22,60,11,67,11,71,22
        .byt 1,22,0
pbas6   .byt 204,2,255,204,2,53,188,3,132,204,2,176,204,2,176,102,1,44,28,1,44
        .byt 63,1,66,102,1,22,24,2,44,102,1,44,222,1,88,204,2,44,56,2,44
        .byt 126,2,66,204,2,22,24,2,44,204,2,44,222,1,66,222,1,22,222,1,66
        .byt 222,1,22,222,1,66,222,1,22,222,1,66,222,1,22,222,1,66,222,1,22
        .byt 222,1,66,222,1,22,222,1,66,222,1,22,222,1,66,222,1,22,222,1,66
        .byt 222,1,22,222,1,22,1,0,22,222,1,132,24,2,88,222,1,88,204,2,88
        .byt 204,2,88,204,2,88,204,2,88,204,2,88,204,2,88,204,2,88,204,2,88
        .byt 204,2,88,204,2,88,204,2,88,204,2,88,204,2,88,204,2,88,188,3,88
        .byt 188,3,88,188,3,88,188,3,88,204,2,88,204,2,88,204,2,88,204,2,88
        .byt 204,2,88,204,2,88,204,2,22,1,0,22,0


; PERDU (Hall of Fame après une partie perdue) - originale, la mineur, lente et
; douce ; 4 mesures de 120 centièmes (noire 30), ~4,8 s.
; mi ré do si | la si do - | ré do si sol | la - - (silence)
perdu   .byt 95,30, 106,30, 119,30, 127,30,  142,30, 127,30, 119,60
        .byt 106,30, 119,30, 127,30, 159,30,  142,90, 1,30
        .byt 0
; basse - la mi / la do / sol mi / la la (blanches)
pbasse  .byt $38,2,60, $F6,2,60,  $38,2,60, $DD,1,60
        .byt $7E,2,60, $F6,2,60,  $38,2,60, $38,2,60
        .byt 0
; ODE À LA JOIE (écran de victoire) - Beethoven, Symphonie n° 9 en ré mineur,
; op. 125, finale, le thème de l'« Ode à la joie », en ré majeur comme chez
; Beethoven ; arrangée pour 2 voix le 2026-11-26 by GliouCNR©70. Noire = 30
; centièmes, 16 mesures + une blanche de silence, ~20 s en boucle.
; fa# fa# sol la | la sol fa# mi | ré ré mi fa# | fa#. mi mi (x2, fin ré)
; mi mi fa# ré | mi fa#-sol fa# ré | mi fa#-sol fa# mi | ré mi la fa# (en
; avance, la syncope de Beethoven) | fa# sol la | la sol fa# mi | ré ré mi fa#
; | mi. ré ré. Basse - ré, sol et la (blanches). Copie de
; ../musiques/ode-a-la-joie.s (branche Musique-Oric).
joie    .byt 84,30,84,30,80,30,71,30,71,30,80,30,84,30,95,30,106,30,106,30
        .byt 95,30,84,30,84,45,95,15,95,60,84,30,84,30,80,30,71,30,71,30
        .byt 80,30,84,30,95,30,106,30,106,30,95,30,84,30,95,45,106,15,106,60
        .byt 95,30,95,30,84,30,106,30,95,30,84,15,80,15,84,30,106,30,95,30
        .byt 84,15,80,15,84,30,95,30,106,30,95,30,142,30,84,60,84,30,80,30
        .byt 71,30,71,30,80,30,84,30,95,30,106,30,106,30,95,30,84,30,95,45
        .byt 106,15,106,60,1,60,0
jbasse  .byt 170,1,60,56,2,60,126,2,60,56,2,60,170,1,60,56,2,60,56,2,60
        .byt 56,2,60,170,1,60,56,2,60,126,2,60,56,2,60,170,1,60,56,2,60
        .byt 56,2,60,170,1,60,56,2,60,170,1,60,56,2,60,170,1,60,56,2,60
        .byt 56,2,60,170,1,60,56,2,60,170,1,60,56,2,60,126,2,60,56,2,60
        .byt 170,1,60,56,2,60,56,2,60,170,1,60,1,0,60,0

bt      .byt 0                ; tops restants de la note de basse
bdeb    .word 0               ; début de sa basse
