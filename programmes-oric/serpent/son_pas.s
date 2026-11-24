; son_pas.s — petit « tic-tac » à chaque pas du serpent, joué par la puce son
; de l'Oric (AY-3-8912) sans ralentir le BASIC.
; Créé le 2026-11-24 by GliouCNR©70
;
;   xa -o son_pas.bin son_pas.s
;   (les octets sont dans la ligne DATA 1070 de serpent.bas, posés en $0490,
;    juste après titre_copie.s ; appelé à chaque pas par CALL SN, SN = #490)
;
; Le son est un « tic » de canal A dont le volume suit l'ENVELOPPE de la puce
; (registre 13, forme 0 - le volume descend tout seul de 15 à 0 puis reste
; muet). La puce fait donc tout le travail - la routine écrit 7 registres et
; rend la main tout de suite (environ 0,4 ms), sans attendre la fin du son.
; Les hauteurs alternent (TON1 / TON2) - tic, tac, tic, tac.
; Tous les registres utiles sont réécrits à chaque pas - PING, ZAP et EXPLODE
; du BASIC peuvent changer la puce entre deux pas, le tic reste le même.
; Écriture d'un registre - routine WriteToAY de la ROM Atmos 1.1 ($F590),
; A = numéro du registre, X = valeur ; pour le registre 7 (mélangeur), elle
; garde le bit 6 à 1 (port A de la puce en sortie), sans lequel le clavier
; ne répondrait plus.
; Attention avec xa - un deux-points est un séparateur, même dans un commentaire.

AY       = $F590      ; WriteToAY - registre A, valeur X
TON1     = $60        ; période du son - 1 MHz / (16 x 96) = 651 Hz
TON2     = $50        ;                  1 MHz / (16 x 80) = 781 Hz
DUREE    = 6          ; période de l'enveloppe - 16 x 256 x 6 / 1 MHz = 25 ms

        * = $0490

pas     lda #0                ; registres 0-1 - période du canal A
        ldx ton
        jsr AY
        lda #1
        ldx #0
        jsr AY
        lda #7                ; mélangeur - son du canal A seul, pas de bruit
        ldx #$3E
        jsr AY
        lda #8                ; volume du canal A - suit l'enveloppe
        ldx #$10
        jsr AY
        lda #11               ; période de l'enveloppe (durée du tic)
        ldx #DUREE
        jsr AY
        lda #12
        ldx #0
        jsr AY
        lda #13               ; forme 0 - descend puis se tait ; écrire ce
        ldx #0                ; registre relance l'enveloppe = nouveau tic
        jsr AY
        lda ton               ; tic <-> tac
        eor #TON1^TON2
        sta ton
        rts

ton     .byt TON1
