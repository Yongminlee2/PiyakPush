# 삐약푸시 v1.1 폴리시 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 실기기 피드백 5건(삐약 울음소리·방향키 확대·챕터 전환 버그·디자인 개선·이동 부드럽게)을 반영해 v1.1을 실기기에 설치한다.

**Architecture:** 진행 판정(다음 스테이지/챕터)을 순수 Dart 함수로 분리해 화면에서 떼어내고, 나머지는 기존 위젯·페인터·사운드 서비스를 제자리에서 개선한다. 엔진(`lib/engine/`)은 건드리지 않는다 — 게임 규칙은 그대로다.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12.2 / provider / shared_preferences / audioplayers / Python 3.12(SFX 합성)

## Global Constraints

- 스펙: `docs/superpowers/specs/2026-08-02-piyakpush-v11-polish-design.md` (충돌 시 스펙 우선)
- `lib/engine/` 아래는 이번 작업에서 **수정 금지** — 게임 규칙 변경 없음
- 런타임 의존성 추가 금지 (`provider`, `shared_preferences`, `audioplayers` 3개 유지). 꽃가루·파티클도 외부 패키지 없이 CustomPainter로 구현
- 한국어 UI 문자열은 전부 `lib/ui/strings.dart`의 `S`를 통해서만 사용
- 애니메이션 시간(ms)·색상 값은 테스트하지 않는다 — 시각 튜닝 값이라 테스트가 변경을 방해한다
- 매 셸 세션 선행 (한글 사용자명 회피, 빼먹으면 `flutter test`가 "Connection closed before test suite loaded"로 실패):
  ```powershell
  $env:Path = "C:\flutter\bin;$env:Path"; $env:PUB_CACHE = "C:\flutter\.pub-cache"; $env:GRADLE_USER_HOME = "C:\workAndroid\gradle-user-ascii"; $env:TEMP = "C:\workAndroid\tmp-ascii"; $env:TMP = "C:\workAndroid\tmp-ascii"
  ```
- 작업 디렉터리: `C:\workAndroid\PiyakPush`
- 커밋 메시지는 한국어 요약 + 마지막 줄 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- 기존 테스트 154개는 계속 통과해야 한다 (이 계획이 명시적으로 갱신하는 것 제외)

## File Structure

| 파일 | 책임 | 상태 |
|---|---|---|
| `lib/models/progression.dart` | 다음 스테이지/챕터 판정 (순수 Dart) | 신규 |
| `lib/ui/widgets/confetti.dart` | 클리어 꽃가루 파티클 페인터 | 신규 |
| `tool/gen_sfx.py` | 삐약 처프 3종 합성 추가, move 제거 | 수정 |
| `lib/services/sound_service.dart` | 이동음 처프 순환 | 수정 |
| `lib/ui/widgets/dpad.dart` | 버튼 확대, 반복 간격 | 수정 |
| `lib/ui/widgets/board_view.dart` | 이동 타이밍, 막힘 흔들림 | 수정 |
| `lib/ui/widgets/tile_painter.dart` | 잔디·지푸라기·벽 그림자·알 광택 | 수정 |
| `lib/ui/widgets/clear_popup.dart` | 별 표시 수정, 문구/버튼 가변, 꽃가루 | 수정 |
| `lib/ui/screens/game_screen.dart` | 레이아웃 재배치, 보드 패널, 흔들림 배선, ClearOutcome | 수정 |
| `lib/ui/screens/stage_screen.dart` | 진행 판정 배선 | 수정 |
| `lib/ui/screens/title_screen.dart` | 로고 패널·진행바·강조 버튼 | 수정 |
| `lib/ui/screens/chapter_screen.dart` | 테마색 스트립·진행바 | 수정 |
| `lib/ui/theme.dart` | 보드 패널색·챕터 테마색 추가 | 수정 |
| `lib/ui/strings.dart` | 챕터 전환 문구 추가 | 수정 |
| `lib/services/save_service.dart` | 해금 기준 상수 공유 | 수정 |

---

### Task 1: 삐약 울음소리 (처프 3종 순환)

**Files:**
- Modify: `tool/gen_sfx.py`
- Modify: `lib/services/sound_service.dart`
- Modify: `test/services/sound_service_test.dart`
- Delete: `assets/audio/move.wav`
- Create: `assets/audio/chirp1.wav`, `chirp2.wav`, `chirp3.wav` (스크립트가 생성)

**Interfaces:**
- Produces: `SoundService.play(Sfx.move)`가 `audio/chirp1.wav` → `chirp2` → `chirp3` → `chirp1` 순으로 순환. 음소거 상태에서는 인덱스가 진행하지 않는다. 그 외 `Sfx`는 기존대로 `audio/<name>.wav`.

- [ ] **Step 1: 실패하는 테스트 작성**

`test/services/sound_service_test.dart`의 기존 `'재생 시 에셋 경로'` 테스트 아래에 추가:

```dart
  test('이동음은 처프 3종을 순환한다', () async {
    final played = <String>[];
    final s = SoundService(
        isMuted: () => false, playOverride: (a) async => played.add(a));
    for (var i = 0; i < 4; i++) {
      await s.play(Sfx.move);
    }
    expect(played, [
      'audio/chirp1.wav',
      'audio/chirp2.wav',
      'audio/chirp3.wav',
      'audio/chirp1.wav',
    ]);
  });

  test('음소거 중엔 처프 순번이 진행하지 않는다', () async {
    var muted = true;
    final played = <String>[];
    final s = SoundService(
        isMuted: () => muted, playOverride: (a) async => played.add(a));
    await s.play(Sfx.move);
    muted = false;
    await s.play(Sfx.move);
    expect(played, ['audio/chirp1.wav']);
  });
```

같은 파일의 기존 이벤트 매핑 테스트에서 `'audio/move.wav'`를 `'audio/chirp1.wav'`로 바꾼다:

```dart
    expect(played, [
      'audio/chirp1.wav',
      'audio/push.wav',
      'audio/slide.wav',
      'audio/clear.wav',
    ]);
```

