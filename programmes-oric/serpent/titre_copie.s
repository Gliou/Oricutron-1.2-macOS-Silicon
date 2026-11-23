; titre_copie.s — recopie l'image de présentation ($6000, chargée par
; boot_etage2.s) dans l'écran HIRES ($A000-$BF3F, 8 000 octets).
; Créé le 2026-11-22 by GliouCNR©70
;
;   xa -o titre_copie.bin titre_copie.s
;   (les octets sont dans les lignes DATA 990-995 de serpent.bas, posés en
;    $0460, juste après la routine du Hall of Fame ; appel - HIRES puis CALL #460)
;
; Le BASIC mettrait plusieurs minutes avec des PEEK/POKE ; ici c'est immédiat.
; 8 000 octets = 31 pages entières + 64 octets.

        * = $0460

        lda #$60
        sta s+2
        lda #$A0
        sta d+2
        ldx #31
        ldy #$00
s       lda $6000,y           ; (les octets hauts avancent d'une page à chaque tour)
d       sta $A000,y
        iny
        bne s
        inc s+2
        inc d+2
        dex
        bne s
fin     lda $7F00,y           ; les 64 derniers octets ($BF00-$BF3F)
        sta $BF00,y
        iny
        cpy #64
        bne fin
        rts
