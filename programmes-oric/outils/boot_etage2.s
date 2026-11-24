; boot_etage2.s — 2e étape du démarrage Microdisc (piste 0, secteurs 4-5),
; chargée en $9900 par boot_microdisc.s. Elle lit le programme BASIC et une
; image HIRES sur les pistes 1, 2..., puis lance le BASIC et le programme.
; Créé le 2026-11-22 by GliouCNR©70
; Modifié le 2026-11-23 by GliouCNR©70 - 2e image facultative (écran de victoire
; du serpent), gardée en mémoire sous HIMEM ; adresses passées par oric_dsk.py.
; Modifié le 2026-11-24 by GliouCNR©70 - « CHARGEMENT EN COURS » clignotant remis
; sur l'écran après l'avoir vidé (le BASIC le garde jusqu'à l'image titre).
; Modifié le 2026-11-24 by GliouCNR©70 - le programme est lu DIRECTEMENT à sa
; place ($0501), sans tampon ni recopie - il n'est plus limité à 6 Ko. Le
; démarrage du BASIC (NEW) met $0501-$0502 à zéro - ces 2 octets sont gardés
; (SAV) et remis juste avant le RUN.
;
;   xa -DPTRK=1 -DPSEC=1 -DNSECT=15 -DITRK=1 -DISEC=16 -DISECT=32 \
;      -DJTRK=3 -DJSEC=5 -DJSECT=32 -DIMGH=96 -DIMG2H=120 \
;      -DHIMEMH=152 '-DPEND=$1234' -o etage2.bin boot_etage2.s
;      (oric_dsk.py s'en charge)
;
;   PTRK/PSEC  piste et secteur où commence le programme BASIC, NSECT secteurs
;              lus directement en $0501 (jusqu'au début de l'image)
;   ITRK/ISEC  piste et secteur où commence l'image, ISECT secteurs lus en
;              IMGH*256 (0 = pas d'image) ; le BASIC la recopie en $A000
;              après HIRES (routine titre_copie.s)
;   JTRK/JSEC  2e image (JSECT secteurs, 0 = aucune), lue en IMG2H*256
;   HIMEMH     octet haut de HIMEM - le BASIC ne touche pas à ce qui est au-dessus
;   PEND       fin du programme BASIC (mise dans $9C-$9D)
;
;   Une image   - programme $0501, image $6000, HIMEM $9800.
;   Deux images - programme $0501, image $5800, 2e image $7800-$97FF gardée
;                pour plus tard, HIMEM $7800.
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
SECTOR   = $F0        ; variables en page zéro (le BASIC les réinitialise ensuite)
COUNT    = $F1
TRIES    = $F2
TRACK    = $F3

        * = $9900

; ----- Lecture du programme, puis de l'image -----
start   lda #$01          ; programme lu en $0501, $0601, $0701...
        sta store+1
        lda #$05
        sta store+2
        lda #PTRK
        sta TRACK
        lda #PSEC
        sta SECTOR
        lda #NSECT
        sta COUNT
        jsr load
        lda $0501             ; ces 2 octets seront effacés par NEW
        sta sav
        lda $0502
        sta sav+1
        lda #$00              ; les images, elles, sont lues page par page
        sta store+1
        lda #ISECT
        beq noimg
        sta COUNT
        lda #IMGH
        sta store+2
        lda #ITRK
        sta TRACK
        lda #ISEC
        sta SECTOR
        jsr load
        lda #JSECT
        beq noimg
        sta COUNT
        lda #IMG2H
        sta store+2
        lda #JTRK
        sta TRACK
        lda #JSEC
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
        sta $0260             ; HIMEM = HIMEMH*256 ($9800, ou $7800 avec 2 images)
        sta $0220
        ldy #HIMEMH
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
        ldx #20               ; « CHARGEMENT EN COURS » clignotant, ligne 13
m2a    lda charge,x          ; (encre cyan 6, attribut 12 = clignotant)
        sta $BD91,x
        dex
        bpl m2a
        lda sav               ; remet les 2 premiers octets du programme
        sta $0501             ; (effacés par NEW au démarrage du BASIC)
        lda sav+1
        sta $0502
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
store   sta $0501,y           ; (adresse modifiée - $0501 + 256 par secteur, ou une image)
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

charge  .byt 6,12
        .asc "CHARGEMENT EN COURS"
sav     .byt 0,0              ; $0501-$0502 gardés pendant le démarrage du BASIC
