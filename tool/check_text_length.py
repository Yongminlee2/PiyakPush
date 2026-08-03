# -*- coding: utf-8 -*-
"""언어별 문구 길이를 재서 화면에서 잘릴 위험을 미리 본다.

    python tool/check_text_length.py

버튼처럼 자리가 좁은 곳에 긴 번역이 들어가면 줄바꿈되거나 잘린다.
독일어·러시아어가 대체로 가장 길다. 실기기에서 12개 언어를 다 눌러보기
전에, 어디를 눈여겨봐야 하는지 목록으로 뽑아 둔다.
"""
import io, os, re, sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 자리가 좁은 곳 — 버튼·배지·HUD
TIGHT = ['start', 'daily', 'stickerBook', 'decoBoard', 'settings', 'undo',
         'restart', 'hint', 'next', 'list', 'moves', 'optimal', 'cancel',
         'ok', 'clear', 'nextChapter', 'toTitle', 'streak', 'dailyPlay']

# 여러 줄이 허용되는 안내문
LONG = ['tutorial1', 'tutorial1Dpad', 'deadlockHint', 'lockedChapter',
        'allCleared', 'hintHowTo', 'ctlJoystick', 'needMoreClears']


def parse():
    src = io.open(os.path.join(ROOT, 'lib', 'ui', 'strings_data.dart'),
                  encoding='utf-8').read()
    blocks = re.split(r"^  '(\w+)': \{", src, flags=re.M)
    out = {}
    for i in range(1, len(blocks), 2):
        body = blocks[i + 1]
        vals = {}
        # 작은따옴표 / 큰따옴표 두 형태 모두
        for k, v in re.findall(r"'(\w+)':\s*'((?:[^'\\]|\\.)*)'", body):
            vals[k] = v
        for k, v in re.findall(r"'(\w+)':\s*\"([^\"]*)\"", body):
            vals[k] = v
        out[blocks[i]] = vals
    return out


def main():
    data = parse()
    ko = data['ko']

    print('■ 좁은 자리 — 12자 넘으면 눈여겨볼 것')
    rows = []
    for code, vals in data.items():
        if code == 'ko':
            continue
        for k in TIGHT:
            if k in vals and len(vals[k]) >= 12:
                rows.append((len(vals[k]), code, k, vals[k]))
    rows.sort(reverse=True)
    for n, code, k, v in rows[:15]:
        print(f'  {n:2d}자  {code}/{k:<12s} "{v}"')
    if not rows:
        print('  없음')

    print()
    print('■ 안내문 — 한국어 대비 길이 배수 (2배 넘으면 줄이 늘어난다)')
    worst = []
    for code, vals in data.items():
        if code == 'ko':
            continue
        for k in LONG:
            if k in vals and k in ko and ko[k]:
                ratio = len(vals[k]) / len(ko[k])
                if ratio >= 1.8:
                    worst.append((ratio, code, k, len(vals[k])))
    worst.sort(reverse=True)
    for r, code, k, n in worst[:12]:
        print(f'  {r:.1f}배  {code}/{k:<16s} {n}자')
    if not worst:
        print('  없음')


if __name__ == '__main__':
    main()
