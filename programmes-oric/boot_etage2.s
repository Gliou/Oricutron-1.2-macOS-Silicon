; boot_etage2.s — 2e étape du démarrage Microdisc (piste 0, secteurs 4-5),
; chargée en $9900 par boot_microdisc.s. Elle lit le programme BASIC et une
; image HIRES sur les pistes 1, 2..., puis lance le BASIC et le programme.
; Créé le 2026-11-22 by GliouCNR©70
;
;   xa -DPTRK=1 -DPSEC=1 -DNSECT=15 -DITRK=1 -DISEC=16 -DISECT=32 \
;      '-DPEND=$1234' -o etage2.bin boot_etage2.s     (oric_dsk.py s'en charge)
;
;   PTRK/PSEC  piste et secteur où commence le programme BASIC, NSECT secteurs
;              lus en $8000 (24 au plus, jusqu'à $97FF)
;   ITRK/ISEC  piste et secteur où commence l'image, ISECT secteurs lus en
;              $6000-$7FFF (0 = pas d'image) ; le BASIC la recopie en $A000
;              après HIRES (routine titre_copie.s)
;   PEND       fin du programme BASIC (mise dans $9C-$9D)
;
; Les secteurs se suivent de 1 à 18 puis passent à la piste suivante  - la tête
; est déplacée par la commande SEEK du WD1793 ($18 = SEEK, tête chargée, sans
; vérification, pas de 6 ms ; la piste visée est mise dans le registre de
; données $0313). À la fin, la tête revient sur la piste 0, où le jeu lit et
; écrit son Hall of Fame (secteur 18, hof_disque.s).
; Attention avec xa - un deux-points est un séparateur, même dans un commentaire.

FDC_CMD  = $0310      ; contrôleur WD1793 - commande / état
FDC_SEC  = $0312      ; secteur
FDC_DAT  = $0313      ; données (et piste visée par SEEK)
MD_CTRL  = $0314      ; registre de contrôle du Microdisc
MD_DRQ   = $0318      ; bit 7 à 0 = un octet est prêt
BUF      = $8000      ; tampon du programme lu
IMG      = $6000      ; tampon de l'image HIRES
SECTOR   = $F0        ; variables en page zéro (le BASIC les réinitialise ensuite)
COUNT    = $F1
TRIES    = $F2
TRACK    = $F3

        * = $9900

; ----- Lecture du programme, puis de l'image -----
start   lda #>BUF
        sta store+2
        lda #PTRK
        sta TRACK
        lda #PSEC
        sta SECTOR
        lda #NSECT
        sta COUNT
        jsr load
        lda #ISECT
        beq noimg
        sta COUNT
        lda #>IMG
        sta store+2
        lda #ITRK
        sta TRACK
        lda #ISEC
        sta SECTOR
        jsr load
noimg   lda #0                ; retour sur la piste 0 (Hall of Fame)
        jsr seek

; ----- Démarrage du BASIC (copie de la routine de reset $F88F) -----
        sei
        lda #$82              ; EPROM éteinte, ROM BASIC allumée, IRQ disque coupée
        sta MD_CTRL
        ldx #$12              ; vecteurs de la page 2 (tableau de la ROM en $F87C)
vec     lda $F87C,x
        sta $0238,x
        dex
        bpl vec
        lda #$20
        sta $024E
        lda #$04
        sta $024F
        lda #$00              ; au lieu du test mémoire $FA14 - Atmos 48 Ko,
        sta $0260             ; HIMEM = $9800
        sta $0220
        ldy #$98
        sta $A6
        sty $A7
        sta $02C1
        sty $02C2
        cli
        jsr $F8B8             ; écran, son, clavier
        lda #<hook            ; détourne « lire une touche »
        sta $023C
        lda #>hook
        sta $023D
        jmp $ECCC             ; démarrage à froid du BASIC (jusqu'à Ready)

; ----- Appelé quand le BASIC attend une touche après Ready -----
hook    lda #$78              ; remet le vecteur d'origine (JMP $EB78)
        sta $023C
        lda #$EB
        sta $023D
        lda #$44              ; marque « démarré de la disquette »
        sta $04FF
        lda #$0A              ; curseur caché (comme POKE 618,10)
        sta $026A
        lda #$7F              ; CAPS éteint (majuscules non verrouillées) -
        sta $020C             ; la ROM ne réécrit plus CAPS, même après TEXT
        lda #$20              ; écran texte vidé - le message du BASIC, Ready
        ldy #$00              ; et CAPS ne restent pas affichés (2026-11-22)
efface  sta $BB80,y           ; $BB80-$BF7F (4 pages)
        sta $BC80,y
        sta $BD80,y
        sta $BE80,y
        iny
        bne efface
efin    sta $BF80,y           ; puis $BF80-$BFDF (96 octets, fin de l'écran)
        iny
        cpy #96
        bne efin
        ldx #NSECT            ; recopie le programme en $0501
        ldy #$00
cp      lda BUF,y
cpd     sta $0501,y
        iny
        bne cp
        inc cp+2
        inc cpd+2
        dex
        bne cp
        lda #<PEND            ; fin du programme (début des variables)
        sta $9C
        lda #>PEND
        sta $9D
        jsr $C55F             ; refait les liens entre les lignes
        jsr $C708             ; RUN - efface les variables, pointe sur la 1re ligne
        jmp $C8C1             ; et exécute

; ----- Lit COUNT secteurs à partir de TRACK/SECTOR, page par page -----
load    lda TRACK
        jsr seek
lnext   lda #8                ; 8 essais par secteur
        sta TRIES
retry   lda SECTOR
        sta FDC_SEC
        lda #$80              ; lecture d'un secteur
        sta FDC_CMD
        jsr attente
        ldy #$00
busy    lda FDC_CMD
        lsr
        bcc done              ; plus occupé - secteur fini
drq     lda MD_DRQ
        bmi busy
        lda FDC_DAT
store   sta BUF,y             ; (l'octet haut est modifié à chaque secteur)
        iny
        jmp drq
done    and #$0E              ; perte de données, CRC, secteur introuvable ?
        beq ok
        dec TRIES
        bne retry
ok      inc store+2
        dec COUNT
        beq fin
        inc SECTOR
        lda SECTOR
        cmp #19               ; après le secteur 18 - piste suivante
        bne lnext
        lda #1
        sta SECTOR
        inc TRACK
        lda TRACK
        jsr seek
        jmp lnext
fin     rts

; ----- Déplace la tête sur la piste A -----
seek    sta FDC_DAT
        lda #$18              ; SEEK
        sta FDC_CMD
        jsr attente
s1      lda FDC_CMD
        lsr                   ; bit 0 = occupé
        bcs s1
        rts

attente ldy #$04
a1      dey
        bne a1
        rts
