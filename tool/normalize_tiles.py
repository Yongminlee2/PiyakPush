# -*- coding: utf-8 -*-
"""타일 PNG의 배경색을 잔디 초록으로 통일한다.

codex가 준 타일 중 둥지·단추·문·벽은 배경이 크림/황토색이라, 잔디 칸과 나란히
놓으면 보드가 얼룩덜룩해진다. 이 도구는 각 이미지의 모서리 색(=배경)을 찾아
잔디 초록으로 바꾼다. 안티에일리어싱된 경계 픽셀은 배경색과의 거리에 비례해
섞어서 테두리에 크림색 실선이 남지 않게 한다.

    python tool/normalize_tiles.py
"""
import os
import sys

from PIL import Image

GRASS = (168, 230, 163)  # tile_grass.png의 배경색 #A8E6A3
TILES = os.path.join(os.path.dirname(__file__), "..", "assets", "images", "tiles")

# 배경이 잔디여야 하는 타일 (바닥 위에 놓이는 것들)
TARGETS = [
    "tile_wall.png",
    "tile_nest.png",
    "tile_button_pink.png",
    "tile_button_blue.png",
    "tile_door_pink.png",
    "tile_door_blue.png",
]

TOL = 70.0  # 이 거리 안쪽이면 배경으로 보고 섞는다


def dist(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5


def normalize(path):
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    bg = px[0, 0][:3]
    if dist(bg, GRASS) < 10:
        return f"건너뜀(이미 잔디): {os.path.basename(path)}"
    changed = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            d = dist((r, g, b), bg)
            if d >= TOL:
                continue
            # 배경에 가까울수록 완전히 초록으로, 멀수록 원본을 남긴다
            t = 1.0 - d / TOL
            px[x, y] = (
                round(r + (GRASS[0] - r) * t),
                round(g + (GRASS[1] - g) * t),
                round(b + (GRASS[2] - b) * t),
                a,
            )
            changed += 1
    im.save(path)
    return (
        f"{os.path.basename(path):24s} #{bg[0]:02X}{bg[1]:02X}{bg[2]:02X} "
        f"-> 잔디 ({changed}px)"
    )


def main():
    for name in TARGETS:
        p = os.path.join(TILES, name)
        if not os.path.exists(p):
            print("없음:", name, file=sys.stderr)
            continue
        print(normalize(p))


if __name__ == "__main__":
    main()
