# 삐약푸시 v2.1 (게임 필·조이스틱·비주얼) 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홀드 중 등속 연속 이동으로 끊김을 없애고, 방향키를 가상 조이스틱으로 교체하고, 기존 codex 이미지·Jua 폰트·전환 애니메이션으로 UI를 단장한다.

**Architecture:** 이동 발행을 화면의 `Timer.periodic(kMoveAnim)`으로 옮기고 곡선을 홀드 여부로 고른다(등속↔감속). 조이스틱은 하단 밴드의 플로팅 위젯. 타일·로고는 "PNG 있으면 그림, 없으면 페인터" 계층(`TileArt`)이라 codex 그림이 오기 전에도 동작한다.

**Tech Stack:** Flutter 3.44.8 / 기존 의존성 3종 유지 / Jua 폰트(에셋 번들)

## Global Constraints

- 스펙: `docs/superpowers/specs/2026-08-02-piyakpush-v21-feel-design.md` (충돌 시 스펙 우선)
- 런타임 의존성 추가 금지. 폰트는 에셋 번들
- 레벨·엔진 규칙 변경 금지
- 한국어 UI 문자열은 `lib/ui/strings.dart`의 `S`로만
- **전체 테스트 스위트를 반복 실행하지 않는다** (사용자 요청 — 토큰 절약). `flutter analyze` + 이번에 만들거나 바꾼 테스트 파일만 1회 실행
- 매 셸 세션 선행:
  ```powershell
  $env:Path = "C:\flutter\bin;$env:Path"; $env:PUB_CACHE = "C:\flutter\.pub-cache"; $env:GRADLE_USER_HOME = "C:\workAndroid\gradle-user-ascii"; $env:TEMP = "C:\workAndroid\tmp-ascii"; $env:TMP = "C:\workAndroid\tmp-ascii"
  ```
- 작업 디렉터리 `C:\workAndroid\PiyakPush`, 브랜치 `feature/v21-feel`
- 커밋: 한국어 요약 + `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`

## File Structure

| 파일 | 책임 | 상태 |
|---|---|---|
| `lib/ui/screens/game_screen.dart` | 홀드 상태·이동 발행 타이머·조이스틱 배선·막 배경 | 수정 |
| `lib/ui/widgets/board_view.dart` | `gliding` 곡선, 뒤뚱·착지 스쿼시, 알 반동 | 수정 |
| `lib/ui/widgets/joystick.dart` | 플로팅 조이스틱 | 신규 |
| `lib/ui/widgets/dpad.dart` | 삭제 | 삭제 |
| `lib/ui/widgets/tile_painter.dart` | 알 PNG+얼굴 오버레이 | 수정 |
| `lib/ui/widgets/act_background.dart` | 막별 배경 레이어 | 신규 |
| `lib/ui/services/tile_art.dart` 아님 → `lib/services/tile_art.dart` | PNG 있으면 그림 계층 | 신규 |
| `lib/ui/nav.dart` | `piyakRoute` 전환 | 신규 |
| `lib/ui/theme.dart` | fontFamily Jua | 수정 |
| `lib/ui/screens/settings_screen.dart` | D-패드 토글 제거 | 수정 |
| `lib/ui/screens/title_screen.dart` 등 | 라우트 교체·로고 계층·배경 | 수정 |
| `assets/fonts/` `assets/images/bg/` `assets/images/egg.png` `assets/images/tiles/` | 에셋 | 신규 |
| `docs/codex-art-request.md` | codex 의뢰서 | 신규 |

---

### Task 1: 연속 이동 (등속 홀드 + 걸음 연출)

**Files:**
- Modify: `lib/ui/widgets/board_view.dart`
- Modify: `lib/ui/screens/game_screen.dart`
- Test: `test/ui/game_screen_test.dart` (스와이프 테스트를 홀드 테스트로 교체 — Task 2에서 조이스틱으로 완성하므로 여기서는 내부 메서드 없이 화면 리팩터만)

**Interfaces:**
- Produces:
  - `BoardView`에 `final bool gliding;` (기본 false) — 알·병아리 `AnimatedPositioned` 곡선이 `gliding ? Curves.linear : Curves.easeOut`
  - `_GameScreenState`에 `void holdDir(Dir d)` / `void releaseDir()` — Task 2의 조이스틱이 호출한다. `holdDir`: 같은 방향이면 무시, 다르면 즉시 1회 이동 후 `Timer.periodic(kMoveAnim)`으로 반복. `releaseDir`: 타이머 취소 + `gliding=false`로 리빌드
  - `ChickSprite`: 스텝마다 기울기 부호가 교차(뒤뚱), 홉 종료 시 80ms 착지 스쿼시(scaleY 0.92→1.0)
  - `EggWidget` → `EggSprite(pos: Point, size: double, onNest: bool)` 로 개명·stateful화: pos가 바뀌면 이동 축으로 0.9 찌그러졌다 복원(120ms)

