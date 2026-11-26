; comptine-serpent.s — comptine originale à 2 voix, en do majeur, mise de côté
; pour un autre projet (elle était sur l'écran titre et le Hall of Fame du
; serpent du 2026-11-24 au 2026-11-26, remplacée par la Pastorale de Beethoven).
; Créé le 2026-11-26 by GliouCNR©70 (tables reprises de ../serpent/son.s)
;
; Format des tables (celui du moteur serpent/son.s) -
;   comptine - période AY sur 1 octet (1 MHz / 16 / fréquence), durée en
;              centièmes de seconde ; période 1 = silence ; 0 = fin (reprise).
;   cbasse   - période AY sur 2 octets (bas, haut), durée ; 0 = fin (reprise).
; Attention avec xa - un deux-points est un séparateur, même dans un commentaire.

; COMPTINE (titre) - originale, do majeur, sautillante ; 8 mesures de 96
; centièmes (noire 24, croche 12, blanche 48), ~7,7 s.
; do mi sol do mi | ré do si la sol - fa la do fa mi | ré mi ré si do
; mi mi ré ré do sol | la si do la sol - do mi sol do mi | ré si sol si do
comptine .byt 119,24, 189,12, 159,12, 119,24, 95,24,  106,12, 119,12, 127,12, 142,12, 159,48
        .byt 179,24, 142,12, 119,12, 90,24,  95,24,   106,12, 95,12,  106,12, 127,12, 119,48
        .byt 95,12,  95,12,  106,12, 106,12, 119,24, 159,24,  142,12, 127,12, 119,12, 142,12, 159,48
        .byt 119,24, 189,12, 159,12, 119,24, 95,24,   106,12, 127,12, 159,12, 127,12, 119,48
        .byt 0
; basse de la comptine - 2 notes par mesure (48), do sol / sol ré / fa do /
; sol do / do sol / fa do / do sol / sol do
cbasse  .byt $DD,1,48, $7E,2,48,  $7E,2,48, $A9,1,48
        .byt $CC,2,48, $DD,1,48,  $7E,2,48, $DD,1,48
        .byt $DD,1,48, $7E,2,48,  $CC,2,48, $DD,1,48
        .byt $DD,1,48, $7E,2,48,  $7E,2,48, $DD,1,48
        .byt 0
