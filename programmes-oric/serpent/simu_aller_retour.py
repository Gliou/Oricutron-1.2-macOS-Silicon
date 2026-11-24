# simu_aller_retour.py — simulateur de la partie complète de serpent.bas (5
# tableaux, murs, portes, retours, pommes) pour tester le Cerveau du robot en
# mode aller-retour, sans Oricutron. Créé le 2026-11-23 by GliouCNR©70
#   python3 simu_aller_retour.py <dossier du bot> <@ par visite> <graine début> <graine fin> <longueur max>
#   ex. : python3 simu_aller_retour.py . 8 0 30 120   -> 30 parties sur 30 gagnées
import sys, random, numpy as np
sys.path.insert(0, sys.argv[1])
import bot_serpent as b


def P(g, x, y, v): g[y - b.LIG_H, x - b.COL_G] = v
def S(g, x, y): return g[y - b.LIG_H, x - b.COL_G]


def partie(graine, quota, seuil, cible=256):
    rng = random.Random(graine)
    murs = {}; PD = {}; E = {L: 0 for L in range(1, 6)}; OP = {L: False for L in range(1, 6)}

    def tableau(L):
        LY = 13 if L == 1 else PD[L - 1] + 1
        if L not in murs:
            g = np.full((b.NL, b.NC), b.VIDE, np.int8)
            PD[L] = PY = 3 + rng.randrange(18)
            for w in range(5 + 2 * L):
                for a in range(30):
                    V = rng.randrange(2); U = 1 - V; Q = 2 + rng.randrange(L + 2)
                    X1 = 4 + rng.randrange(33 - Q * U - V); Y1 = 3 + rng.randrange(21 - Q * V - U)
                    X2 = X1 + (Q - 1) * U; Y2 = Y1 + (Q - 1) * V
                    if X1 < 25 and Y1 < LY + 3 and Y2 > LY - 3: continue
                    if X2 > 31 and Y1 < PY + 4 and Y2 > PY - 2: continue
                    if any(S(g, i, j) != b.VIDE for i in range(X1 - 1, X2 + 2)
                           for j in range(Y1 - 1, Y2 + 2) if 2 <= i <= 37 and 1 <= j <= 24): continue
                    for i in range(X1, X2 + 1):
                        for j in range(Y1, Y2 + 1): P(g, i, j, b.MUR)
                    break
            murs[L] = g
        g = murs[L].copy()
        for y in range(1, 25): P(g, 2, y, b.BORD); P(g, 37, y, b.BORD)
        for x in range(3, 37): P(g, x, 1, b.BORD); P(g, x, 24, b.BORD)
        if L > 1:
            for y in (LY - 1, LY, LY + 1): P(g, 2, y, b.VIDE)
        if OP[L]:
            for y in range(PD[L], PD[L] + 3): P(g, 37, y, b.VIDE)
        return g

    L = 1; longueur = 4; EY = 13; EN = 0
    sens = 1; visites = 0; trace = []
    cer = b.Cerveau(cible)
    while True:
        g = tableau(L)
        trace.append(L)
        if EN == 0: corps = [(3, EY)]; d = (1, 0)
        else: corps = [(36, EY)]; d = (-1, 0)
        attente = longueur - 1; prevu = d; mangees = 0; depart = 2
        def libre_vide():
            while True:
                x, y = 3 + rng.randrange(34), 2 + rng.randrange(22)
                if S(g, x, y) == b.VIDE and (x, y) not in corps: return (x, y)
        pomme = libre_vide(); pas = 0
        change = None
        while change is None:
            pas += 1
            if pas > 20000: return longueur, 'tourne en rond', trace
            if quota and longueur >= seuil:
                sortie = None
            elif quota and mangees >= quota:
                sortie = "D" if (sens > 0 and L < 5) else ("G" if L > 1 else "D")
            elif quota:
                sortie = None
            else:
                sortie = "D" if L < 5 else None
            gv = g.copy(); P(gv, pomme[0], pomme[1], b.POMME)
            d1 = prevu
            p1 = (corps[-1][0] + d1[0], corps[-1][1] + d1[1])
            c1, a1 = b.Cerveau.avancer(corps, attente, [p1], p1 == pomme)
            if depart > 0:
                d2, why = d1, 'départ'; depart -= 1
            else:
                d2, why = cer.decider(gv, c1, a1, d1, longueur, set(corps), sortie)
            nx = p1
            c = S(g, *nx) if 2 <= nx[0] <= 37 and 1 <= nx[1] <= 24 else b.BORD
            if c == b.VIDE and nx[0] == 37:
                change = (L + 1, 0, nx[1]); break
            if c == b.VIDE and nx[0] == 2:
                change = (L - 1, 1, nx[1]); break
            queue_part = nx == corps[0] and attente == 0 and nx != pomme
            if c != b.VIDE or (nx in corps and not queue_part):
                return longueur, f'mort niv {L} en {nx} ({why}, sortie {sortie}, attente {attente}, pas {pas}, mangées {mangees})', trace
            mange = nx == pomme
            if mange: pass
            elif attente > 0: attente -= 1
            else: corps.pop(0)
            corps.append(nx)
            if mange:
                longueur += 1; mangees += 1; E[L] += 1
                if longueur >= cible:
                    return longueur, 'gagné', trace
                if E[L] == 5 and L < 5 and not OP[L]:
                    OP[L] = True
                    for y in range(PD[L], PD[L] + 3): P(g, 37, y, b.VIDE)
                pomme = libre_vide()
            prevu = d2
        L, EN, EY = change
        if L == 5: sens = -1
        elif L == 1: sens = 1


quota = int(sys.argv[2]); seuil = int(sys.argv[5])
res = [partie(s, quota, seuil) for s in range(int(sys.argv[3]), int(sys.argv[4]))]
for r in res:
    print(r[0], r[1], 'visites', len(r[2]), ''.join(map(str, r[2]))[:80])
print(sum(r[1] == 'gagné' for r in res), '/', len(res))
