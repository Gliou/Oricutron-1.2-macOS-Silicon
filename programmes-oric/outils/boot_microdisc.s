; boot_microdisc.s — secteur de démarrage (piste 0, secteur 2) pour le Microdisc
; de l'Oric Atmos  - 1re étape du chargement d'un jeu en BASIC.
; Créé le 2026-11-21 by GliouCNR©70 — marque « disquette » ajoutée le 2026-11-22,
; réduit à la 1re étape (le reste est dans boot_etage2.s) le 2026-11-22
;
;   xa -o boot.bin boot_microdisc.s        (oric_dsk.py s'en charge)
;
; Au démarrage, la ROM du Microdisc lit le répertoire (piste 0, secteur 3),
; y trouve SYSTEM.DOS dont le descripteur est le secteur 2, et exécute le code
; qui suit l'en-tête de ce secteur. Ce code -
;   1. se recopie en $9000 (il ne sait pas à quelle adresse la ROM l'a mis) ;
;   2. lit les secteurs 4 et 5 de la piste 0 (la 2e étape, boot_etage2.s) en
;      $9900, au-dessus de HIMEM ($9800), et y saute.
; La ROM du Microdisc ne charge pas ce secteur au-delà de l'octet $F7
; (vérifié le 2026-11-22)  - d'où les deux étapes, la 2e n'a pas cette limite
; et sait changer de piste.
; Modifié le 2026-11-24 by GliouCNR©70 - « CHARGEMENT EN COURS » clignotant
; (attribut 12 de l'Oric) écrit sur l'écran noir pendant le chargement.
; Attention avec xa - un deux-points est un séparateur, même dans un commentaire.

FDC_CMD  = $0310      ; contrôleur WD1793 - commande / état
FDC_SEC  = $0312      ; secteur
FDC_DAT  = $0313      ; données
MD_DRQ   = $0318      ; bit 7 à 0 = un octet est prêt
DEST     = $9000      ; où ce code se recopie
ETAGE2   = $9900      ; où va la 2e étape
FIRSTSEC = 4          ; ses secteurs sur la piste 0
NSECT2   = 2
SECTOR   = $F0        ; variables en page zéro
COUNT    = $F1
TRIES    = $F2

; ----- En-tête du descripteur de SYSTEM.DOS (23 octets, tels quels) -----
        * = $0000
        .byt $00,$00,$FF,$00,$D0,$9F,$D0,$9F,$02,$B9,$01,$00
        .byt $FF,$00,$00,$B9,$E4,$B9,$00,$00,$E6,$12,$00

; ----- Prologue indépendant de l'adresse (offset $17) -----
; Un JSR vers un RTS posé en $00 laisse sur la pile l'adresse de retour,
; donc l'adresse où la ROM a mis ce secteur.
        sei
        lda #$60              ; RTS
        sta $00
        jsr $0000
        tsx
        dex
        clc
        lda $0100,x           ; adresse de retour (octet bas) = offset $1E
        adc #$1F              ; + $1F = offset $3D, début du code principal
        sta $00
        lda $0101,x
        adc #$00
        sta $01
        ldy #$00
copy    lda ($00),y
        sta DEST,y
        iny
        bne copy
        jmp DEST

; ----- Code principal, exécuté en $9000 (offset $3D) -----
        * = DEST

main    lda #$20              ; écran noir pendant le chargement (2026-11-22) -
        ldy #$00              ; efface le message de la ROM, CAPS et le curseur,
efface  sta $BB80,y           ; attributs de couleur compris ($BB80-$BF7F)
        sta $BC80,y
        sta $BD80,y
        sta $BE80,y
        iny
        bne efface
efin    sta $BF80,y           ; puis $BF80-$BFDF
        iny
        cpy #96
        bne efin
        ldx #20               ; « CHARGEMENT EN COURS » clignotant, ligne 13
m1a    lda charge,x          ; (encre cyan 6, attribut 12 = clignotant)
        sta $BD91,x
        dex
        bpl m1a
        lda #FIRSTSEC         ; la ROM vient de lire la piste 0 - la tête y est déjà
        sta SECTOR
        lda #NSECT2
        sta COUNT

next    lda #8                ; 8 essais par secteur
        sta TRIES
retry   lda SECTOR
        sta FDC_SEC
        lda #$80              ; lecture d'un secteur
        sta FDC_CMD
        ldy #$04
w3      dey
        bne w3
        ldy #$00
busy    lda FDC_CMD
        lsr
        bcc done              ; plus occupé - secteur fini
drq     lda MD_DRQ
        bmi busy
        lda FDC_DAT
store   sta ETAGE2,y          ; (l'octet haut est modifié à chaque secteur)
        iny
        jmp drq
done    and #$0E              ; perte de données, CRC, secteur introuvable ?
        beq ok
        dec TRIES
        bne retry
ok      inc SECTOR
        inc store+2
        dec COUNT
        bne next
        jmp ETAGE2

charge  .byt 6,12
        .asc "CHARGEMENT EN COURS"
