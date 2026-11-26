; fanfare-serpent.s — fanfare de victoire originale à 2 voix (do majeur, appels
; de trompette), mise de côté pour un autre projet (elle était sur l'écran de
; victoire du serpent du 2026-11-24 au 2026-11-26, remplacée par l'Ode à la
; joie de Beethoven).
; Créé le 2026-11-26 by GliouCNR©70 (tables reprises de ../serpent/son.s)
;
; Format des tables (celui du moteur serpent/son.s) -
;   fanfare - période AY sur 1 octet (1 MHz / 16 / fréquence), durée en
;             centièmes de seconde ; période 1 = silence ; 0 = fin (reprise).
;   fbasse  - période AY sur 2 octets (bas, haut), durée ; 0 = fin (reprise).
; Attention avec xa - un deux-points est un séparateur, même dans un commentaire.

; FANFARE (victoire) - originale, do majeur, appels de trompette ; 4 mesures de
; 120 centièmes puis un silence de 60, ~5,4 s en boucle. la5 71, si5 63, do6 60.
; sol do mi sol- mi sol-- | fa fa fa sol- la sol-- |
; la la la si- la sol- mi | sol sol la si do6------ | (silence)
fanfare .byt 159,10, 119,10, 95,10, 80,30, 95,10, 80,50
        .byt 90,10,  90,10,  90,10, 80,30, 71,10, 80,50
        .byt 71,10,  71,10,  71,10, 63,30, 71,10, 80,30, 95,20
        .byt 80,10,  80,10,  71,10, 63,10, 60,80
        .byt 1,60
        .byt 0
; basse - do sol / fa do / sol ré / sol do / silence (blanches de 60)
fbasse  .byt $DD,1,60, $7E,2,60,  $CC,2,60, $DD,1,60
        .byt $7E,2,60, $A9,1,60,  $7E,2,60, $DD,1,60
        .byt 1,0,60
        .byt 0