- [ ] **Step 2: 실행해 실패 확인**

Run: `flutter test --no-pub test/services/sound_service_test.dart`
Expected: FAIL — 실제 `audio/move.wav`가 재생되어 기대값과 불일치

- [ ] **Step 3: 처프 합성 추가**

`tool/gen_sfx.py`에서 `write_wav("move", tone(660, 60, 0.35, "square"))` 줄을 지우고, 그 자리에 넣는다:

```python
def chirp(base, ms=110, vol=0.42):
    """2음절 삐약: 앞 40% 상승, 뒤 60% 하강."""
    n = int(SR * ms / 1000)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / n
        if t < 0.4:
            f = base * (1.0 + 0.55 * (t / 0.4))
        else:
            f = base * (1.55 - 0.85 * ((t - 0.4) / 0.6))
        phase += 2 * math.pi * f / SR
        v = math.sin(phase) + 0.25 * math.sin(2 * phase)
        out.append(v * vol * env(i, n, attack=0.008))
    return out


write_wav("chirp1", chirp(900))
write_wav("chirp2", chirp(980))
write_wav("chirp3", chirp(850))
```

- [ ] **Step 4: 소리 파일 생성**

```powershell
& "C:\Users\사용자\AppData\Local\Programs\Python\Python312\python.exe" tool\gen_sfx.py
```
Expected: `chirp1/2/3.wav` 생성 로그. 이어서 옛 파일 삭제:
```powershell
Remove-Item assets\audio\move.wav
```

- [ ] **Step 5: 순환 재생 구현**

`lib/services/sound_service.dart`의 `play`를 다음으로 교체하고 필드를 추가한다:

```dart
  /// 이동음은 처프 3종을 돌려써서 걸을 때 기계음처럼 들리지 않게 한다.
  int _chirp = 0;

  String _assetFor(Sfx s) {
    if (s != Sfx.move) return 'audio/${s.name}.wav';
    _chirp = (_chirp % 3) + 1;
    return 'audio/chirp$_chirp.wav';
  }

  Future<void> play(Sfx s) async {
    if (isMuted()) return; // 음소거면 순번도 진행하지 않는다
    final asset = _assetFor(s);
    if (playOverride != null) {
      await playOverride!(asset);
      return;
    }
    final p = AudioPlayer();
    p.onPlayerComplete.listen((_) => p.dispose());
    await p.play(AssetSource(asset), mode: PlayerMode.lowLatency);
  }
```

- [ ] **Step 6: 통과 확인**

Run: `flutter test --no-pub test/services/sound_service_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 7: 커밋**

```powershell
git add -A; git commit -m "삐약 울음소리: 2음절 처프 3종 합성 + 순환 재생

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: 방향키 확대 (A안)

**Files:**
- Modify: `lib/ui/widgets/dpad.dart`

**Interfaces:**
- Consumes: 없음
- Produces: `DPad(onDir:)` 시그니처 불변. 버튼 76px, 아이콘 48px, 십자 중앙 간격 76px, 터치 여백 6px.

- [ ] **Step 1: 크기 상수 적용**

`lib/ui/widgets/dpad.dart` 상단에 상수를 추가하고 하드코딩된 값을 대체한다:

```dart
const double _kBtn = 76; // 버튼 한 변
const double _kIcon = 48;
const double _kPad = 6; // 보이는 크기 밖 터치 여유
```

`DPad.build`의 `SizedBox(width: 60)`를 `SizedBox(width: _kBtn)`로 바꾼다(십자 중앙 간격 = 버튼 한 칸).

`_DPadButtonState.build`의 `Container`를 `Padding` + `Container` 조합으로 바꿔 터치 영역을 넓힌다:

```dart
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      behavior: HitTestBehavior.opaque, // 여백까지 터치를 받는다
      child: Padding(
        padding: const EdgeInsets.all(_kPad),
        child: Container(
          width: _kBtn,
          height: _kBtn,
          decoration: BoxDecoration(
            color: _pressed
                ? PiyakColors.chickYellow
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PiyakColors.outline, width: 2.5),
            boxShadow: _pressed
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x335D4037),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Icon(widget.icon, size: _kIcon, color: PiyakColors.outline),
        ),
      ),
    );
  }
```

기존 `margin: const EdgeInsets.all(2)`는 제거한다(Padding이 대신한다).

- [ ] **Step 2: 기존 방향키 테스트 통과 확인**

Run: `flutter test --no-pub test/ui/game_screen_test.dart`
Expected: PASS — 특히 `'방향키가 기본 표시되고 탭으로 이동'`

- [ ] **Step 3: 커밋**

```powershell
git add -A; git commit -m "방향키 확대: 버튼 76px·아이콘 48px·터치 여백 6px

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: 진행 판정 순수 함수

**Files:**
- Create: `lib/models/progression.dart`
- Create: `test/models/progression_test.dart`
- Modify: `lib/services/save_service.dart` (해금 기준 상수 공유)

**Interfaces:**
- Produces (Task 4가 소비):
  - `sealed class NextStep`
  - `class NextInChapter extends NextStep { final int index; }`
  - `class NextChapter extends NextStep { final int chapter; }`
  - `class ChapterLocked extends NextStep { final int chapter; final int starsNeeded; }`
  - `class AllChaptersCleared extends NextStep {}`
  - `const int kChapterUnlockStars = 12;`
  - `const int kChapterCount = 5;`
  - `NextStep resolveNextStep({required int chapter, required int index, required int levelCount, required int currentChapterStars, int chapterCount = kChapterCount})`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/models/progression_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/progression.dart';

void main() {
  test('챕터 중간이면 같은 챕터 다음 스테이지', () {
    final s = resolveNextStep(
        chapter: 1, index: 3, levelCount: 10, currentChapterStars: 9);
    expect(s, isA<NextInChapter>());
    expect((s as NextInChapter).index, 4);
  });

  test('챕터 마지막 + 별 12개 이상이면 다음 챕터', () {
    final s = resolveNextStep(
        chapter: 1, index: 9, levelCount: 10, currentChapterStars: 12);
    expect(s, isA<NextChapter>());
    expect((s as NextChapter).chapter, 2);
  });

  test('챕터 마지막 + 별 부족이면 잠김과 부족분', () {
    final s = resolveNextStep(
        chapter: 2, index: 9, levelCount: 10, currentChapterStars: 9);
    expect(s, isA<ChapterLocked>());
    expect((s as ChapterLocked).chapter, 3);
    expect(s.starsNeeded, 3);
  });

  test('마지막 챕터 마지막 스테이지면 전체 클리어', () {
    final s = resolveNextStep(
        chapter: 5, index: 9, levelCount: 10, currentChapterStars: 30);
    expect(s, isA<AllChaptersCleared>());
  });

  test('마지막 챕터는 별이 모자라도 잠김이 아니라 전체 클리어', () {
    final s = resolveNextStep(
        chapter: 5, index: 9, levelCount: 10, currentChapterStars: 3);
    expect(s, isA<AllChaptersCleared>());
  });
}
```

