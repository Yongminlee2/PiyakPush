# 삐약푸시 v2.1 — 게임 필·조이스틱·비주얼

- 날짜: 2026-08-02
- 상태: 승인됨
- 기반: v1 / v1.1 / v2 스펙

## 배경

v2 플레이 피드백 세 가지: ①움직임이 여전히 딱딱 끊긴다 ②방향키가 불편하다
③UI를 더 예쁘게. 기존 codex 생성 이미지(1,181장 단어 그림 + 배경·씬)를
재활용해도 좋다는 허락과, 부족한 그림은 codex에 의뢰해도 좋다는 허락을 받았다.

## 1. 연속 이동 — 끊김의 근본 원인 제거

v1.1에서 시간(160ms)은 맞췄지만 **속도 곡선**이 문제였다. 매 칸 easeInOut이라
칸 경계마다 속도가 0으로 떨어졌다 다시 가속한다. 여기에 홀드 시작 후 320ms
공백이 겹친다.

- 방향이 **눌려 있는 동안**: 곡선 `Curves.linear`(등속), 이동 발행 간격 =
  `kMoveAnim`(160ms)과 정확히 일치. 시작 지연 없이 첫 이동 직후부터 연달아 발행.
- 손을 뗀 뒤 **마지막 칸만** `Curves.easeOut`으로 감속.
- 입력 방향이 바뀌면 즉시 새 방향으로 이어간다 (홀드 유지).
- 구현: `BoardView`에 `bool gliding`(홀드 중 여부)을 내려 곡선을 고른다.
  이동 발행은 화면(GameScreen)이 `Timer.periodic(kMoveAnim)`으로 잡는다.

### 걸음 연출

- 홉 + **좌우 뒤뚱 교차**: 스텝마다 기울기 부호를 번갈아(왼발·오른발 느낌).
- **착지 스쿼시**: 홉이 끝나는 프레임에 세로 0.92→1.0 복원(80ms).
- **알 반동**: 알이 밀리기 시작할 때 진행 방향으로 살짝 찌그러졌다(가로 0.9)
  복원. `EggWidget`을 스텝 트리거를 받는 stateful로 바꾼다.

## 2. 가상 조이스틱 (십자키·스와이프 대체)

- 보드 아래 영역(HUD·보드 제외한 하단 밴드) 아무 곳이나 터치하면 그 지점에
  조이스틱 베이스(반투명 링 + 노브)가 나타난다.
- 드래그 오프셋이 **데드존 18px**을 넘으면 상하좌우 중 가까운 4방향으로 스냅해
  그 방향을 "눌린 상태"로 유지 → 1절의 연속 이동이 걸린다.
- 노브는 오프셋을 따라가되 최대 반경 56px로 제한. 손을 떼면 사라진다.
- 기존 `DPad` 위젯, 게임 화면 스와이프 제스처, 설정의 D-패드 토글을 **제거**한다.
  (`SaveService.dpadOn`은 저장 키만 남고 읽지 않는다 — 키 정리는 하지 않는다.)
- 파일: `lib/ui/widgets/joystick.dart` 신규, `dpad.dart` 삭제.

## 3. 비주얼

### 3.1 폰트

- Google Fonts의 **Jua**(단일 웨이트, OFL)를 다운로드해 `assets/fonts/Jua.ttf`로
  번들하고 `piyakTheme()`의 `fontFamily`로 전역 적용한다. 다운로드는 사용자가
  명시적으로 허락했다. OFL 라이선스 파일도 `assets/fonts/OFL.txt`로 함께 둔다.

### 3.2 기존 이미지 재활용 (codex 의뢰 불필요분)

| 용도 | 파일 | 적용 |
|---|---|---|
| 타이틀·1막 배경 | `PiyakAssets/banner/banner_grass.png` | 화면 배경(하단 정렬, 위는 크림색으로 페이드) |
| 2막 배경 | `banner_sky.png` | 챕터 6~10의 게임 화면 배경 |
| 3막 배경 | `banner_class.png` | 챕터 11~15 |
| 4막 배경 | `banner_night.png` | 챕터 16~20 |
| 알 몸통 | `PiyakAssets/words/word_egg.png` | PNG 위에 기존 페인터의 눈·볼터치·행복 표정만 오버레이 |

배경은 `Stack` 최하층에 `Image.asset(fit: cover, opacity 약화)`로 깔고 보드
패널이 그 위에 얹힌다. 게임 화면 배경은 챕터 번호로 막을 판정해 고른다.
타이틀·챕터·데일리 화면은 banner_grass 고정.

### 3.3 타일 PNG 계층 + codex 의뢰서

- `assets/images/tiles/` 아래 해당 파일이 있으면 PNG로 그리고, 없으면 기존
  CustomPainter로 그린다. 판정은 앱 시작 시 `AssetManifest`로 한 번만 한다.
  (`TileArt.load()` → `Map<Tile, ImageProvider?>`)
- codex 의뢰서를 `docs/codex-art-request.md`로 작성한다. 내용:
  - 스타일 가이드: 진갈색 외곽선 `#5D4037` 두껍게, 파스텔 채움, 볼터치 무드,
    512×512 PNG, 배경 투명, 여백 최소
  - 목록: `tile_grass.png`(밝은 잔디 정사각), `tile_wall.png`(울타리 블록),
    `tile_nest.png`(지푸라기 둥지), `tile_ice.png`(광택 얼음), `tile_portal_purple.png`,
    `tile_portal_orange.png`(굴 두 색), `tile_button_pink.png`, `tile_door_pink.png`,
    `tile_button_blue.png`, `tile_door_blue.png`, `tile_cracked.png`(금 간 바닥),
    `logo.png`(가로형 "삐약푸시" 로고, 병아리 포함, 1024×512)
  - 완성 후 넣을 위치와 확인 방법
- 로고 PNG가 도착하기 전까지 타이틀은 지금 텍스트 로고를 유지한다
  (`assets/images/tiles/logo.png` 존재 시 이미지로 교체하는 같은 계층).

### 3.4 화면 전환·버튼 반동

- 모든 `MaterialPageRoute`를 공용 `piyakRoute(page)`로 교체: 페이드 + 아래서
  6% 떠오르는 220ms 전환.
- 메뉴 버튼·조이스틱 노브에 눌림 스케일(0.96) 반동.
- 클리어 팝업 카드 등장을 `elasticOut` 스케일로.

## 4. 테스트 전략

- 연속 이동: `GameController`는 불변이므로 화면 레벨 위젯 테스트 —
  조이스틱 홀드 시뮬레이션(포인터 다운→드래그→2×kMoveAnim 대기) 후 이동수 ≥ 2 확인.
- 조이스틱: 데드존 안 드래그 = 이동 0, 오른쪽 드래그 = 오른쪽 이동, 방향 전환.
- TileArt: 매니페스트에 없는 파일이면 null(페인터 폴백) 반환.
- 기존 테스트 중 DPad 참조는 조이스틱으로 교체.
- 애니메이션 수치(곡선·기울기·스쿼시)는 테스트하지 않는다.

## 5. 범위 제외

- 레벨·규칙 변경 없음, 새 의존성 없음(폰트는 에셋)
- codex 그림 제작 자체(의뢰서만 산출물 — 실행은 사용자가 codex에게)
- 배경음악
