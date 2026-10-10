"""Draws the ForeverRoute CurseForge avatar (400x400 PNG, original art).

A winding dashed route through dungeon stops on a dark map background, ending at a flag,
with "FR" below. Rendered at 4x and scaled down for smooth edges.

    python media/make_avatar.py        (needs: pip install pillow)
"""
import math
import pathlib
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = pathlib.Path(__file__).resolve().parent / "avatar.png"
S = 4                      # supersampling
W = 400 * S

GOLD = (236, 190, 92)
GOLD_DARK = (150, 108, 40)
STONE = (52, 70, 92)
INK = (14, 22, 36)
GREEN = (98, 214, 120)

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

# Background: radial gradient, deep navy edges to slate-teal centre.
bg = Image.new("RGB", (W, W))
px = bg.load()
cx, cy = W * 0.5, W * 0.42
maxd = math.hypot(W, W) * 0.55
for y in range(0, W, 2):
    for x in range(0, W, 2):
        t = min(1.0, math.hypot(x - cx, y - cy) / maxd)
        c = lerp((38, 74, 92), (10, 16, 30), t ** 1.2)
        px[x, y] = c
        if x + 1 < W: px[x + 1, y] = c
        if y + 1 < W:
            px[x, y + 1] = c
            if x + 1 < W: px[x + 1, y + 1] = c
img = bg.convert("RGBA")

# Faint map grid.
grid = Image.new("RGBA", (W, W), (0, 0, 0, 0))
g = ImageDraw.Draw(grid)
for i in range(1, 8):
    p = i * W // 8
    g.line([(p, 0), (p, W)], fill=(255, 255, 255, 14), width=S)
    g.line([(0, p), (W, p)], fill=(255, 255, 255, 14), width=S)
img = Image.alpha_composite(img, grid)

# Route: smooth curve through dungeon stops (bottom-left -> top-right).
stops = [(70, 300), (150, 220), (115, 140), (215, 110), (300, 160), (335, 75)]
stops = [(x * S, y * S) for x, y in stops]

def catmull(points, steps=40):
    pts = [points[0]] + points + [points[-1]]
    out = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for s in range(steps):
            t = s / steps
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[k]) + (-p0[k] + p2[k]) * t +
                                    (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2 +
                                    (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3) for k in range(2)))
    out.append(points[-1])
    return out

curve = catmull(stops)

# Glow under the route.
glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
ImageDraw.Draw(glow).line(curve, fill=GOLD + (120,), width=14 * S, joint="curve")
img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(9 * S)))

# Dashed route line.
route = Image.new("RGBA", (W, W), (0, 0, 0, 0))
r = ImageDraw.Draw(route)
dash, gap, acc, on = 16 * S, 10 * S, 0.0, True
for a, b in zip(curve, curve[1:]):
    seg = math.dist(a, b)
    if on:
        r.line([a, b], fill=GOLD, width=6 * S)
    acc += seg
    if acc >= (dash if on else gap):
        acc, on = 0.0, not on
img = Image.alpha_composite(img, route)

# Dungeon stops: done (green check-ish fill), current (gold ring), upcoming (stone).
d = ImageDraw.Draw(img)
for i, (x, y) in enumerate(stops[:-1]):
    rad = 15 * S
    if i < 2:
        fill, ring = GREEN, (230, 255, 235)
    elif i == 2:
        fill, ring = GOLD, (255, 240, 200)
    else:
        fill, ring = STONE, GOLD_DARK
    d.ellipse([x - rad - 3 * S, y - rad - 3 * S, x + rad + 3 * S, y + rad + 3 * S], fill=INK)
    d.ellipse([x - rad, y - rad, x + rad, y + rad], fill=ring)
    d.ellipse([x - rad + 4 * S, y - rad + 4 * S, x + rad - 4 * S, y + rad - 4 * S], fill=fill)
    if i < 2:  # little tick for finished stops
        d.line([(x - 6 * S, y), (x - 1 * S, y + 6 * S), (x + 8 * S, y - 7 * S)], fill=INK, width=4 * S, joint="curve")

# Goal flag at the last stop.
fx, fy = stops[-1]
d.line([(fx, fy + 22 * S), (fx, fy - 34 * S)], fill=(230, 220, 200), width=5 * S)
d.polygon([(fx + 2 * S, fy - 34 * S), (fx + 44 * S, fy - 24 * S), (fx + 2 * S, fy - 12 * S)], fill=(214, 70, 64))
d.ellipse([fx - 9 * S, fy + 16 * S, fx + 9 * S, fy + 28 * S], fill=GOLD_DARK)

# "FR" monogram.
font = ImageFont.truetype(r"C:\Windows\Fonts\seguibl.ttf", 120 * S)
text = "FR"
bbox = d.textbbox((0, 0), text, font=font)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
tx, ty = (W - tw) // 2 - bbox[0] + 40 * S, 268 * S - bbox[1]
shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
ImageDraw.Draw(shadow).text((tx + 4 * S, ty + 6 * S), text, font=font, fill=(0, 0, 0, 170))
img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(4 * S)))
d = ImageDraw.Draw(img)
d.text((tx, ty), text, font=font, fill=GOLD, stroke_width=3 * S, stroke_fill=INK)

# Thin gold frame.
d.rounded_rectangle([6 * S, 6 * S, W - 6 * S, W - 6 * S], radius=28 * S, outline=GOLD_DARK, width=4 * S)

img.resize((400, 400), Image.LANCZOS).convert("RGB").save(OUT, "PNG", optimize=True)
print("wrote", OUT)