- [ ] **Step 2: 실행해 실패 확인**

Run: `flutter test --no-pub test/models/progression_test.dart`
Expected: FAIL — `progression.dart` 없음

- [ ] **Step 3: 구현**

`lib/models/progression.dart`:

```dart
/// 스테이지를 깬 뒤 "다음에 무엇을 할지" 판정. 화면 없이 테스트할 수 있도록
/// 순수 함수로 둔다 — v1에서 챕터 마지막 스테이지에 다음 경로가 없던 결손을
/// 재발시키지 않기 위한 분리다.
library;

const int kChapterUnlockStars = 12;
const int kChapterCount = 5;

sealed class NextStep {
  const NextStep();
}

/// 같은 챕터의 [index] 번째 스테이지로 이어서 플레이.
class NextInChapter extends NextStep {
  final int index;
  const NextInChapter(this.index);
}

/// [chapter] 챕터로 넘어간다.
class NextChapter extends NextStep {
  final int chapter;
  const NextChapter(this.chapter);
}

/// [chapter] 챕터가 별 [starsNeeded] 개 부족으로 잠겨 있다.
class ChapterLocked extends NextStep {
  final int chapter;
  final int starsNeeded;
  const ChapterLocked(this.chapter, this.starsNeeded);
}

/// 마지막 챕터의 마지막 스테이지까지 끝냈다.
class AllChaptersCleared extends NextStep {
  const AllChaptersCleared();
}

NextStep resolveNextStep({
  required int chapter,
  required int index,
  required int levelCount,
  required int currentChapterStars,
  int chapterCount = kChapterCount,
}) {
  if (index + 1 < levelCount) return NextInChapter(index + 1);
  if (chapter >= chapterCount) return const AllChaptersCleared();
  if (currentChapterStars >= kChapterUnlockStars) {
    return NextChapter(chapter + 1);
  }
  return ChapterLocked(chapter + 1, kChapterUnlockStars - currentChapterStars);
}
```

- [ ] **Step 4: SaveService가 같은 상수를 쓰게 한다**

`lib/services/save_service.dart` 상단에 import를 추가하고:

```dart
import '../models/progression.dart';
```

`chapterUnlocked`의 하드코딩 12를 상수로 바꾼다:

```dart
  bool chapterUnlocked(int c) =>
      c == 1 || chapterStars(c - 1) >= kChapterUnlockStars;
```

- [ ] **Step 5: 통과 확인**

Run: `flutter test --no-pub test/models/ test/services/save_service_test.dart`
Expected: PASS

- [ ] **Step 6: 커밋**

```powershell
git add -A; git commit -m "진행 판정 순수 함수 분리 (resolveNextStep) + 해금 기준 상수 공유

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: 챕터 전환 배선 (버그 수정)

**Files:**
- Modify: `lib/ui/strings.dart`
- Modify: `lib/ui/widgets/clear_popup.dart`
- Modify: `lib/ui/screens/game_screen.dart`
- Modify: `lib/ui/screens/stage_screen.dart`
- Modify: `test/ui/game_screen_test.dart`

**Interfaces:**
- Consumes: Task 3의 `resolveNextStep`, `NextInChapter`, `NextChapter`, `ChapterLocked`, `AllChaptersCleared`
- Produces:
  - `class ClearOutcome { final String? nextLabel; final VoidCallback? onNext; final String? note; const ClearOutcome({this.nextLabel, this.onNext, this.note}); }` (game_screen.dart에 선언)
  - `GameScreen`에 `final ClearOutcome Function()? clearOutcome;` 추가 — 클리어 팝업을 그릴 때 호출되므로 별이 저장된 뒤의 최신 상태를 읽는다. null이면 기존 `onNext`로 동작한다.
  - `ClearPopup`에 `String nextLabel`, `String? note` 추가

- [ ] **Step 1: 문구 추가**

`lib/ui/strings.dart`의 `S` 안에 추가:

```dart
  static const nextChapter = '다음 챕터';
  static const chapterCleared = '챕터 클리어!';
  static const allCleared = '모든 챕터 클리어! 대단해요!';
  static const toTitle = '처음으로';

  static String needMoreStars(int n) => '별 $n개만 더 모으면 다음 챕터가 열려요';
```

- [ ] **Step 2: 실패하는 테스트 작성**

`test/ui/game_screen_test.dart`에 추가:

```dart
  testWidgets('clearOutcome의 문구와 버튼이 팝업에 반영된다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
        level: lv(['#####', '#@\$o#', '#####'], optimal: 1),
        clearOutcome: () => const ClearOutcome(
            note: '별 3개만 더 모으면 다음 챕터가 열려요'),
      ),
    ));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.keyboard_arrow_right_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('별 3개만 더 모으면 다음 챕터가 열려요'), findsOneWidget);
    expect(find.text('다음'), findsNothing); // onNext 없으면 다음 버튼도 없다
    await tester.pump(const Duration(seconds: 2));
    await cleanup(tester);
  });

  testWidgets('clearOutcome이 없으면 기존 onNext가 다음 버튼으로 뜬다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
        level: lv(['#####', '#@\$o#', '#####'], optimal: 1),
        onNext: () {},
      ),
    ));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.keyboard_arrow_right_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('다음'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await cleanup(tester);
  });
