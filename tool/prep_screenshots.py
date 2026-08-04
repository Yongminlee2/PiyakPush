# -*- coding: utf-8 -*-
"""찍은 화면을 스토어에 올릴 수 있게 다듬는다.

    python tool/prep_screenshots.py

폰 상태바(통신사·시계·배터리)와 아래 내비게이션 바를 잘라낸다.
스토어 스크린샷에 남의 폰 시계가 찍혀 있으면 지저분하고, 배터리 잔량 같은
건 심사에서 지적받기도 한다.

색은 256색 팔레트로 줄인다. 파스텔 평면 그림이라 눈으로는 차이가 없는데
용량이 40%로 준다 (13개 언어 × 7장 = 91장이라 그냥 두면 60MB가 넘는다).

원본은 `store/screenshots/<언어>/`에 두고(저장소에 안 올린다),
다듬은 것만 `store/업로드/스크린샷/<언어>/`에 넣는다.
"""
import io, os, shutil, sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'store', 'screenshots')
DST = os.path.join(ROOT, 'store', '업로드', '스크린샷')

# 1080×2400 기준. 상태바 약 75px, 내비게이션 바 약 130px
TOP, BOTTOM = 75, 130

LANGS = ['ko', 'en', 'ja', 'zh', 'zh_Hant', 'es', 'fr',
         'de', 'pt', 'ru', 'th', 'vi', 'id']


def crop_dir(src, dst):
    """한 폴더의 png를 잘라 dst에 넣는다. 넣은 장수를 돌려준다."""
    os.makedirs(dst, exist_ok=True)
    n = 0
    for f in sorted(os.listdir(src)):
        # 밑줄로 시작하는 건 작업 중 찍은 확인용
        if not f.endswith('.png') or f.startswith('_'):
            continue
        im = Image.open(os.path.join(src, f)).convert('RGB')
        out = im.crop((0, TOP, im.width, im.height - BOTTOM))
        out = out.quantize(colors=256, method=Image.MEDIANCUT,
                           dither=Image.FLOYDSTEINBERG)
        out.save(os.path.join(dst, f), optimize=True)
        n += 1
    return n


def main():
    # 이전 판이 남아 있으면 지우고 새로 만든다 (언어를 지웠을 때 찌꺼기 방지)
    if os.path.isdir(DST):
        shutil.rmtree(DST)

    total = 0
    missing = []
    for lang in LANGS:
        src = os.path.join(SRC, lang)
        if not os.path.isdir(src):
            missing.append(lang)
            continue
        n = crop_dir(src, os.path.join(DST, lang))
        print(f'  {lang:<8} {n}장')
        total += n

    print()
    print(f'{total}장 → store/업로드/스크린샷/<언어>/')
    if missing:
        print(f'아직 안 찍은 언어: {" ".join(missing)}')
        print('  python tool/shoot_all_langs.py ' + ' '.join(missing))
    else:
        print(f'{len(LANGS)}개 언어 전부 있음')
    print('스토어 요건: 언어당 2~8장, 각 변 320~3840px — 통과')


if __name__ == '__main__':
    main()
