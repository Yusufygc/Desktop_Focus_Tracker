"""
3D ada asset üreticisi.

Harici model indirmeden (lisans / ağ / paketleme riski olmadan) low-poly ama
gerçekçi oranlarda 3D modelleri prosedürel olarak üretir:

    1. Her model glTF 2.0 (.glb) olarak `assets/island3d/` altına yazılır
       (Blender vb. ile açılıp incelenebilir / değiştirilebilir).
    2. Qt'nin `balsam` aracıyla Qt Quick 3D'nin yerel `.mesh` formatına
       dönüştürülür ve `app/ui/qml/components/island3d/meshes/` altına kopyalanır.

Her modelde parçalar ayrı "subset" (glTF primitive) olarak tutulur; QML
tarafı bu subset'lere sırasıyla kendi PrincipledMaterial'larını atar — böylece
ağaç rengi (konu rengi) ve biome paleti çalışma anında değiştirilebilir.
SUBSETS sözlüğü, QML'deki `materials: [...]` sırasının tek kaynağıdır.

Ölçek: 1 birim = 1 metre. Zemin seviyesi y = 0 (ada çimeni y = 0.15'te,
QML modelleri oraya yerleştirir).

Kullanım:
    venv\\Scripts\\python.exe tools\\build_island_assets.py
"""

import json
import math
import os
import random
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GLB_DIR = os.path.join(ROOT, "assets", "island3d")
MESH_DIR = os.path.join(ROOT, "app", "ui", "qml", "components", "island3d", "meshes")