```

파일 상단 import에 추가: `import 'package:piyak_push/ui/screens/game_screen.dart';`는 이미 있으므로 그대로 둔다.

- [ ] **Step 3: 실행해 실패 확인**

Run: `flutter test --no-pub test/ui/game_screen_test.dart`
Expected: FAIL — `clearOutcome` 파라미터 없음(컴파일 에러)

- [ ] **Step 4: ClearPopup에 문구·버튼 라벨 추가**

`lib/ui/widgets/clear_popup.dart`의 생성자와 필드에 추가하고, 버튼 행 위에 note를 그린다:

```dart
  final String nextLabel;
  final String? note;
```
생성자 파라미터에 `this.nextLabel = S.next, this.note,` 추가.

`Text('${S.moves} ${widget.moves} / ${S.optimal} ${widget.optimal}')` 아래에 삽입:

```dart
              if (widget.note != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.note!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PiyakColors.outline),
                ),
              ],
```

버튼 행의 `FilledButton`의 라벨을 `Text(widget.nextLabel)`로 바꾼다.

- [ ] **Step 5: GameScreen에 ClearOutcome 배선**

`lib/ui/screens/game_screen.dart` 파일 상단(클래스 밖)에 추가:

```dart
/// 클리어 팝업이 무엇을 보여줄지 — 진행 판정 결과를 화면이 이해하는 형태로 옮긴 것.
class ClearOutcome {
  final String? nextLabel;
  final VoidCallback? onNext;
  final String? note;
  const ClearOutcome({this.nextLabel, this.onNext, this.note});
}
```

`GameScreen`에 필드·생성자 파라미터 추가:

```dart
  /// 팝업을 그리는 시점에 호출된다 — 이 스테이지의 별이 저장된 뒤라야
  /// 다음 챕터 해금 여부를 정확히 판정할 수 있기 때문이다.
  final ClearOutcome Function()? clearOutcome;
```

`build`의 클리어 분기를 교체:

```dart
            if (c.cleared)
              Builder(builder: (context) {
                final outcome = widget.clearOutcome?.call() ??
                    ClearOutcome(nextLabel: S.next, onNext: widget.onNext);
                return Positioned.fill(
                  child: ClearPopup(
                    stars: c.stars,
                    moves: c.moves,
                    optimal: widget.level.optimal,
                    nextLabel: outcome.nextLabel ?? S.next,
                    note: outcome.note,
                    onNext: outcome.onNext,
                    onRetry: _restart,
                    onList: Navigator.canPop(context)
                        ? () => Navigator.pop(context)
                        : null,
                  ),
                );
              }),
