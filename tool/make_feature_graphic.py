# -*- coding: utf-8 -*-
"""플레이 스토어 그래픽 이미지(1024×500)를 만든다.

    python tool/make_feature_graphic.py

스토어 목록 맨 위에 걸리는 배너다. 게임 배경 위에 아이콘 속 병아리를 얹는다.
글자는 넣지 않는다 — 13개 언어로 나가는데 배너에 한 언어만 박으면 어색하고,
스토어가 이 이미지 위에 앱 이름을 따로 얹어 주기도 한다.
"""
import io, os, sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 1024, 500


def main():
    # 배경: 1막 낮 풀밭 (가로형이 이 비율에 가깝다)
    bg = Image.open(
        os.path.join(ROOT, 'assets', 'images', 'bg', 'bg_act1_wide.png')
    ).convert('RGB')
    # 가로를 맞추고 아래쪽(풀밭)이 보이게 잘라낸다
    scale = W / bg.width
    bg = bg.resize((W, int(bg.height * scale)), Image.LANCZOS)
    top = max(0, bg.height - H)
    out = bg.crop((0, top, W, top + H)) if bg.height >= H else bg.resize((W, H))

    # 주인공: 아이콘 앞층(투명)을 그대로 쓴다 — 아이콘과 같은 얼굴로 보이게
    fg = Image.open(
        os.path.join(os.path.dirname(ROOT), 'PiyakAssets', 'icon2',
                     'icon2_6_fg.png')
    ).convert('RGBA')
    size = int(H * 0.92)
    fg = fg.resize((size, size), Image.LANCZOS)
    out.paste(fg, (int(W * 0.60), H - size - 10), fg)

    dst = os.path.join(ROOT, 'store', 'feature_graphic.png')
    out.save(dst)
    print(f'{dst}  {out.size}')


if __name__ == '__main__':
    main()
