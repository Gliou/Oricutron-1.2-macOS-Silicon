; titre.s — écran titre animé pour Oric Atmos, en assembleur 6502 (xa65)
;
;   xa -o titre.bin titre.s
;   python3 oric_tap.py bin titre.bin titre.tap 0x0800 TITRE
;
; Écrit directement dans l'écran texte ($BB80, 40 colonnes x 28 lignes).
; Sur l'Oric, la couleur se règle par des « attributs » placés dans l'écran  -
;   0-7   = couleur d'encre      16-23 = couleur de fond (papier)
;   10    = caractères double hauteur (le haut sur une ligne paire,
;           le bas sur la ligne impaire suivante)
; Couleurs  - 0 noir 1 rouge 2 vert 3 jaune 4 bleu 5 magenta 6 cyan 7 blanc.
; Une touche quelconque remet l'écran BASIC d'avant et rend la main au BASIC.

SCREEN  = $BB80
KEY     = $02DF          ; dernière touche lue par la ROM (bit 7 = nouvelle touche)
FLAGS   = $026A          ; bit 0 = curseur affiché

#define ROW(r) SCREEN+40*r

        * = $0800

start   lda FLAGS
        sta oldflags
        and #$FE               ; cache le curseur (sinon il clignote dans le décor)
        sta FLAGS
        lda #0
        sta KEY
        jsr save               ; garde l'écran BASIC (texte et couleurs) pour la sortie
        jsr clear

; --- Titre double hauteur, lignes 4 et 5  - fond bleu, encre jaune -------------
        ldx #0
t1      lda title,x
        sta ROW(4)+3,x
        sta ROW(5)+3,x
        inx
        cpx #TITLELEN
        bne t1
        lda #20                ; papier bleu
        sta ROW(4)
        sta ROW(5)
        lda #3                 ; encre jaune
        sta ROW(4)+1
        sta ROW(5)+1
        lda #10                ; double hauteur
        sta ROW(4)+2
        sta ROW(5)+2

; --- Sous-titres -------------------------------------------------------------
        ldx #0
t2      lda sub1,x
        sta ROW(8)+2,x
        inx
        cpx #SUB1LEN
        bne t2
        lda #6                 ; cyan
        sta ROW(8)+1
        ldx #0
t3      lda sub2,x
        sta ROW(10)+2,x
        inx
        cpx #SUB2LEN
        bne t3
        lda #2                 ; vert
        sta ROW(10)+1
        ldx #0
t4      lda sub3,x
        sta ROW(26)+2,x
        inx
        cpx #SUB3LEN
        bne t4
        lda #5                 ; magenta
        sta ROW(26)+1

; --- Bandeau défilant, ligne 23  - fond rouge, encre blanche --------------------
        lda #17
        sta ROW(23)
        lda #7
        sta ROW(23)+1

; --- Boucle principale ---------------------------------------------------------
loop    jsr rainbow
        jsr scroller
        jsr delay
        lda KEY
        bpl loop               ; pas de touche  - on continue

        lda #0                 ; touche  - on remet l'écran BASIC et on rend la main
        sta KEY
        jsr restore
        lda oldflags
        sta FLAGS
        rts

; Arc-en-ciel  - lignes 13 à 20, le fond de chaque ligne tourne d'une couleur
; toutes les 4 images.
rainbow inc tick
        lda tick
        and #3
        bne r9
        inc phase
r9      lda phase
        and #7
        ora #16
        sta ROW(13)
        clc
        adc #1
        and #7
        ora #16
        sta ROW(14)
        adc #1
        and #7
        ora #16
        sta ROW(15)
        adc #1
        and #7
        ora #16
        sta ROW(16)
        adc #1
        and #7
        ora #16
        sta ROW(17)
        adc #1
        and #7
        ora #16
        sta ROW(18)
        adc #1
        and #7
        ora #16
        sta ROW(19)
        adc #1
        and #7
        ora #16
        sta ROW(20)
        rts

; Texte défilant  - 38 caractères visibles, avance d'un caractère toutes les 3 images.
scroller dec scdelay
        bne s0
        lda #3
        sta scdelay
        inc pos
        lda pos
        cmp #MSGLEN
        bne s0
        lda #0
        sta pos
s0      ldy pos
        ldx #0
s1      lda msg,y
        sta ROW(23)+2,x
        iny
        cpy #MSGLEN
        bne s2
        ldy #0
s2      inx
        cpx #38
        bne s1
        rts

; Efface les lignes 1 à 27 (la ligne 0 est la ligne d'état de la ROM).
clear   lda #32
        ldx #0
c1      sta ROW(1),x
        sta ROW(1)+$100,x
        sta ROW(1)+$200,x
        sta ROW(1)+$300,x
        inx
        bne c1
        ldx #ROW(28)-(ROW(1)+$400)-1
c2      sta ROW(1)+$400,x
        dex
        bpl c2
        rts

; Sauvegarde / restauration des lignes 1 à 27 (1080 octets) dans BUFFER.
BUFFER  = $0C00
SAVELEN = 40*27            ; lignes 1 à 27
save    ldx #0
v1      lda ROW(1),x
        sta BUFFER,x
        lda ROW(1)+$100,x
        sta BUFFER+$100,x
        lda ROW(1)+$200,x
        sta BUFFER+$200,x
        lda ROW(1)+$300,x
        sta BUFFER+$300,x
        inx
        bne v1
        ldx #SAVELEN-$400-1
v2      lda ROW(1)+$400,x
        sta BUFFER+$400,x
        dex
        bpl v2
        rts

restore ldx #0
w1      lda BUFFER,x
        sta ROW(1),x
        lda BUFFER+$100,x
        sta ROW(1)+$100,x
        lda BUFFER+$200,x
        sta ROW(1)+$200,x
        lda BUFFER+$300,x
        sta ROW(1)+$300,x
        inx
        bne w1
        ldx #SAVELEN-$400-1
w2      lda BUFFER+$400,x
        sta ROW(1)+$400,x
        dex
        bpl w2
        rts

; Environ 25 ms (20 x 256 x 5 cycles à 1 MHz).
delay   ldy #20
d1      ldx #0
d2      dex
        bne d2
        dey
        bne d1
        rts

; --- Données -------------------------------------------------------------------
oldflags .byt 0
tick     .byt 0
phase    .byt 0
pos      .byt 0
scdelay  .byt 3

title    .asc "         ORICUTRON 1.2          "
TITLELEN = * - title
sub1     .asc "      MAC  -  IPHONE  -  IPAD"
SUB1LEN  = * - sub1
sub2     .asc "  EMULATEUR ORIC DE PETER GORDON"
SUB2LEN  = * - sub2
sub3     .asc "  UNE TOUCHE POUR REVENIR AU BASIC"
SUB3LEN  = * - sub3
msg      .asc "BONJOUR DEPUIS L'ORIC ATMOS !  CET ECRAN EST ECRIT EN "
         .asc "ASSEMBLEUR 6502, ASSEMBLE AVEC XA SUR UN MAC APPLE SILICON "
         .asc "ET TESTE DANS ORICUTRON.  MERCI PETER GORDON !     "
MSGLEN   = * - msg