```

- [ ] **Step 6: 통과 확인**

Run: `flutter test --no-pub test/ui/game_screen_test.dart`
Expected: PASS

- [ ] **Step 7: StageScreen에서 진행 판정 사용**

`lib/ui/screens/stage_screen.dart`에 import 추가:

```dart
import '../../models/progression.dart';
```

`_gameRoute`의 `onNext:` 줄을 지우고 `clearOutcome:`으로 교체한다:

```dart
  Route _gameRoute(BuildContext context, List<Level> levels, int idx) {
    final save = context.read<SaveService>();
    final sound = context.read<SoundService>();
    final level = levels[idx];
    return MaterialPageRoute(
      builder: (_) => GameScreen(
        key: ValueKey(level.id),
        level: level,
        showDpad: save.dpadOn,
        hintProvider: (c) => hintFor(c.board),
        onEvents: sound.playForEvents,
        onCleared: (stars) => save.setStars(level.id, stars),
        clearOutcome: () => _outcomeFor(context, levels, idx),
      ),
    );
  }

  /// 팝업이 그려질 때 호출된다 — 방금 딴 별까지 반영된 상태로 판정한다.
  ClearOutcome _outcomeFor(BuildContext context, List<Level> levels, int idx) {
    final save = context.read<SaveService>();
    final step = resolveNextStep(
      chapter: chapter,
      index: idx,
      levelCount: levels.length,
      currentChapterStars: save.chapterStars(chapter),
    );
    return switch (step) {
      NextInChapter(:final index) => ClearOutcome(
          nextLabel: S.next,
          onNext: () => Navigator.pushReplacement(
              context, _gameRoute(context, levels, index)),
        ),
      NextChapter(:final chapter) => ClearOutcome(
          nextLabel: S.nextChapter,
          note: S.chapterCleared,
          onNext: () {
            Navigator.pop(context); // 게임 화면을 닫고
            Navigator.pushReplacement( // 스테이지 목록을 다음 챕터로 교체
                context,
                MaterialPageRoute(
                    builder: (_) => StageScreen(chapter: chapter)));
          },
        ),
      ChapterLocked(:final starsNeeded) =>
        ClearOutcome(note: S.needMoreStars(starsNeeded)),
      AllChaptersCleared() => ClearOutcome(
          nextLabel: S.toTitle,
          note: S.allCleared,
          onNext: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
    };
  }
```

- [ ] **Step 8: 전체 테스트 + 정적 분석**

Run: `flutter analyze` 그리고 `flutter test --no-pub`
Expected: analyze 0 issues, 전체 PASS

- [ ] **Step 9: 커밋**

```powershell
git add -A; git commit -m "챕터 마지막 스테이지에서 다음 챕터로 이어지도록 수정 (v1 결손)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: 클리어 팝업 별 표시 수정 + 꽃가루

**Files:**
- Create: `lib/ui/widgets/confetti.dart`
- Modify: `lib/ui/widgets/clear_popup.dart`
- Create: `test/ui/clear_popup_test.dart`

**Interfaces:**
- Consumes: Task 4의 `ClearPopup(nextLabel:, note:)`
- Produces: `ConfettiOverlay({required Animation<double> progress})` — 진행도 0→1 동안 파티클이 퍼졌다 사라진다. 외부 의존성 없음.
- 미획득 별은 애니메이션 없이 항상 회색으로 보인다. 획득 별만 단일 컨트롤러 + `Interval`로 순차 등장한다(`Future.delayed` 제거 — 리빌드에 취약해 v1에서 별이 사라진 원인으로 의심되는 구조).

- [ ] **Step 1: 실패하는 테스트 작성**

`test/ui/clear_popup_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/ui/theme.dart';
import 'package:piyak_push/ui/widgets/clear_popup.dart';

Future<void> pumpPopup(WidgetTester tester, int stars) async {
  await tester.pumpWidget(MaterialApp(
    home: ClearPopup(stars: stars, moves: 9, optimal: 7, onRetry: () {}),
  ));
  await tester.pump(const Duration(milliseconds: 1600));
}

int yellowStars(WidgetTester tester) => tester
    .widgetList<Icon>(find.byIcon(Icons.star_rounded))
    .where((i) => i.color == PiyakColors.starYellow)
    .length;

void main() {
  for (final n in [1, 2, 3]) {
    testWidgets('별 $n개면 노란 별 $n개, 전체 별 자리는 3개', (tester) async {
      await pumpPopup(tester, n);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(yellowStars(tester), n);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('애니메이션 시작 직후에도 별 자리 3개가 렌더된다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ClearPopup(stars: 2, moves: 9, optimal: 7, onRetry: () {}),
    ));
    await tester.pump(); // 첫 프레임
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
  });
}
```

- [ ] **Step 2: 실행해 실패 확인**

Run: `flutter test --no-pub test/ui/clear_popup_test.dart`
Expected: 별 색 검증에서 FAIL 또는 타이머 관련 실패 (현재 `Future.delayed` 구조)

- [ ] **Step 3: 꽃가루 페인터 작성**

`lib/ui/widgets/confetti.dart`:

```dart
/// 클리어 축하 꽃가루. 외부 패키지 없이 CustomPainter로만 그린다.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class ConfettiOverlay extends StatelessWidget {
  final Animation<double> progress;
  const ConfettiOverlay({required this.progress, super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(progress.value),
          ),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static const _colors = [
    PiyakColors.starYellow,
    PiyakColors.blush,
    PiyakColors.iceBlue,
    PiyakColors.grass,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    // 고정 시드 — 매 프레임 같은 궤적이어야 흔들리지 않는다.
    final rng = math.Random(7);
    final origin = Offset(size.width / 2, size.height * 0.38);
    for (var i = 0; i < 28; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 90 + rng.nextDouble() * 190;
      final spin = rng.nextDouble() * math.pi;
      final color = _colors[i % _colors.length];
      final dx = math.cos(angle) * speed * t;
      final dy = math.sin(angle) * speed * t + 320 * t * t; // 중력
      final p = origin + Offset(dx, dy);
      final fade = (1.0 - t).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(spin + t * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 9, height: 6),
          const Radius.circular(2),
        ),
        Paint()..color = color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
```

- [ ] **Step 4: ClearPopup 별 구조 교체**

`lib/ui/widgets/clear_popup.dart`의 `_ClearPopupState`에서 `_starCtrls` 리스트와 `initState`의 `Future.delayed` 루프를 모두 지우고 단일 컨트롤러로 바꾼다:

```dart
class _ClearPopupState extends State<ClearPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// i번째 별이 튀어나오는 구간.
  Animation<double> _starAnim(int i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0.10 + i * 0.16, 0.10 + i * 0.16 + 0.34,
            curve: Curves.elasticOut),
      );
```

별 행을 교체한다 — **미획득 별은 애니메이션으로 감싸지 않아 항상 보인다**:

```dart
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final earned = i < widget.stars;
                  final star = Icon(
                    Icons.star_rounded,
                    size: 56,
                    color: earned
                        ? PiyakColors.starYellow
                        : PiyakColors.outline.withValues(alpha: 0.18),
                  );
                  if (!earned) return star;
                  return ScaleTransition(scale: _starAnim(i), child: star);
                }),
              ),
```

꽃가루를 카드 뒤에 깔기 위해 `build`의 최상위 `ColoredBox`의 child를 `Stack`으로 감싼다:

```dart
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: Stack(
        children: [
          Positioned.fill(child: ConfettiOverlay(progress: _ctrl)),
          Center(
            child: Container(
              // ... 기존 카드 내용 그대로
            ),
          ),
        ],
      ),
    );
```

`import 'confetti.dart';`를 추가한다.

- [ ] **Step 5: 통과 확인**

Run: `flutter test --no-pub test/ui/`
Expected: PASS (clear_popup 4건 포함)

- [ ] **Step 6: 커밋**

```powershell
git add -A; git commit -m "클리어 팝업: 별이 안 보이던 문제 수정(단일 컨트롤러) + 꽃가루 연출

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: 이동 부드럽게 + 막힘 반응

**Files:**
- Modify: `lib/ui/widgets/board_view.dart`
- Modify: `lib/ui/widgets/dpad.dart`
- Modify: `lib/ui/screens/game_screen.dart`

**Interfaces:**
- Consumes: `GameController.move(Dir)`가 성공 여부 bool 반환 (기존)
- Produces:
  - `kMoveAnim = Duration(milliseconds: 160)`, 커브 `Curves.easeInOut`
  - `BoardView`에 `final Dir? bumpDir; final int bumpToken;` 추가 (기본 `null`, `0`)
  - `ChickSprite`에 `final Dir? bumpDir; final int bumpToken;` 추가 — 토큰이 바뀌면 그 방향으로 밀렸다 돌아온다(140ms)
  - `DPad` 연속 이동 간격 160→170ms

- [ ] **Step 1: 타이밍 상수 조정**

`lib/ui/widgets/board_view.dart`:

```dart
/// 한 칸 이동 시간. DPad 연속 간격(170ms)과 거의 맞물려야 연속 이동이
/// 끊겨 보이지 않는다.
const kMoveAnim = Duration(milliseconds: 160);
```

같은 파일의 알·병아리 `AnimatedPositioned` 두 곳의 `curve: Curves.easeOut`을 `curve: Curves.easeInOut`으로 바꾼다.

`_ChickSpriteState`의 `_hop` duration을 `220` → `160`으로 바꾼다.

`lib/ui/widgets/dpad.dart`의 반복 타이머 간격을 바꾼다:

```dart
      _repeat = Timer.periodic(
          const Duration(milliseconds: 170), (_) => widget.onFire());
```

- [ ] **Step 2: 막힘 흔들림 — ChickSprite**

`ChickSprite`에 필드·생성자 파라미터를 추가한다:

```dart
  final Dir? bumpDir;
  final int bumpToken;
```
생성자에 `this.bumpDir, this.bumpToken = 0,` 추가.

`_ChickSpriteState`에 컨트롤러와 감지 로직 추가:

```dart
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );
  Dir? _lastBumpDir;