- [ ] **Step 1: BoardView에 gliding 곡선**

`board_view.dart`의 `BoardView`에 `final bool gliding;`(생성자 `this.gliding = false`)을 추가하고, 알·병아리 `AnimatedPositioned` 두 곳의 `curve:`를 바꾼다:

```dart
              curve: widget.gliding ? Curves.linear : Curves.easeOut,
```

- [ ] **Step 2: 뒤뚱 + 착지 스쿼시**

`_ChickSpriteState`에서:

```dart
  int _stepParity = 1;
  late final AnimationController _land = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
  );
```

`initState`를 추가해 홉 종료에 착지를 연결한다:

```dart
  @override
  void initState() {
    super.initState();
    _hop.addStatusListener((s) {
      if (s == AnimationStatus.completed) _land.forward(from: 0);
    });
  }
```

`didUpdateWidget`의 위치 변경 분기에서 기존 `_tiltSign` 계산을 교체한다 — 좌우 이동은 진행 방향, 상하 이동은 걸음마다 교차:

```dart
    if (old.pos != widget.pos) {
      final dx = widget.pos.x - old.pos.x;
      _stepParity = -_stepParity;
      _tiltSign = dx != 0 ? (dx > 0 ? 1 : -1) : _stepParity;
      _hop.forward(from: 0);
    }
```

`build`의 `AnimatedBuilder` `animation:`에 `_land`를 추가(`Listenable.merge([_bob, _hop, _bump, _land])`)하고, breathe 계산 뒤에 착지 스쿼시를 합성한다:

```dart
        final landT = math.sin(math.pi * _land.value); // 0→1→0
        final squashY = 1.0 - 0.08 * landT;
```

기존 `Matrix4.diagonal3Values(2.0 - breathe, breathe, 1.0)`를
`Matrix4.diagonal3Values((2.0 - breathe) / squashY, breathe * squashY, 1.0)`로 바꾼다.
`dispose`에 `_land.dispose();` 추가.

- [ ] **Step 3: EggSprite (알 반동)**

`tile_painter.dart`의 `EggWidget`을 `EggSprite`로 교체한다 (`_EggPainter`는 그대로 둔다):

```dart
/// 알 — 밀리기 시작하면 이동 축으로 살짝 찌그러졌다 복원된다.
class EggSprite extends StatefulWidget {
  final Point pos;
  final double size;
  final bool onNest;
  const EggSprite(
      {required this.pos, required this.size, this.onNest = false, super.key});

  @override
  State<EggSprite> createState() => _EggSpriteState();
}

class _EggSpriteState extends State<EggSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _recoil = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  bool _horizontal = true;

  @override
  void didUpdateWidget(EggSprite old) {
    super.didUpdateWidget(old);
    if (old.pos != widget.pos) {
      _horizontal = widget.pos.y == old.pos.y;
      _recoil.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _recoil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _recoil,
      builder: (context, child) {
        final t = math.sin(math.pi * _recoil.value);
        final s = 1.0 - 0.10 * t;
        return Transform(
          alignment: Alignment.center,
          transform: _horizontal
              ? Matrix4.diagonal3Values(s, 2.0 - s, 1.0)
              : Matrix4.diagonal3Values(2.0 - s, s, 1.0),
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _EggPainter(widget.onNest),
      ),
    );
  }
}
```

파일 상단에 `import 'dart:math' as math;`와 `import '../../engine/geometry.dart';`가 필요하다(이미 있으면 그대로).

`board_view.dart`의 알 생성부를 교체한다:

```dart
              child: EggSprite(
                pos: _eggOrder[i],
                size: cell,
                onNest: b.tileAt(_eggOrder[i]) == Tile.nest,
              ),
```

`test/ui/board_view_test.dart`에서 `EggWidget` 참조가 있으면 `EggSprite`로 바꾼다.

- [ ] **Step 4: GameScreen 홀드 발행**

`game_screen.dart`의 `_GameScreenState`에 추가한다:

```dart
  Dir? _heldDir;
  Timer? _glide;

  bool get _gliding => _heldDir != null;

  /// 조이스틱이 방향을 잡거나 바꿀 때. 같은 방향이면 무시.
  void holdDir(Dir d) {
    if (_heldDir == d) return;
    _heldDir = d;
    _glide?.cancel();
    _input(d);
    _glide = Timer.periodic(kMoveAnim, (_) => _input(d));
    setState(() {});
  }

  /// 손을 뗐거나 데드존으로 돌아왔을 때 — 마지막 칸은 easeOut으로 감속.
  void releaseDir() {
    _glide?.cancel();
    _glide = null;
    if (_heldDir != null) setState(() => _heldDir = null);
  }
```

