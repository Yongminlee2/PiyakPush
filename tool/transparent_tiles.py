# -*- coding: utf-8 -*-
"""오브젝트 타일의 초록 배경을 투명하게 만든다.

지형은 코드가 그리는 파스텔 체커보드로 되돌리고, codex의 오브젝트(둥지·굴·
단추·문)만 그 위에 얹기 위해서다. 배경색과 가까운 픽셀일수록 투명하게
(경계는 반투명으로 부드럽게) 처리한다.

    python tool/transparent_tiles.py
"""
import os

from PIL import Image

TILES = os.path.join(os.path.dirname(__file__), "..", "assets", "images", "tiles")
TARGETS = [
    "tile_nest.png",
    "tile_portal_purple.png",
    "tile_portal_orange.png",
    "tile_button_pink.png",
    "tile_button_blue.png",
    "tile_door_pink.png",
    "tile_door_blue.png",
]
TOL = 60.0


def main():
    for name in TARGETS:
        p = os.path.join(TILES, name)
        im = Image.open(p).convert("RGBA")
        px = im.load()
        w, h = im.size
        bg = px[0, 0][:3]
        if px[0, 0][3] == 0:
            print(f"건너뜀(이미 투명): {name}")
            continue
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                d = ((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2) ** 0.5
                if d < TOL:
                    # 배경에 가까울수록 투명하게 — 경계는 부드럽게 남는다
                    px[x, y] = (r, g, b, round(a * (d / TOL)))
        im.save(p)
        print(f"{name}: 배경 #{bg[0]:02X}{bg[1]:02X}{bg[2]:02X} -> 투명")


if __name__ == "__main__":
    main()