```

`didUpdateWidget` 안에 추가:

```dart
    if (widget.bumpToken != old.bumpToken && widget.bumpDir != null) {
      _lastBumpDir = widget.bumpDir;
      _bump.forward(from: 0);
    }
```

`dispose`에 `_bump.dispose();` 추가.

`AnimatedBuilder`의 `animation:`을 `Listenable.merge([_bob, _hop, _bump])`로 바꾸고, builder 안에서 오프셋을 합친다:

```dart
        final bumpT = math.sin(math.pi * _bump.value); // 0→1→0
        final push = widget.cell * 0.12 * bumpT;
        final bump = switch (_lastBumpDir) {
          Dir.up => Offset(0, -push),
          Dir.down => Offset(0, push),
          Dir.left => Offset(-push, 0),
          Dir.right => Offset(push, 0),
          null => Offset.zero,
        };
        return Transform.translate(
          offset: Offset(bump.dx, hopY + bump.dy),
          // ... 이하 기존 Transform.rotate / Transform 그대로
```

- [ ] **Step 3: BoardView가 값을 전달하도록**

`BoardView`에 필드·파라미터 `final Dir? bumpDir;`, `final int bumpToken;` (기본 `null`, `0`)을 추가하고, `ChickSprite` 생성 시 넘긴다:

```dart
            child: ChickSprite(
              pos: b.chick,
              cell: cell,
              mood: widget.chickMood,
              bumpDir: widget.bumpDir,
              bumpToken: widget.bumpToken,
            ),
```

- [ ] **Step 4: GameScreen에서 실패한 입력 감지**

`_GameScreenState`에 필드 추가:

```dart
  Dir? _bumpDir;
  int _bumpToken = 0;
```

`_input`을 교체한다 — 성공하면 컨트롤러가 알아서 리빌드하고, 실패하면 흔들림만 갱신한다:

```dart
  void _input(Dir d) {
    _resetIdleTimers();
    _hintMoves = null;
    if (c.move(d)) {
      widget.onEvents?.call(c.lastEvents, c.cleared);
    } else {
      setState(() {
        _bumpDir = d;
        _bumpToken++;
      });
    }
  }
```

`BoardView(...)` 호출에 전달을 추가한다:

```dart
                            bumpDir: _bumpDir,
                            bumpToken: _bumpToken,
```

- [ ] **Step 5: 전체 테스트**

Run: `flutter test --no-pub`
Expected: 전체 PASS (기존 이동 테스트가 새 타이밍에서도 통과 — 테스트는 충분한 시간을 pump한다)

- [ ] **Step 6: 커밋**

```powershell
git add -A; git commit -m "이동 연속성 개선(160ms·easeInOut·반복 170ms) + 막힌 입력에 흔들림 반응

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: 게임 화면 여백·배치 + 보드 패널

**Files:**
- Modify: `lib/ui/theme.dart`
- Modify: `lib/ui/screens/game_screen.dart`
- Modify: `lib/ui/widgets/hud.dart`

**Interfaces:**
- Consumes: Task 6의 `BoardView(bumpDir:, bumpToken:)`
- Produces: `PiyakColors.boardPanel` 추가. 게임 화면 세로 구성이 HUD(카드) → 보드(패널, 남는 공간 차지) → 방향키(하단 고정)로 고정되고, 말풍선은 보드 영역 위에 겹쳐 떠서 **방향키 위치를 밀지 않는다**.

- [ ] **Step 1: 패널 색 추가**

`lib/ui/theme.dart`의 `PiyakColors`에 추가:

```dart
  static const boardPanel = Color(0xFFF2E7C9);
```

- [ ] **Step 2: HUD를 카드로**

`lib/ui/widgets/hud.dart`의 `Padding`을 `Container`로 감싼다:

```dart
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PiyakColors.outline, width: 2),
      ),
      child: Row(
        // ... 기존 Row children 그대로
      ),
    );
```

기존 바깥 `Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Row(...))`를 위 구조로 대체한다.

- [ ] **Step 3: 보드를 패널로 감싸고 세로 배치 정리**

`lib/ui/screens/game_screen.dart`의 `Expanded(...)` 블록을 교체한다. 말풍선은 Stack으로 보드 위에 겹쳐 방향키를 밀지 않게 한다:

```dart
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) => _drag = Offset.zero,
                    onPanUpdate: (d) => _drag += d.delta,
                    onPanEnd: (_) {
                      if (_drag.distance < 24) return;
                      final d = _drag.dx.abs() > _drag.dy.abs()
                          ? (_drag.dx > 0 ? Dir.right : Dir.left)
                          : (_drag.dy > 0 ? Dir.down : Dir.up);
                      _input(d);
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final b = c.board;
                              // 패널 안쪽 여백(10*2)과 화면 여백(12*2)을 뺀 뒤 나눈다
                              final avail = Size(
                                  box.maxWidth - 44, box.maxHeight - 44);
                              final cell = (avail.width / b.width <
                                      avail.height / b.height)
                                  ? avail.width / b.width
                                  : avail.height / b.height;
                              return Center(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: PiyakColors.boardPanel,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                        color: PiyakColors.outline, width: 3),
                                  ),
                                  child: BoardView(
                                    board: b,
                                    cellSize: cell.clamp(20.0, 96.0),
                                    chickMood: mood,
                                    hintMoves: _hintMoves,
                                    bumpDir: _bumpDir,
                                    bumpToken: _bumpToken,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (bubble != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: SpeechBubble(text: bubble),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.showDpad)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DPad(onDir: _input),
                  ),
```

기존의 `if (bubble != null) SpeechBubble(text: bubble),`와 그 아래 `const SizedBox(height: 8),`는 삭제한다(말풍선은 Stack으로, 하단 여백은 DPad Padding으로 옮겼다).

- [ ] **Step 4: 테스트 + 육안 확인**

Run: `flutter test --no-pub test/ui/ test/widget_test.dart`
Expected: PASS (튜토리얼 말풍선 테스트 포함 — Stack 안에 있어도 `find.textContaining`은 찾는다)

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 5: 커밋**

```powershell
git add -A; git commit -m "게임 화면 재배치: 보드 패널·HUD 카드·타일 96px 상한·말풍선 오버레이

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: 보드 그래픽 디테일

**Files:**
- Modify: `lib/ui/widgets/tile_painter.dart`

**Interfaces:**
- Consumes: 없음 (`BoardPainter`, `_EggPainter` 내부만 변경)
- Produces: 시각 변경만. 공개 API 불변.

- [ ] **Step 1: 잔디 무늬 (바닥 타일)**

`_paintCell`의 `case Tile.floor:` 를 교체한다. 무늬 위치는 좌표 해시로 정해 매 프레임 고정한다:

```dart
      case Tile.floor:
        // 좌표 해시로 무늬를 고정한다 — 난수를 쓰면 프레임마다 흔들린다.
        final h = (p.x * 31 + p.y * 17) % 4;
        if (h < 2) {
          final blade = Paint()
            ..color = PiyakColors.grassDark
            ..strokeWidth = cell * 0.05
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
          final bx = r.left + r.width * (h == 0 ? 0.30 : 0.62);
          final by = r.top + r.height * (h == 0 ? 0.68 : 0.40);
          final s = cell * 0.10;
          canvas.drawLine(Offset(bx, by), Offset(bx - s, by - s), blade);
          canvas.drawLine(Offset(bx, by), Offset(bx + s, by - s), blade);
        }
```

- [ ] **Step 2: 둥지 지푸라기 결**

`case Tile.nest:` 블록의 마지막(안쪽 원을 그린 뒤)에 추가:

```dart
        final straw = Paint()
          ..color = PiyakColors.outline.withValues(alpha: 0.35)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        for (var k = 0; k < 3; k++) {
          final a = 0.6 + k * 1.9;
          canvas.drawLine(
            Offset(c.dx + math.cos(a) * r.width * 0.20,
                c.dy + math.sin(a) * r.width * 0.20),
            Offset(c.dx + math.cos(a) * r.width * 0.33,
                c.dy + math.sin(a) * r.width * 0.33),
            straw,
          );
        }
```

파일 상단에 `import 'dart:math' as math;`를 추가한다.

- [ ] **Step 3: 벽 아래 그림자**

`case Tile.wall:` 블록의 널빤지 선을 그린 뒤에 추가:

```dart
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(r.left, r.bottom - r.height * 0.16, r.right, r.bottom),
            Radius.circular(cell * 0.14),
          ),
          Paint()..color = PiyakColors.outline.withValues(alpha: 0.18),
        );
