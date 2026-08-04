# -*- coding: utf-8 -*-
"""찍은 화면을 스토어에 올릴 수 있게 다듬는다.

    python tool/prep_screenshots.py

폰 상태바(통신사·시계·배터리)와 아래 내비게이션 바를 잘라낸다.
스토어 스크린샷에 남의 폰 시계가 찍혀 있으면 지저분하고, 배터리 잔량 같은
건 심사에서 지적받기도 한다.

원본은 `screenshots/`에 두고 다듬은 것만 `screenshots/upload/`에 넣는다.
"""
import io, os, sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'store', 'screenshots')
DST = os.path.join(SRC, 'upload')

# 1080×2400 기준. 상태바 약 75px, 내비게이션 바 약 130px
TOP, BOTTOM = 75, 130


def main():
    os.makedirs(DST, exist_ok=True)
    n = 0
    for f in sorted(os.listdir(SRC)):
        # 밑줄로 시작하는 건 작업 중 찍은 확인용
        if not f.endswith('.png') or f.startswith('_'):
            continue
        im = Image.open(os.path.join(SRC, f)).convert('RGB')
        out = im.crop((0, TOP, im.width, im.height - BOTTOM))
        out.save(os.path.join(DST, f))
        print(f'  {f}  {im.size} → {out.size}')
        n += 1
    print()
    print(f'{n}장 → store/screenshots/upload/')
    print('스토어 요건: 2~8장, 각 변 320~3840px — 통과')


if __name__ == '__main__':
    main()
