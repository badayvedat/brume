"""Visuels pixel art de l'écran de démarrage (Souffle, Terminal), dans le codage de PixelArt.swift.

Chaque forme est tracée en SVG, rastérisée par rsvg-convert en sur-échantillonnage, puis éclairée depuis
le haut à gauche (produit scalaire avec la normale du bord) et cernée d'un contour `O`.
Usage : python3 scripts/pixel-art.py [planche.png]  -> affiche les tableaux Swift et écrit une planche d'aperçu.
"""
import io
import math
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


RACINE = Path(__file__).resolve().parent.parent
SS = 12


def smooth(points):
    """Catmull-Rom -> segments de Bézier cubiques."""
    out = []
    n = len(points)
    for i in range(n - 1):
        p0 = points[i - 1] if i > 0 else points[i]
        p1, p2 = points[i], points[i + 1]
        p3 = points[i + 2] if i + 2 < n else points[i + 1]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        out.append(f"C{c1[0]:.2f} {c1[1]:.2f} {c2[0]:.2f} {c2[1]:.2f} {p2[0]:.2f} {p2[1]:.2f}")
    return out


def lame(cx, cy, S, phi, sweep, R1, ex, W, tp, rise, head, N=48):
    """Une lame : axe en spirale de r=1 (tête) à r=R1 (pointe), largeur W en tête, effilée à zéro."""
    def axe(t):
        th = math.radians(phi + sweep * t)
        r = R1 + (1 - R1) * max(0.0, 1 - t) ** ex
        return r * math.cos(th), r * math.sin(th)

    def nrm(t):
        (x1, y1), (x2, y2) = axe(t - 1e-4), axe(t + 1e-4)
        L = math.hypot(x2 - x1, y2 - y1) or 1
        return -(y2 - y1) / L, (x2 - x1) / L

    def larg(t):
        a = rise + (1 - rise) * math.sin(min(t / 0.18, 1) * math.pi / 2)
        return W * a * max(0.0, 1 - t) ** tp

    def pt(t, s):
        x, y = axe(t)
        nx, ny = nrm(t)
        o = s * larg(t) / 2
        return cx + S * (x + nx * o), cy + S * (y + ny * o)

    ts = [i / N for i in range(N + 1)]
    ext = [pt(t, -1) for t in ts]
    inn = [pt(t, 1) for t in ts]
    d = f"M{ext[0][0]:.2f} {ext[0][1]:.2f} " + " ".join(smooth(ext))
    d += " " + " ".join(smooth(list(reversed(inn))))
    # tête arrondie : on recule vers t<0 le long de l'axe
    (hx, hy), (ox, oy) = inn[0], ext[0]
    bx, by = axe(-0.01)
    ax, ay = axe(0)
    L = math.hypot(bx - ax, by - ay)
    ux, uy = (bx - ax) / L, (by - ay) / L
    ww = S * larg(0)
    d += (f" C{hx + ux * ww * head[0]:.2f} {hy + uy * ww * head[0]:.2f} "
          f"{ox + ux * ww * head[1]:.2f} {oy + uy * ww * head[1]:.2f} {ox:.2f} {oy:.2f}Z")
    return d


def souffle(cx, cy, S, phi=-150.0, sweep=210.0, R1=0.10, ex=1.25, W=0.46, tp=1.1, rise=0.9, head=(0.55, 0.45)):
    return " ".join(lame(cx, cy, S, phi + 120 * i, sweep, R1, ex, W, tp, rise, head) for i in range(3))


def couverture(svg_corps, w, h):
    """Part de chaque pixel de la grille w×h couverte par la forme (0 à 1)."""
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * SS}" height="{h * SS}" viewBox="0 0 {w} {h}">'
           f'<rect width="{w}" height="{h}" fill="#000"/>{svg_corps}</svg>')
    png = subprocess.run(["rsvg-convert"], input=svg.encode(), capture_output=True, check=True).stdout
    im = Image.open(io.BytesIO(png)).convert("L").resize((w, h), Image.BOX)
    return [[im.getpixel((x, y)) / 255 for x in range(w)] for y in range(h)]


