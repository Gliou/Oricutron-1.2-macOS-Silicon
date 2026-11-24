#!/usr/bin/env python3
"""
bot_serpent.py — un robot qui joue au SERPENT dans Oricutron en lisant l'écran.
Créé le 2026-11-23 by GliouCNR©70

Le robot regarde en direct une zone de l'écran du Mac (celle où Oricutron
affiche l'Oric), reconnaît chaque case du terrain (bord, murs, serpent, pomme,
portes) et envoie les flèches du clavier à Oricutron, sans prendre le clavier
ni la souris de l'utilisateur.

  python3 bot_serpent.py                 # on montre la zone avec la souris
  python3 bot_serpent.py --fenetre       # zone = fenêtre d'Oricutron
  python3 bot_serpent.py --zone 960,328,640,500

Il faut : pip install mss numpy pyobjc-framework-Quartz
et, dans Réglages Système › Confidentialité et sécurité, autoriser le
Terminal dans « Enregistrement de l'écran » (et « Accessibilité » si les
touches n'arrivent pas).

Score parfait — le serpent garde ses positions dans X(255),Y(255) : un tampon
de 256 cases. Au-delà de 256 anneaux, la tête écrase la queue dans le tampon
et le jeu se dérègle. La meilleure partie possible est donc :
  - niveaux 1 à 4 : manger juste les 5 @ qui ouvrent la porte, puis sortir
    (5x10 + 5x20 + 5x30 + 5x40 = 500 points, le serpent passe de 4 à 24) ;
  - niveau 5 : manger 232 @ à 50 points (le serpent arrive à 256)
  - total : 500 + 232 x 50 = 12 100 points.
Le robot vise exactement cela, puis rend la main (option --longueur-max).

Aller-retour (option --aller-retour N, ajouté le 2026-11-23 by GliouCNR©70) :
le robot mange N @ par visite d'un tableau puis repart - vers la droite
jusqu'au niveau 5, puis vers la gauche (porte de retour) jusqu'au niveau 1,
et ainsi de suite. Depuis le 2026-11-23 le jeu est gagné à 256 anneaux sur
n'importe quel niveau : la partie finit là où le serpent est complet.
Au-delà de --aller-retour-max anneaux (120), le robot ne change plus de
tableau : en entrant avec un serpent très long, celui-ci doit se dérouler
depuis la porte, queue bloquée à l'entrée, et s'enferme souvent (simulé :
30 parties sur 30 gagnées à 120, 12 sur 20 à 170).

Compatibilité (2026-11-24) : Mac seulement, macOS 12.3 ou plus (ScreenCaptureKit,
Quartz) ; testé sur Mac Apple Silicon. Pour PC et Linux, voir le LISEZ-MOI.

Vitesse (2026-11-24) : --mhz N si Oricutron est accéléré (F1 > Overclock).
Sûr à 1 MHz ; à 2 MHz jusqu'au niveau 4 ; au-delà, le flottement des images
(50 i/s d'Oricutron, 60 i/s de l'écran) dépasse la durée d'un pas.

Lecture de l'écran : on repère le cadre - briques blanches à joints magenta,
colonnes 2 et 37, lignes 1 et 24 du PLOT - pour caler la grille, puis on lit le centre de chacun des 6x8
points de chaque case et on compare au dessin des caractères redéfinis par
serpent.bas (DATA 996-999).

Synchronisation : le jeu lit la dernière touche (PEEK(735)) au début de chaque
pas. Une touche vue après le tracé du pas k agit au pas k+2 : le robot décide
donc toujours un pas à l'avance, et appuie au milieu du pas pour ne tomber ni
trop tôt ni trop tard.
"""

import argparse
import collections
import fcntl
import os
import sys
import tempfile
import threading
import time

try:
    import mss
    import numpy as np
    import Quartz
except ImportError:
    sys.exit("Il manque des modules : pip install mss numpy pyobjc-framework-Quartz")
try:    # flux continu de la fenêtre (macOS 12.3+), sinon capture image par image
    import objc
    import CoreMedia
    import dispatch
    import ScreenCaptureKit as SCK
except ImportError:
    SCK = None

# ---------------------------------------------------------------- terrain
COL_G, COL_D = 2, 37            # colonnes du bord (PLOT)
LIG_H, LIG_B = 1, 24            # lignes du bord (25 avant le 2026-11-23)
NC, NL = COL_D - COL_G + 1, LIG_B - LIG_H + 1   # 36 x 25 cases lues

VIDE, BORD, MUR, CORPS, TETE, QUEUE, POMME, AUTRE = range(8)
NOMS = "VIDE BORD MUR CORPS TETE QUEUE POMME AUTRE".split()

# Dessins des caractères (6 points par ligne, bit 5 = gauche), serpent.bas
DESSINS = {
    (POMME, None): [6, 8, 27, 63, 63, 63, 30, 12],
    (QUEUE, None): [3, 7, 15, 63, 63, 15, 7, 3],
    (QUEUE, 1): [48, 56, 60, 63, 63, 60, 56, 48],
    (QUEUE, 2): [12, 12, 30, 30, 30, 63, 63, 30],
    (QUEUE, 3): [30, 63, 63, 30, 30, 30, 12, 12],
    (CORPS, None): [30, 51, 45, 45, 51, 63, 63, 30],
    (TETE, (1, 0)): [28, 62, 58, 63, 63, 58, 62, 28],
    (TETE, (-1, 0)): [14, 31, 23, 63, 63, 23, 31, 14],
    (TETE, (0, 1)): [30, 63, 63, 63, 45, 63, 30, 12],
    (TETE, (0, -1)): [12, 30, 63, 45, 63, 63, 63, 30],
}
GABARITS = []
for (genre, info), octets in DESSINS.items():
    bits = np.array([[(o >> (5 - i)) & 1 for i in range(6)] for o in octets], bool)
    GABARITS.append((genre, info, bits))
