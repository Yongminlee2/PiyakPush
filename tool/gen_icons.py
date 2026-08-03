# -*- coding: utf-8 -*-
"""앱 아이콘 후보 10종을 게임 팔레트로 그린다.

    python tool/gen_icons.py

`tool/icon_candidates/` 에 512x512 PNG 10장과 대조용 시트를 만든다.
시트에는 실제 런처 크기(48dp 상당)로 줄인 줄도 같이 넣는다 —
아이콘은 작게 줄였을 때 알아볼 수 있어야 고른 보람이 있다.
"""
import io, math, os, sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from PIL import Image, ImageDraw

S = 512                      # 캔버스
OUT = os.path.join(os.path.dirname(__file__), 'icon_candidates')

OUTLINE = (0x5D, 0x40, 0x37)
CREAM   = (0xFF, 0xF8, 0xE1)
YELLOW  = (0xFF, 0xE0, 0x82)
STAR    = (0xFF, 0xD5, 0x4F)
BEAK    = (0xFF, 0xA7, 0x26)
BLUSH   = (0xF8, 0xBB, 0xD0)
EGG     = (0xFF, 0xFD, 0xF2)
EGGSH   = (0xEC, 0xE4, 0xCE)
GRASS   = (0xC5, 0xE8, 0xB0)
GRASSD  = (0xB5, 0xDC, 0xA0)
NEST    = (0xE0, 0xB8, 0x78)
NESTD   = (0xC2, 0x9A, 0x58)
SKY     = (0xBF, 0xE5, 0xF5)
PINK    = (0xF4, 0x8F, 0xB1)
WHITE   = (0xFF, 0xFF, 0xFF)

LW = 11                      # 외곽선 두께 (512 기준)


def canvas(bg):
    im = Image.new('RGB', (S, S), bg)
    return im, ImageDraw.Draw(im)


def ell(d, box, fill, w=LW, outline=OUTLINE):
    d.ellipse(box, fill=fill, outline=outline, width=w)


def chick(d, cx, cy, r, wing=True, look=0):
    """정면 병아리. r = 몸통 반지름."""
    # 몸통
    ell(d, (cx - r, cy - r * 0.92, cx + r, cy + r * 1.02), YELLOW)
    # 머리 깃털
    d.line([(cx - r * 0.1, cy - r * 0.86), (cx - r * 0.02, cy - r * 1.28)],
           fill=OUTLINE, width=LW)
    d.line([(cx - r * 0.02, cy - r * 1.28), (cx + r * 0.24, cy - r * 1.06)],
           fill=OUTLINE, width=LW)
    # 눈
    er = r * 0.115
    for sx in (-0.34, 0.30):
        ex = cx + r * (sx + look * 0.06)
        d.ellipse((ex - er, cy - r * 0.28 - er, ex + er, cy - r * 0.28 + er),
                  fill=OUTLINE)
    # 부리
    bw = r * 0.24
    d.polygon([(cx - bw * 0.5, cy - r * 0.02), (cx + bw * 0.5, cy - r * 0.02),
               (cx, cy + r * 0.22)], fill=BEAK, outline=OUTLINE)
    # 볼
    for sx in (-0.62, 0.58):
        bx = cx + r * sx
        d.ellipse((bx - r * 0.15, cy - r * 0.02, bx + r * 0.15, cy + r * 0.2),
                  fill=BLUSH)
    if wing:
        d.arc((cx - r * 1.02, cy - r * 0.3, cx - r * 0.42, cy + r * 0.6),
              start=100, end=260, fill=OUTLINE, width=LW)


