# SERPENT — petit jeu en BASIC pour Oric Atmos
# Flèches du clavier pour diriger le serpent, mange les @ (+10 points).
# Perdu si le serpent touche le bord (*) ou sa propre queue (O).
# Clavier : on lit la dernière touche mémorisée par la ROM (PEEK(735), bit 7 =
# nouvelle touche) plutôt que KEY$, qui rate les appuis brefs (clavier virtuel,
# écran tactile) quand la boucle est lente.
# Variables : X(),Y() positions (tampon circulaire), H tête, T queue,
# DX/DY direction, S score, FX/FY nourriture.
10 REM SERPENT - ORICUTRON MAC/IOS
20 CLS:PAPER 0:INK 2:POKE 618,10
30 DIM X(255),Y(255)
40 FOR I=2 TO 38:PLOT I,1,"*":PLOT I,25,"*":NEXT
50 FOR I=1 TO 25:PLOT 2,I,"*":PLOT 38,I,"*":NEXT
60 H=3:T=0:S=0:DX=1:DY=0
70 FOR I=0 TO 3:X(I)=10+I:Y(I)=13:PLOT X(I),13,"O":NEXT
80 PLOT 3,26,"SCORE 0":PLOT 18,26,"FLECHES = DIRECTION"
90 GOSUB 500
95 PLOT 13,16,"ESPACE = DEPART":GET K$:PLOT 13,16,"               "
100 K=PEEK(735):IF K<128 THEN 150
105 POKE 735,0:K=K-128
110 IF K=8 AND DX=0 THEN DX=-1:DY=0
120 IF K=9 AND DX=0 THEN DX=1:DY=0
130 IF K=10 AND DY=0 THEN DX=0:DY=1
140 IF K=11 AND DY=0 THEN DX=0:DY=-1
150 NX=X(H)+DX:NY=Y(H)+DY:C=SCRN(NX,NY)
160 IF C=42 OR C=79 THEN 300
170 H=(H+1) AND 255:X(H)=NX:Y(H)=NY:PLOT NX,NY,"O"
180 IF C=64 THEN S=S+10:PING:PLOT 9,26,STR$(S):GOSUB 500:GOTO 100
190 PLOT X(T),Y(T)," ":T=(T+1) AND 255
200 WAIT 8:GOTO 100
300 EXPLODE:PLOT 15,12,"  PERDU !  ":PLOT 10,14," ESPACE = REJOUER "
310 GET K$:IF K$<>" " THEN 310
320 RUN
500 FX=INT(RND(1)*35)+3:FY=INT(RND(1)*23)+2
510 IF SCRN(FX,FY)<>32 THEN 500
520 PLOT FX,FY,"@":RETURN