GAB_BITS = np.array([g[2] for g in GABARITS])          # (G, 8, 6)
# Pomme posée en vidéo inverse (depuis le 2026-11-23) : CHR$(192), grosse
# pomme magenta, le reste de la case blanc (DATA 996 de serpent.bas)
POMME_INV = np.array([[(o >> (5 - i)) & 1 for i in range(6)]
                      for o in [6, 12, 59, 63, 63, 63, 63, 30]], bool)
# Bord en briques, en vidéo inverse (depuis le 2026-11-23, ligne 32) : joints
# magenta, briques blanches
BORD_INV = np.array([[(o >> (5 - i)) & 1 for i in range(6)]
                     for o in [63, 4, 4, 4, 63, 32, 32, 32]], bool)
GAB_GENRE = np.array([g[0] for g in GABARITS], np.int8)

# Couleurs de l'Oric (le filtrage OpenGL les adoucit : on prend la plus proche)
PALETTE = np.array([(0, 0, 0), (255, 0, 0), (0, 255, 0), (255, 255, 0),
                    (0, 0, 255), (255, 0, 255), (0, 255, 255), (255, 255, 255)],
                   np.int32)
NOIR, VERT, MAGENTA, BLANC = 0, 2, 5, 7

FLECHES = {(-1, 0): 123, (1, 0): 124, (0, 1): 125, (0, -1): 126}   # codes Mac
ESPACE = 49
DIRS = [(1, 0), (-1, 0), (0, 1), (0, -1)]


def maintenant():
    return time.perf_counter()


