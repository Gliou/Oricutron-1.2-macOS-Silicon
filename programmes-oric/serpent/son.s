; son.s — moteur de son du serpent, avec un VOLUME réglable (0 à 15), qui
; remplace PING, ZAP et EXPLODE de la ROM (trop forts) et le tic-tac des pas.
; Créé le 2026-11-24 by GliouCNR©70 (remplace son_pas.s)
; Modifié le 2026-11-24 by GliouCNR©70 - petite musique de l'écran titre (MUSIQUE),
; jouée en boucle par l'interruption, de l'image titre au début de la partie
; (elle sert aussi à régler le volume sur l'écran du Hall of Fame). Corrigé - le
; saut « pas de tic en cours » sautait aussi la musique (une seule note tenue).
; Modifié le 2026-11-24 by GliouCNR©70 - vraie petite musique - 4 phrases (~10 s)
; sur le canal A et une basse sur le canal C (2 voix), moteur déplacé en $5400.
;
;   xa -o son.bin son.s
;   (les octets sont dans les lignes DATA 1070+ de serpent.bas, posés en $5400,
;    au-dessus de HIMEM abaissé à $5400, juste SOUS l'image titre ($5800-$773F)
;    - le moteur est chargé avant l'image, pour que la musique démarre avec
;    elle, et le BASIC range ses chaînes sous HIMEM, donc jamais dans l'image.
;    Avant le 2026-11-24 soir, le moteur était en $7600, dans la fin du tampon
;    de l'image - les noms du Hall of Fame lus avant l'image l'abîmaient.)
;   CALL #5400  INIT   installe le moteur sur l'interruption de l'horloge
;                      (100 fois par seconde) et règle le mélangeur
;   CALL #5403  PAS    tic-tac du pas (canal A, 30 ms)
;   CALL #5406  PING   PING au volume choisi (canal B, ~1 s)
;   CALL #5409  ZAP    ZAP au volume choisi (canal B, balayage de 0,3 s)
;   CALL #540C  BOUM   EXPLODE au volume choisi (canal C, bruit, ~1,5 s)
;   POKE #540F,v       le volume, 0 (muet) à 15 (le maximum de la puce)
;   CALL #5410  MUSIQUE petite musique en boucle (mélodie canal A, basse canal
;                      C), au volume choisi ;
;                      INIT l'arrête
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
; Attention avec xa - un deux-points est un séparateur, même dans un commentaire.

AY       = $F590      ; WriteToAY
VIA_IFR  = $030D      ; bit 6 = interruption de l'horloge (timer 1)
IRQV     = $0245      ; adresse sautée par l'interruption (JMP $EE22)
ROMIRQ   = $EE22

        * = $5400

        jmp init
        jmp pas
        jmp ping
        jmp zap
        jmp boum
vol     .byt 15               ; $540F - volume choisi (0-15)
        jmp musique           ; $5410

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
musique sei
        lda #7                ; mélangeur - sons A, B et C, pas de bruit
        ldx #$38
        jsr AY
        lda #0
        sta mi
        sta bi
        jsr note
        jsr basse
        cli
        rts

; Joue la note suivante de la mélodie (période, durée en tops), 0 = fin
note    ldy mi
        lda melodie,y
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
        ldy mi
        lda melodie+1,y
        sta mt
        iny
        iny
        sty mi
        rts
mfin    sta mi                ; (A = 0) fin de la mélodie - on la reprend
        jmp note              ; au début (elle tourne jusqu'à INIT)

; Joue la note de basse suivante (période sur 2 octets, durée), 0 = fin
basse   ldy bi
        lda basses,y
        beq bfin
        tax
        lda #4                ; période du canal C, partie basse...
        jsr AY
        ldy bi
        ldx basses+1,y
        lda #5                ; ... et partie haute
        jsr AY
        ldy bi
        lda basses+2,y
        sta bt
        iny
        iny
        iny
        sty bi
        lda #10               ; volume du canal C
        ldx vol
        jmp AY
bfin    sta bi
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
mi      .byt 0                ; position dans la mélodie

; Musique originale en la mineur, 4 phrases de 2 mesures (A, A', B, C), ~10 s.
; Mélodie - période AY (1 MHz / 16 / fréquence), durée en centièmes ; 30 = une
; noire. la4 142, si4 127, do5 119, ré5 106, mi5 95, fa5 90, sol5 80, sol4 159.
melodie .byt 142,30, 119,15, 106,15, 95,30, 142,30, 159,15, 142,15, 119,30, 127,60
        .byt 142,30, 119,15, 106,15, 95,30, 80,30,  90,15,  95,15, 106,30, 95,60
        .byt 90,30,  95,15,  106,15, 119,30, 106,30, 95,15, 106,15, 119,30, 127,30, 159,30
        .byt 142,15, 127,15, 119,15, 106,15, 95,30, 119,30, 127,15, 159,15, 127,30, 142,60
        .byt 0
; Basse - période sur 2 octets (bas, haut), durée ; une blanche (60) par note.
; la2 568, sol2 638, do3 477, ré3 425, mi3 379, fa2 716, mi2 758.
basses  .byt $38,2,60, $38,2,60, $7E,2,60, $7E,2,60
        .byt $38,2,60, $DD,1,60, $A9,1,60, $7B,1,60
        .byt $CC,2,60, $CC,2,60, $DD,1,60, $7E,2,60
        .byt $38,2,60, $A9,1,60, $F6,2,60, $38,2,60
        .byt 0
bt      .byt 0                ; tops restants de la note de basse
bi      .byt 0                ; position dans la basse