`dispose`에 `_glide?.cancel();` 추가. `BoardView(...)` 호출에 `gliding: _gliding,` 추가.
`import '../widgets/board_view.dart';`는 이미 있고 `kMoveAnim`도 거기서 온다.

- [ ] **Step 5: 분석**

Run: `flutter analyze`
Expected: No issues found (아직 holdDir 미사용 경고가 나면 Task 2에서 배선되므로 `// ignore: unused_element`는 달지 말고 Task 2를 이어서 진행)

- [ ] **Step 6: 커밋**

```powershell
git add -A; git commit -m "연속 이동: 홀드 중 등속 + 뒤뚱·착지 스쿼시 + 알 반동

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: 가상 조이스틱 (십자키·스와이프 제거)

**Files:**
- Create: `lib/ui/widgets/joystick.dart`
- Delete: `lib/ui/widgets/dpad.dart`
- Modify: `lib/ui/screens/game_screen.dart`, `lib/ui/screens/stage_screen.dart`, `lib/ui/screens/daily_screen.dart`, `lib/ui/screens/settings_screen.dart`, `lib/ui/strings.dart`
- Test: `test/ui/game_screen_test.dart`

**Interfaces:**
- Consumes: Task 1의 `holdDir(Dir)` / `releaseDir()`
- Produces:
  - `class Joystick extends StatefulWidget { final void Function(Dir) onDir; final VoidCallback onRelease; const Joystick({required this.onDir, required this.onRelease, super.key}); }` — 밴드 전체가 터치 영역. 터치 지점에 베이스 링 표시, 드래그 18px 초과 시 4방향 스냅해 `onDir`, 데드존 복귀·손 떼면 `onRelease`
  - `GameScreen`에서 `showDpad` 파라미터 제거 (조이스틱 상시)
  - `SaveService.dpadOn`은 읽지 않는다 (키 정리는 하지 않음)

- [ ] **Step 1: 테스트 교체**

`test/ui/game_screen_test.dart`에서 `import ... dpad.dart`를 `import 'package:piyak_push/ui/widgets/joystick.dart';`로 바꾸고, `'방향키가 기본 표시되고 탭으로 이동'` 테스트를 교체한다:

```dart
  testWidgets('조이스틱 드래그로 이동하고 놓으면 멈춘다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(level: lv(['#######', '#@..\$o#', '#######'], optimal: 3)),
    ));
    await tester.pump();
    expect(find.byType(Joystick), findsOneWidget);

    final band = tester.getCenter(find.byType(Joystick));
    final g = await tester.startGesture(band);
    await g.moveBy(const Offset(40, 0)); // 데드존(18px) 초과 → 오른쪽
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('이동 1'), findsOneWidget);
    await tester.pump(kMoveAnim); // 홀드 유지 → 두 번째 이동
    expect(find.textContaining('이동 2'), findsOneWidget);
    await g.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('이동 2'), findsOneWidget); // 더는 안 움직임
    await cleanup(tester);
  });

  testWidgets('데드존 안 드래그는 이동 없음', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(level: lv(['#######', '#@..\$o#', '#######'], optimal: 3)),
    ));
    await tester.pump();
    final band = tester.getCenter(find.byType(Joystick));
    final g = await tester.startGesture(band);
    await g.moveBy(const Offset(10, 0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('이동 0'), findsOneWidget);
    await g.up();
    await tester.pump(const Duration(milliseconds: 300));
    await cleanup(tester);
  });
```

`kMoveAnim` import: `import 'package:piyak_push/ui/widgets/board_view.dart';`

- [ ] **Step 2: 실행해 실패 확인**

Run: `flutter test --no-pub test/ui/game_screen_test.dart`
Expected: FAIL — `joystick.dart` 없음

- [ ] **Step 3: Joystick 구현**

`lib/ui/widgets/joystick.dart`:

```dart
/// 플로팅 가상 조이스틱 — 하단 밴드 아무 데나 눌러 그 자리에서 조작한다.
///
/// 드래그가 데드존(18px)을 넘으면 상하좌우 중 가까운 방향으로 스냅해
/// onDir을 부르고, 데드존으로 돌아오거나 손을 떼면 onRelease를 부른다.
library;

import 'package:flutter/material.dart';

import '../../engine/geometry.dart';
import '../theme.dart';

