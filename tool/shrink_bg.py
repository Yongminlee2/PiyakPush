# -*- coding: utf-8 -*-
"""게임 화면 배경의 세로 길이를 줄인다.

    python tool/shrink_bg.py 800     # 1080x1080 원본 -> 1080x800

원본(`PiyakAssets/banner/bg_*.png`, 1080×1080)을 세로로만 눌러
`assets/images/bg/bg_act{n}.png` 로 넣는다.

잘라내지 않고 누르는 이유: 무지개(2막)·해(3막)·달(4막)이 모두 그림 위쪽에
있어서 위를 자르면 다 사라진다. 아래를 자르면 정작 보여야 할 앞쪽 풍경이
없어진다. 평면 일러스트라 세로로 조금 누르는 정도는 눈에 잘 띄지 않는다.
"""
import io, os, sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(os.path.dirname(ROOT), 'PiyakAssets', 'banner')
DST = os.path.join(ROOT, 'assets', 'images', 'bg')

# 막 번호 -> 원본 파일
ACTS = {1: 'bg_meadow', 2: 'bg_sky', 3: 'bg_garden', 4: 'bg_night'}


def main():
    h = int(sys.argv[1]) if len(sys.argv) > 1 else 800
    for act, name in ACTS.items():
        im = Image.open(os.path.join(SRC, f'{name}.png')).convert('RGB')
        out = im.resize((im.width, h), Image.LANCZOS)
        out.save(os.path.join(DST, f'bg_act{act}.png'))
        print(f'bg_act{act}.png  {im.width}x{im.height} -> {im.width}x{h}')
    print()
    print(f'가로세로비 {1080 / h:.3f} — ActBackground.aspect 를 맞출 것')
    print(f'화면 폭 411dp 기준 높이 {411 * h / 1080:.0f}dp (원본은 411dp)')


if __name__ == '__main__':
    main()
