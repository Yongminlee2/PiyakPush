# -*- coding: utf-8 -*-
"""고른 아이콘을 안드로이드 런처 아이콘 전 해상도로 깔아 넣는다.

    python tool/apply_icon.py c        # PiyakAssets/icon/icon_c.png 를 적용

만드는 것:
  mipmap-*/ic_launcher.png              구형 런처용 (정사각 통짜)
  drawable-*/ic_launcher_foreground.png 적응형 아이콘 앞층 (투명)
  values/colors.xml                     적응형 아이콘 뒤층 색
  store/icon_512.png                    플레이 콘솔에 올릴 512 아이콘

적응형 아이콘은 108dp 캔버스 중 가운데 72dp만 확실히 보인다.
앞층 원본(`*_fg.png`)이 이미 그 안에 그려져 있으므로 그대로 넣는다 —
`ic_launcher.xml` 에서 inset을 더 주면 홈 화면에서 눈에 띄게 작아진다.
"""
import io, os, sys, xml.etree.ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(os.path.dirname(ROOT), 'PiyakAssets', 'icon')
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')

# 구형 런처 아이콘 크기 (dp = px, 48dp 기준)
LEGACY = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
# 적응형 아이콘 층 크기 (108dp 캔버스)
ADAPTIVE = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324,
            'xxxhdpi': 432}


def bg_color_of(im):
    """귀퉁이 픽셀 = 배경색. 적응형 뒤층 색으로 쓴다."""
    r, g, b = im.convert('RGB').getpixel((4, 4))
    return f'#{r:02X}{g:02X}{b:02X}'


def main():
    which = (sys.argv[1] if len(sys.argv) > 1 else 'c').lower()
    flat = Image.open(os.path.join(SRC, f'icon_{which}.png')).convert('RGB')
    fg = Image.open(os.path.join(SRC, f'icon_{which}_fg.png')).convert('RGBA')

    for d, px in LEGACY.items():
        p = os.path.join(RES, f'mipmap-{d}', 'ic_launcher.png')
        os.makedirs(os.path.dirname(p), exist_ok=True)
        flat.resize((px, px), Image.LANCZOS).save(p)
    print(f'구형 런처 아이콘 {len(LEGACY)}종')

    for d, px in ADAPTIVE.items():
        p = os.path.join(RES, f'drawable-{d}', 'ic_launcher_foreground.png')
        os.makedirs(os.path.dirname(p), exist_ok=True)
        fg.resize((px, px), Image.LANCZOS).save(p)
    print(f'적응형 앞층 {len(ADAPTIVE)}종')

    # 뒤층 색을 그림의 배경색으로 맞춘다 — 앞뒤가 따로 놀지 않게
    color = bg_color_of(flat)
    cp = os.path.join(RES, 'values', 'colors.xml')
    tree = ET.parse(cp)
    for el in tree.getroot():
        if el.get('name') == 'ic_launcher_background':
            el.text = color
    tree.write(cp, encoding='utf-8', xml_declaration=True)
    print(f'적응형 뒤층 색 {color}')

    # 플레이 콘솔용 512
    store = os.path.join(ROOT, 'store')
    os.makedirs(store, exist_ok=True)
    flat.save(os.path.join(store, 'icon_512.png'))
    print('스토어용 store/icon_512.png')


if __name__ == '__main__':
    main()
