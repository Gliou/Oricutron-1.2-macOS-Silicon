; hof_disque.s — lit et écrit le secteur du Hall of Fame (piste 0, secteur 18)
; sur la disquette Microdisc, pour le jeu du serpent.
; Créé le 2026-11-22 by GliouCNR©70
;
;   xa -o hof_disque.bin hof_disque.s
;   (les octets sont recopiés dans les lignes DATA de serpent.bas)
;
; Placé en $0400 par le BASIC (POKE depuis des DATA), puis -
;   CALL #400  lit le secteur dans le tampon $9800-$98FF
;   CALL #403  écrit le tampon $9800-$98FF dans le secteur
; Après l'appel, PEEK(#4FE) = 0 si tout s'est bien passé (sinon l'état
; d'erreur du contrôleur). La tête est déjà sur la piste 0 - le démarrage
; vient d'y lire le programme et rien d'autre ne la déplace.
; Attention avec xa - un deux-points sépare les instructions, même ici.

FDC_CMD  = $0310
FDC_SEC  = $0312
FDC_DAT  = $0313
MD_DRQ   = $0318      ; bit 7 à 0 = le contrôleur attend / donne un octet
BUF      = $9800      ; au-dessus de HIMEM, libre en mode texte
SECTEUR  = 18
STATUS   = $04FE

        * = $0400

        jmp lire
        jmp ecrire

lire    sei
        lda #SECTEUR
        sta FDC_SEC
        lda #$80              ; lecture d'un secteur
        sta FDC_CMD
        jsr attente
        ldy #$00
l1      lda FDC_CMD
        lsr
        bcc fin               ; plus occupé - terminé
l2      lda MD_DRQ
        bmi l1
        lda FDC_DAT
        sta BUF,y
        iny
        jmp l2

ecrire  sei
        lda #SECTEUR
        sta FDC_SEC
        lda #$A0              ; écriture d'un secteur
        sta FDC_CMD
        jsr attente
        ldy #$00
e1      lda FDC_CMD
        lsr
        bcc fin
e2      lda MD_DRQ
        bmi e1
        lda BUF,y
        sta FDC_DAT
        iny
        jmp e2

fin     and #$2E              ; protégée, introuvable, CRC, octet perdu
        sta STATUS
        cli
        rts

attente ldy #$04
a1      dey
        bne a1
        rts