const _kDead = 18.0;
const _kKnobMax = 56.0;

class Joystick extends StatefulWidget {
  final void Function(Dir) onDir;
  final VoidCallback onRelease;
  const Joystick({required this.onDir, required this.onRelease, super.key});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset? _base;
  Offset _knob = Offset.zero;

  void _update(Offset local) {
    var d = local - _base!;
    if (d.distance > _kKnobMax) d = d / d.distance * _kKnobMax;
    setState(() => _knob = d);
    if (d.distance < _kDead) {
      widget.onRelease();
      return;
    }
    widget.onDir(d.dx.abs() > d.dy.abs()
        ? (d.dx > 0 ? Dir.right : Dir.left)
        : (d.dy > 0 ? Dir.down : Dir.up));
  }

  void _end() {
    widget.onRelease();
    setState(() {
      _base = null;
      _knob = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (e) => setState(() {
        _base = e.localPosition;
        _knob = Offset.zero;
      }),
      onPanUpdate: (e) => _base == null ? null : _update(e.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: SizedBox.expand(
        child: _base == null
            ? Center(
                child: Text(
                  '아무 데나 누르고 기울여 보세요',
                  style: TextStyle(
                    fontSize: 13,
                    color: PiyakColors.outline.withValues(alpha: 0.35),
                  ),
                ),
              )
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: _base!.dx - 52,
                    top: _base!.dy - 52,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.45),
                        border: Border.all(
                            color: PiyakColors.outline.withValues(alpha: 0.5),
                            width: 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _base!.dx + _knob.dx - 30,
                    top: _base!.dy + _knob.dy - 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PiyakColors.chickYellow,
                        border:
                            Border.all(color: PiyakColors.outline, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
```

문구는 `S`에 추가한다 — `strings.dart`에 `static const joystickHint = '아무 데나 누르고 기울여 보세요';` 를 넣고 위 `Text`에서 `S.joystickHint`를 쓴다 (`import '../strings.dart';`).

- [ ] **Step 4: GameScreen 배선 + 구세대 제거**

`game_screen.dart`:
- `showDpad` 필드·생성자 파라미터 삭제, `import '../widgets/dpad.dart';` → `import '../widgets/joystick.dart';`
- 보드 영역을 감싸던 스와이프 `GestureDetector`(onPanStart/Update/End)를 제거하고 자식만 남긴다
- 하단 D-패드 블록을 교체한다:

```dart
                SizedBox(
                  height: 180,
                  child: Joystick(onDir: holdDir, onRelease: releaseDir),
                ),
```

`stage_screen.dart`·`daily_screen.dart`에서 `showDpad: save.dpadOn,` 줄 삭제.
`settings_screen.dart`에서 D-패드 `SwitchListTile` 블록 삭제 (`S.dpadOn`도 strings에서 삭제).
`lib/ui/widgets/dpad.dart` 파일 삭제: `Remove-Item lib\ui\widgets\dpad.dart`

- [ ] **Step 5: 테스트·분석**

Run: `flutter test --no-pub test/ui/game_screen_test.dart` → PASS
Run: `flutter analyze` → No issues found

- [ ] **Step 6: 커밋**

```powershell
git add -A; git commit -m "가상 조이스틱 도입, 십자키·스와이프 제거

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Jua 폰트 번들

**Files:**
- Create: `assets/fonts/Jua-Regular.ttf`, `assets/fonts/OFL.txt` (다운로드 — 사용자 허락 완료)
- Modify: `pubspec.yaml`, `lib/ui/theme.dart`

**Interfaces:**
- Produces: 앱 전역 `fontFamily: 'Jua'`

- [ ] **Step 1: 폰트 다운로드** (Google Fonts 공식 저장소, 약 1.3MB)

```powershell
New-Item -ItemType Directory -Force assets\fonts | Out-Null
Invoke-WebRequest -Uri "https://github.com/google/fonts/raw/main/ofl/jua/Jua-Regular.ttf" -OutFile "assets\fonts\Jua-Regular.ttf"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/google/fonts/main/ofl/jua/OFL.txt" -OutFile "assets\fonts\OFL.txt"
(Get-Item assets\fonts\Jua-Regular.ttf).Length
```
Expected: 1MB 내외 크기 출력. 실패(네트워크) 시 사용자에게 알리고 이 태스크만 건너뛴다 — 이후 태스크는 독립.

- [ ] **Step 2: pubspec 등록**

`pubspec.yaml`의 `flutter:` 섹션(assets 아래)에 추가:

```yaml
  fonts:
    - family: Jua
      fonts:
        - asset: assets/fonts/Jua-Regular.ttf
```

- [ ] **Step 3: 테마 적용**

`theme.dart`의 `piyakTheme()`에서 `fontFamily: null,` 줄을 `fontFamily: 'Jua',`로 바꾼다.

- [ ] **Step 4: 분석 + 커밋**

Run: `flutter analyze` → No issues found

```powershell
git add -A; git commit -m "Jua 폰트 번들·전역 적용 (OFL)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: 배경 재활용 + 알 PNG

**Files:**
- Create: `assets/images/bg/bg_act1.png` ~ `bg_act4.png`, `assets/images/egg.png` (복사)
- Create: `lib/ui/widgets/act_background.dart`
- Modify: `pubspec.yaml`, `lib/ui/widgets/tile_painter.dart`, `lib/ui/screens/game_screen.dart`, `title_screen.dart`, `chapter_screen.dart`, `daily_screen.dart`

**Interfaces:**
- Produces:
  - `class ActBackground extends StatelessWidget { final int chapter; const ActBackground({this.chapter = 1, super.key}); }` — 막 판정 `(chapter - 1) ~/ 5`, 이미지 하단 정렬 + 위쪽은 creamBg 그라데이션 페이드. Stack 최하층용
  - `_EggPainter`가 몸통을 그리지 않고 `assets/images/egg.png` 위에 눈·볼터치·행복 표정만 오버레이

- [ ] **Step 1: 에셋 복사·등록**

```powershell
New-Item -ItemType Directory -Force assets\images\bg | Out-Null
Copy-Item C:\workAndroid\PiyakAssets\banner\banner_grass.png assets\images\bg\bg_act1.png
Copy-Item C:\workAndroid\PiyakAssets\banner\banner_sky.png assets\images\bg\bg_act2.png
Copy-Item C:\workAndroid\PiyakAssets\banner\banner_class.png assets\images\bg\bg_act3.png
Copy-Item C:\workAndroid\PiyakAssets\banner\banner_night.png assets\images\bg\bg_act4.png
Copy-Item C:\workAndroid\PiyakAssets\words\word_egg.png assets\images\egg.png
```

`pubspec.yaml` assets에 `- assets/images/bg/`와 `- assets/images/egg.png` 추가.

- [ ] **Step 2: ActBackground**

`lib/ui/widgets/act_background.dart`:

```dart
/// 막별 배경 — 기존 codex 배너 그림을 하단에 깔고 위는 크림색으로 녹인다.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class ActBackground extends StatelessWidget {
  final int chapter;
  const ActBackground({this.chapter = 1, super.key});

  @override
  Widget build(BuildContext context) {
    final act = ((chapter - 1) ~/ 5).clamp(0, 3) + 1;
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: PiyakColors.creamBg),
              child: const SizedBox.expand(),
            ),
          ),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black],
              stops: [0.0, 0.35],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              'assets/images/bg/bg_act$act.png',
              width: double.infinity,
              fit: BoxFit.cover,
              height: 260,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 화면에 배경 깔기**

- `game_screen.dart`: `SafeArea`의 `Stack` 첫 자식으로 `ActBackground(chapter: widget.level.chapter)` 추가 (`chapter: 0`인 데일리는 1막 배경이 된다 — `clamp`가 처리)
- `title_screen.dart`·`chapter_screen.dart`·`daily_screen.dart`: `Scaffold body`를 `Stack(children: [const ActBackground(), <기존 본문>])`으로 감싼다. chapter_screen은 `ListView` 위에 얹으므로 기존 본문을 그대로 두 번째 자식으로

- [ ] **Step 4: 알 PNG + 얼굴 오버레이**

`tile_painter.dart`의 `EggSprite.build`에서 `CustomPaint`를 Stack으로 교체한다:

```dart
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.all(widget.size * 0.10),
            child: Image.asset('assets/images/egg.png', fit: BoxFit.contain),
          ),
          CustomPaint(painter: _EggPainter(widget.onNest)),
        ],
      ),
```

`_EggPainter.paint`에서 몸통 타원(`drawOval` fill/line)과 광택 블록을 **삭제**하고 눈·볼터치·행복 표정만 남긴다 (좌표는 기존 비율 그대로 — PNG가 같은 자리에 온다).

- [ ] **Step 5: 스모크 + 분석**

Run: `flutter test --no-pub test/ui/board_view_test.dart` → PASS
Run: `flutter analyze` → No issues found

- [ ] **Step 6: 커밋**

```powershell
git add -A; git commit -m "막별 배경(codex 배너 재활용) + 알 PNG·얼굴 오버레이

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: TileArt 계층 + codex 의뢰서

**Files:**
- Create: `lib/services/tile_art.dart`
- Create: `docs/codex-art-request.md`
- Modify: `lib/main.dart`, `lib/ui/widgets/board_view.dart`, `lib/ui/screens/title_screen.dart`, `pubspec.yaml`
- Create: `assets/images/tiles/.gitkeep` (빈 폴더 유지용)
- Test: `test/services/tile_art_test.dart`

**Interfaces:**
- Produces:
  - `class TileArt { static Future<void> load(); static ImageProvider? of(Tile t); static ImageProvider? logo; }` — `AssetManifest`에서 `assets/images/tiles/` 존재 파일만 매핑. 없으면 null → 호출부가 페인터 폴백
  - 파일명 규약: `tile_grass` `tile_wall` `tile_nest` `tile_ice` `tile_portal_purple`(1·2) `tile_portal_orange`(3·4) `tile_button_pink`(b) `tile_door_pink`(B) `tile_button_blue`(d) `tile_door_blue`(D) `tile_cracked` + `logo`
  - `BoardView`: art가 있는 타일은 셀 위치에 `Image(image:)` 위젯을 겹치고, `BoardPainter`에 `final Set<Tile> skip;`을 넘겨 그 타일의 장식을 건너뛴다(바탕 잔디는 항상 페인터)

- [ ] **Step 1: 테스트 작성**

`test/services/tile_art_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/tile.dart';
import 'package:piyak_push/services/tile_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('타일 PNG가 없으면 null (페인터 폴백)', () async {
    await TileArt.load();
    // 아직 codex 그림이 없으므로 전부 null이어야 한다
    expect(TileArt.of(Tile.wall), null);
    expect(TileArt.of(Tile.ice), null);
    expect(TileArt.logo, null);
  });
}
```

- [ ] **Step 2: 실행해 실패 확인**

Run: `flutter test --no-pub test/services/tile_art_test.dart`
Expected: FAIL — `tile_art.dart` 없음

- [ ] **Step 3: TileArt 구현**

`lib/services/tile_art.dart`:

```dart
/// "PNG가 있으면 그림, 없으면 페인터" 계층. codex 그림이 도착하기 전에도
/// 앱이 동작하고, assets/images/tiles/에 파일을 넣고 빌드만 다시 하면 적용된다.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../engine/tile.dart';

class TileArt {
  static const _dir = 'assets/images/tiles';

