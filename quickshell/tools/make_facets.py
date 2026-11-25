#!/usr/bin/env python3
"""Готовит грани журавлика из SVG в JS-массив для QML.

Использование:
    python3 tools/make_facets.py [путь к SVG]

По умолчанию берёт assets/crane.svg. Исходный SVG — «Origami - Crane.svg»
с Wikimedia Commons, автор Binnette, лицензия CC BY-SA 3.0 (см. ATTRIBUTION.md).
"""
import re
import sys
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
SVG = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "assets" / "crane.svg"
OUT = HERE / "facets.js"

# z и оттенок для каждой грани (порядок путей в SVG)
Z_SHADE = [
    (40, 0.90),   # 0
    (45, 0.85),   # 1
    (-5, 0.75),   # 2
    (12, 0.90),   # 3
    (-55, 0.80),  # 4
    (25, 0.95),   # 5
    (20, 0.82),   # 6
    (-25, 0.80),  # 7
    (-50, 0.78),  # 8
    (-60, 0.72),  # 9
    (-65, 0.68),  # 10
    (5, 0.70),    # 11
    (10, 0.93),   # 12
    (15, 0.88),   # 13
    (55, 0.92),   # 14
    (60, 0.98),   # 15
]

src = SVG.read_text()
polys = []
for m in re.finditer(r'<path[^>]*?\sd="([^"]+)"[^>]*?>', src):
    d = m.group(1)
    if any(c in d for c in "CcQqSsTtAa"):
        continue
    pairs = re.findall(r'([ML])\s*([-\d.]+)[, ]([-\d.]+)', d)
    if len(pairs) < 3:
        continue
    pts = [(float(x), float(y)) for _, x, y in pairs]
    if len(pts) > 3 and abs(pts[0][0] - pts[-1][0]) < 0.01 and abs(pts[0][1] - pts[-1][1]) < 0.01:
        pts = pts[:-1]
    polys.append(pts)

assert len(polys) == len(Z_SHADE), len(polys)

allp = [p for poly in polys for p in poly]
minx = min(p[0] for p in allp)
maxx = max(p[0] for p in allp)
miny = min(p[1] for p in allp)
maxy = max(p[1] for p in allp)
cx = (minx + maxx) / 2
cy = (miny + maxy) / 2
scale = 460 / (maxy - miny)


def model(p):
    return [round((p[0] - cx) * scale, 2), round(-(p[1] - cy) * scale, 2)]


out = []
for i, poly in enumerate(polys):
    pts = [model(p) for p in poly]
    # лицевая сторона — против часовой (нормаль +Z)
    area = 0.0
    for j in range(len(pts)):
        x1, y1 = pts[j]
        x2, y2 = pts[(j + 1) % len(pts)]
        area += x1 * y2 - x2 * y1
    if area < 0:
        pts.reverse()
    z, shade = Z_SHADE[i]
    # uv: габариты всей фигуры -> вся страница
    uvs = [[round((p[0] - minx * scale + (maxx - minx) * scale / 2 - cx * 0) * 0 + 0, 4)] for p in pts]  # placeholder
    out.append({
        "pts": pts,
        "z": z,
        "shade": shade,
        "uvs": None,
    })

# UV считаем в общих координатах модели
minX = min(p[0] for f in out for p in f["pts"])
maxX = max(p[0] for f in out for p in f["pts"])
minY = min(p[1] for f in out for p in f["pts"])
maxY = max(p[1] for f in out for p in f["pts"])
for f in out:
    f["uvs"] = [
        [round((p[0] - minX) / (maxX - minX), 4), round((p[1] - minY) / (maxY - minY), 4)]
        for p in f["pts"]
    ]

mirror = []
for f in out:
    pts = [[-p[0], p[1]] for p in f["pts"]][::-1]
    uvs = [[round(1 - u, 4), v] for u, v in f["uvs"]][::-1]
    mirror.append({"pts": pts, "uvs": uvs, "z": f["z"], "shade": f["shade"]})

lines = [".pragma library", "", "var facets = ["]
for f in out:
    lines.append("    { pts: %s, uvs: %s, z: %s, shade: %s }," % (
        json.dumps(f["pts"]), json.dumps(f["uvs"]), f["z"], f["shade"]))
lines.append("];")
lines.append("")
lines.append("var facetsMirror = [")
for f in mirror:
    lines.append("    { pts: %s, uvs: %s, z: %s, shade: %s }," % (
        json.dumps(f["pts"]), json.dumps(f["uvs"]), f["z"], f["shade"]))
lines.append("];")
lines.append("")
OUT.write_text("\n".join(lines))
print("written", OUT, len(out), "facets", "bbox", (minX, maxX, minY, maxY))
