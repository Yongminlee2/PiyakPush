# 삐약푸시 (PiyakPush)

병아리가 알을 밀어 둥지에 넣는 소코반 퍼즐 게임. Flutter로 만들어 Android·iOS를 모두 지원한다 (v1은 Android 사이드로드, iOS는 코드 호환 유지).

## 게임 규칙

- 스와이프(또는 설정에서 D-패드 켜기)로 병아리를 상하좌우 한 칸씩 이동
- 알은 한 번에 하나만, 한 칸씩 밀 수 있다 (당기기 없음)
- 모든 알이 둥지 위에 오면 클리어. 이동수에 따라 별 1~3개
  - 3★ 최적수 이하 · 2★ 최적수 1.5배 이하 · 1★ 클리어
- 되돌리기 무제한, 힌트는 현재 상태 기준 다음 5수를 화살표로 표시

### 기믹 (챕터별 도입)

| 챕터 | 기믹 | 규칙 |
|---|---|---|
| 1 풀밭 | 기본 | 벽·알·둥지 |
| 2 얼음길 | 얼음 | 알만 미끄러진다. 비얼음 칸 진입 또는 막히면 정지. 병아리는 평범하게 걷는다 |
| 3 비밀 굴 | 텔레포트 | 굴 쌍(1↔2, 3↔4)으로 즉시 이동. 출구가 막히면 진입 불가. 나온 알은 그 자리에 정지 |
| 4 단추와 문 | 버튼·문 | 같은 색 버튼 위에 알·병아리가 있는 동안 문이 열린다. 문 위에 있으면 닫히지 않는다 |
| 5 금 간 바닥 | 붕괴+종합 | 금 간 바닥은 밟고 떠나면 구멍. 구멍엔 아무도 못 들어간다. 금 간 바닥 위 알을 밀면 병아리는 제자리 |

### 메타

- 별 누적 6개마다 스티커 1종 해금 (총 24종) → 스티커북·꾸미기 보드(드래그 배치, 저장됨)
- 데일리 퍼즐: 날짜 시드로 매일 새 퍼즐(항상 풀이 가능 보장), 달력 도장·연속 출석
- 챕터 해금: 이전 챕터에서 별 12개

## 빌드 (이 기계 전용 주의사항 포함)

한글 사용자명 때문에 **모든 경로를 ASCII로 강제**해야 한다. 매 셸 세션:

```powershell
$env:Path = "C:\flutter\bin;$env:Path"
$env:PUB_CACHE = "C:\flutter\.pub-cache"
$env:GRADLE_USER_HOME = "C:\workAndroid\gradle-user-ascii"
$env:TEMP = "C:\workAndroid\tmp-ascii"; $env:TMP = "C:\workAndroid\tmp-ascii"
```

- **TEMP/TMP 재지정 필수**: 기본 한글 temp면 flutter_tester가 0xC0000409로 즉사 → `flutter test`가 "Connection closed before test suite loaded"로 실패한다
- Android SDK: `C:\workAndroid\android-sdk-ascii` (`flutter config --android-sdk`), JDK: Android Studio JBR (`flutter config --jdk-dir`)

```powershell
flutter test                          # 전체 테스트 (엔진·솔버·레벨·UI 150+)
dart run tool/validate_levels.dart    # 레벨 전수 검증 + optimal 재기록
flutter build apk --release           # 릴리즈 APK
adb install -r build\app\outputs\flutter-apk\app-release.apk
flutter run -d web-server --web-port 8123   # 웹 미리보기 (개발용)
```

## 레벨 추가법

`assets/levels/chapterN.json`에 항목 추가:

```json
{"id": "c1s11", "chapter": 1, "title": "새 레벨", "rows": ["#####", "#@$o#", "#####"], "optimal": 0}
```

기호: `#`벽 `.`바닥 `@`병아리 `$`알 `o`둥지 `*`둥지 위 알 `+`둥지 위 병아리 `i`얼음 `c`금 간 바닥 `1~4`굴 쌍 `b`/`B`·`d`/`D` 버튼/문

이후 **반드시** `dart run tool/validate_levels.dart` 실행 — 풀이 불가면 실패하고, `optimal`을 솔버 실측값으로 채운다. 테스트(`test/levels/`)가 optimal 불일치를 잡으므로 CLI를 빼먹으면 커밋 전에 걸린다.

### 레벨 설계 시 함정 (실제로 밟은 것들)

- 알이 보드 가장자리 행/열에 있으면 수직/수평 밀기가 불가능해 데드락 나기 쉽다
- 굴 출구 칸 위의 알은 "출구 옆 칸"에서만 밀 수 있다 — 병아리는 굴 칸에 서 있을 수 없다(들어가면 순간이동)
- 금 간 바닥 위 알을 밀면 병아리가 못 따라간다 — 밀기 경로의 균열은 둥지 직전에만 배치
- 문 너머로 배달한 뒤 병아리가 돌아올 우회 통로가 있는지 확인 (문이 닫히면 갇힌다)

## 구조

- `lib/engine/` — 순수 Dart 게임 엔진 (Flutter import 금지): 보드·이동·기믹·데드락·BFS 솔버
- `lib/models/` — Level·Sticker, `lib/services/` — 저장·사운드·힌트·데일리·레벨 로더
- `lib/ui/` — 화면·위젯 (타일은 CustomPainter, 병아리·스티커는 `PiyakAssets` PNG 재활용)
- `tool/` — 레벨 검증 CLI, SFX 합성(`python tool/gen_sfx.py`), 데일리 프리셋 생성
- 설계 문서: `docs/superpowers/specs/`, 구현 계획: `docs/superpowers/plans/`