  static const _names = {
    Tile.floor: 'tile_grass',
    Tile.wall: 'tile_wall',
    Tile.nest: 'tile_nest',
    Tile.ice: 'tile_ice',
    Tile.portal1: 'tile_portal_purple',
    Tile.portal2: 'tile_portal_purple',
    Tile.portal3: 'tile_portal_orange',
    Tile.portal4: 'tile_portal_orange',
    Tile.buttonB: 'tile_button_pink',
    Tile.doorB: 'tile_door_pink',
    Tile.buttonD: 'tile_button_blue',
    Tile.doorD: 'tile_door_blue',
    Tile.cracked: 'tile_cracked',
  };

  static Map<Tile, ImageProvider>? _map;
  static ImageProvider? logo;

  static Future<void> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();
    _map = {
      for (final e in _names.entries)
        if (assets.contains('$_dir/${e.value}.png'))
          e.key: AssetImage('$_dir/${e.value}.png'),
    };
    logo = assets.contains('$_dir/logo.png')
        ? const AssetImage('$_dir/logo.png')
        : null;
  }

  static ImageProvider? of(Tile t) => _map?[t];
}
```

`pubspec.yaml` assets에 `- assets/images/tiles/` 추가, 빈 폴더가 유지되게 `.gitkeep` 생성:
```powershell
New-Item -ItemType Directory -Force assets\images\tiles | Out-Null
New-Item -ItemType File assets\images\tiles\.gitkeep | Out-Null
```
(주의: 에셋 디렉터리가 비어 있으면 빌드 경고가 나므로 `.gitkeep`이 아니라 pubspec에는 등록하되 경고가 나면 등록을 `logo.png` 도착 후로 미룬다 — 빌드가 실패하면 pubspec의 tiles 줄을 지우고 `TileArt.load()`의 manifest 조회는 그대로 둔다. manifest에 없으니 전부 null로 동작한다.)

`lib/main.dart`의 `main()`에서 `SaveService.load()` 앞에 `await TileArt.load();` 추가 (`import 'services/tile_art.dart';`).

- [ ] **Step 4: BoardView·타이틀 연결**

`board_view.dart`의 `BoardPainter` 생성자를 `BoardPainter(this.board, this.cell, {this.skip = const {}})`로 바꾸고 `final Set<Tile> skip;` 추가. `_paintCell` 첫 부분(바탕 잔디 뒤)에:

```dart
    if (skip.contains(t) && t != Tile.floor) return; // 그림이 대신 그린다
