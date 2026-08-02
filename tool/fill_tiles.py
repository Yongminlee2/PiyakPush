# -*- coding: utf-8 -*-
"""벽·문 타일의 그림을 캔버스 꽉 차게 늘린다.

codex가 준 벽·문 그림은 캔버스 안에 여백을 두고 그려져 있어서, 보드에 깔면
벽끼리 떨어져 보인다. 내용물(배경색과 다른 픽셀)의 경계 상자를 찾아 잘라내고
512×512로 다시 늘려 이웃 타일과 붙어 보이게 한다.

    python tool/fill_tiles.py
"""
import os

from PIL import Image

TILES = os.path.join(os.path.dirname(__file__), "..", "assets", "images", "tiles")
TARGETS = ["tile_wall.png", "tile_door_pink.png", "tile_door_blue.png"]
TOL2 = 40 * 40  # 배경으로 보는 색 거리(제곱)


def content_bbox(im, bg):
    w, h = im.size
    px = im.load()
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y][:3]
            d2 = (r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2
            if d2 > TOL2:
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    return (x0, y0, x1 + 1, y1 + 1)


for name in TARGETS:
    p = os.path.join(TILES, name)
    im = Image.open(p).convert("RGBA")
    bg = im.load()[0, 0][:3]
    box = content_bbox(im, bg)
    out = im.crop(box).resize(im.size, Image.LANCZOS)
    out.save(p)
    print(f"{name}: {box} -> 512x512")
