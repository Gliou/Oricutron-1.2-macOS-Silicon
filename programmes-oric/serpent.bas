# SERPENT — petit jeu en BASIC pour Oric Atmos
# Créé le 2026-11-21 by GliouCNR©70 — Hall of Fame ajouté le 2026-11-22
# Flèches du clavier pour diriger le serpent, mange les @ (+10 points).
# Perdu si le serpent touche le bord (*) ou sa propre queue (O).
# Hall of Fame : les 10 meilleurs scores avec leur nom ; le premier est le
# HI-SCORE affiché pendant la partie. Sur la disquette (serpent.dsk), il est
# sauvegardé sur la piste 0, secteur 18, par la routine machine de
# hof_disque.s (lignes DATA 1000+, chargée en $0400) : CALL #400 lit le secteur
# dans $9800-$98FF, CALL #403 l'écrit. Le démarrage de la disquette met 68 ("D")
# en $04FF : sans cette marque (cassette), le Hall of Fame reste en mémoire.
# Secteur : octet 0 = 72 ("H"), puis 10 fois (nom sur 8 lettres, score haut, bas).
# Clavier : on lit la dernière touche mémorisée par la ROM (PEEK(735), bit 7 =
# nouvelle touche) plutôt que KEY$, qui rate les appuis brefs (clavier virtuel,
# écran tactile) quand la boucle est lente.
# Variables : X(),Y() positions (tampon circulaire), H tête, T queue,
# DX/DY direction, S score, FX/FY nourriture, N$(),SC() Hall of Fame,
# D = disquette présente.
# La queue est effacée AVANT d'avancer la tête : la case qu'elle quitte est libre
# (ligne 155), sinon le serpent mourait en suivant sa queue de près.
10 REM SERPENT - ORICUTRON MAC/IOS
20 CLS:PAPER 0:INK 2:POKE 618,10
30 DIM X(255),Y(255),N$(10),SC(10)
40 FOR I=0 TO 92:READ B:POKE #400+I,B:NEXT
50 FOR I=1 TO 10:N$(I)="ATMOS   ":SC(I)=110-I*10:NEXT
60 D=(PEEK(#4FF)=68):IF D THEN CALL #400:IF PEEK(#4FE)=0 AND PEEK(#9800)=72 THEN GOSUB 950
70 GOSUB 700:PLOT 12,22,"ESPACE = JOUER"
75 GET K$:IF K$<>" " THEN 75
80 CLS:H=3:T=0:S=0:DX=1:DY=0
85 FOR I=2 TO 38:PLOT I,1,"*":PLOT I,25,"*":NEXT
90 FOR I=1 TO 25:PLOT 2,I,"*":PLOT 38,I,"*":NEXT
92 FOR I=0 TO 3:X(I)=10+I:Y(I)=13:PLOT X(I),13,"O":NEXT
94 PLOT 3,26,"SCORE 0":PLOT 21,26,"HI-SCORE"+STR$(SC(1))
96 PLOT 11,16,"FLECHES = DIRECTION":WAIT 150:PLOT 11,16,"                   ":POKE 735,0
98 GOSUB 500
100 K=PEEK(735):IF K<128 THEN 150
105 POKE 735,0:K=K-128
110 IF K=8 AND DX=0 THEN DX=-1:DY=0
120 IF K=9 AND DX=0 THEN DX=1:DY=0
130 IF K=10 AND DY=0 THEN DX=0:DY=1
140 IF K=11 AND DY=0 THEN DX=0:DY=-1
150 NX=X(H)+DX:NY=Y(H)+DY:C=SCRN(NX,NY)
155 IF C=79 AND NX=X(T) AND NY=Y(T) THEN C=32
160 IF C=42 OR C=79 THEN 300
165 IF C<>64 THEN PLOT X(T),Y(T)," ":T=(T+1) AND 255
170 H=(H+1) AND 255:X(H)=NX:Y(H)=NY:PLOT NX,NY,"O"
180 IF C=64 THEN S=S+10:PING:GOSUB 600:GOSUB 500:GOTO 100
200 WAIT 8:GOTO 100
300 EXPLODE:PLOT 15,12,"  PERDU !  ":WAIT 250
310 IF S>SC(10) THEN GOSUB 800
320 GOTO 70
500 FX=INT(RND(1)*35)+3:FY=INT(RND(1)*23)+2
510 IF SCRN(FX,FY)<>32 THEN 500
520 PLOT FX,FY,"@":RETURN
600 PLOT 9,26,STR$(S):IF S>SC(1) THEN PLOT 29,26,STR$(S)
610 RETURN
700 CLS:PLOT 11,2,6:PLOT 13,2,"S E R P E N T"
705 PLOT 11,5,3:PLOT 13,5,"HALL OF FAME"
710 FOR I=1 TO 10:R=7+I
715 PLOT 8,R,7:PLOT 9,R,RIGHT$(" "+STR$(I),3)+". "+N$(I)
720 PLOT 23,R,3:PLOT 24,R,RIGHT$("    "+STR$(SC(I)),6)
725 NEXT:POKE 735,0:RETURN
800 P=11:FOR I=10 TO 1 STEP -1
805 IF S>SC(I) THEN P=I
810 NEXT
815 CLS:POKE 618,11:PRINT:PRINT:PRINT "   BRAVO ! NOUVEAU RECORD :";S
820 PRINT:PRINT "   TU ENTRES AU HALL OF FAME, PLACE";P
825 PRINT:INPUT "   TON NOM (8 LETTRES)";NM$
830 POKE 618,10:IF NM$="" THEN NM$="?"
835 NM$=LEFT$(NM$+"        ",8)
840 IF P<10 THEN FOR I=10 TO P+1 STEP -1:N$(I)=N$(I-1):SC(I)=SC(I-1):NEXT
845 N$(P)=NM$:SC(P)=S
850 IF D THEN GOSUB 900
855 RETURN
900 POKE #9800,72:FOR I=1 TO 10:A=#9800+I*10-9
905 FOR J=0 TO 7:POKE A+J,ASC(MID$(N$(I),J+1,1)):NEXT
910 POKE A+8,INT(SC(I)/256):POKE A+9,SC(I) AND 255:NEXT
915 PRINT:PRINT "   SAUVEGARDE SUR LA DISQUETTE...":CALL #403
920 IF PEEK(#4FE) THEN PRINT "   ERREUR DISQUE";PEEK(#4FE):WAIT 300
925 RETURN
950 FOR I=1 TO 10:A=#9800+I*10-9:N$(I)=""
955 FOR J=0 TO 7:N$(I)=N$(I)+CHR$(PEEK(A+J)):NEXT
960 SC(I)=PEEK(A+8)*256+PEEK(A+9):NEXT:RETURN
# Routine machine de hof_disque.s (xa -o hof_disque.bin hof_disque.s)
1000 DATA 76,6,4,76,43,4,120,169,18,141,18,3,169,128,141,16,3,32,87,4
1010 DATA 160,0,173,16,3,74,144,52,173,24,3,48,245,173,19,3,153,0,152,200
1020 DATA 76,28,4,120,169,18,141,18,3,169,160,141,16,3,32,87,4,160,0,173
1030 DATA 16,3,74,144,15,173,24,3,48,245,185,0,152,141,19,3,200,76,65,4
1040 DATA 41,46,141,254,4,88,96,160,4,136,208,253,96