# ---------------------------------------------------------------- écran
class Ecran:
    """Capture de la zone et lecture des cases."""

    def __init__(self, zone, wid=None, flux=None):
        self.zone = zone
        self.wid = wid              # fenêtre d'Oricutron : capturée même cachée
        self.flux = flux            # ScreenCaptureKit : images poussées en continu
        self.vu = 0
        if flux is not None:
            self.vu, img = flux.attendre(0, 2.0)
            if img is None:
                raise RuntimeError("aucune image de ScreenCaptureKit")
            self.zone = (0, 0, img.shape[1], img.shape[0])   # coordonnées de l'image
        self.sct = None if wid else mss.MSS()
        self.grille = None          # (x0, y0, sx, sy) en pixels de capture
        self.date_image = None      # heure d'arrivée de la dernière image
        self.decoupe = None         # zone réduite au terrain, une fois calé

    def capture(self, entiere=False):
        if self.flux is not None:
            self.vu, img = self.flux.attendre(self.vu)
            self.date_image = self.flux.date
            if not entiere and self.decoupe is not None:
                x, y, w, h = self.decoupe
                img = img[y:y + h, x:x + w]
            return img[..., 2::-1]
        if entiere and self.wid:
            self.zone = cadre_fenetre(self.wid) or self.zone   # fenêtre déplacée ?
        x, y, w, h = self.zone if (entiere or self.decoupe is None) else self.decoupe
        if self.wid:
            # la fenêtre elle-même, même sous une autre fenêtre ou sur un autre
            # bureau (Space) : l'utilisateur peut faire autre chose pendant ce temps
            cg = Quartz.CGWindowListCreateImage(
                Quartz.CGRectMake(x, y, w, h), Quartz.kCGWindowListOptionIncludingWindow,
                self.wid, Quartz.kCGWindowImageBoundsIgnoreFraming
                | Quartz.kCGWindowImageNominalResolution)
            if cg is None:
                return np.zeros((h, w, 3), np.uint8)
            cw, ch = Quartz.CGImageGetWidth(cg), Quartz.CGImageGetHeight(cg)
            bpr = Quartz.CGImageGetBytesPerRow(cg)
            data = Quartz.CGDataProviderCopyData(Quartz.CGImageGetDataProvider(cg))
            img = np.frombuffer(data, np.uint8).reshape(ch, bpr // 4, 4)[:, :cw]
        else:
            img = np.asarray(self.sct.grab({"left": x, "top": y, "width": w, "height": h}))
        return img[..., 2::-1]                          # BGRA -> RGB

    @staticmethod
    def couleurs(img):
        # couleur Oric = R + 2 G + 4 B (0 noir, 2 vert, 5 magenta, 7 blanc...)
        c = img > 150          # le vert d'Oricutron vaut (117, 251, 76)
        return c[..., 0] + 2 * c[..., 1] + 4 * c[..., 2]

    def caler(self, img):
        """Cherche le cadre (img = capture entière de la zone). Le bord est fait
        de briques blanches à joints magenta (avant le 2026-11-23 : magenta
        plein) : chaque ligne de points du bord est blanche et magenta, avec
        au moins un peu de magenta - ce qui écarte la barre de titre grise."""
        self.decoupe = None
        r, g, b = [img[..., i].astype(np.int32) for i in range(3)]
        mag = (r > 150) & (b > 150) & (g < 110)
        bord = mag | ((r > 200) & (g > 200) & (b > 200))
        lignes = np.where((bord.sum(1) > bord.shape[1] * 0.5)
                          & (mag.sum(1) > bord.shape[1] * 0.04))[0]
        if len(lignes) < 2:
            return False
        y0, y1 = lignes[0], lignes[-1] + 1
        # colonnes du bord : presque toute la hauteur du cadre (les portes
        # font 3 cases sur 25, un mur au plus 8)
        cols = np.where(bord[y0:y1].mean(0) > 0.8)[0]
        if len(cols) < 2:
            return False
        x0, x1 = cols[0], cols[-1] + 1
        sx, sy = (x1 - x0) / (NC * 6), (y1 - y0) / (NL * 8)
        if not (1.0 <= sx <= 8 and 0.8 <= sy <= 8):
            return False
        self.grille = (x0, y0, sx, sy)
        # ne capturer ensuite que le terrain (k = pixels par point d'écran Mac)
        k = img.shape[1] / self.zone[2]
        dx, dy = int(x0 / k), int(y0 / k)
        self.decoupe = (self.zone[0] + dx, self.zone[1] + dy,
                        int(np.ceil(x1 / k)) - dx, int(np.ceil(y1 / k)) - dy)
        ox, oy = dx * k, dy * k
        # indices des 6x8 points de chaque case, dans la capture découpée
        cx = np.arange(NC * 6)
        cy = np.arange(NL * 8)
        self.ix = np.clip((x0 - ox + (cx + 0.5) * sx).astype(int), 0, int((x1 - ox)) - 1)
        self.iy = np.clip((y0 - oy + (cy + 0.5) * sy).astype(int), 0, int((y1 - oy)) - 1)
        return True

    def lire(self, img):
        """Renvoie la grille des genres [NL][NC] et la direction de la tête."""
        pts = img[np.ix_(self.iy, self.ix)]                 # (NL*8, NC*6, 3)
        coul = self.couleurs(pts).reshape(NL, 8, NC, 6).transpose(0, 2, 1, 3)
        n_mag = (coul == MAGENTA).sum((2, 3))
        n_bla = (coul == BLANC).sum((2, 3))
        n_ver = (coul == VERT).sum((2, 3))
        n_noir = (coul == NOIR).sum((2, 3))
        bits = coul == VERT                                   # (NL, NC, 8, 6)
        ecarts = (bits[:, :, None] != GAB_BITS).sum((3, 4))  # (NL, NC, G)
        g_idx = ecarts.argmin(-1)
        g_ecart = ecarts.min(-1)

        genres = np.full((NL, NC), AUTRE, np.int8)
        vert = (n_ver >= 8) & (n_ver + n_noir >= 44) & (g_ecart <= 8)
        genres[vert] = GAB_GENRE[g_idx[vert]]
        genres[n_noir >= 46] = VIDE
        genres[n_bla >= 40] = MUR
        genres[n_mag >= 40] = BORD
        ecart_bord = ((coul == MAGENTA) != BORD_INV).sum((2, 3))
        genres[(n_mag + n_bla >= 38) & (n_mag >= 8) & (n_mag <= 30)
               & (ecart_bord <= 9)] = BORD
        # pomme en inverse : magenta + blanc, forme de la pomme (elle a 37
        # points magenta, le bord 48 : on la reconnaît à son dessin)
        ecart_inv = ((coul == MAGENTA) != POMME_INV).sum((2, 3))
        genres[(n_mag + n_bla >= 38) & (n_bla >= 3) & (n_mag >= 25) & (ecart_inv <= 9)] = POMME
        dir_tete = {}
        for l, c in zip(*np.where(genres == TETE)):
            dir_tete[(int(c) + COL_G, int(l) + LIG_H)] = GABARITS[g_idx[l, c]][1]
        return genres, dir_tete


class FluxFenetre:
    """Reçoit en continu les images d'une fenêtre par ScreenCaptureKit.

    L'ancienne capture (CGWindowListCreateImage, utilisée aussi par mss) est
    restée deux fois bloquée exactement 30 s en pleine partie : le serpent,
    aveugle, est mort. Ici macOS pousse lui-même les images (60 par seconde),
    même si la fenêtre est cachée ou sur un autre bureau."""

    def __init__(self, wid, largeur, hauteur):
        self.image = None
        self.numero = 0
        self.date = None
        self.nouvelle = threading.Condition()
        pret, boite = threading.Event(), {}

        def contenu(c, err):
            boite["c"] = c
            pret.set()
        SCK.SCShareableContent.getShareableContentExcludingDesktopWindows_onScreenWindowsOnly_completionHandler_(
            False, False, contenu)
        if not pret.wait(5) or boite.get("c") is None:
            raise RuntimeError("ScreenCaptureKit ne répond pas")
        fen = [w for w in boite["c"].windows() if w.windowID() == wid]
        if not fen:
            raise RuntimeError("fenêtre d'Oricutron introuvable pour ScreenCaptureKit")
        filtre = SCK.SCContentFilter.alloc().initWithDesktopIndependentWindow_(fen[0])
        cfg = SCK.SCStreamConfiguration.alloc().init()
        cfg.setWidth_(int(largeur))
        cfg.setHeight_(int(hauteur))
        cfg.setMinimumFrameInterval_(CoreMedia.CMTimeMake(1, 60))
        cfg.setPixelFormat_(0x42475241)          # 'BGRA'
        cfg.setShowsCursor_(False)               # le pointeur ne cache plus de case
        cfg.setQueueDepth_(3)
        self.flux = SCK.SCStream.alloc().initWithFilter_configuration_delegate_(filtre, cfg, None)
        self.sortie = _SortieFlux.alloc().init()
        self.sortie.proprietaire = self
        self.file = dispatch.dispatch_queue_create(b"serpent.flux", None)
        ok, err = self.flux.addStreamOutput_type_sampleHandlerQueue_error_(
            self.sortie, SCK.SCStreamOutputTypeScreen, self.file, None)
        if not ok:
            raise RuntimeError(f"ScreenCaptureKit : {err}")
        parti, boite["e"] = threading.Event(), None

        def demarre(err):
            boite["e"] = err
            parti.set()
        self.flux.startCaptureWithCompletionHandler_(demarre)
        if not parti.wait(5) or boite["e"] is not None:
            raise RuntimeError(f"ScreenCaptureKit ne démarre pas : {boite['e']}")

    def recevoir(self, img):
        with self.nouvelle:
            self.image = img
            self.date = maintenant()      # heure d'arrivée de l'image
            self.numero += 1
            self.nouvelle.notify_all()

    def attendre(self, deja_vu, delai=0.1):
        """Renvoie (numéro, image BGRA) en attendant au plus `delai` une image
        plus récente que `deja_vu`."""
        with self.nouvelle:
            if self.numero == deja_vu:
                self.nouvelle.wait(delai)
            return self.numero, self.image

    def arreter(self):
        def fin(err):
            pass
        self.flux.stopCaptureWithCompletionHandler_(fin)


if SCK is not None:
    class _SortieFlux(objc.lookUpClass("NSObject")):
        proprietaire = None

        def stream_didOutputSampleBuffer_ofType_(self, flux, tampon, genre):
            if genre != SCK.SCStreamOutputTypeScreen:
                return
            pb = CoreMedia.CMSampleBufferGetImageBuffer(tampon)
            if pb is None:
                return                           # image « inchangée » : rien de neuf
            Quartz.CVPixelBufferLockBaseAddress(pb, 1)
            try:
                w, h = Quartz.CVPixelBufferGetWidth(pb), Quartz.CVPixelBufferGetHeight(pb)
                bpr = Quartz.CVPixelBufferGetBytesPerRow(pb)
                octets = Quartz.CVPixelBufferGetBaseAddress(pb).as_buffer(bpr * h)
                img = np.frombuffer(octets, np.uint8).reshape(h, bpr // 4, 4)[:, :w].copy()
            finally:
                Quartz.CVPixelBufferUnlockBaseAddress(pb, 1)
            self.proprietaire.recevoir(img)


# ---------------------------------------------------------------- clavier
class Clavier:
    """Envoie les touches au processus d'Oricutron (sans le mettre devant)."""

    MAINTIEN = 0.06          # l'Oric doit voir la touche pendant ~3 images

    def __init__(self, pid):
        self.pid = pid
        self.relacher = []    # (heure, code)

    def appuyer(self, code):
        e = Quartz.CGEventCreateKeyboardEvent(None, code, True)
        Quartz.CGEventPostToPid(self.pid, e)
        self.relacher.append((maintenant() + self.MAINTIEN, code))

    def tic(self):
        t = maintenant()
        for item in [r for r in self.relacher if r[0] <= t]:
            e = Quartz.CGEventCreateKeyboardEvent(None, item[1], False)
            Quartz.CGEventPostToPid(self.pid, e)
            self.relacher.remove(item)


def fenetre_oricutron():
    """PID, cadre et numéro de la plus grande fenêtre d'Oricutron (pas un
    dialogue), y compris si elle est cachée ou sur un autre bureau."""
    meilleure = None
    for w in Quartz.CGWindowListCopyWindowInfo(Quartz.kCGWindowListOptionAll,
                                               Quartz.kCGNullWindowID):
        if w.get("kCGWindowOwnerName") == "Oricutron" and w.get("kCGWindowLayer") == 0:
            b = w["kCGWindowBounds"]
            cadre = (int(b["X"]), int(b["Y"]), int(b["Width"]), int(b["Height"]))
            if meilleure is None or cadre[2] * cadre[3] > meilleure[1][2] * meilleure[1][3]:
                meilleure = (w["kCGWindowOwnerPID"], cadre, w["kCGWindowNumber"])
    return meilleure or (None, None, None)


def pid_oricutron():
    pid, cadre, _ = fenetre_oricutron()
    return pid, cadre


def cadre_fenetre(wid):
    for w in Quartz.CGWindowListCopyWindowInfo(Quartz.kCGWindowListOptionIncludingWindow, wid):
        b = w["kCGWindowBounds"]
        return int(b["X"]), int(b["Y"]), int(b["Width"]), int(b["Height"])
    return None


def position_souris():
    p = Quartz.CGEventGetLocation(Quartz.CGEventCreate(None))
    return int(p.x), int(p.y)


def choisir_zone():
    print("Montre la zone de l'écran de l'Oric avec la souris :")
    input("  1) pointe le coin HAUT-GAUCHE de l'écran de l'Oric, puis Entrée ")
    x0, y0 = position_souris()
    input("  2) pointe le coin BAS-DROIT, puis Entrée ")
    x1, y1 = position_souris()
    x0, x1 = sorted((x0, x1))
    y0, y1 = sorted((y0, y1))
    print(f"  zone : {x0},{y0},{x1 - x0},{y1 - y0}  (réutilisable avec --zone)")
    return x0, y0, x1 - x0, y1 - y0


# ---------------------------------------------------------------- cerveau
class Cerveau:
    """Décide de la direction, un pas à l'avance."""

    def __init__(self, longueur_max):
        self.longueur_max = longueur_max

    @staticmethod
    def voisins(p):
        for d in DIRS:
            yield (p[0] + d[0], p[1] + d[1]), d

    def preparer(self, genres, corps, attente, sortie, pomme, veut_pomme, connus=None):
        """Carte des cases : -1 = libre, sinon nombre de pas avant libération."""
        self.libre_a = {}
        bloque = set()
        for l in range(NL):
            for c in range(NC):
                g = genres[l, c]
                pos = (c + COL_G, l + LIG_H)
                if g in (BORD, MUR, AUTRE):
                    bloque.add(pos)
                elif g in (CORPS, QUEUE, TETE) and connus is not None and pos not in connus:
                    bloque.add(pos)          # anneau vu dont on ignore l'ordre (après l'estime)
                elif g == POMME and not veut_pomme:
                    bloque.add(pos)
                elif g == VIDE and ((pos[0] == COL_G and sortie != "G")
                                    or (pos[0] == COL_D and sortie != "D")):
                    bloque.add(pos)          # porte qu'on ne veut pas prendre
        for i, pos in enumerate(corps[:-1]):  # corps[0] = queue
            self.libre_a[pos] = i + attente + 1
        bloque.discard(None)
        self.bloque = bloque

    def libre(self, pos, t, libre_a):
        if not (COL_G <= pos[0] <= COL_D and LIG_H <= pos[1] <= LIG_B):
            return False
        if pos in self.bloque:
            return False
        return libre_a.get(pos, 0) <= t

    def bfs(self, depart, cibles, libre_a, t0=0):
        """Plus court chemin (en tenant compte de la queue qui avance)."""
        prec = {depart: None}
        file = collections.deque([(depart, t0)])
        while file:
            p, t = file.popleft()
            if p in cibles and p != depart:
                chemin = []
                while p != depart:
                    chemin.append(p)
                    p = prec[p]
                return chemin[::-1]
            for q, _ in self.voisins(p):
                if q not in prec and self.libre(q, t + 1, libre_a):
                    prec[q] = p
                    file.append((q, t + 1))
        return None

    def aire(self, depart, libre_a, limite):
        vus = {depart}
        file = collections.deque([(depart, 0)])
        while file and len(vus) < limite:
            p, t = file.popleft()
            for q, _ in self.voisins(p):
                if q not in vus and self.libre(q, t + 1, libre_a):
                    vus.add(q)
                    file.append((q, t + 1))
        return len(vus)

    @staticmethod
    def avancer(corps, attente, chemin, mange_fin):
        """Simule le serpent le long du chemin ; renvoie (corps, attente)."""
        corps = list(corps)
        for i, p in enumerate(chemin):
            mange = mange_fin and i == len(chemin) - 1
            # comme serpent.bas : en mangeant (ligne 155 -> 170) la queue ne
            # bouge pas ce pas-là ; sinon elle avance, sauf s'il reste des
            # anneaux à faire sortir du mur (GR, ligne 166)
            if mange:
                pass
            elif attente > 0:
                attente -= 1
            else:
                corps.pop(0)
            corps.append(p)
        return corps, attente

    def carte(self, corps, attente):
        return {pos: i + attente + 1 for i, pos in enumerate(corps[:-1])}

    def sur(self, corps, attente):
        """Le serpent peut-il encore rejoindre sa queue ?"""
        libre_a = self.carte(corps, attente)
        tete, queue = corps[-1], corps[0]
        if len(corps) < 3:
            return True
        # seule garantie : un chemin vers la queue (« assez de place » ne
        # suffit pas : le serpent de 189 anneaux s'est enfermé ainsi)
        return self.bfs(tete, {queue}, libre_a) is not None

    def decider(self, genres, corps, attente, d1, longueur, connus=None, sortie="D"):
        """corps = état APRÈS le pas k+1 prévu ; renvoie la direction du pas k+2.
        sortie : porte à prendre dès qu'elle est ouverte - "D" (droite), "G"
        (gauche, retour au niveau précédent) ou None (manger d'abord)."""
        tete = corps[-1]
        col = {"D": COL_D, "G": COL_G}.get(sortie)
        portes = set() if col is None else {
            (col, y) for y in range(LIG_H + 1, LIG_B) if genres[y - LIG_H, col - COL_G] == VIDE}
        pommes = {(c + COL_G, l + LIG_H) for l, c in zip(*np.where(genres == POMME))}
        veut_pomme = not portes and longueur < self.longueur_max
        self.preparer(genres, corps, attente, sortie if portes else None, pommes, veut_pomme, connus)
        libre_a = self.carte(corps, attente)
        demi_tour = (-d1[0], -d1[1])

        # 1) la porte de sortie, dès qu'elle est ouverte
        if portes:
            ch = self.bfs(tete, portes, libre_a)
            if ch:
                return self.dir(tete, ch[0]), "porte"
        # 2) la pomme, si on peut encore rejoindre sa queue après l'avoir mangée
        if veut_pomme and pommes:
            ch = self.bfs(tete, pommes, libre_a)
            if ch:
                c2, a2 = self.avancer(corps, attente, ch, True)
                if self.sur(c2, a2):
                    return self.dir(tete, ch[0]), "pomme"
        # 3) sinon suivre sa queue par le plus long détour possible
        meilleur, note = None, None
        for q, d in self.voisins(tete):
            if d == demi_tour or not self.libre(q, 1, libre_a):
                continue
            c2, a2 = self.avancer(corps, attente, [q], q in pommes)
            la2 = self.carte(c2, a2)
            ch = self.bfs(q, {c2[0]}, la2) if len(c2) > 2 else [q]
            # une pomme mangée en passant retarde la queue d'un pas : ne la
            # prendre que si aucune autre case ne convient
            sans_pomme = 0 if q in pommes else 1
            if ch is not None:
                n = (2, sans_pomme, len(ch))
            else:
                n = (1, sans_pomme, self.aire(q, la2, 900))
            if note is None or n > note:
                meilleur, note = d, n
        if meilleur:
            return meilleur, "queue" if note[0] == 2 else "place"
        return d1, "coincé"

    @staticmethod
    def dir(a, b):
        return (b[0] - a[0], b[1] - a[1])


# ---------------------------------------------------------------- robot
class Robot:
    def __init__(self, ecran, clavier, cerveau, verbeux, test_gel=0, aller_retour=0,
                 aller_retour_max=120, mhz=1):
        self.mhz = mhz                     # vitesse choisie dans Oricutron (Overclock)
        # appui à 0,4 pas après l'image à 1 MHz ; plus tôt quand l'Oric va plus
        # vite (le retard de l'image pèse plus lourd) ; ensuite auto-réglé
        self.avance = 1 if mhz <= 2 else 2  # pas engagés avant que la touche agisse
        self.phase = 0.2 if mhz == 2 else 0.4
        self.dernier_ecart = -1
        self.aller_retour = aller_retour   # @ à manger par visite (0 = score parfait)
        self.aller_retour_max = aller_retour_max   # au-delà : on reste dans le tableau
        self.test_gel = test_gel
        self.prochain_gel = maintenant() + test_gel
        self.ecran, self.clavier, self.cerveau = ecran, clavier, cerveau
        self.verbeux = verbeux
        self.reinit_partie()
        self.periode = 0.20
        self.derniere_vue = None     # heure du dernier pas vu
        self.appui = None            # (heure, direction) à envoyer
        self.vu_terrain = 0
        # Le pilote (fil séparé) envoie les touches à l'heure dite, même si une
        # capture d'écran reste bloquée ; il avance alors le serpent « à
        # l'estime » (sans voir l'écran) jusqu'au retour des images.
        self.verrou = threading.RLock()
        self.genres = None
        self.estimes = 0
        self.occupe = False          # attendre_pomme en cours (verrou relâché)
        self.derniere_image = maintenant()   # dernière image qui a CHANGÉ
        self.empreinte = None
        self.tete_visible = False    # la dernière image montrait une tête
        threading.Thread(target=self.pilote, daemon=True).start()

    def photo(self, nom):
        """Enregistre l'écran (variable BOT_PHOTOS = dossier) pour comprendre une
        défaite. Ajouté le 2026-11-23 by GliouCNR©70."""
        try:
            import mss.tools
            import numpy as np
            img = np.ascontiguousarray(self.ecran.capture(entiere=True)[:, :, :3])
            f = os.path.join(os.environ["BOT_PHOTOS"], time.strftime("%H%M%S_") + nom + ".png")
            mss.tools.to_png(img.tobytes(), (img.shape[1], img.shape[0]), output=f)
            self.log("photo", f)
        except Exception as ex:
            self.log("photo impossible :", ex)

    def reinit_partie(self):
        self.histo = []              # positions de la tête depuis l'entrée dans le tableau
        self.longueur = 4
        self.niveau = 1
        self.score = 0
        self.prevu = None            # direction prévue pour le pas suivant
        self.attendu = None          # direction prévue pour le pas qu'on va voir
        self.plan = []               # directions engagées : plan[0] = attendu
        self.ecarts = 0              # pas qui n'ont pas pris la direction prévue
        self.mangees = 0             # @ mangés dans ce tableau (cette visite)
        self.e_niveau = [0] * 6      # @ mangés en tout dans chaque tableau (porte à 5)
        self.sens = 1                # aller-retour : 1 = vers le niveau 5, -1 = vers le 1
        self.visites = 0
        self.pomme = None
        self.entrees = 0

    def log(self, *a):
        if self.verbeux:
            t = time.time()
            print(f"{time.strftime('%H:%M:%S', time.localtime(t))}.{int(t * 1000) % 1000:03d}",
                  *a, flush=True)

    def sortie(self):
        """Porte à prendre : "D", "G" ou None (manger encore)."""
        if not self.aller_retour:
            return "D" if self.niveau < 5 else None      # score parfait
        if self.mangees < self.aller_retour or self.longueur >= self.aller_retour_max:
            return None
        if self.sens > 0 and self.niveau < 5:
            return "D"
        if self.niveau > 1:
            return "G"
        return "D"

    def statut(self):
        print(f"\rNIVEAU {self.niveau}  SCORE {self.score:6d}  LONGUEUR {self.longueur:3d}  "
              f"pas {1000 * self.periode:4.0f} ms  écarts {self.ecarts}   ", end="", flush=True)

    def pilote(self):
        while True:
            time.sleep(0.004)
            with self.verrou:
                self.clavier.tic()
                t = maintenant()
                if self.appui and t >= self.appui[0]:
                    self.clavier.appuyer(FLECHES[self.appui[1]])
                    self.log("touche", self.appui[1])
                    self.appui = None
                h = self.histo
                if (not self.occupe and self.tete_visible and len(h) >= 2 and self.attendu and self.derniere_vue is not None
                        and self.genres is not None and self.estimes < 300
                        and t - self.derniere_image > 0.4
                        and t - self.derniere_vue > 1.3 * self.periode):
                    # aucune image depuis 0,4 s : la capture est bloquée
                    d = self.attendu
                    tete = (h[-1][0] + d[0], h[-1][1] + d[1])
                    self.estimes += 1
                    if self.estimes == 1 and os.environ.get("BOT_PHOTOS"):
                        self.photo("fige")
                    self.observer(self.derniere_vue + self.periode, tete, d, self.genres,
                                  simule=True)

    def boucle(self):
        sans_terrain = 0
        while True:
            t = maintenant()
            if self.ecran.decoupe is None or sans_terrain > 3:
                ok = self.ecran.caler(self.ecran.capture(entiere=True))
                self.derniere_image = maintenant()
                if not ok:
                    sans_terrain += 1
                    if sans_terrain == 60:
                        print("\nPlus de terrain (fin de partie ?).", flush=True)
                        self.reinit_partie()
                    time.sleep(0.03)
                    continue
            if self.test_gel and t > self.prochain_gel:
                self.prochain_gel = t + self.test_gel
                self.log("TEST : capture figée 1,5 s")
                time.sleep(1.5)
            img = self.ecran.capture()
            # Modifié le 2026-11-23 by GliouCNR©70 : les délais d'appui partent
            # de l'heure d'ARRIVÉE de l'image. Avant, t était pris avant
            # d'attendre l'image (jusqu'à 0,1 s plus tôt) : la touche partait
            # au hasard trop tôt ou trop tard, et le serpent tournait une case
            # en avance ou fonçait dans le mur.
            t_image = self.ecran.date_image or maintenant()
            # une fenêtre cachée peut cesser d'être redessinée alors que le jeu
            # tourne : une image figée compte comme une image absente
            empreinte = hash(img[::4, ::4].tobytes())
            if empreinte != self.empreinte:
                self.empreinte = empreinte
                self.derniere_image = maintenant()
            duree = maintenant() - t
            if duree > 0.3:
                self.log(f"capture lente : {duree:.1f} s")
            genres, tetes = self.ecran.lire(img)
            self.tete_visible = len(tetes) == 1   # pas d'estime pendant un redessin
            if (genres[:, 0] != BORD).sum() > 6 or (genres[0] != BORD).sum() > 6:
                sans_terrain += 1          # cadre absent : autre écran
                time.sleep(0.01)
                continue
            if sans_terrain >= 60:
                self.reinit_partie()
                self.log("nouvelle partie")
            sans_terrain = 0
            if len(tetes) != 1:
                continue                   # image prise entre deux PLOT
            (tete, dtete), = tetes.items()
            with self.verrou:
                avance = self.observer(t_image, tete, dtete, genres)
            if avance:
                if self.longueur >= self.cerveau.longueur_max:
                    print(f"\nLongueur {self.longueur} atteinte : score {self.score}. "
                          "Je rends la main.", flush=True)
                    return

    def observer(self, t, tete, dtete, genres, simule=False):
        """Nouvelle image (ou pas estimé) : renvoie True si la tête a avancé."""
        h = self.histo
        if h and h[-1] == tete:
            return False
        if not simule and self.estimes and tete in h[-8:]:
            # l'estime est allée plus vite que le jeu : revenir à ce qu'on voit
            del h[h.index(tete, len(h) - 8) + 1:]
            self.log(f"images revenues après {self.estimes} pas estimés (estime en avance)")
            self.estimes = 0
            self.appui = None
            self.attendu = None
            self.prevu = dtete
            self.plan = [None, dtete]
            return False
        if not simule and self.estimes:
            self.log(f"images revenues après {self.estimes} pas estimés")
            self.estimes = 0
        n_serpent = int(((genres == CORPS) | (genres == TETE) | (genres == QUEUE)).sum())
        ecart = abs(tete[0] - h[-1][0]) + abs(tete[1] - h[-1][1]) if h else 0
        if h and ecart == 1:
            h.append(tete)
        elif h and 2 <= ecart <= 8 and (tete[0] == h[-1][0] or tete[1] == h[-1][1]) \
                and dtete == (np.sign(tete[0] - h[-1][0]), np.sign(tete[1] - h[-1][1])):
            # image en retard : la tête a filé tout droit de plusieurs cases
            sx, sy = dtete
            for i in range(1, ecart + 1):
                h.append((h[-1][0] + sx, h[-1][1] + sy))
            self.log(f"{ecart - 1} pas manqués, rattrapés")
        else:
            if h:
                if tete[0] == 3 and h[-1][0] >= 35:
                    self.niveau = min(5, self.niveau + 1)
                elif tete[0] == 36 and h[-1][0] <= 4:
                    self.niveau = max(1, self.niveau - 1)
                if self.niveau == 5:
                    self.sens = -1
                elif self.niveau == 1:
                    self.sens = 1
                self.visites += 1
                self.log(f"nouveau tableau, niveau {self.niveau}")
            self.histo = h = [tete]
            self.prevu = dtete
            self.attendu = None
            self.plan = [None, dtete]
            self.mangees = 0
            self.pomme = None
            self.appui = None
            self.statut()
            return False
        # le pas vient d'avoir lieu ; une touche encore en attente part tout de
        # suite (la remplacer ferait perdre un virage)
        if self.appui:
            self.clavier.appuyer(FLECHES[self.appui[1]])
            self.log("touche en retard", self.appui[1])
            self.appui = None
        if self.derniere_vue is not None and not simule:
            dt = t - self.derniere_vue
            if 0.03 < dt < 0.5 and self.pomme != tete:
                self.periode = 0.6 * self.periode + 0.4 * dt
        self.derniere_vue = t
        a_mange = self.pomme == tete
        if a_mange:
            self.longueur += 1
            self.mangees += 1
            self.e_niveau[self.niveau] += 1
            self.score += 10 * self.niveau
            self.statut()
        if self.attendu and dtete != self.attendu:
            # la touche a agi un pas trop tôt (ou pas du tout) : se recaler sur
            # ce qu'on voit, le pas suivant continue dans la direction de la tête
            self.ecarts += 1
            self.log(f"!! direction vue {dtete}, prévue {self.attendu}")
            # Moment d'appui auto-réglé (2026-11-24 by GliouCNR©70) : tout droit
            # alors qu'on attendait le virage = touche trop tard -> appuyer plus
            # tôt ; virage déjà pris (direction du pas d'après) = trop tôt.
            # (le pas qui suit un écart en est la suite : on ne le compte pas)
            if not simule and len(h) >= 3 and self.dernier_ecart != len(h) - 1:
                avant = (h[-2][0] - h[-3][0], h[-2][1] - h[-3][1])
                if dtete == avant != self.attendu:
                    self.phase = max(0.0, self.phase - 0.08)
                    self.log(f"touche trop tard : appui à {self.phase:.2f} pas")
                elif dtete == self.prevu != self.attendu:
                    self.phase = min(0.85, self.phase + 0.08)
                    self.log(f"touche trop tôt : appui à {self.phase:.2f} pas")
            self.dernier_ecart = len(h)
            self.prevu = dtete
            self.plan = [None, dtete]
            self.appui = None
        if simule:
            # sans image : le corps est la fin de l'historique, la pomme
            # mangée est inconnue (le serpent suit alors sa queue)
            n_serpent = min(len(h), self.longueur)
            if a_mange:
                genres = genres.copy()
                genres[genres == POMME] = VIDE
                self.genres = genres
        else:
            self.genres = genres
        self.longueur = max(self.longueur, n_serpent)
        corps = h[-n_serpent:] if n_serpent <= len(h) else h[:]
        attente = max(0, self.longueur - len(corps))
        if a_mange and not simule:
            # le jeu place une nouvelle pomme (et peut ouvrir la porte) avant de
            # relire le clavier : attendre de la voir avant de décider
            genres = self.attendre_pomme(genres)
        pommes = list(zip(*np.where(genres == POMME)))
        self.pomme = (pommes[0][1] + COL_G, pommes[0][0] + LIG_H) if pommes else None

        # Pas déjà engagés (file self.plan, 2026-11-24 by GliouCNR©70) : à
        # 1-2 MHz, une touche vue après le pas k agit au pas k+2 - un seul pas
        # engagé (self.avance = 1). Plus vite, l'image arrive si tard que le jeu
        # a déjà relu le clavier : la touche agit au pas k+3, deux pas engagés.
        self.plan = self.plan[1:]
        engage = self.plan[:self.avance]
        while len(engage) < self.avance:
            engage.append(engage[-1] if engage else dtete)
        p, c1, a1 = tete, corps, attente
        for d in engage:
            p = (p[0] + d[0], p[1] + d[1])
            c1, a1 = Cerveau.avancer(c1, a1, [p], p == self.pomme)
        p1, d1 = p, engage[-1]
        if len(h) < 2:
            d2, pourquoi = d1, "départ"          # le jeu efface les touches au départ
        else:
            d2, pourquoi = self.cerveau.decider(genres, c1, a1, d1, self.longueur,
                                                None if simule else set(corps), self.sortie())
        # À l'estime, un virage risque de tomber un pas trop tôt ou trop tard :
        # aller tout droit tant que les deux cases devant sont libres.
        if simule and d2 != d1 and pourquoi != "coincé":
            q = (p1[0] + d1[0], p1[1] + d1[1])
            q2 = (q[0] + d1[0], q[1] + d1[1])
            la = self.cerveau.carte(c1, a1)
            if self.cerveau.libre(q, 1, la) and self.cerveau.libre(q2, 2, la):
                d2, pourquoi = d1, "tout droit à l'estime"
        # 5e @ des niveaux 1 à 4 : le jeu ouvre la porte (3 PLOT + ZAP) avant
        # de relire le clavier ; une touche envoyée trop tôt écraserait celle
        # du pas k+2 encore en attente. On va donc tout droit si c'est sûr.
        porte_ouvre = a_mange and self.e_niveau[self.niveau] == 5 and self.niveau < 5
        if porte_ouvre and d2 != d1 and pourquoi != "coincé":
            q = (p1[0] + d1[0], p1[1] + d1[1])
            if self.cerveau.libre(q, 1, self.cerveau.carte(c1, a1)):
                c2, a2 = Cerveau.avancer(c1, a1, [q], False)
                if self.cerveau.sur(c2, a2):
                    d2, pourquoi = d1, "tout droit, la porte s'ouvre"
        self.log(f"tête {tete} -> {p1}, ensuite {d2} ({pourquoi})" + (" [estime]" if simule else ""))
        if d2 != d1:
            if porte_ouvre:
                delai = 0.30
            elif a_mange and self.avance == 1:
                # la pomme est déjà tracée : le jeu vient de relire le clavier
                delai = 0.0
            else:
                # après le tracé, le jeu fait WAIT WT (WT = 5 - niveau, en
                # centièmes) puis lit la touche : viser un peu avant le milieu
                # de l'intervalle entre cette lecture et la suivante (la touche
                # met encore 0 à 30 ms à être vue par l'Oric). Modifié le
                # 2026-11-23 by GliouCNR©70 : compté depuis l'arrivée de
                # l'image (voir t_image dans boucle). --mhz (2026-11-24) :
                # Oricutron accéléré compte aussi ses WAIT plus vite ; la
                # fraction de pas (self.phase) se règle toute seule.
                wt = 0.01 * max(0, 5 - self.niveau) / self.mhz
                delai = wt + self.phase * self.periode
            base = maintenant() if (a_mange and not simule) else t
            self.appui = (base + delai, d2)
            if not simule:
                self.log(f"calcul {1000 * (maintenant() - t):.0f} ms, appui prévu à "
                         f"+{1000 * (base + delai - t):.0f} ms, pas {1000 * self.periode:.0f} ms")
        self.plan = engage + [d2]
        self.attendu = self.plan[0]
        self.prevu = self.plan[1]
        return True

    def attendre_pomme(self, genres):
        # appelée verrou pris : le relâcher pendant les captures, pour que le
        # pilote continue d'envoyer les touches si une capture bloque
        fin = maintenant() + 1.0
        self.occupe = True
        self.verrou.release()
        try:
            while maintenant() < fin:
                g, _ = self.ecran.lire(self.ecran.capture())
                self.derniere_image = maintenant()
                if (g == POMME).any():
                    time.sleep(0.02)
                    g, _ = self.ecran.lire(self.ecran.capture())
                    return g
            return genres
        finally:
            self.verrou.acquire()
            self.occupe = False


def main():
    ap = argparse.ArgumentParser(description="Robot joueur de SERPENT pour Oricutron.")
    ap.add_argument("--zone", help="x,y,largeur,hauteur de la zone à lire (points écran)")
    ap.add_argument("--fenetre", action="store_true",
                    help="lire la fenêtre d'Oricutron elle-même (marche même cachée "
                         "ou sur un autre bureau)")
    ap.add_argument("--longueur-max", type=int, default=256,
                    help="longueur à atteindre au niveau 5 (256 = score parfait)")
    ap.add_argument("--jouer", action="store_true", help="appuie sur Espace pour lancer la partie")
    ap.add_argument("-v", "--verbeux", action="store_true", help="journal détaillé")
    ap.add_argument("--aller-retour", type=int, default=0, metavar="N",
                    help="manger N @ par visite puis changer de tableau, du niveau 1 au 5 "
                         "et retour (0 = score parfait, tout au niveau 5)")
    ap.add_argument("--mhz", type=float, default=1,
                    help="vitesse de l'Oric réglée dans Oricutron (F1 > Overclock), 1 par défaut")
    ap.add_argument("--aller-retour-max", type=int, default=120, metavar="L",
                    help="longueur à partir de laquelle on ne change plus de tableau (120)")
    ap.add_argument("--test-gel", type=float, default=0, metavar="S",
                    help="essai : fige la capture 1,5 s toutes les S secondes")
    args = ap.parse_args()

    # Un seul robot à la fois (ajouté le 2026-11-23 by GliouCNR©70) : deux
    # robots enverraient chacun leurs flèches et feraient perdre le serpent.
    global VERROU
    VERROU = open(os.path.join(tempfile.gettempdir(), "bot_serpent.lock"), "w")
    try:
        fcntl.flock(VERROU, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        sys.exit("Un autre robot Serpent tourne déjà : arrêtez-le d'abord (Ctrl-C).")

    pid, fenetre, wid = fenetre_oricutron()
    if pid is None:
        sys.exit("Oricutron n'est pas ouvert.")
    if args.zone:
        zone = tuple(int(v) for v in args.zone.split(","))
    elif args.fenetre:
        zone = fenetre
    else:
        zone = choisir_zone()

    flux = None
    if args.fenetre and not args.zone and SCK is not None:
        try:
            flux = FluxFenetre(wid, fenetre[2], fenetre[3])
            print("Capture : flux ScreenCaptureKit de la fenêtre d'Oricutron.")
        except Exception as e:
            print(f"ScreenCaptureKit indisponible ({e}) : capture image par image.")
    ecran = Ecran(zone, wid if (args.fenetre and not args.zone) else None, flux)
    clavier = Clavier(pid)
    if args.jouer:
        clavier.appuyer(ESPACE)
        time.sleep(0.1)
        clavier.tic()
    print("Le robot regarde l'écran... (Ctrl-C pour arrêter)")
    try:
        Robot(ecran, clavier, Cerveau(args.longueur_max), args.verbeux,
              args.test_gel, args.aller_retour, args.aller_retour_max, args.mhz).boucle()
    except KeyboardInterrupt:
        print("\nArrêt.")
    finally:
        for _, code in clavier.relacher:
            Quartz.CGEventPostToPid(pid, Quartz.CGEventCreateKeyboardEvent(None, code, False))


if __name__ == "__main__":
    main()