def chick_side(d, cx, cy, r, face=1):
    """옆모습 병아리. face=1이면 오른쪽을 본다."""
    ell(d, (cx - r, cy - r * 0.92, cx + r, cy + r * 1.02), YELLOW)
    d.line([(cx - face * r * 0.1, cy - r * 0.86),
            (cx - face * r * 0.05, cy - r * 1.3)], fill=OUTLINE, width=LW)
    d.line([(cx - face * r * 0.05, cy - r * 1.3),
            (cx + face * r * 0.22, cy - r * 1.08)], fill=OUTLINE, width=LW)
    er = r * 0.12
    ex = cx + face * r * 0.34
    d.ellipse((ex - er, cy - r * 0.3 - er, ex + er, cy - r * 0.3 + er),
              fill=OUTLINE)
    # 옆부리
    d.polygon([(cx + face * r * 0.82, cy - r * 0.06),
               (cx + face * r * 1.24, cy + r * 0.06),
               (cx + face * r * 0.82, cy + r * 0.2)],
              fill=BEAK, outline=OUTLINE)
    bx = cx + face * r * 0.5
    d.ellipse((bx - r * 0.15, cy + r * 0.02, bx + r * 0.15, cy + r * 0.24),
              fill=BLUSH)
    # 발
    for fx in (-0.3, 0.3):
        px = cx + r * fx
        d.line([(px, cy + r * 0.95), (px, cy + r * 1.2)], fill=BEAK, width=LW)


def egg(d, cx, cy, rw, rh, shine=True):
    ell(d, (cx - rw, cy - rh, cx + rw, cy + rh), EGG)
    if shine:
        d.ellipse((cx - rw * 0.42, cy - rh * 0.62,
                   cx - rw * 0.02, cy - rh * 0.18), fill=WHITE)


def nest(d, cx, cy, rw, rh):
    ell(d, (cx - rw, cy - rh, cx + rw, cy + rh), NEST)
    d.arc((cx - rw * 0.72, cy - rh * 0.5, cx + rw * 0.72, cy + rh * 0.9),
          start=200, end=340, fill=NESTD, width=int(LW * 0.8))


def arrow(d, x, y, size, color=STAR, direction='right'):
    h = size * 0.5
    if direction == 'right':
        pts = [(x, y - h * 0.5), (x + size * 0.55, y - h * 0.5),
               (x + size * 0.55, y - h), (x + size, y),
               (x + size * 0.55, y + h), (x + size * 0.55, y + h * 0.5),
               (x, y + h * 0.5)]
    else:  # up
        pts = [(x - h * 0.5, y), (x - h * 0.5, y - size * 0.55),
               (x - h, y - size * 0.55), (x, y - size),
               (x + h, y - size * 0.55), (x + h * 0.5, y - size * 0.55),
               (x + h * 0.5, y)]
    d.polygon(pts, fill=color, outline=OUTLINE)


def checker(d, cols=4, light=GRASS, dark=GRASSD):
    c = S / cols
    for r in range(cols):
        for k in range(cols):
            if (r + k) % 2:
                d.rectangle((k * c, r * c, (k + 1) * c, (r + 1) * c), fill=dark)


# ── 후보 10종 ────────────────────────────────────────────────

def icon01():
    """미는 순간 — 게임의 동작 그 자체"""
    im, d = canvas(GRASS)
    checker(d)
    nest(d, 380, 330, 92, 62)
    egg(d, 300, 300, 72, 88)
    chick_side(d, 148, 300, 92)
    return im, '01 미는 순간'


def icon02():
    """병아리 얼굴 — 작게 줄여도 가장 잘 보인다"""
    im, d = canvas(CREAM)
    chick(d, 256, 268, 168)
    return im, '02 병아리 얼굴'


def icon03():
    """알을 안은 병아리"""
    im, d = canvas(SKY)
    chick(d, 256, 250, 150, wing=False)
    egg(d, 256, 352, 84, 100)
    d.arc((70, 210, 250, 400), start=290, end=80, fill=OUTLINE, width=LW)
    d.arc((262, 210, 442, 400), start=100, end=250, fill=OUTLINE, width=LW)
    return im, '03 알을 안은'


def icon04():
    """둥지 위의 병아리 — 클리어의 상징"""
    im, d = canvas(CREAM)
    chick(d, 256, 210, 128)
    nest(d, 256, 386, 178, 84)
    return im, '04 둥지 위'


def icon05():
    """알 + 화살표 — 소코반임을 바로 알림"""
    im, d = canvas(GRASS)
    checker(d, 4)
    egg(d, 300, 256, 96, 118)
    arrow(d, 70, 256, 150)
    return im, '05 알과 화살표'