```

- [ ] **Step 4: 알 광택**

`_EggPainter.paint`에서 볼터치를 그리기 전에 추가:

```dart
    // 좌상단 광택
    canvas.save();
    canvas.translate(w * 0.38, h * 0.30);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero, width: w * 0.16, height: h * 0.10),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.restore();
```

- [ ] **Step 5: 테스트 + 정적 분석**

Run: `flutter test --no-pub test/ui/board_view_test.dart`
Expected: PASS (스모크 — 예외 없이 렌더링)

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 6: 커밋**

```powershell
git add -A; git commit -m "보드 그래픽: 잔디 무늬·둥지 지푸라기·벽 그림자·알 광택

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 9: 타이틀·챕터 화면 단장

**Files:**
- Modify: `lib/ui/theme.dart`
- Modify: `lib/ui/screens/title_screen.dart`
- Modify: `lib/ui/screens/chapter_screen.dart`

**Interfaces:**
- Consumes: `SaveService.totalStars`, `chapterStars`, `chapterUnlocked` (기존)
- Produces: `PiyakColors.chapterColors` — 챕터 1~5 테마색 5개 리스트

- [ ] **Step 1: 챕터 테마색 추가**

`lib/ui/theme.dart`의 `PiyakColors`에 추가:

```dart
  /// 챕터 1~5 테마색 (풀밭·얼음길·비밀굴·단추와문·금간바닥)
  static const chapterColors = [
    Color(0xFF8FD16A),
    Color(0xFF7FC8E8),
    Color(0xFFB98FD6),
    Color(0xFFF08FB0),
    Color(0xFFC49A6C),
  ];
```

- [ ] **Step 2: 타이틀 로고 패널·진행바·강조 버튼**

`lib/ui/screens/title_screen.dart`에서 제목 `Text`와 별 표시 `Row`를 로고 카드로 교체한다:

```dart
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: PiyakColors.outline, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        S.appTitle,
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: PiyakColors.outline,
                          letterSpacing: 2,
                        ),
                      ),
                      Image.asset('assets/images/chick/chick_cheer.png',
                          height: 120),
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: save.totalStars / 150,
                            minHeight: 12,
                            backgroundColor: PiyakColors.creamBg,
                            valueColor: const AlwaysStoppedAnimation(
                                PiyakColors.starYellow),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: PiyakColors.starYellow, size: 20),
                          Text(' ${save.totalStars} / 150',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: PiyakColors.outline)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
```

기존의 별도 `Image.asset('assets/images/chick/chick_cheer.png', height: 140)` 줄과 그 위아래 `SizedBox`, 옛 제목/별 `Row`는 삭제한다(카드 안으로 들어갔다).

