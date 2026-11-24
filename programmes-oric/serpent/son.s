; son.s — moteur de son du serpent, avec un VOLUME réglable (0 à 15), qui
; remplace PING, ZAP et EXPLODE de la ROM (trop forts) et le tic-tac des pas.
; Créé le 2026-11-24 by GliouCNR©70 (remplace son_pas.s)
;
;   xa -o son.bin son.s
;   (les octets sont dans les lignes DATA 1070+ de serpent.bas, posés en $7600,
;    au-dessus de HIMEM abaissé à $7600 et sous la 2e image ($7800). C'est la
;    fin de la place de l'image titre ($5800-$773F) - elle est déjà recopiée à
;    l'écran (ligne 14) quand le BASIC pose le moteur (ligne 52).)
;
;   CALL #7600  INIT   installe le moteur sur l'interruption de l'horloge
;                      (100 fois par seconde) et règle le mélangeur
;   CALL #7603  PAS    tic-tac du pas (canal A, 30 ms)
;   CALL #7606  PING   PING au volume choisi (canal B, ~1 s)
;   CALL #7609  ZAP    ZAP au volume choisi (canal B, balayage de 0,3 s)
;   CALL #760C  BOUM   EXPLODE au volume choisi (canal C, bruit, ~1,5 s)
;   POKE #760F,v       le volume, 0 (muet) à 15 (le maximum de la puce)
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

        * = $7600

        jmp init
        jmp pas
        jmp ping
        jmp zap
        jmp boum
vol     .byt 15               ; $760F - volume choisi (0-15)

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

; ----- Interruption - 100 fois par seconde -----
tick    pha
        lda VIA_IFR
        and #$40
        beq rom               ; pas l'horloge - rien à faire ici
        txa
        pha
        tya
        pha
        lda ga                ; canal A - fin du tic
        beq tb
        dec ga
        bne tb
        lda #8
        ldx #0
        jsr AY
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
