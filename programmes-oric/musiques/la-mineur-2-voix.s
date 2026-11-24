; la-mineur-2-voix.s — musique originale en la mineur, à 2 voix, mise de côté
; pour un autre projet (elle était sur l'écran titre du serpent le 2026-11-24).
; Créé le 2026-11-24 by GliouCNR©70
;
; Forme - 4 phrases de 2 mesures (A, A', B, C), ~10 s, en boucle. Tempo - une
; noire = 30 centièmes de seconde. Mélodie sur le canal A de la puce son
; (AY-3-8912), basse détachée sur le canal C (une blanche par note, 10
; centièmes de silence à la fin de chaque note).
;
; Format des tables (celui du moteur serpent/son.s) -
;   melodie - période AY sur 1 octet (1 MHz / 16 / fréquence), durée en
;             centièmes de seconde ; période 1 = silence ; 0 = fin (reprise).
;   basses  - période AY sur 2 octets (bas, haut), durée ; 0 = fin (reprise).
; Les deux tables durent 960 centièmes : elles restent ensemble en boucle.
;
; Notes - la4 142, si4 127, do5 119, ré5 106, mi5 95, fa5 90, sol5 80, sol4 159 ;
; basse - la2 568, sol2 638, do3 477, ré3 425, mi3 379, fa2 716, mi2 758.
;
; Phrase A  - la do ré mi la | sol la do si
; Phrase A' - la do ré mi sol | fa mi ré mi
; Phrase B  - fa mi ré do ré | mi ré do si sol
; Phrase C  - la si do ré mi do | si sol si la
; Attention avec xa - un deux-points est un séparateur, même dans un commentaire.

melodie .byt 142,30, 119,15, 106,15, 95,30, 142,30, 159,15, 142,15, 119,30, 127,60
        .byt 142,30, 119,15, 106,15, 95,30, 80,30,  90,15,  95,15, 106,30, 95,60
        .byt 90,30,  95,15,  106,15, 119,30, 106,30, 95,15, 106,15, 119,30, 127,30, 159,30
        .byt 142,15, 127,15, 119,15, 106,15, 95,30, 119,30, 127,15, 159,15, 127,30, 142,60
        .byt 0

basses  .byt $38,2,60, $38,2,60, $7E,2,60, $7E,2,60
        .byt $38,2,60, $DD,1,60, $A9,1,60, $7B,1,60
        .byt $CC,2,60, $CC,2,60, $DD,1,60, $7E,2,60
        .byt $38,2,60, $A9,1,60, $F6,2,60, $38,2,60
        .byt 0