`_menuButton`의 버튼에 눌림 그림자를 준다 — `style` 안 `shape` 아래에 추가:

```dart
      elevation: 0,
      shadowColor: Colors.transparent,
```
그리고 버튼을 감싼 `Padding`의 `child`를 `Container`로 감싸 아래 그림자를 준다:

```dart
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x335D4037),
                offset: Offset(0, 4),
                blurRadius: 0),
          ],
        ),
        child: FilledButton(
          style: style,
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => page)),
          child: Text(label),
        ),
      ),
    );
```

- [ ] **Step 3: 챕터 카드에 테마색과 진행바**

`lib/ui/screens/chapter_screen.dart`의 `Card`를 교체한다 — 좌측 색 스트립과 진행바를 넣는다:

```dart
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: unlocked
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PiyakColors.outline, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 96,
                  color: unlocked
                      ? PiyakColors.chapterColors[i]
                      : PiyakColors.outline.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    leading: Icon(
                      unlocked ? _icons[i] : Icons.lock_rounded,
                      size: 36,
                      color: PiyakColors.outline,
                    ),
                    title: Text(
                      '$c. ${S.chapterNames[i]}',
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: PiyakColors.outline),
                    ),
                    subtitle: unlocked
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: stars / 30,
                                  minHeight: 8,
                                  backgroundColor: PiyakColors.creamBg,
                                  valueColor: AlwaysStoppedAnimation(
                                      PiyakColors.chapterColors[i]),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: PiyakColors.starYellow,
                                      size: 16),
                                  Text(' $stars / 30',
                                      style: const TextStyle(
                                          color: PiyakColors.outline,
                                          fontSize: 13)),
                                ],
                              ),
                            ],
                          )
                        : const Text(S.lockedChapter,
                            style: TextStyle(
                                color: PiyakColors.outline, fontSize: 12)),
                    onTap: unlocked
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => StageScreen(chapter: c)))
                        : null,
                  ),
                ),
              ],
            ),
          );
```

- [ ] **Step 4: 테스트 + 정적 분석**

Run: `flutter test --no-pub test/widget_test.dart`
Expected: PASS — 타이틀에서 '시작' 탭 → 챕터 화면, 자물쇠 4개

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 5: 커밋**

```powershell
git add -A; git commit -m "타이틀·챕터 화면 단장: 로고 카드·진행바·챕터 테마색

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 10: 전체 점검 · 릴리즈 · 실기기 확인

**Files:**
- Modify: `README.md` (조작·소리 설명 갱신)

**Interfaces:**
- Consumes: Task 1~9 전부

- [ ] **Step 1: 전체 테스트 + 정적 분석**

```powershell
flutter analyze
flutter test --no-pub
```
Expected: analyze `No issues found`, 테스트 전부 PASS (v1 154건 + 이번 추가분)

- [ ] **Step 2: 레벨 무결성 재확인**

```powershell
dart run tool/validate_levels.dart
```
Expected: 풀이 불가 0건, 전체 70개 분포 출력 (엔진을 안 건드렸으므로 v1과 동일해야 한다)

- [ ] **Step 3: README 갱신**

`README.md`의 "게임 규칙" 첫 항목을 교체한다:

```markdown
- 화면 아래 방향키로 병아리를 상하좌우 한 칸씩 이동 (꾹 누르면 연속 이동, 스와이프도 가능)
- 걸을 때마다 삐약 소리가 나고, 벽에 막히면 병아리가 살짝 튕긴다
```

- [ ] **Step 4: 릴리즈 빌드**

```powershell
flutter build apk --release
```
Expected: `√ Built build\app\outputs\flutter-apk\app-release.apk`

- [ ] **Step 5: 실기기 설치·확인**

```powershell
C:\workAndroid\android-sdk-ascii\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-release.apk
C:\workAndroid\android-sdk-ascii\platform-tools\adb.exe shell am start -n com.piyak.piyak_push/.MainActivity
```

육안 체크리스트 (스크린샷으로 근거 남길 것):
1. 방향키가 커졌고 누르기 편한가
2. 걸을 때 삐약 소리가 나고 연속 이동해도 자연스러운가
3. 이동이 끊기지 않고 이어지는가, 벽에 막히면 튕기는가
4. 챕터 마지막 스테이지 클리어 → "다음 챕터" 또는 별 부족 안내가 뜨는가
5. 클리어 팝업에 별이 보이고 꽃가루가 날리는가
6. 보드 패널·타이틀 카드·챕터 색이 적용됐는가

- [ ] **Step 6: 커밋**

```powershell
git add -A; git commit -m "v1.1: README 갱신 및 실기기 확인

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Self-Review 기록

- **스펙 커버리지**: 1절 삐약 소리→Task 1 / 2절 방향키→Task 2 / 3절 챕터 전환→Task 3·4 / 4.1 게임 화면→Task 7 / 4.2 타이틀·메뉴→Task 9 / 4.3 보드 그래픽→Task 8 / 4.4 클리어 별·꽃가루→Task 5 / 5절 이동 부드럽게+막힘 반응→Task 6 / 테스트 전략→각 Task의 테스트 단계 + Task 10. 누락 없음.
- **타입 일관성**: `resolveNextStep`의 반환 타입 4종(Task 3)을 Task 4의 `switch`에서 그대로 소비. `ClearOutcome`(Task 4)을 Task 4 안에서만 사용. `BoardView.bumpDir/bumpToken`(Task 6)을 Task 7의 `BoardView` 호출에서 그대로 전달. `PiyakColors.boardPanel`(Task 7)·`chapterColors`(Task 9) 각각 선언 태스크에서 사용.
- **의존 순서**: Task 6이 `BoardView`에 파라미터를 추가하고 Task 7이 그 파라미터를 전달하므로 6 → 7 순서를 지켜야 한다. Task 4는 Task 3에, Task 5는 Task 4의 `ClearPopup` 시그니처에 의존한다. 1·2·8·9는 서로 독립.
- **범위**: 엔진·레벨·저장 포맷 불변 → 기존 진행 기록이 재설치 후에도 유지된다.
