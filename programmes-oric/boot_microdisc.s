; boot_microdisc.s — secteur de démarrage (piste 0, secteur 2) pour le Microdisc
; de l'Oric Atmos, qui charge un programme BASIC et le lance tout seul.
; Créé le 2026-11-21 by GliouCNR©70 — marque « disquette » ajoutée le 2026-11-22
;
;   xa -DNSECT=4 -DPEND=\$0880 -o boot.bin boot_microdisc.s
;   (oric_dsk.py s'en charge - NSECT = nombre de secteurs du programme,
;    PEND = adresse de fin du programme BASIC, celle qui va dans $9C-$9D)
;
; Au démarrage, la ROM du Microdisc lit le répertoire (piste 0, secteur 3),
; y trouve SYSTEM.DOS dont le descripteur est le secteur 2, et exécute le code
; qui suit l'en-tête de ce secteur. Ce code -
;   1. se recopie en $9000 (il ne sait pas à quelle adresse la ROM l'a mis) ;
;   2. lit le programme BASIC (secteurs 4, 5... de la piste 0) en $8000 ;
;   3. allume la ROM BASIC et refait son démarrage à froid, sauf le test de la
;      mémoire, qui effacerait tout ;
;   4. détourne la lecture du clavier ($023B) - quand le BASIC attend la
;      première touche après Ready, on recopie le programme en $0501 et on
;      fait RUN, comme CLOAD le fait pour une cassette qui se lance seule.
;      Il pose aussi 68 (« D ») en $04FF - le programme sait ainsi qu'il a
;      démarré de la disquette et peut y lire et écrire (Hall of Fame).
; Le code doit finir avant l'octet $F7 du secteur - au-delà, la ROM du
; Microdisc ne le charge pas (vérifié le 2026-11-22 - octets perdus).
; Attention avec xa - un deux-points est un séparateur, même dans un commentaire.

FDC_CMD  = $0310      ; contrôleur WD1793 - commande / état
FDC_TRK  = $0311      ; piste
FDC_SEC  = $0312      ; secteur
FDC_DAT  = $0313      ; données
MD_CTRL  = $0314      ; registre de contrôle du Microdisc
MD_DRQ   = $0318      ; bit 7 à 0 = un octet est prêt
BUF      = $8000      ; tampon pour le programme lu
DEST     = $9000      ; où ce code se recopie
FIRSTSEC = 4          ; premier secteur du programme
SECTOR   = $F0        ; variables en page zéro (le BASIC les réinitialise ensuite)
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

main    lda #FIRSTSEC     ; la ROM vient de lire la piste 0 - la tête y est déjà
        sta SECTOR
        lda #NSECT
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
store   sta BUF,y             ; (l'octet haut est modifié à chaque secteur)
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

