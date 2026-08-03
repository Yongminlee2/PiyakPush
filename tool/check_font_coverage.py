# -*- coding: utf-8 -*-
"""번들한 Jua 폰트가 12개 언어 문자열을 실제로 그릴 수 있는지 검사한다.

    python tool/check_font_coverage.py

Jua는 한글용 폰트라 키릴·태국·가나·한자·악센트 붙은 라틴 글자가 없다.
없는 글자는 기기 기본 폰트로 대체되는데, 한 문장 안에서 글꼴이 섞이면
어색해 보인다. 그래서 언어별로 폰트를 갈아 끼운다 —
이 검사 결과가 `piyakTheme(useJua:)` 판단의 근거다.
"""
import io, os, re, sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IGNORE = set(" .!?,:;()·—…0123456789{}/'\"\\n+-")

NAMES = {'ko': '한국어', 'en': 'English', 'ja': '日本語', 'zh': '中文',
         'es': 'Español', 'fr': 'Français', 'de': 'Deutsch',
         'pt': 'Português', 'ru': 'Русский', 'th': 'ไทย',
         'vi': 'Tiếng Việt', 'id': 'Indonesia'}


def main():
    font = TTFont(os.path.join(ROOT, 'assets', 'fonts', 'Jua-Regular.ttf'))
    cmap = set()
    for t in font['cmap'].tables:
        cmap |= set(t.cmap.keys())

    src = io.open(os.path.join(ROOT, 'lib', 'ui', 'strings_data.dart'),
                  encoding='utf-8').read()
    blocks = re.split(r"^  '(\w+)': \{", src, flags=re.M)

    ok = []
    print('Jua 폰트 커버리지 — 앱이 실제로 쓰는 문자열 전부 검사')
    for i in range(1, len(blocks), 2):
        code, body = blocks[i], blocks[i + 1]
        if code not in NAMES:
            continue
        values = re.findall(r":\s*'((?:[^'\\]|\\.)*)'", body)
        chars = {c for v in values for c in v if c not in IGNORE}
        missing = sorted(c for c in chars if ord(c) not in cmap)
        if missing:
            print(f'  {NAMES[code]:11s} 없는 글자 {len(missing):3d}종  '
                  f'예: {"".join(missing[:12])}')
        else:
            print(f'  {NAMES[code]:11s} 전부 표시 가능')
            ok.append(code)

    print()
    print('Jua를 써도 되는 언어:', ok)
    print('나머지는 기기 기본 폰트로 그려야 글꼴이 섞이지 않는다.')


if __name__ == '__main__':
    main()