```

`BoardView.build`의 CustomPaint를:

```dart
          CustomPaint(
            size: Size(b.width * cell, b.height * cell),
            painter: BoardPainter(b, cell,
                skip: {
                  for (var i = 0; i < b.tiles.length; i++)
                    if (TileArt.of(b.tiles[i]) != null) b.tiles[i]
                }),
          ),
          for (var i = 0; i < b.tiles.length; i++)
            if (TileArt.of(b.tiles[i]) != null)
              Positioned(
                left: (i % b.width) * cell,
                top: (i ~/ b.width) * cell,
                width: cell,
                height: cell,
                child: Image(image: TileArt.of(b.tiles[i])!, fit: BoxFit.contain),
              ),
```

(`import '../../services/tile_art.dart';` 추가)

`title_screen.dart`의 로고 `Text(S.appTitle...)`를:

```dart
                      TileArt.logo != null
                          ? Image(image: TileArt.logo!, height: 90)
                          : const Text(
                              S.appTitle,
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: PiyakColors.outline,
                                letterSpacing: 2,
                              ),
                            ),
```

- [ ] **Step 5: codex 의뢰서 작성**

`docs/codex-art-request.md` — 아래 내용 그대로:

```markdown
# 삐약푸시 타일셋 아트 의뢰 (codex용)