def eclairer(cov, teinte, seuil=.5, cx=None, cy=None):
    """Grille de lettres : forme pleine éclairée d'en haut à gauche, puis contour d'un pixel."""
    h, w = len(cov), len(cov[0])
    dedans = [[cov[y][x] >= seuil for x in range(w)] for y in range(h)]
    # Normale du bord : gradient d'un masque adouci, qui pointe vers l'intérieur.
    im = Image.new("L", (w, h))
    im.putdata([255 if dedans[y][x] else 0 for y in range(h) for x in range(w)])
    doux = im.resize((w * 4, h * 4), Image.NEAREST).filter(ImageFilter.GaussianBlur(5)).resize((w, h), Image.BOX)
    m = lambda x, y: doux.getpixel((min(max(x, 0), w - 1), min(max(y, 0), h - 1))) / 255
    lx, ly = -1 / math.sqrt(2), -1 / math.sqrt(2)
    lettres = [["."] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if not dedans[y][x]:
                continue
            gx, gy = (m(x + 1, y) - m(x - 1, y)) / 2, (m(x, y + 1) - m(x, y - 1)) / 2
            # gradient vers l'intérieur : la normale extérieure est son opposé
            e = (-gx * lx - gy * ly) * 4
            lettres[y][x] = teinte(x, y, e)
    for y in range(h):
        for x in range(w):
            if dedans[y][x]:
                continue
            if any(0 <= x + dx < w and 0 <= y + dy < h and dedans[y + dy][x + dx]
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1))):
                lettres[y][x] = "O"
    return ["".join(r) for r in lettres]


def niveau(e, clair, corps, ombre, profond, eclat=None):
    if eclat and e > .55:
        return eclat
    if e > .2:
        return clair
    if e < -.45:
        return profond
    if e < -.12:
        return ombre
    return corps


def souffle_px(w, h, echelle, decalage=(0, 0)):
    cx, cy = w / 2 + decalage[0], h / 2 + decalage[1]
    d = souffle(cx, cy, echelle)
    cov = couverture(f'<path d="{d}" fill="#fff"/>', w, h)

    def teinte(x, y, e):
        r = math.hypot(x + .5 - cx, y + .5 - cy) / echelle
        if r > .62:        # la tête, blanche
            return niveau(e, "H", "W", "W", "G")
        if r > .38:        # le corps passe à l'accent clair
            return niveau(e, "H", "L", "A", "D")
        return niveau(e, "L", "A", "D", "E")  # la pointe, dans l'accent

    return eclairer(cov, teinte)


def invite_px(w, h, cx, cy, haut, ep, barre):
    """`>` et `_` en traits épais, l'ensemble centré sur (cx, cy)."""
    larg_chev = haut / 2
    ecart = ep * 1.1
    total = larg_chev + ecart + barre
    x0 = cx - total / 2 + ep / 2
    y0, y1 = cy - haut / 2, cy + haut / 2
    corps = (f'<polyline points="{x0},{y0} {x0 + larg_chev},{cy} {x0},{y1}" fill="none" stroke="#fff" '
             f'stroke-width="{ep}" stroke-linecap="square" stroke-linejoin="miter"/>'
             f'<line x1="{x0 + larg_chev + ecart}" y1="{y1}" x2="{x0 + larg_chev + ecart + barre}" y2="{y1}" '
             f'stroke="#fff" stroke-width="{ep}" stroke-linecap="square"/>')
    cov = couverture(corps, w, h)
    return eclairer(cov, lambda x, y, e: niveau(e, "L", "A", "D", "E", eclat="H"))