def icon06():
    """격자 위 병아리 — 퍼즐판 느낌"""
    im, d = canvas(GRASS)
    checker(d, 3)
    for i in range(1, 3):
        p = S / 3 * i
        d.line([(p, 0), (p, S)], fill=OUTLINE, width=5)
        d.line([(0, p), (S, p)], fill=OUTLINE, width=5)
    chick(d, 256, 256, 116)
    return im, '06 격자 위'


def icon07():
    """세 알 — 여러 알을 옮기는 게임"""
    im, d = canvas(CREAM)
    nest(d, 256, 392, 200, 88)
    egg(d, 152, 300, 62, 76)
    egg(d, 360, 300, 62, 76)
    egg(d, 256, 250, 70, 86)
    chick(d, 256, 150, 78, wing=False)
    return im, '07 세 알'


def icon08():
    """방향 화살표에 둘러싸인 병아리 — 조작 강조"""
    im, d = canvas(SKY)
    chick(d, 256, 268, 122)
    arrow(d, 256, 118, 92, direction='up')
    return im, '08 방향키'


def icon09():
    """알에서 갓 나온 병아리 — 브랜드 마크"""
    im, d = canvas(CREAM)
    # 아래 껍질
    d.pieslice((146, 210, 366, 430), start=0, end=180,
               fill=EGG, outline=OUTLINE, width=LW)
    chick(d, 256, 236, 104, wing=False)
    # 위 껍질 조각
    d.polygon([(150, 264), (196, 226), (240, 258), (286, 222),
               (330, 256), (362, 232), (362, 264)],
              fill=EGGSH, outline=OUTLINE)
    return im, '09 알에서 나온'


def icon10():
    """위에서 본 판 — 알 하나를 둥지로"""
    im, d = canvas(GRASS)
    checker(d, 3)
    nest(d, 400, 400, 78, 58)
    egg(d, 256, 256, 66, 80)
    chick(d, 118, 118, 82, wing=False)
    d.line([(180, 180), (326, 326)], fill=OUTLINE, width=8)
    arrow(d, 330, 330, 80)
    return im, '10 위에서 본 판'


ICONS = [icon01, icon02, icon03, icon04, icon05,
         icon06, icon07, icon08, icon09, icon10]


def rounded(im, radius=110):
    """런처에서 보이는 느낌으로 모서리를 둥글린다 (시트 전용)."""
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.size[0], im.size[1]),
                                           radius=radius, fill=255)
    out = Image.new('RGBA', im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    made = []
    for fn in ICONS:
        im, name = fn()
        num = name.split()[0]
        path = os.path.join(OUT, f'icon_{num}.png')
        im.save(path)
        made.append((im, name))
        print('그림', path)

    # 대조 시트: 큰 그림 5열 2줄 + 각 줄 아래에 작게 줄인 것
    cell, pad, small = 240, 18, 72
    cols, rows = 5, 2
    W = cols * (cell + pad) + pad
    H = rows * (cell + small + pad * 3) + pad
    sheet = Image.new('RGB', (W, H), (250, 248, 244))
    sd = ImageDraw.Draw(sheet)
    for i, (im, name) in enumerate(made):
        r, c = divmod(i, cols)
        x = pad + c * (cell + pad)
        y = pad + r * (cell + small + pad * 3)
        big = rounded(im.resize((cell, cell), Image.LANCZOS), radius=52)
        sheet.paste(big, (x, y), big)  # 알파를 마스크로 — 모서리가 검게 안 뜬다
        sd.text((x + 4, y + cell + 6), name, fill=(60, 50, 45))
        # 실제 런처 크기 근처로 줄여 보기
        tiny = rounded(im.resize((small, small), Image.LANCZOS), radius=16)
        sheet.paste(tiny, (x + cell // 2 - small // 2, y + cell + 26), tiny)
    sheet_path = os.path.join(OUT, 'sheet.png')
    sheet.save(sheet_path)
    print('시트', sheet_path)


if __name__ == '__main__':
    main()