삐약푸시는 병아리가 알을 밀어 둥지에 넣는 소코반 퍼즐이다. 아래 12장의 PNG를
생성해 달라. 완성본은 `C:\workAndroid\PiyakPush\assets\images\tiles\`에 파일명
그대로 넣으면 앱이 자동으로 사용한다 (없으면 코드가 그린 임시 타일로 동작).

## 스타일 가이드 (기존 에셋과 통일)

- 진갈색(#5D4037) 굵은 외곽선 + 파스텔 채움 — `PiyakAssets/chick/chick_idle.png`,
  `PiyakAssets/words/word_egg.png`와 같은 스타일
- 512×512 PNG, 배경 투명, 도형이 캔버스를 거의 꽉 채우게 (여백 5% 이내)
- 타일은 위에서 비스듬히 본 느낌 없이 정면 평면(2D 탑다운 보드게임 말판)
- 귀엽게: 모서리 둥글게, 필요하면 볼터치·광택 한 방울

## 목록

| 파일명 | 내용 |
|---|---|
| tile_grass.png | 밝은 연두 잔디 타일. 둥근 사각형, 잔디 결 두어 개 |
| tile_wall.png | 갈색 나무 울타리 블록 (통나무 느낌 가로줄 2개) |
| tile_nest.png | 지푸라기 둥지 (가운데 움푹, 도넛형) |
| tile_ice.png | 하늘색 얼음 타일, 광택 사선 2개 |
| tile_portal_purple.png | 보라 테두리의 굴(어두운 구멍) |
| tile_portal_orange.png | 주황 테두리의 굴(어두운 구멍) |
| tile_button_pink.png | 분홍 둥근 단추(눌리는 버튼), 잔디 위에 놓인 느낌 |
| tile_door_pink.png | 분홍 자물쇠 무늬가 있는 울타리 문(닫힘) |
| tile_button_blue.png | 하늘색 둥근 단추 |
| tile_door_blue.png | 하늘색 자물쇠 무늬 울타리 문(닫힘) |
| tile_cracked.png | 잔디 타일에 금이 간 모양 (갈라진 선 3~4개) |
| logo.png | 가로형 타이틀 로고 1024×512: "삐약푸시" 손글씨 느낌 + 병아리 얼굴 장식 |

## 확인 방법

파일을 넣은 뒤 `flutter build apk --release`로 다시 빌드하면 게임 보드에
그림 타일이 나온다. 일부만 넣어도 된다 — 있는 것만 그림으로 바뀐다.
```

- [ ] **Step 6: 테스트·분석·커밋**

Run: `flutter test --no-pub test/services/tile_art_test.dart` → PASS
Run: `flutter analyze` → No issues found

```powershell
git add -A; git commit -m "TileArt 계층(PNG 있으면 그림, 없으면 페인터) + codex 타일셋 의뢰서

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: 화면 전환·버튼 반동·팝업 등장

**Files:**
- Create: `lib/ui/nav.dart`
- Modify: `lib/ui/screens/title_screen.dart`, `chapter_screen.dart`, `stage_screen.dart`, `daily_screen.dart`, `lib/ui/widgets/clear_popup.dart`

**Interfaces:**
- Produces: `Route<T> piyakRoute<T>(Widget page)` — 페이드 + 아래서 6% 떠오름, 220ms

- [ ] **Step 1: piyakRoute**

`lib/ui/nav.dart`:

```dart
/// 공용 화면 전환 — 페이드 + 살짝 떠오르는 220ms.
library;