def invite_net(n, t, gap, barre, ep_barre):
    """`>` et `_` posés au pixel : la branche du bas est le miroir exact de celle du haut.

    n : demi-hauteur du chevron, t : épaisseur horizontale d'une branche, ep_barre : hauteur du `_`.
    Ombrage d'un pixel net : bord du haut éclairé, bord du bas dans l'ombre.
    """
    haut = 2 * n + 1
    larg = n + t + gap + barre
    dedans = [[False] * larg for _ in range(haut)]
    for y in range(haut):
        d = y if y <= n else 2 * n - y
        for x in range(d, d + t):
            dedans[y][x] = True
    for y in range(haut - ep_barre, haut):
        for x in range(n + t + gap, larg):
            dedans[y][x] = True
    # une marge d'un pixel pour le contour
    dedans = [[False] * (larg + 2)] + [[False] + r + [False] for r in dedans] + [[False] * (larg + 2)]
    h, w = len(dedans), len(dedans[0])
    a = lambda x, y: 0 <= x < w and 0 <= y < h and dedans[y][x]
    px = [["."] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if a(x, y):
                # lumière venant du haut : chaque branche a un pixel clair en haut et un sombre en bas
                haut_libre, bas_libre = not a(x, y - 1), not a(x, y + 1)
                if haut_libre:
                    px[y][x] = "L"
                elif bas_libre:
                    px[y][x] = "D"
                else:
                    px[y][x] = "A"
            elif any(a(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                px[y][x] = "O"
    # un éclat blanc au coin du haut de chaque trait
    px[1][1] = "H"
    px[haut - ep_barre + 1][n + t + gap + 1] = "H"
    return ["".join(r) for r in px]


def rogner(px, marge=0):
    """Retire les lignes et colonnes vides au-delà d'une marge, en gardant une hauteur paire."""
    lignes = [i for i, r in enumerate(px) if r.strip(".")]
    cols = [x for x in range(len(px[0])) if any(r[x] != "." for r in px)]
    y0, y1 = max(lignes[0] - marge, 0), min(lignes[-1] + marge, len(px) - 1)
    x0, x1 = max(cols[0] - marge, 0), min(cols[-1] + marge, len(px[0]) - 1)
    out = [r[x0:x1 + 1] for r in px[y0:y1 + 1]]
    if len(out) % 2:
        out.append("." * len(out[0]))
    return out


def couleurs(accent):
    def mix(a, b, t):
        ca, cb = [int(a[i:i + 2], 16) for i in (0, 2, 4)], [int(b[i:i + 2], 16) for i in (0, 2, 4)]
        return "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(ca, cb))
    return {"A": accent, "L": mix(accent, "ffffff", .45), "D": mix(accent, "000000", .4), "E": mix(accent, "000000", .7),
            "H": "ffffff", "W": "ebebeb", "G": "c2c2cc", "S": "85858f", "O": "3c3c46", "K": "101014",
            "Z": "ffe49a", "Y": "f2c14e", "y": "b07d22"}


def existants():
    src = (RACINE / "Sources/BrumeCore/Constants/PixelArt.swift").read_text()
    out = {}
    for nom, corps in re.findall(r"private static let (\w+) = \[(.*?)\n    \]", src, re.S):
        out[nom] = re.findall(r'"([^"]*)"', corps)
    return out


def planche(chemin, dessins, accents=("8b9dc3", "f97316")):
    z = 8
    larg = sum(max(len(p[0]) for p in dessins.values()) * z + 24 for _ in [0])
    blocs = []
    for accent in accents:
        col = couleurs(accent)
        for nom, px in dessins.items():
            im = Image.new("RGB", (len(px[0]) * z + 24, len(px) * z + 24), (38, 40, 48))
            d = ImageDraw.Draw(im)
            for y, r in enumerate(px):
                for x, c in enumerate(r):
                    if c in col:
                        d.rectangle([12 + x * z, 12 + y * z, 12 + x * z + z - 1, 12 + y * z + z - 1], fill="#" + col[c])
            blocs.append(im)
    par_ligne = len(dessins)
    lignes = [blocs[i:i + par_ligne] for i in range(0, len(blocs), par_ligne)]
    W = max(sum(b.width for b in l) for l in lignes)
    H = sum(max(b.height for b in l) for l in lignes)
    out = Image.new("RGB", (W, H), (30, 32, 38))
    y = 0
    for l in lignes:
        x = 0
        for b in l:
            out.paste(b, (x, y))
            x += b.width
        y += max(b.height for b in l)
    out.save(chemin)


def swift(nom, px):
    print(f"    private static let {nom} = [")
    for r in px:
        print(f'        "{r}",')
    print("    ]\n")


if __name__ == "__main__":
    breath = rogner(souffle_px(36, 36, 15.4))
    breath_small = rogner(souffle_px(24, 24, 9.5))
    prompt = rogner(invite_net(12, 7, 4, 15, 5))
    prompt_small = rogner(invite_net(7, 4, 3, 9, 3))
    for nom, px in (("breath", breath), ("prompt", prompt), ("breathSmall", breath_small), ("promptSmall", prompt_small)):
        swift(nom, px)
    if len(sys.argv) > 1:
        ex = existants()
        planche(sys.argv[1], {"ghost": ex["ghost"], "cloud": ex["cloud"], "breath": breath, "prompt": prompt})
        planche(sys.argv[1].replace(".png", "-petit.png"),
                {"ghost": ex["ghostSmall"], "cloud": ex["cloudSmall"], "breath": breath_small, "prompt": prompt_small})
