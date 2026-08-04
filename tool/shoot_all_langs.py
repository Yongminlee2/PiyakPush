# -*- coding: utf-8 -*-
"""13개 언어의 스토어 스크린샷을 폰에서 자동으로 찍는다.

    python tool/shoot_all_langs.py          # 전부
    python tool/shoot_all_langs.py ja ru    # 지정한 언어만

폰이 연결돼 있어야 하고, 앱이 설치돼 있어야 한다.
결과: store/screenshots/<언어코드>/01_title.png ...

언어를 바꿀 때 기기 설정을 건드리지 않고 **앱 안의 언어 선택**을 쓴다.
기기 언어는 adb로 못 바꾸고(루팅 필요), 앱 설정은 화면만 두드리면 되기 때문.
"""
import io, os, subprocess, sys, time

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADB = r'C:\workAndroid\android-sdk-ascii\platform-tools\adb.exe'
PKG = 'com.peep.puzzle'
OUT = os.path.join(ROOT, 'store', 'screenshots')

# 언어 선택 목록 순서 (lib/ui/strings_data.dart 의 kLangCodes 와 같아야 한다)
LANGS = ['ko', 'en', 'ja', 'zh', 'zh_Hant', 'es', 'fr',
         'de', 'pt', 'ru', 'th', 'vi', 'id']

# ── 화면 좌표 (1080×2400 기준, 실기기에서 확인한 값)
TITLE_START = (540, 1190)     # 타이틀 '시작'
TITLE_DAILY = (540, 1364)     # 타이틀 '데일리'
TITLE_SETTINGS = (540, 1884)  # 타이틀 '설정'
SETTINGS_LANG = (540, 355)    # 설정 '언어'
CHAPTER_2 = (540, 800)        # 챕터 목록 2번째 카드
CHAPTER_4 = (540, 1400)       # 챕터 목록 4번째 카드
STAGE_4 = (800, 780)          # 스테이지 격자 4번
STAGE_1 = (290, 380)          # 스테이지 격자 1번
HINT_BTN = (955, 180)         # 게임 화면 힌트

# 언어 목록: '기기 언어 따르기'가 0번, 그 뒤로 LANGS 순서
ROW0_Y = 1194                 # '기기 언어 따르기' 중앙 (안 밀었을 때)
ROW_H = 148                   # 줄 간격
VISIBLE_ROWS = 6              # 스크롤 없이 확실히 닿는 줄 수

# 목록을 끝까지 밀어 올렸을 때 **맨 아래 줄**(13번, Bahasa Indonesia)의 중앙.
# 아래쪽 언어는 "얼마나 밀렸는지"를 계산하면 안 된다 — 목록이 끝에 닿으면
# 요청한 만큼 안 밀리고, 그만큼 계산이 어긋나 엉뚱한 언어가 찍힌다.
# (실제로 마지막 언어가 그 앞 언어로 찍혔다.) 끝까지 민 다음 바닥에서 센다.
BOTTOM_LAST_Y = 2198


def sh(*args):
    subprocess.run([ADB, *args], capture_output=True)


def tap(xy, wait=1.2):
    sh('shell', 'input', 'tap', str(xy[0]), str(xy[1]))
    time.sleep(wait)


def swipe(x1, y1, x2, y2, ms=250, wait=0.6):
    sh('shell', 'input', 'swipe', str(x1), str(y1), str(x2), str(y2), str(ms))
    time.sleep(wait)


def back(wait=1.2):
    sh('shell', 'input', 'keyevent', 'KEYCODE_BACK')
    time.sleep(wait)


def shot(lang, name):
    d = os.path.join(OUT, lang)
    os.makedirs(d, exist_ok=True)
    p = os.path.join(d, f'{name}.png')
    with open(p, 'wb') as f:
        r = subprocess.run([ADB, 'exec-out', 'screencap', '-p'],
                           stdout=subprocess.PIPE)
        f.write(r.stdout)
    return os.path.getsize(p)


def restart_app():
    sh('shell', 'am', 'force-stop', PKG)
    time.sleep(1)
    sh('shell', 'monkey', '-p', PKG, '-c',
       'android.intent.category.LAUNCHER', '1')
    time.sleep(4)


def pick_language(code):
    """설정 → 언어 → 해당 언어 고르기. 타이틀에서 시작해 타이틀로 끝난다."""
    tap(TITLE_SETTINGS, 1.5)
    tap(SETTINGS_LANG, 1.5)

    idx = LANGS.index(code) + 1  # 0번은 '기기 언어 따르기'
    if idx <= VISIBLE_ROWS:
        y = ROW0_Y + idx * ROW_H
    else:
        # 끝까지 밀어 올린 다음 **바닥에서** 센다.
        # 세 번 미는 건 확실히 끝에 닿게 하려고 — 이미 끝이면 더 안 밀린다.
        for _ in range(3):
            swipe(540, 2100, 540, 900, 400, 0.8)
        y = BOTTOM_LAST_Y - (len(LANGS) - idx) * ROW_H
    tap((540, y), 1.5)
    back(1.5)  # 설정 → 타이틀


def capture_set(lang):
    """한 언어에서 스토어에 쓸 화면들을 찍는다."""
    n = 0
    shot(lang, '01_title'); n += 1

    tap(TITLE_START, 1.8)
    shot(lang, '02_chapters'); n += 1

    # 얼음 챕터 → 힌트 켠 화면
    tap(CHAPTER_2, 1.8)
    tap(STAGE_4, 2.0)
    shot(lang, '03_ice'); n += 1
    tap(HINT_BTN, 2.5)
    shot(lang, '04_hint'); n += 1

    # 단추와 문 챕터 → 풀어서 클리어 팝업
    back(1.0); back(1.0)
    tap(CHAPTER_4, 1.8)
    tap(STAGE_1, 2.0)
    shot(lang, '05_door'); n += 1
    for _ in range(4):
        swipe(540, 1600, 720, 1600, 250, 0.5)
    time.sleep(2.0)
    shot(lang, '06_clear'); n += 1

    # 데일리
    back(1.0); back(1.0); back(1.0)
    tap(TITLE_DAILY, 2.0)
    shot(lang, '07_daily'); n += 1
    back(1.5)
    return n


def main():
    targets = sys.argv[1:] or LANGS
    for code in targets:
        if code not in LANGS:
            print(f'모르는 언어: {code}')
            continue
        print(f'── {code}')
        restart_app()
        pick_language(code)
        n = capture_set(code)
        print(f'   {n}장')
    print()
    print('끝. store/screenshots/<언어>/ 확인')


if __name__ == '__main__':
    main()