# ── vektör yardımcıları ────────────────────────────────────────────


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def mul(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def norm(a):
    ln = math.sqrt(dot(a, a)) or 1.0
    return (a[0] / ln, a[1] / ln, a[2] / ln)


def rot_y(p, ang):
    c, s = math.cos(ang), math.sin(ang)
    return (p[0] * c + p[2] * s, p[1], -p[0] * s + p[2] * c)


def rot_z(p, ang):
    c, s = math.cos(ang), math.sin(ang)
    return (p[0] * c - p[1] * s, p[0] * s + p[1] * c, p[2])


def rot_x(p, ang):
    c, s = math.cos(ang), math.sin(ang)
    return (p[0], p[1] * c - p[2] * s, p[1] * s + p[2] * c)


# ── mesh oluşturucu ────────────────────────────────────────────────


class MeshBuilder:
    """Malzeme slotu başına üçgen listesi tutar. Her katı parça eklenirken
    üçgenler bir 'iç nokta'ya göre dışa dönük olacak şekilde yönlendirilir
    (sarım hatası → görünmez yüz riskini ortadan kaldırır)."""

    def __init__(self, slots):
        self.slots = list(slots)
        self.tris = {s: [] for s in self.slots}

    def solid(self, slot, tris, inside):
        out = self.tris[slot]
        for a, b, c in tris:
            n = cross(sub(b, a), sub(c, a))
            centroid = mul(add(add(a, b), c), 1.0 / 3.0)
            ref = inside(centroid) if callable(inside) else inside
            if dot(n, sub(centroid, ref)) < 0:
                b, c = c, b
            out.append((a, b, c))

    def merge(self, other, transform=lambda p: p, slot_map=None):
        for s, tris in other.tris.items():
            target = (slot_map or {}).get(s, s)
            for a, b, c in tris:
                ta, tb, tc = transform(a), transform(b), transform(c)
                # dönüşüm (yansıma yoksa) sarımı korur
                self.tris[target].append((ta, tb, tc))


# ── temel katı geometriler (merkez ve üçgen listesi döner) ─────────


def frustum(rb, rt, h, seg, base=(0.0, 0.0, 0.0), jitter=0.0, rng=None, phase=0.0,
            caps=(True, True), top_offset=(0.0, 0.0)):
    bx, by, bz = base
    bot, top = [], []
    for i in range(seg):
        a = phase + 2 * math.pi * i / seg
        jb = 1.0 + (rng.uniform(-jitter, jitter) if rng and jitter else 0.0)
        jt = 1.0 + (rng.uniform(-jitter, jitter) if rng and jitter else 0.0)
        bot.append((bx + math.cos(a) * rb * jb, by, bz + math.sin(a) * rb * jb))
        top.append((bx + top_offset[0] + math.cos(a) * rt * jt, by + h,
                    bz + top_offset[1] + math.sin(a) * rt * jt))
    tris = []
    for i in range(seg):
        j = (i + 1) % seg
        if rt > 1e-6:
            tris.append((bot[i], bot[j], top[j]))
            tris.append((bot[i], top[j], top[i]))
        else:
            tris.append((bot[i], bot[j], top[0]))
    cb = (bx, by, bz)
    ct = (bx + top_offset[0], by + h, bz + top_offset[1])
    for i in range(seg):
        j = (i + 1) % seg
        if caps[0]:
            tris.append((cb, bot[j], bot[i]))
        if caps[1] and rt > 1e-6:
            tris.append((ct, top[i], top[j]))
    if rt <= 1e-6:
        apex = (bx + top_offset[0], by + h, bz + top_offset[1])
        tris = [t if t[2] != top[0] else (t[0], t[1], apex) for t in tris]
    center = (bx + top_offset[0] * 0.5, by + h * 0.35, bz + top_offset[1] * 0.5)
    return tris, center


def box(cx, cy, cz, w, h, d):
    """cy = taban yüksekliği (kutu cy..cy+h arasında)."""
    x0, x1 = cx - w / 2, cx + w / 2
    y0, y1 = cy, cy + h
    z0, z1 = cz - d / 2, cz + d / 2
    v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
         (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    faces = [(0, 1, 2, 3), (5, 4, 7, 6), (4, 0, 3, 7), (1, 5, 6, 2), (3, 2, 6, 7), (4, 5, 1, 0)]
    tris = []
    for a, b, c, d_ in faces:
        tris.append((v[a], v[b], v[c]))
        tris.append((v[a], v[c], v[d_]))
    return tris, (cx, cy + h / 2, cz)


def gable_roof(cx, cy, cz, w, d, h, along_x=True):
    """Beşik çatı (üçgen prizma). Mahya `along_x` ise X ekseni boyunca."""
    if along_x:
        hw, hd = w / 2, d / 2
        a, b = (cx - hw, cy, cz - hd), (cx + hw, cy, cz - hd)
        c, e = (cx + hw, cy, cz + hd), (cx - hw, cy, cz + hd)
        r0, r1 = (cx - hw, cy + h, cz), (cx + hw, cy + h, cz)
        tris = [(a, b, r1), (a, r1, r0), (e, r0, r1), (e, r1, c),
                (a, r0, e), (b, c, r1), (a, e, c), (a, c, b)]
    else:
        hw, hd = w / 2, d / 2
        a, b = (cx - hw, cy, cz - hd), (cx - hw, cy, cz + hd)
        c, e = (cx + hw, cy, cz + hd), (cx + hw, cy, cz - hd)
        r0, r1 = (cx, cy + h, cz - hd), (cx, cy + h, cz + hd)
        tris = [(a, b, r1), (a, r1, r0), (e, r0, r1), (e, r1, c),
                (a, r0, e), (b, c, r1), (a, e, c), (a, c, b)]
    return tris, (cx, cy + h * 0.3, cz)


def pyramid(cx, cy, cz, w, d, h):
    hw, hd = w / 2, d / 2
    a, b, c, e = (cx - hw, cy, cz - hd), (cx + hw, cy, cz - hd), (cx + hw, cy, cz + hd), (cx - hw, cy, cz + hd)
    t = (cx, cy + h, cz)
    return [(a, b, t), (b, c, t), (c, e, t), (e, a, t), (a, c, b), (a, e, c)], (cx, cy + h * 0.25, cz)


def icosphere(center, r, subdiv=1, noise=0.0, rng=None, squash=1.0):
    t = (1 + 5 ** 0.5) / 2
    verts = [norm(p) for p in [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t),
                               (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]]
    faces = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2),
             (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5),
             (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    for _ in range(subdiv):
        cache, nf = {}, []

        def mid(i, j):
            key = (min(i, j), max(i, j))
            if key not in cache:
                verts.append(norm(mul(add(verts[i], verts[j]), 0.5)))
                cache[key] = len(verts) - 1
            return cache[key]
        for a, b, c in faces:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        faces = nf
    disp = [1.0 + (rng.uniform(-noise, noise) if rng and noise else 0.0) for _ in verts]
    pts = [(center[0] + v[0] * r * disp[i], center[1] + v[1] * r * disp[i] * squash,
            center[2] + v[2] * r * disp[i]) for i, v in enumerate(verts)]
    return [(pts[a], pts[b], pts[c]) for a, b, c in faces], center


def ring_battlements(cx, cy, cz, r, count, mh, mw, depth):
    """Yuvarlak kule tepesi için mazgal dişleri."""
    out = []
    for i in range(count):
        a = 2 * math.pi * i / count
        px, pz = cx + math.cos(a) * (r - depth / 2), cz + math.sin(a) * (r - depth / 2)
        tris, c = box(0, 0, 0, mw, mh, depth)
        tris = [tuple(add(rot_y(p, -a + math.pi / 2), (px, cy, pz)) for p in t) for t in tris]
        out.append((tris, (px, cy + mh / 2, pz)))
    return out


def line_battlements(x0, z0, x1, z1, y, mh, mw, depth, gap):
    out = []
    ln = math.hypot(x1 - x0, z1 - z0)
    n = max(1, int(ln / (mw + gap)))
    ang = math.atan2(z1 - z0, x1 - x0)
    for i in range(n):
        t = (i + 0.5) / n
        px, pz = x0 + (x1 - x0) * t, z0 + (z1 - z0) * t
        tris, _ = box(0, 0, 0, mw, mh, depth)
        tris = [tuple(add(rot_y(p, -ang), (px, y, pz)) for p in tr) for tr in tris]
        out.append((tris, (px, y + mh / 2, pz)))
    return out


# ── model tanımları ────────────────────────────────────────────────

SUBSETS = {}


def model(name, slots):
    def deco(fn):
        def run():
            mb = MeshBuilder(slots)
            fn(mb, random.Random(zlib.crc32(name.encode("utf-8"))))
            return mb
        SUBSETS[name] = slots
        run.__name__ = name
        MODELS[name] = run
        return run
    return deco


MODELS = {}


@model("island_base", ["grass", "dirt", "rock"])
def island_base(mb, rng):
    rng.seed(7)
    seg = 36
    top_y = 0.15
    rim = []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        r = 4.85 + 0.22 * math.sin(a * 3 + 0.7) + 0.12 * math.sin(a * 7) + rng.uniform(-0.05, 0.05)
        rim.append((a, r))
    # Çim üst yüzey: merkez düz (yapılar için), dışa doğru hafif tümsekler
    rings = [(0.0, top_y), (0.55, top_y), (0.82, top_y + 0.02), (1.0, top_y - 0.05)]
    grid = []
    for frac, y in rings:
        row = []
        for a, r in rim:
            yy = y + (rng.uniform(-0.03, 0.04) if frac > 0.7 else 0.0)
            row.append((math.cos(a) * r * frac, yy, math.sin(a) * r * frac))
        grid.append(row)
    tris = []
    for k in range(len(grid) - 1):
        for i in range(seg):
            j = (i + 1) % seg
            p00, p01, p10, p11 = grid[k][i], grid[k][j], grid[k + 1][i], grid[k + 1][j]
            if k == 0:
                tris.append((p00, p10, p11))
            else:
                tris += [(p00, p10, p11), (p00, p11, p01)]
    mb.solid("grass", tris, (0, -10, 0))
    # Çim kenar dudağı (hafif sarkan)
    lip = [(math.cos(a) * (r + 0.04), top_y - 0.16, math.sin(a) * (r + 0.04)) for a, r in rim]
    edge = grid[-1]
    tris = []
    for i in range(seg):
        j = (i + 1) % seg
        tris += [(edge[i], lip[i], lip[j]), (edge[i], lip[j], edge[j])]
    mb.solid("grass", tris, lambda c: (0, c[1], 0))
    # Toprak katmanı
    d1 = [(math.cos(a) * r * 0.95, -0.45 + rng.uniform(-0.06, 0.06), math.sin(a) * r * 0.95) for a, r in rim]
    tris = []
    for i in range(seg):
        j = (i + 1) % seg
        tris += [(lip[i], d1[i], d1[j]), (lip[i], d1[j], lip[j])]
    mb.solid("dirt", tris, lambda c: (0, c[1], 0))
    # Yüzen kaya gövdesi: düzensiz halkalarla sivrilen alt kısım
    prev = d1
    layers = [(0.78, -1.1), (0.52, -1.9), (0.26, -2.7)]
    for frac, y in layers:
        cur = []
        for a, r in rim:
            rr = r * frac * (1 + rng.uniform(-0.12, 0.12))
            cur.append((math.cos(a + rng.uniform(-0.05, 0.05)) * rr, y + rng.uniform(-0.18, 0.18),
                        math.sin(a + rng.uniform(-0.05, 0.05)) * rr))
        tris = []
        for i in range(seg):
            j = (i + 1) % seg
            tris += [(prev[i], cur[i], cur[j]), (prev[i], cur[j], prev[j])]
        mb.solid("rock", tris, lambda c: (0, c[1], 0))
        prev = cur
    apex = (0.15, -3.6, -0.1)
    mb.solid("rock", [(prev[i], apex, prev[(i + 1) % seg]) for i in range(seg)], (0, -2.5, 0))
    # Kenar kayaları ve küçük taşlar
    for k in range(9):
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(3.9, 4.5)
        c = (math.cos(a) * r, top_y + 0.02, math.sin(a) * r)
        s = rng.uniform(0.12, 0.26)
        t, cc = icosphere(c, s, 0, 0.25, rng, squash=0.6)
        mb.solid("rock", t, cc)
    # Kayadan sarkan küçük sivri kayalar
    for k in range(6):
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(2.0, 3.4)
        b = (math.cos(a) * r, -1.0 - rng.uniform(0, 0.6), math.sin(a) * r)
        t, cc = frustum(rng.uniform(0.3, 0.5), 0.0, -rng.uniform(0.8, 1.4), 5, base=b, jitter=0.2, rng=rng)
        mb.solid("rock", t, add(b, (0, -0.2, 0)))


@model("pine_tree", ["bark", "leaf"])
def pine_tree(mb, rng):
    t, c = frustum(0.075, 0.05, 0.55, 7, jitter=0.08, rng=rng)
    mb.solid("bark", t, c)
    tiers = [(0.58, 0.62, 0.28), (0.46, 0.55, 0.62), (0.33, 0.5, 0.94), (0.19, 0.38, 1.22)]
    for idx, (r, h, y) in enumerate(tiers):
        # Etek: içe kıvrık alt halka + koni (gerçek çamdaki katmanlı dal görünümü)
        t, c = frustum(r, 0.0, h, 8, base=(0, y, 0), jitter=0.1, rng=rng, phase=idx * 0.4)
        mb.solid("leaf", t, c)
        t, c = frustum(r * 0.55, r, 0.07, 8, base=(0, y - 0.07, 0), jitter=0.08, rng=rng, phase=idx * 0.4,
                       caps=(True, False))
        mb.solid("leaf", t, c)


@model("oak_tree", ["bark", "leaf"])
def oak_tree(mb, rng):
    t, c = frustum(0.12, 0.08, 0.75, 7, jitter=0.1, rng=rng)
    mb.solid("bark", t, c)
    # Kök çıkıntıları
    for i in range(4):
        a = i * math.pi / 2 + 0.3
        b = (math.cos(a) * 0.08, 0.0, math.sin(a) * 0.08)
        t, c = frustum(0.06, 0.0, 0.22, 4, base=b, top_offset=(-math.cos(a) * 0.06, -math.sin(a) * 0.06))
        mb.solid("bark", t, c)
    # Dallar
    for ang, tilt in ((0.4, 0.35), (2.6, 0.4), (4.4, 0.3)):
        dx, dz = math.cos(ang) * tilt, math.sin(ang) * tilt
        t, c = frustum(0.05, 0.03, 0.4, 5, base=(0, 0.6, 0), top_offset=(dx, dz))
        mb.solid("bark", t, c)
    # Taç: farklı boyutlarda bozulmuş küreler
    blobs = [((0, 1.18, 0), 0.5), ((0.32, 1.02, 0.12), 0.36), ((-0.3, 1.05, -0.15), 0.37),
             ((0.05, 1.0, -0.33), 0.33), ((-0.1, 1.02, 0.32), 0.32), ((0.1, 1.45, 0.05), 0.3)]
    for cen, r in blobs:
        t, c = icosphere(cen, r, 1, 0.14, rng, squash=0.88)
        mb.solid("leaf", t, c)


@model("stump", ["bark", "wood", "leaf"])
def stump(mb, rng):
    t, c = frustum(0.2, 0.16, 0.26, 9, jitter=0.08, rng=rng, caps=(True, False))
    mb.solid("bark", t, c)
    t, c = frustum(0.155, 0.155, 0.01, 9, base=(0, 0.255, 0), caps=(False, True))
    mb.solid("wood", t, c)
    t, c = frustum(0.09, 0.09, 0.012, 9, base=(0, 0.262, 0), caps=(False, True))
    mb.solid("bark", t, c)
    for i in range(4):
        a = i * math.pi / 2 + 0.6
        b = (math.cos(a) * 0.15, 0.0, math.sin(a) * 0.15)
        t, c = frustum(0.07, 0.0, 0.14, 4, base=b, top_offset=(-math.cos(a) * 0.08, -math.sin(a) * 0.08))
        mb.solid("bark", t, c)
    # Filiz
    t, c = frustum(0.008, 0.006, 0.16, 4, base=(0.08, 0.26, 0.03))
    mb.solid("wood", t, c)
    for k in range(3):
        t, c = icosphere((0.08 + 0.03 * math.cos(k * 2.1), 0.42, 0.03 + 0.03 * math.sin(k * 2.1)), 0.04, 0, 0.1, rng)
        mb.solid("leaf", t, c)


def _house(mb, rng, cx, cz, w, d, ground_h, upper_h, roof_h, rot=0.0, roof_slot="roof", timber=True):
    """Taş zemin kat + sıvalı üst kat + ahşap karkas + beşik çatı + baca."""
    tmp = MeshBuilder(mb.slots)
    t, c = box(0, 0, 0, w, ground_h, d)
    tmp.solid("stone", t, c)
    t, c = box(0, ground_h, 0, w * 1.04, upper_h, d * 1.04)
    tmp.solid("plaster", t, c)
    if timber:
        for sx in (-1, 1):
            for sz in (-1, 1):
                t, c = box(sx * w * 0.52, ground_h, sz * d * 0.52, 0.06, upper_h, 0.06)
                tmp.solid("wood", t, c)
        for zz in (-d * 0.525, d * 0.525):
            t, c = box(0, ground_h - 0.02, zz, w * 1.06, 0.05, 0.03)
            tmp.solid("wood", t, c)
            t, c = box(0, ground_h + upper_h - 0.04, zz, w * 1.06, 0.05, 0.03)
            tmp.solid("wood", t, c)
    top = ground_h + upper_h
    t, c = gable_roof(0, top - 0.02, 0, w * 1.18, d * 1.25, roof_h, along_x=True)
    tmp.solid(roof_slot, t, c)
    # Baca
    t, c = box(w * 0.28, top + roof_h * 0.2, d * 0.15, 0.14, roof_h * 0.95, 0.14)
    tmp.solid("stone", t, c)
    # Kapı ve pencereler (ön yüz +z)
    t, c = box(-w * 0.18, 0, d / 2 + 0.01, 0.2, ground_h * 0.8, 0.03)
    tmp.solid("wood", t, c)
    for wx in (w * 0.2, -w * 0.25, w * 0.25):
        y = ground_h * 0.35 if wx == w * 0.2 else ground_h + upper_h * 0.3
        t, c = box(wx, y - 0.02, d / 2 + 0.03, 0.2, 0.24, 0.02)
        tmp.solid("wood", t, c)
        t, c = box(wx, y, d / 2 + 0.04, 0.15, 0.19, 0.02)
        tmp.solid("glass", t, c)
    # Yan pencereler
    for sx in (-1, 1):
        t, c = box(sx * (w / 2 + 0.04), ground_h + upper_h * 0.3, 0, 0.02, 0.19, 0.15)
        tmp.solid("glass", t, c)
    mb.merge(tmp, lambda p: add(rot_y(p, rot), (cx, 0, cz)))


@model("hut", ["log", "roof", "stone", "wood"])
def hut(mb, rng):
    w, d, h = 1.0, 0.8, 0.55
    t, c = box(0, 0, 0, w, 0.08, d)
    mb.solid("stone", t, c)
    # Yatay kütük duvarlar (köşelerden taşan)
    n = 6
    for i in range(n):
        y = 0.08 + i * (h / n)
        r = h / n / 2
        for zz in (-d / 2, d / 2):
            t, c = frustum(r, r, w + 0.16, 6, base=(0, 0, 0))
            t = [tuple(add(rot_z(p, -math.pi / 2), (-(w + 0.16) / 2, y + r, zz)) for p in tr) for tr in t]
            mb.solid("log", t, (0, y + r, zz))
        for xx in (-w / 2, w / 2):
            t, c = frustum(r, r, d + 0.16, 6, base=(0, 0, 0))
            t = [tuple(add(rot_x(p, math.pi / 2), (xx, y + r, -(d + 0.16) / 2)) for p in tr) for tr in t]
            mb.solid("log", t, (xx, y + r, 0))
    t, c = box(0, 0.08, 0, w - 0.04, h, d - 0.04)
    mb.solid("log", t, c)
    t, c = gable_roof(0, 0.08 + h, 0, w * 1.35, d * 1.45, 0.5)
    mb.solid("roof", t, c)
    t, c = box(0.28, 0.5, -0.12, 0.14, 0.55, 0.14)
    mb.solid("stone", t, c)
    t, c = box(-0.12, 0.08, d / 2 + 0.06, 0.22, 0.4, 0.03)
    mb.solid("wood", t, c)
    # Odun yığını
    for i in range(3):
        for j in range(3 - i):
            t, c = frustum(0.035, 0.035, 0.3, 6)
            t = [tuple(add(rot_x(p, math.pi / 2), (0.62 + j * 0.075 + i * 0.037, 0.035 + i * 0.065, -0.15)) for p in tr)
                 for tr in t]
            mb.solid("wood", t, (0.62 + j * 0.075 + i * 0.037, 0.035 + i * 0.065, 0))


@model("house", ["stone", "plaster", "roof", "wood", "glass"])
def house(mb, rng):
    _house(mb, rng, 0, 0, 1.4, 1.05, 0.55, 0.5, 0.6)
    # Çit ve bahçe
    for i in range(7):
        x = -0.9 + i * 0.3
        t, c = box(x, 0, 0.95, 0.04, 0.22, 0.04)
        mb.solid("wood", t, c)
    t, c = box(0, 0.12, 0.95, 1.85, 0.03, 0.02)
    mb.solid("wood", t, c)


@model("farm", ["barn", "roof", "wood", "stone", "plaster", "trim", "hay"])
def farm(mb, rng):
    # Ahır
    t, c = box(-0.75, 0, 0, 1.2, 0.85, 0.95)
    mb.solid("barn", t, c)
    t, c = gable_roof(-0.75, 0.83, 0, 1.38, 1.15, 0.55, along_x=False)
    mb.solid("roof", t, c)
    # Ahır kapısı + beyaz çapraz çıtalar
    t, c = box(-0.75, 0, 0.48, 0.5, 0.6, 0.03)
    mb.solid("barn", t, c)
    for x0, x1 in ((-1.0, -0.5), (-0.5, -1.0)):
        ang = math.atan2(0.6, x1 - x0)
        t, c = box(0, 0, 0, 0.78, 0.05, 0.02)
        t = [tuple(add(rot_z(p, ang if x1 > x0 else math.pi - ang), (-0.75, 0.3, 0.5)) for p in tr) for tr in t]
        mb.solid("trim", t, (-0.75, 0.3, 0.0))
    for x in (-1.0, -0.5):
        t, c = box(x, 0, 0.5, 0.04, 0.62, 0.02)
        mb.solid("trim", t, c)
    t, c = box(-0.75, 0.6, 0.5, 0.54, 0.04, 0.02)
    mb.solid("trim", t, c)
    # Yel değirmeni gövdesi (kanatlar ayrı model: windmill_blades)
    t, c = frustum(0.36, 0.24, 1.55, 10, base=(0.75, 0, -0.15))
    mb.solid("plaster", t, c)
    t, c = frustum(0.38, 0.38, 0.12, 10, base=(0.75, 0, -0.15))
    mb.solid("stone", t, c)
    t, c = frustum(0.3, 0.0, 0.42, 10, base=(0.75, 1.55, -0.15))
    mb.solid("roof", t, c)
    t, c = box(0.75, 0, 0.21, 0.18, 0.38, 0.03)
    mb.solid("wood", t, c)
    # Saman balyaları
    for i, (x, z) in enumerate(((0.1, 0.65), (0.4, 0.75), (0.25, 0.85))):
        t, c = frustum(0.13, 0.13, 0.22, 10)
        y = 0.13 if i < 2 else 0.13
        t = [tuple(add(rot_x(p, math.pi / 2), (x, y, z - 0.11)) for p in tr) for tr in t]
        mb.solid("hay", t, (x, y, z))
    # Çit
    for i in range(8):
        x = -1.45 + i * 0.27
        t, c = box(x, 0, -0.8, 0.04, 0.2, 0.04)
        mb.solid("wood", t, c)
    t, c = box(-0.5, 0.12, -0.8, 1.95, 0.03, 0.02)
    mb.solid("wood", t, c)


@model("windmill_blades", ["wood", "sail"])
def windmill_blades(mb, rng):
    # Merkez göbek: yerel orijinde, kanatlar XY düzleminde (Z ekseni etrafında döner)
    t, c = frustum(0.06, 0.06, 0.12, 8)
    t = [tuple(rot_x(p, math.pi / 2) for p in tr) for tr in t]
    mb.solid("wood", t, (0, 0, 0.06))
    for k in range(4):
        a = k * math.pi / 2
        t, c = box(0, 0, 0, 0.04, 0.85, 0.03)
        t = [tuple(rot_z(add(p, (0, 0.05, 0.1)), a) for p in tr) for tr in t]
        mb.solid("wood", t, rot_z((0, 0.45, 0.1), a))
        t, c = box(0, 0, 0, 0.16, 0.62, 0.015)
        t = [tuple(rot_z(add(p, (0.1, 0.25, 0.1)), a) for p in tr) for tr in t]
        mb.solid("sail", t, rot_z((0.1, 0.56, 0.1), a))


@model("village", ["stone", "plaster", "roof", "roof2", "wood", "glass", "water"])
def village(mb, rng):
    # Meydan taşları
    for i in range(14):
        a = 2 * math.pi * i / 14
        r = 0.55 + (i % 2) * 0.12
        t, c = frustum(0.13, 0.13, 0.03, 6, base=(math.cos(a) * r, 0, math.sin(a) * r), phase=a)
        mb.solid("stone", t, c)
    # Kuyu / çeşme
    t, c = frustum(0.32, 0.32, 0.26, 12)
    mb.solid("stone", t, c)
    t, c = frustum(0.25, 0.25, 0.02, 12, base=(0, 0.22, 0))
    mb.solid("water", t, c)
    for sx in (-1, 1):
        t, c = box(sx * 0.27, 0.2, 0, 0.05, 0.5, 0.05)
        mb.solid("wood", t, c)
    t, c = gable_roof(0, 0.68, 0, 0.75, 0.5, 0.22, along_x=True)
    mb.solid("roof", t, c)
    _house(mb, rng, -1.25, -0.55, 1.0, 0.8, 0.45, 0.42, 0.48, rot=0.35)
    _house(mb, rng, 1.25, -0.5, 1.0, 0.8, 0.45, 0.42, 0.48, rot=-0.4, roof_slot="roof2")
    _house(mb, rng, 0.1, -1.45, 1.1, 0.8, 0.5, 0.45, 0.5, rot=0.0)


@model("town", ["stone", "plaster", "roof", "roof2", "wood", "glass", "gold"])
def town(mb, rng):
    # Belediye binası
    t, c = box(0, 0, -0.55, 2.2, 0.35, 1.2)
    mb.solid("stone", t, c)
    t, c = box(0, 0.35, -0.55, 2.2, 0.75, 1.2)
    mb.solid("plaster", t, c)
    t, c = gable_roof(0, 1.08, -0.55, 2.4, 1.4, 0.6)
    mb.solid("roof", t, c)
    for i in range(6):
        x = -0.9 + i * 0.36
        t, c = box(x, 0.5, 0.06, 0.16, 0.36, 0.02)
        mb.solid("glass", t, c)
        t, c = box(x, 0.0, 0.08, 0.07, 0.35, 0.07)
        mb.solid("stone", t, c)
    # Saat kulesi
    t, c = box(0, 0, 0.35, 0.75, 2.6, 0.75)
    mb.solid("stone", t, c)
    t, c = box(0, 2.6, 0.35, 0.85, 0.1, 0.85)
    mb.solid("stone", t, c)
    for sx in (-1, 1):
        for sz in (-1, 1):
            t, c = box(sx * 0.32, 2.7, 0.35 + sz * 0.32, 0.1, 0.5, 0.1)
            mb.solid("stone", t, c)
    t, c = box(0, 2.7, 0.35, 0.5, 0.05, 0.5)
    mb.solid("wood", t, c)
    t, c = pyramid(0, 3.2, 0.35, 0.95, 0.95, 1.0)
    mb.solid("roof2", t, c)
    t, c = frustum(0.24, 0.24, 0.03, 16, base=(0, 0, 0))
    t = [tuple(add(rot_x(p, math.pi / 2), (0, 2.1, 0.73)) for p in tr) for tr in t]
    mb.solid("gold", t, (0, 2.1, 0.7))
    t, c = frustum(0.2, 0.2, 0.03, 16, base=(0, 0, 0))
    t = [tuple(add(rot_x(p, math.pi / 2), (0, 2.1, 0.75)) for p in tr) for tr in t]
    mb.solid("plaster", t, (0, 2.1, 0.72))
    t, c = box(0, 0, 0.73, 0.3, 0.55, 0.03)
    mb.solid("wood", t, c)
    _house(mb, rng, -1.6, 0.7, 0.85, 0.75, 0.42, 0.4, 0.45, rot=0.6, roof_slot="roof2")
    _house(mb, rng, 1.6, 0.7, 0.85, 0.75, 0.42, 0.4, 0.45, rot=-0.6)


@model("castle", ["stone", "stone_dark", "roof", "wood", "gold", "banner"])
def castle(mb, rng):
    s = 1.25  # kule merkezlerinin yarı açıklığı
    # Sur duvarları
    corners = [(-s, -s), (s, -s), (s, s), (-s, s)]
    for i in range(4):
        x0, z0 = corners[i]
        x1, z1 = corners[(i + 1) % 4]
        cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
        horiz = abs(z1 - z0) < 1e-6
        w, d = (abs(x1 - x0), 0.22) if horiz else (0.22, abs(z1 - z0))
        t, c = box(cx, 0, cz, w, 0.85, d)
        mb.solid("stone", t, c)
        for tris, cc in line_battlements(x0, z0, x1, z1, 0.85, 0.12, 0.11, 0.24, 0.09):
            mb.solid("stone", tris, cc)
    # Kapı kulesi (ön +z)
    t, c = box(0, 0, s, 0.7, 1.15, 0.4)
    mb.solid("stone_dark", t, c)
    for tris, cc in line_battlements(-0.35, s + 0.2, 0.35, s + 0.2, 1.15, 0.12, 0.1, 0.06, 0.06):
        mb.solid("stone_dark", tris, cc)
    t, c = box(0, 0, s + 0.21, 0.34, 0.55, 0.03)
    mb.solid("wood", t, c)
    t, c = frustum(0.17, 0.17, 0.03, 10, base=(0, 0, 0), caps=(True, True))
    t = [tuple(add(rot_x(p, math.pi / 2), (0, 0.55, s + 0.205)) for p in tr) for tr in t]
    mb.solid("wood", t, (0, 0.55, s + 0.19))
    # Ana kale (keep)
    t, c = box(0, 0, -0.1, 1.2, 1.75, 1.2)
    mb.solid("stone_dark", t, c)
    for x0, z0, x1, z1 in ((-0.6, 0.5, 0.6, 0.5), (-0.6, -0.7, 0.6, -0.7), (-0.6, -0.7, -0.6, 0.5), (0.6, -0.7, 0.6, 0.5)):
        for tris, cc in line_battlements(x0, z0, x1, z1, 1.75, 0.14, 0.12, 0.08, 0.09):
            mb.solid("stone_dark", tris, cc)
    for i in range(3):
        y = 0.5 + i * 0.42
        for x in (-0.3, 0.3):
            t, c = box(x, y, 0.51, 0.08, 0.2, 0.02)
            mb.solid("wood", t, c)
    # Köşe kuleleri
    for x, z in corners:
        t, c = frustum(0.36, 0.32, 1.45, 12, base=(x, 0, z))
        mb.solid("stone", t, c)
        t, c = frustum(0.4, 0.4, 0.08, 12, base=(x, 1.45, z))
        mb.solid("stone", t, c)
        for tris, cc in ring_battlements(x, 1.53, z, 0.4, 8, 0.12, 0.12, 0.08):
            mb.solid("stone", tris, cc)
        t, c = frustum(0.33, 0.0, 0.75, 12, base=(x, 1.53, z))
        mb.solid("roof", t, c)
        t, c = box(x, 0.8, z + (0.33 if z > 0 else -0.33), 0.06, 0.16, 0.03)
        mb.solid("wood", t, c)
    # Bayrak direği + flama
    t, c = frustum(0.02, 0.015, 0.75, 6, base=(0, 1.75, -0.1))
    mb.solid("gold", t, c)
    t, c = box(0.18, 2.3, -0.1, 0.32, 0.18, 0.015)
    mb.solid("banner", t, c)


@model("lighthouse", ["rock", "white", "red", "glass", "dark"])
def lighthouse(mb, rng):
    t, c = icosphere((0, 0.05, 0), 0.5, 1, 0.22, rng, squash=0.45)
    mb.solid("rock", t, c)
    bands = [(0.0, 0.36, "white"), (0.36, 0.34, "red"), (0.7, 0.36, "white"), (1.06, 0.3, "red")]
    rb, rt_total, h_total = 0.3, 0.2, 1.36
    for y, h, slot in bands:
        r0 = rb - (rb - rt_total) * (y / h_total)
        r1 = rb - (rb - rt_total) * ((y + h) / h_total)
        t, c = frustum(r0, r1, h, 12, base=(0, 0.2 + y, 0))
        mb.solid(slot, t, c)
    top = 0.2 + h_total
    t, c = frustum(0.3, 0.3, 0.05, 12, base=(0, top, 0))
    mb.solid("dark", t, c)
    for i in range(12):
        a = 2 * math.pi * i / 12
        t, c = box(math.cos(a) * 0.28, top + 0.05, math.sin(a) * 0.28, 0.02, 0.12, 0.02)
        mb.solid("dark", t, c)
    t, c = frustum(0.15, 0.15, 0.24, 8, base=(0, top + 0.05, 0))
    mb.solid("glass", t, c)
    t, c = frustum(0.2, 0.0, 0.2, 8, base=(0, top + 0.29, 0))
    mb.solid("red", t, c)
    t, c = box(0, 0.2, 0.28, 0.12, 0.22, 0.03)
    mb.solid("dark", t, c)


@model("monument", ["stone", "marble", "gold"])
def monument(mb, rng):
    t, c = box(0, 0, 0, 0.8, 0.1, 0.8)
    mb.solid("stone", t, c)
    t, c = box(0, 0.1, 0, 0.6, 0.1, 0.6)
    mb.solid("stone", t, c)
    t, c = box(0, 0.2, 0, 0.42, 0.12, 0.42)
    mb.solid("marble", t, c)
    # Dikilitaş (hafif daralan)
    t, c = frustum(0.16, 0.11, 1.2, 4, base=(0, 0.32, 0), phase=math.pi / 4)
    mb.solid("marble", t, c)
    t, c = pyramid(0, 1.52, 0, 0.155, 0.155, 0.16)
    mb.solid("gold", t, c)


# ── glTF (GLB) yazıcı ──────────────────────────────────────────────


def write_glb(path, mb, name):
    bin_chunks, buffer_views, accessors, primitives, materials = [], [], [], [], []
    offset = 0

    def push(data, target):
        nonlocal offset
        pad = (4 - len(data) % 4) % 4
        data += b"\x00" * pad
        buffer_views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(data) - pad, "target": target})
        bin_chunks.append(data)
        offset += len(data)
        return len(buffer_views) - 1

    for slot in mb.slots:
        tris = mb.tris[slot]
        if not tris:
            # Boş slot'a da tek bir dejenere üçgen koy — subset sırası QML ile hizalı kalsın
            tris = [((0, -50, 0), (0.0001, -50, 0), (0, -50, 0.0001))]
        pos, nrm, idx = [], [], []
        for a, b, c in tris:
            n = norm(cross(sub(b, a), sub(c, a)))
            for p in (a, b, c):
                pos.extend(p)
                nrm.extend(n)
                idx.append(len(idx))
        xs, ys, zs = pos[0::3], pos[1::3], pos[2::3]
        pv = push(struct.pack("<%df" % len(pos), *pos), 34962)
        nv = push(struct.pack("<%df" % len(nrm), *nrm), 34962)
        iv = push(struct.pack("<%dI" % len(idx), *idx), 34963)
        accessors.append({"bufferView": pv, "componentType": 5126, "count": len(pos) // 3, "type": "VEC3",
                          "min": [min(xs), min(ys), min(zs)], "max": [max(xs), max(ys), max(zs)]})
        accessors.append({"bufferView": nv, "componentType": 5126, "count": len(nrm) // 3, "type": "VEC3"})
        accessors.append({"bufferView": iv, "componentType": 5125, "count": len(idx), "type": "SCALAR"})
        materials.append({"name": slot, "pbrMetallicRoughness": {"baseColorFactor": [0.8, 0.8, 0.8, 1.0],
                                                                 "metallicFactor": 0.0, "roughnessFactor": 0.85}})
        primitives.append({"attributes": {"POSITION": len(accessors) - 3, "NORMAL": len(accessors) - 2},
                           "indices": len(accessors) - 1, "material": len(materials) - 1})

    blob = b"".join(bin_chunks)
    gltf = {
        "asset": {"version": "2.0", "generator": "FocusTracker build_island_assets.py"},
        "scene": 0, "scenes": [{"nodes": [0]}],
        "nodes": [{"name": name, "mesh": 0}],
        "meshes": [{"name": name, "primitives": primitives}],
        "materials": materials, "accessors": accessors, "bufferViews": buffer_views,
        "buffers": [{"byteLength": len(blob)}],
    }
    js = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    js += b" " * ((4 - len(js) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(blob)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(blob), 0x004E4942) + blob)
    return sum(len(mb.tris[s]) for s in mb.slots)


def find_balsam():
    import PySide6
    exe = os.path.join(os.path.dirname(PySide6.__file__), "balsam.exe" if os.name == "nt" else "balsam")
    if not os.path.exists(exe):
        sys.exit("balsam bulunamadı: " + exe)
    return exe


def main():
    os.makedirs(GLB_DIR, exist_ok=True)
    os.makedirs(MESH_DIR, exist_ok=True)
    balsam = find_balsam()
    for name, fn in MODELS.items():
        mb = fn()
        glb = os.path.join(GLB_DIR, name + ".glb")
        tri_count = write_glb(glb, mb, name)
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run([balsam, glb, "-o", tmp], check=True, capture_output=True)
            meshes = []
            for dirpath, _, files in os.walk(tmp):
                meshes += [os.path.join(dirpath, f) for f in files if f.endswith(".mesh")]
            if len(meshes) != 1:
                sys.exit(f"{name}: beklenmeyen mesh sayısı {len(meshes)}")
            shutil.copyfile(meshes[0], os.path.join(MESH_DIR, name + ".mesh"))
        print(f"{name:16s} {tri_count:6d} üçgen  subsets={SUBSETS[name]}")
    with open(os.path.join(GLB_DIR, "README.md"), "w", encoding="utf-8") as f:
        f.write("# 3D ada kaynak modelleri\n\n"
                "Bu `.glb` dosyaları `tools/build_island_assets.py` tarafından prosedürel olarak üretilir "
                "(harici kaynak / lisans yok). Uygulama, `balsam` ile dönüştürülmüş "
                "`app/ui/qml/components/island3d/meshes/*.mesh` dosyalarını kullanır.\n\n"
                "Subset (malzeme) sırası:\n\n")
        for n, s in SUBSETS.items():
            f.write(f"- `{n}`: {', '.join(s)}\n")


if __name__ == "__main__":
    main()