import 'package:flutter/material.dart';

Route<T> piyakRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
```

- [ ] **Step 2: 라우트 교체**

네 화면에서 `MaterialPageRoute(builder: (_) => X)`를 전부 `piyakRoute(X)`로 바꾼다
(`import '../nav.dart';` 추가). 대상: title_screen(메뉴 5곳), chapter_screen(1곳),
stage_screen(`_gameRoute` 내부 1곳 + `_outcomeFor`의 StageScreen 교체 1곳), daily_screen(1곳).
`_gameRoute`의 반환 타입은 `Route`라 그대로 호환된다.

- [ ] **Step 3: 버튼 반동 + 팝업 등장**

`title_screen.dart`의 `_menuButton`에서 `FilledButton`을 `AnimatedScale` 반동으로 감싼다 —
`FilledButton`의 `style`에 이미 `elevation: 0`이 있으니 그대로 두고, `DecoratedBox` 안을:

```dart
        child: _Bouncy(
          child: FilledButton(
            style: style,
            onPressed: () => Navigator.push(context, piyakRoute(page)),
            child: Text(label),
          ),
        ),
```

파일 하단에 추가:

```dart
/// 눌리는 동안 살짝 줄어드는 반동.
class _Bouncy extends StatefulWidget {
  final Widget child;
  const _Bouncy({required this.child});

  @override
  State<_Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<_Bouncy> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}
```

`clear_popup.dart`에서 카드(`Center` 안의 `Container`)를 등장 스케일로 감싼다:

```dart
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _ctrl,
                curve: const Interval(0.0, 0.30, curve: Curves.elasticOut),
              ),
              child: Container(
                // ... 기존 카드 그대로
```

- [ ] **Step 4: 분석 + 커밋**

Run: `flutter analyze` → No issues found

```powershell
git add -A; git commit -m "화면 전환 페이드·떠오름 + 버튼 반동 + 클리어 팝업 등장 연출

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: 빌드·실기기 확인

**Files:** 없음 (빌드 산출물)

- [ ] **Step 1: 변경 테스트 1회 + 분석**

Run: `flutter analyze` 그리고 `flutter test --no-pub test/ui/ test/services/tile_art_test.dart`
Expected: 통과. (전체 스위트는 돌리지 않는다 — Global Constraints)

- [ ] **Step 2: 릴리즈 빌드**

```powershell
flutter build apk --release
```

- [ ] **Step 3: 설치·확인**

```powershell
C:\workAndroid\android-sdk-ascii\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-release.apk
C:\workAndroid\android-sdk-ascii\platform-tools\adb.exe shell am start -n com.piyak.piyak_push/.MainActivity
```

육안 체크리스트(스크린샷 근거):
1. 타이틀 — Jua 폰트·잔디 배경이 보이는가
2. 게임 — 조이스틱으로 연속 이동이 물 흐르듯 이어지는가, 알 PNG·막별 배경
3. 사용자에게 codex 의뢰서 위치(`docs/codex-art-request.md`) 안내

- [ ] **Step 4: 커밋·머지**

```powershell
git add -A; git commit -m "v2.1 마무리"; git checkout main; git merge feature/v21-feel; git branch -d feature/v21-feel
```

---

## Self-Review 기록

- **스펙 커버리지**: 1절 연속 이동·걸음 연출→T1 / 2절 조이스틱·제거→T2 / 3.1 폰트→T3 / 3.2 재활용→T4 / 3.3 TileArt·의뢰서·로고→T5 / 3.4 전환·반동→T6 / 테스트 전략→T2·T5 + "전체 스위트 미실행" 제약 반영. 누락 없음.
- **타입 일관성**: `holdDir`/`releaseDir`(T1)를 T2의 Joystick 배선이 사용. `EggSprite(pos, size, onNest)`(T1)를 T4가 내부 수정. `TileArt.of`/`logo`(T5)를 board_view·title_screen이 사용. `piyakRoute`(T6) 시그니처 일관.
- **순서**: T1→T2 필수(홀드 API), T4는 T1의 EggSprite 이후. T3·T5·T6 상호 독립.
- **위험**: 빈 `assets/images/tiles/` 등록이 빌드 경고/실패를 낼 수 있음 — T5 Step 3에 폴백 절차 명시.
