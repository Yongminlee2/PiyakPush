# 삐약푸시 (PiyakPush) 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 병아리가 알을 둥지로 미는 소코반 퍼즐(50스테이지 + 데일리)을 Flutter로 완성하고 릴리즈 APK를 실기기에 설치한다.

**Architecture:** `lib/engine`은 Flutter 의존 없는 순수 Dart(불변 Board + tryMove가 새 Board와 이벤트 목록 반환). BFS 솔버가 레벨 검증·별 기준·힌트를 모두 담당. UI는 순수 Flutter 위젯(타일은 CustomPainter, 캐릭터는 기존 PNG), 상태는 provider(ChangeNotifier), 저장은 shared_preferences.

**Tech Stack:** Flutter stable / provider / shared_preferences / audioplayers / (dev) flutter_launcher_icons / Python 3.12(SFX 생성)

## Global Constraints

- 스펙: `docs/superpowers/specs/2026-08-02-piyakpush-design.md` (규칙 충돌 시 스펙 우선)
- Flame 등 게임엔진 금지, 순수 Flutter 위젯만
- 런타임 의존성은 `provider`, `shared_preferences`, `audioplayers` 3개만 (dev 의존성: `flutter_launcher_icons`)
- `lib/engine/` 아래 파일은 `dart:` 이외 import 금지 (Flutter·패키지 의존 금지)
- ASCII 경로 강제: Flutter SDK `C:\flutter`, `PUB_CACHE=C:\flutter\.pub-cache`, `GRADLE_USER_HOME=C:\workAndroid\gradle-user-ascii`, Android SDK `C:\workAndroid\android-sdk-ascii`
- 프로젝트명 `piyak_push`, org `com.piyak`, 앱 표시명 `삐약푸시`
- 레벨 파일 수정 후엔 반드시 `dart run tool/validate_levels.dart` 통과 후 커밋
- 한국어 UI 문자열은 전부 `lib/ui/strings.dart` 상수로만 사용
- 커밋 메시지는 한국어 요약 + `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- 모든 셸 명령은 PowerShell 기준. 매 세션 시작 시 `$env:Path = "C:\flutter\bin;$env:Path"; $env:PUB_CACHE = "C:\flutter\.pub-cache"; $env:GRADLE_USER_HOME = "C:\workAndroid\gradle-user-ascii"` 선행

### ASCII 레벨 기호 (전 태스크 공통)

`#`벽 `.`바닥 `@`병아리 `$`알 `o`둥지 `*`둥지 위 알 `+`둥지 위 병아리 `i`얼음 `c`금 간 바닥 `1↔2`,`3↔4`굴 쌍 `b`,`d`버튼 `B`,`D`대응 문

### 엔진 규칙 확정 사항 (스펙 보완)

- 굴에서 나온 알은 그 자리(짝 굴 칸)에서 멈춘다. 굴 칸은 얼음일 수 없으므로 "나온 칸이 얼음이면 계속" 규칙은 자연 소멸.
- 금 간 바닥 위의 알을 밀면: 알이 떠난 직후 그 칸이 구멍이 되므로 병아리는 따라 들어가지 못하고 제자리에 남는다(밀기는 성공, 1수 카운트).
- 미끄러지는 알은 얼음 칸에 있는 동안만 계속 전진한다. 금 간 바닥·굴 등 비얼음 칸에 들어서면 멈춘다.

---

### Task 1: Flutter SDK 설치 + 프로젝트 스캐폴드

**Files:**
- Create: `C:\flutter` (SDK), `pubspec.yaml`, `analysis_options.yaml`, Flutter 표준 스캐폴드 전체
- Create: `.gitignore` (flutter create 기본 + `.pub-cache/`)

**Interfaces:**
- Produces: 이후 모든 태스크가 쓰는 실행 환경. `flutter test`, `dart run` 동작 보장.

- [ ] **Step 1: Flutter SDK 클론** (약 1GB 다운로드, 수 분 소요)

```powershell
git clone -b stable --depth 1 https://github.com/flutter/flutter.git C:\flutter
$env:Path = "C:\flutter\bin;$env:Path"; $env:PUB_CACHE = "C:\flutter\.pub-cache"
flutter --version
```
Expected: Flutter stable 버전 출력 (첫 실행 시 Dart SDK 자동 다운로드)

- [ ] **Step 2: Android 툴체인 연결 + doctor**

```powershell
flutter config --android-sdk "C:\workAndroid\android-sdk-ascii"
flutter doctor --android-licenses
flutter doctor
```
Expected: Android toolchain OK. JDK 없으면 `winget install EclipseAdoptium.Temurin.17.JDK` 후 재시도. (VS/Chrome 경고는 무시 가능 — 모바일 타깃만 사용)

- [ ] **Step 3: 프로젝트 생성** (기존 `docs/` 유지한 채 현재 폴더에 생성)

```powershell
cd C:\workAndroid\PiyakPush
flutter create --project-name piyak_push --org com.piyak --platforms android,ios .
flutter pub add provider shared_preferences audioplayers
flutter test
```
Expected: 기본 위젯 테스트 PASS

- [ ] **Step 4: 커밋**

```powershell
git add -A; git commit -m "Flutter 프로젝트 스캐폴드 + 의존성 3종"
```

---

### Task 2: 엔진 기반 타입 + ASCII 파싱

**Files:**
- Create: `lib/engine/geometry.dart`, `lib/engine/tile.dart`, `lib/engine/board.dart`
- Test: `test/engine/board_parse_test.dart`

**Interfaces:**
- Produces (이후 전 태스크의 기반):
  - `enum Dir { up, down, left, right }`
  - `class Point { final int x, y; const Point(this.x, this.y); Point step(Dir d); }` (==, hashCode 구현)
  - `enum Tile { floor, wall, nest, ice, cracked, hole, portal1, portal2, portal3, portal4, buttonB, buttonD, doorB, doorD }`
  - 헬퍼: `Tile? portalPair(Tile)`, `bool isPortal(Tile)`, `bool isButton(Tile)`, `bool isDoor(Tile)`, `Tile doorForButton(Tile)`, `Tile buttonForDoor(Tile)`
  - `class Board { final int width, height; final List<Tile> tiles; final Set<Point> eggs; final Point chick; }`
  - `factory Board.fromAscii(List<String> rows)` — `$`/`*`는 eggs에, `@`/`+`는 chick에, 바탕 타일은 tiles에
  - `Tile tileAt(Point p)`, `bool inBounds(Point p)`, `bool get isCleared` (모든 알이 nest 위), `String get stateKey` (chick + 정렬된 eggs + 남은 cracked 인덱스), `Board copyWith({List<Tile>? tiles, Set<Point>? eggs, Point? chick})`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
// test/engine/board_parse_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/tile.dart';

void main() {
  test('ASCII 파싱: 기호별 타일·알·병아리 배치', () {
    final b = Board.fromAscii(['#####', '#@\$o#', '#i*c#', '#1b2B#'.substring(0, 5), '#####']);
    expect(b.width, 5);
    expect(b.chick, const Point(1, 1));
    expect(b.eggs, {const Point(2, 1), const Point(2, 2)});
    expect(b.tileAt(const Point(3, 1)), Tile.nest);
    expect(b.tileAt(const Point(2, 2)), Tile.nest); // '*' 알 밑은 둥지
    expect(b.tileAt(const Point(1, 2)), Tile.ice);
    expect(b.tileAt(const Point(3, 2)), Tile.cracked);
    expect(b.isCleared, false);
  });
  test('isCleared: 모든 알이 둥지 위', () {
    final b = Board.fromAscii(['#####', '#@*o#', '#####']);
    expect(b.isCleared, true);
  });
  test('stateKey는 배치 동일하면 동일', () {
    final a = Board.fromAscii(['####', '#@\$#', '####']);
    final b2 = Board.fromAscii(['####', '#@\$#', '####']);
    expect(a.stateKey, b2.stateKey);
  });
}
```

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/engine/board_parse_test.dart` → FAIL (파일 없음)
- [ ] **Step 3: 구현** — 위 Produces 시그니처 그대로. `fromAscii`는 행 길이가 다르면 짧은 행을 wall로 패딩. 알 수와 둥지 수 불일치면 `ArgumentError`.
- [ ] **Step 4: 통과 확인** — `flutter test test/engine/board_parse_test.dart` → PASS
- [ ] **Step 5: 커밋** — `git add -A; git commit -m "엔진: 보드 타입·ASCII 파싱"`

---

### Task 3: 기본 이동·밀기 (tryMove)

**Files:**
- Create: `lib/engine/move.dart` (GameEvent, MoveOutcome, Board 확장 tryMove)
- Test: `test/engine/move_basic_test.dart`

**Interfaces:**
- Produces:
  - `enum GameEventType { chickMoved, chickTeleported, eggPushed, eggSlid, eggTeleported, eggNested, floorBroke, doorOpened, doorClosed }`
  - `class GameEvent { final GameEventType type; final Point from; final Point to; }`
  - `class MoveOutcome { final Board? board; final List<GameEvent> events; bool get blocked => board == null; }`
  - `extension BoardMove on Board { MoveOutcome tryMove(Dir d); bool occupied(Point p); bool doorOpenFor(Tile door); }`
  - 이동 알고리즘 순서(태스크 4~7이 이 골격에 살을 붙임): ①목표 칸 판정 ②알이면 밀기 판정(착지 계산: 굴 해석→얼음 슬라이드) ③알 이동 확정, 떠난 칸 붕괴 ④병아리 이동(막히면 제자리) ⑤병아리가 떠난 칸 붕괴 ⑥문 상태 변화 이벤트
  - `doorOpenFor`: 대응 버튼 위에 알·병아리가 있거나, 그 문 칸 위에 알·병아리가 있으면 true (파생 상태, 저장 없음)

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
// test/engine/move_basic_test.dart (발췌 — 전 케이스 나열)
test('빈 칸 이동', () {
  final o = Board.fromAscii(['####', '#@.#', '####']).tryMove(Dir.right);
  expect(o.board!.chick, const Point(2, 1));
  expect(o.events.map((e) => e.type), contains(GameEventType.chickMoved));
});
test('벽으로 이동 불가', () {
  expect(Board.fromAscii(['###', '#@#', '###']).tryMove(Dir.right).blocked, true);
});
test('알 밀기 + 둥지 도착 이벤트', () {
  final o = Board.fromAscii(['#####', '#@\$o#', '#####']).tryMove(Dir.right);
  expect(o.board!.eggs, {const Point(3, 1)});
  expect(o.board!.chick, const Point(2, 1));
  expect(o.board!.isCleared, true);
  expect(o.events.map((e) => e.type), contains(GameEventType.eggNested));
});
```
추가 케이스(각각 별도 test로, 기대값 명시): 알 두 개 연속 → blocked / 알 뒤 벽 → blocked / 둥지 위 알도 다시 밀림 / 보드 밖 이동 → blocked.

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/engine/move_basic_test.dart` → FAIL
- [ ] **Step 3: 구현** — 위 알고리즘 순서대로. 이번 태스크에선 floor/wall/nest만 처리하고 얼음·굴·문·붕괴 지점은 훅 함수(`_resolveEggLanding`, `_afterLeave`)로 비워 둔다(현재는 항등 동작).
- [ ] **Step 4: 통과 확인** → PASS
- [ ] **Step 5: 커밋** — `"엔진: 기본 이동·밀기"`

---

### Task 4: 얼음 미끄러짐

**Files:**
- Modify: `lib/engine/move.dart` (`_resolveEggLanding`에 슬라이드 루프)
- Test: `test/engine/move_ice_test.dart`

**Interfaces:**
- Consumes: Task 3의 tryMove 골격
- Produces: 알이 얼음 위에 있는 동안 같은 방향 전진, 비얼음 칸 진입 또는 전방 막힘 시 정지. 칸당 `eggSlid` 이벤트 1개(from→to). 병아리는 얼음에서 평범하게 걷는다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('얼음 위 미끄러져 끝까지', () {
  final o = Board.fromAscii(['#######', '#@\$ii.#', '#######']).tryMove(Dir.right);
  expect(o.board!.eggs, {const Point(5, 1)}); // 얼음 2칸 지나 바닥에서 정지
});
test('얼음 중간 벽에 막힘', () {
  final o = Board.fromAscii(['######', '#@\$i##', '######']).tryMove(Dir.right);
  expect(o.board!.eggs, {const Point(3, 1)}); // 얼음 칸에서 정지
});
```
추가 케이스: 얼음 위 다른 알에 막힘 / 얼음에서 둥지로 미끄러져 eggNested / 병아리는 얼음에서 한 칸씩만 이동.

- [ ] **Step 2~5:** FAIL 확인 → 슬라이드 루프 구현(현재 칸이 ice인 동안 다음 칸 진입 시도) → PASS → 커밋 `"엔진: 얼음 미끄러짐"`

---

### Task 5: 텔레포트 굴

**Files:**
- Modify: `lib/engine/move.dart` (진입 해석 시 굴 처리)
- Test: `test/engine/move_portal_test.dart`

**Interfaces:**
- Consumes: Task 4까지의 tryMove
- Produces: 병아리·알이 굴 칸 진입 시 짝 굴로 즉시 이동(`chickTeleported`/`eggTeleported`). 짝 굴 출구가 점유(알·병아리)면 진입 자체 불가(blocked). 굴에서 나온 알은 그 자리에서 정지.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('병아리 굴 통과', () {
  final o = Board.fromAscii(['######', '#@1.2#', '######']).tryMove(Dir.right);
  expect(o.board!.chick, const Point(4, 1)); // 1로 들어가 2로 나옴
});
test('알 굴 통과 후 정지', () {
  final o = Board.fromAscii(['#######', '#@\$1.2#', '#######']).tryMove(Dir.right);
  expect(o.board!.eggs, {const Point(5, 1)});
});
test('출구 막히면 진입 불가', () {
  // 짝 굴(2) 바로 위에 알이 있는 배치: 병아리가 1로 들어가려 해도 출구 점유로 blocked
  final b = Board.fromAscii(['######', '#@1.2#', '######'])
      .copyWith(eggs: {const Point(4, 1)});
  expect(b.tryMove(Dir.right).blocked, true);
});
```
추가 케이스: 얼음에서 미끄러지던 알이 굴 진입 → 짝 굴에서 정지 / 3·4 쌍 독립 동작.

- [ ] **Step 2~5:** FAIL → 진입 해석 함수에서 `isPortal`이면 짝 굴 좌표로 치환(점유 시 null) → PASS → 커밋 `"엔진: 텔레포트 굴"`

---

### Task 6: 버튼·문

**Files:**
- Modify: `lib/engine/move.dart` (닫힌 문 통행 차단 + 문 상태 변화 이벤트)
- Test: `test/engine/move_door_test.dart`

**Interfaces:**
- Consumes: Task 5까지
- Produces: 닫힌 문은 벽 취급(병아리·알·슬라이드 모두). `doorOpenFor` 파생 규칙은 Task 3 정의 그대로. 이동 전후 문 상태가 바뀌면 `doorOpened`/`doorClosed` 이벤트.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('버튼 위 알 → 문 열림', () {
  final b = Board.fromAscii(['#######', '#@\$b.B#', '#######']).tryMove(Dir.right).board!; // 알이 버튼 위로
  expect(b.doorOpenFor(Tile.doorB), true);
  expect(b.tryMove(Dir.right), isNot(predicate((o) => (o as MoveOutcome).blocked))); // 병아리 버튼 위 알 밀며 전진 가능? → 아래 추가 케이스로 세분
});
test('닫힌 문은 벽', () {
  expect(Board.fromAscii(['#####', '#@B.#', '#####']).tryMove(Dir.right).blocked, true);
});
test('문 위에 있으면 버튼 떼도 안 닫힘', () {
  // 병아리가 열린 문 위에 있는 상태를 fromAscii로 직접 구성해 검증
  final b = Board.fromAscii(['#######', '#.\$b.B#', '#######']).copyWith(chick: const Point(5, 1));
  // 버튼 위 알($ 위치를 b로 이동시킨 상태) 구성: eggs를 {Point(3,1)}로
  final onDoor = b.copyWith(eggs: {const Point(3, 1)});
  expect(onDoor.doorOpenFor(Tile.doorB), true); // 버튼 점유
  final released = onDoor.copyWith(eggs: {const Point(2, 1)}); // 버튼에서 내려옴
  expect(released.doorOpenFor(Tile.doorB), true); // 병아리가 문 위 → 유지
});
```
추가 케이스: 알이 열린 문 칸에 있으면 유지 / 슬라이드 중 닫힌 문에 막힘 / b·B와 d·D 독립.

- [ ] **Step 2~5:** FAIL → 구현 → PASS → 커밋 `"엔진: 버튼과 문"`

---

### Task 7: 금 간 바닥·구멍

**Files:**
- Modify: `lib/engine/move.dart` (`_afterLeave` 훅 구현)
- Test: `test/engine/move_crack_test.dart`

**Interfaces:**
- Consumes: Task 6까지
- Produces: 병아리·알이 cracked 칸을 떠나면 그 칸이 hole로 변경(`floorBroke`). hole은 누구도 진입 불가. 금 간 바닥 위 알을 밀면 알만 이동하고 병아리는 제자리(밀기 성공, 이벤트 eggPushed+floorBroke). stateKey에 cracked 잔존 상태 반영(이미 Task 2에서 키에 포함).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('병아리가 지나가면 구멍', () {
  final b1 = Board.fromAscii(['#####', '#@c.#', '#####']).tryMove(Dir.right).board!;
  final b2 = b1.tryMove(Dir.right).board!;
  expect(b2.tileAt(const Point(2, 1)), Tile.hole);
  expect(b2.tryMove(Dir.left).blocked, true); // 구멍으로 못 돌아감
});
test('금 간 바닥 위 알을 밀면 병아리는 제자리', () {
  final o = Board.fromAscii(['#####', '#@\$.#', '#####']);
  final start = o.copyWith(tiles: (() { final t = List<Tile>.from(o.tiles); t[1 * 5 + 2] = Tile.cracked; return t; })());
  final r = start.tryMove(Dir.right);
  expect(r.board!.eggs, {const Point(3, 1)});
  expect(r.board!.chick, const Point(1, 1)); // 제자리
  expect(r.board!.tileAt(const Point(2, 1)), Tile.hole);
});
```
추가 케이스: 알을 구멍 방향으로 밀기 → blocked / cracked 위 알이 얼음 쪽으로 밀려 미끄러진 뒤에도 원래 칸은 hole.

- [ ] **Step 2~5:** FAIL → 구현 → PASS → 커밋 `"엔진: 금 간 바닥과 구멍"`

---

### Task 8: 데드락 감지

**Files:**
- Create: `lib/engine/deadlock.dart`
- Test: `test/engine/deadlock_test.dart`

**Interfaces:**
- Consumes: Board
- Produces: `bool hasCornerDeadlock(Board b)` — 둥지가 아닌 칸의 알이 직교 두 방향(예: 위+왼쪽)이 모두 벽(보드 밖 포함)이면 true. 문·알은 벽으로 치지 않음(열릴/움직일 수 있으므로 오탐 방지).

- [ ] **Step 1: 테스트 작성**

```dart
test('모서리 알 = 데드락', () {
  expect(hasCornerDeadlock(Board.fromAscii(['####', '#\$.#', '#.@#', '####'])), true);
});
test('둥지 위 모서리 알은 데드락 아님', () {
  expect(hasCornerDeadlock(Board.fromAscii(['####', '#*.#', '#.@#', '####'])), false);
});
```
추가 케이스: 벽 한 방향만 접촉 → false / 보드 밖 경계도 벽 취급 → true / 닫힌 문 옆 알 → false(문은 열릴 수 있음).

- [ ] **Step 2~5:** FAIL → 구현 → PASS → 커밋 `"엔진: 모서리 데드락 감지"`

---

### Task 9: BFS 솔버

**Files:**
- Create: `lib/engine/solver.dart`
- Test: `test/engine/solver_test.dart`

**Interfaces:**
- Consumes: Board.tryMove, stateKey, hasCornerDeadlock
- Produces: `class Solver { final int maxStates; Solver({this.maxStates = 2000000}); List<Dir>? solve(Board start); }` — 이동수 최적해(BFS, 이동 1수=간선 1). 미해결/상한 초과 시 null. 데드락 상태는 큐에 넣지 않음. 방문 판정은 stateKey.

- [ ] **Step 1: 테스트 작성**

```dart
test('1수 최적해', () {
  expect(Solver().solve(Board.fromAscii(['#####', '#@\$o#', '#####'])), [Dir.right]);
});
test('돌아가서 밀기 최적해 길이', () {
  final sol = Solver().solve(Board.fromAscii(['#####', '#.o.#', '#.\$.#', '#.@.#', '#####']))!;
  expect(sol.length, 1); // 위로 한 번
});
test('불가능 레벨은 null', () {
  expect(Solver().solve(Board.fromAscii(['####', '#@\$#', '#o.#', '####'])), null); // 알이 오른벽에 붙어 아래로 못 꺾음
});
test('얼음 포함 레벨도 풀이', () {
  expect(Solver().solve(Board.fromAscii(['#######', '#@\$iio#', '#######'])), [Dir.right]);
});
```

- [ ] **Step 2~5:** FAIL → 구현(부모 맵 `Map<String,(String,Dir)>`로 경로 복원, Queue<Board>) → PASS → 커밋 `"엔진: BFS 솔버"`

---

### Task 10: 레벨 로더 + 검증 CLI

**Files:**
- Create: `lib/models/level.dart`, `lib/services/level_repository.dart`, `tool/validate_levels.dart`
- Create: `assets/levels/chapter1.json` (임시 레벨 1개로 시작)
- Modify: `pubspec.yaml` (assets 등록)
- Test: `test/models/level_test.dart`

**Interfaces:**
- Consumes: Board.fromAscii, Solver
- Produces:
  - `class Level { final String id; final int chapter; final String title; final List<String> rows; final int optimal; Board toBoard(); static Level fromJson(Map<String, dynamic> j); Map<String, dynamic> toJson(); }`
  - `class LevelRepository { static Future<List<Level>> loadChapter(int c); static Future<Level> byId(String id); }` (rootBundle에서 `assets/levels/chapter$c.json` 로드)
  - `tool/validate_levels.dart`: `dart run tool/validate_levels.dart` → assets/levels/chapter*.json + daily_presets.json 전 레벨을 솔버로 풀고 ①불가능 레벨 나열+exit 1 ②optimal 필드를 실측값으로 재기록 ③"챕터별 최적수 분포" 출력
  - 레벨 JSON 형식: `{"id":"c1s01","chapter":1,"title":"첫 걸음","rows":["#####","#@$o#","#####"],"optimal":1}`

- [ ] **Step 1: 테스트 작성** — Level.fromJson/toJson 왕복, toBoard 파싱, 잘못된 rows(알≠둥지 수) ArgumentError.
- [ ] **Step 2~4:** FAIL → 구현 → PASS. `tool/validate_levels.dart`는 `dart:io`로 파일 직접 읽기/쓰기(Flutter 불필요).
- [ ] **Step 5: CLI 동작 확인** — `dart run tool/validate_levels.dart` → 임시 레벨 1개 통과, optimal 기록 확인
- [ ] **Step 6: 커밋** — `"레벨 로더 + 검증 CLI"`

---

### Task 11: 챕터1 레벨 10개 제작

**Files:**
- Modify: `assets/levels/chapter1.json`
- Test: `test/levels/all_levels_solvable_test.dart` (모든 챕터 파일을 solver로 검증하는 테스트 — 이후 챕터 추가 시 자동 포함)

**Interfaces:**
- Consumes: 검증 CLI
- Produces: c1s01~c1s10. 기믹 없이 벽·알·둥지만. s01~s03은 튜토리얼용 초소형(최적 10수 미만), s10은 알 4개 보스급.

- [ ] **Step 1: 레벨 10개 작성** — 예시 두 개(그대로 사용 가능), 나머지 8개는 같은 스타일로 직접 설계:

```json
{"id":"c1s01","chapter":1,"title":"첫 걸음","rows":["#####","#@$o#","#####"],"optimal":0}
{"id":"c1s04","chapter":1,"title":"모퉁이 돌기","rows":["######","#.o..#","#.$$.#","#.@o.#","######"],"optimal":0}
```
설계 규칙: 보드 6×6~9×9, 알 1→4개 점증, 밀어야 할 방향 전환이 스테이지마다 1개씩 늘도록.

- [ ] **Step 2: 검증** — `dart run tool/validate_levels.dart` → 10개 전부 풀이 가능, optimal 자동 기록, s01~s03 최적 10수 미만 확인
- [ ] **Step 3: 전 레벨 테스트 작성·통과** — `flutter test test/levels/` PASS
- [ ] **Step 4: 커밋** — `"챕터1 레벨 10개"`

---

### Task 12: 테마·타일 렌더링·에셋 반입

**Files:**
- Create: `lib/ui/theme.dart`, `lib/ui/strings.dart`, `lib/ui/widgets/tile_painter.dart`, `lib/ui/widgets/board_view.dart`
- Create: `assets/images/chick/` (PiyakAssets에서 11종 복사), `assets/images/sticker/` (12종 복사)
- Test: `test/ui/board_view_test.dart` (스모크)

**Interfaces:**
- Consumes: Board
- Produces:
  - `theme.dart`: `const outline = Color(0xFF5D4037); const grass = Color(0xFFA5D6A7); const iceBlue = Color(0xFFB3E5FC); const creamBg = Color(0xFFFFF8E1);` 등 팔레트 상수 + 둥근 모서리 반경 상수
  - `TilePainter`: CustomPainter — 타일 종류별 그리기(풀밭 바탕, 벽=갈색 울타리, 둥지=지푸라기 링, 얼음=하늘색+광택, 굴=갈색 구멍+숫자색 테두리, 버튼=눌린 원, 문=울타리색+버튼색 자물쇠, 금 간 바닥=균열, 구멍=검은 구멍). 전부 진갈색 외곽선+파스텔 채움.
  - 알은 `EggWidget`(흰 타원+외곽선+볼터치), 병아리는 `Image.asset('assets/images/chick/chick_idle.png')`
  - `BoardView(board: Board, cellSize: double)`: Stack — 바닥 CustomPaint 레이어 + `AnimatedPositioned` 알들(120ms) + 병아리. 알 위치는 `Key('egg-i')`가 아니라 **정렬된 위치 리스트의 안정 매칭**(직전 프레임 위치에서 한 칸 거리 이내 매칭)으로 애니메이션 연속성 유지.
- 에셋 복사: `Copy-Item C:\workAndroid\PiyakAssets\chick\*.png assets\images\chick\` 등. pubspec assets 등록.

- [ ] **Step 1: 에셋 복사 + pubspec 등록**
- [ ] **Step 2: 스모크 테스트 작성** — BoardView를 3×3 보드로 pump → 예외 없음, EggWidget 1개 존재
- [ ] **Step 3: 구현 → 테스트 PASS**
- [ ] **Step 4: 커밋** — `"UI 테마·타일 페인터·보드 뷰 + 에셋 반입"`

---

### Task 13: GameController

**Files:**
- Create: `lib/ui/game_controller.dart`
- Test: `test/ui/game_controller_test.dart`

**Interfaces:**
- Consumes: Level, Board.tryMove, hasCornerDeadlock
- Produces:
  - `enum ChickMood { idle, think, sleep, cheer, sad, speak }`
  - `class GameController extends ChangeNotifier { GameController(this.level); final Level level; Board get board; int get moves; List<GameEvent> get lastEvents; bool get cleared; bool get deadlocked; ChickMood get mood; bool move(Dir d); void undo(); void restart(); int get stars; }`
  - `stars`: cleared 시 moves<=optimal→3, moves<=(optimal*1.5).ceil()→2, 아니면 1. 미클리어 0.
  - undo 무제한(내부 `List<Board>` 히스토리, moves도 히스토리 길이-1), restart는 히스토리 초기화.
  - mood 전이: move 성공→idle 복귀, cleared→cheer, deadlocked→sad. think/sleep 타이머는 컨트롤러가 아니라 화면(Task 14)에서 `markIdle10s()`/`markIdle30s()` 호출로 주입(테스트 용이성).

- [ ] **Step 1: 테스트 작성** — 이동→moves 증가, undo→원복, restart, 클리어 시 stars 계산(최적수 조작한 Level로 3/2/1 각각), 데드락 보드에서 mood==sad.
- [ ] **Step 2~5:** FAIL → 구현 → PASS → 커밋 `"게임 컨트롤러"`

---

### Task 14: 게임 화면

**Files:**
- Create: `lib/ui/screens/game_screen.dart`, `lib/ui/widgets/hud.dart`, `lib/ui/widgets/clear_popup.dart`, `lib/ui/widgets/speech_bubble.dart`, `lib/ui/widgets/dpad.dart`
- Modify: `lib/main.dart` (임시로 게임 화면 직행)
- Test: `test/ui/game_screen_test.dart`

**Interfaces:**
- Consumes: GameController, BoardView, strings.dart
- Produces:
  - `GameScreen(level: Level, {VoidCallback? onNext})` — Scaffold: 상단 HUD(스테이지 제목, `이동 N / 최적 M`, 되돌리기·재시작·힌트 버튼), 중앙 `LayoutBuilder`로 cellSize 산출한 BoardView, 하단 병아리 무드 이미지(`chick_{mood}.png` 매핑: idle→chick_idle, think→chick_think, sleep→chick_sleep, cheer→chick_cheer, sad→chick_sad, speak→chick_speak).
  - 입력: `GestureDetector.onPanEnd` 스와이프(dx·dy 절대값 큰 축, 24px 이상) → `controller.move`. 설정의 D-패드 켜짐 시 우하단 오버레이.
  - think/sleep: `Timer` 10s/30s, 입력 시 리셋.
  - 클리어 → `ClearPopup`(별 1~3개 ScaleTransition 순차, 이동/최적 표시, [다음][다시][목록]).
  - 튜토리얼: level.id가 c1s01~c1s03이면 `SpeechBubble` 고정 문구(strings.dart: 스와이프 안내, 되돌리기 안내, 둥지 목표 안내).
  - 데드락 → SpeechBubble '되돌리기를 눌러볼까?' + sad.
- 사운드 훅: 이벤트→사운드는 Task 17에서 연결(이번엔 인터페이스만 — `void Function(List<GameEvent>)? onEvents` 콜백).

- [ ] **Step 1: 위젯 테스트 작성** — 스와이프 시뮬레이션(drag) → 이동수 텍스트 '이동 1' / 클리어 레벨 pump → ClearPopup 표시·별 3개.
- [ ] **Step 2~5:** FAIL → 구현 → PASS → `flutter run`으로 임시 실행해 육안 확인(에뮬레이터 또는 실기기) → 커밋 `"게임 화면(스와이프·HUD·클리어 팝업·튜토리얼)"`

---

### Task 15: 저장 + 내비게이션 (타이틀·챕터·스테이지·설정)

**Files:**
- Create: `lib/services/save_service.dart`, `lib/ui/screens/title_screen.dart`, `lib/ui/screens/chapter_screen.dart`, `lib/ui/screens/stage_screen.dart`, `lib/ui/screens/settings_screen.dart`
- Modify: `lib/main.dart` (라우팅: '/'→타이틀)
- Test: `test/services/save_service_test.dart` (`SharedPreferences.setMockInitialValues` 사용)

**Interfaces:**
- Consumes: LevelRepository, GameScreen
- Produces:
  - `class SaveService { static Future<SaveService> load(); int starsOf(String levelId); Future<void> setStars(String levelId, int stars); int get totalStars; int chapterStars(int c); bool chapterUnlocked(int c); bool get soundOn; bool get dpadOn; Future<void> setSoundOn(bool v); Future<void> setDpadOn(bool v); Future<void> resetAll(); }`
  - 키 규칙: `stars.<levelId>`(int, 최고 기록만 갱신), `opt.sound`/`opt.dpad`(bool)
  - `chapterUnlocked(c)`: c==1 항상, 그 외 `chapterStars(c-1) >= 12`
  - 화면 흐름: 타이틀[시작/데일리/스티커북/설정] → 챕터(5카드+별 합계, 잠금 자물쇠) → 스테이지(10그리드+별) → GameScreen(onNext로 다음 스테이지, 클리어 시 setStars)
- Provider 주입: `MultiProvider`(SaveService, 이후 SoundService)

- [ ] **Step 1: SaveService 테스트 작성·FAIL** — 별 저장·최고기록 유지(낮은 별로 덮어쓰기 안 됨)·챕터 해금 경계(11개=잠금, 12개=해금)·리셋.
- [ ] **Step 2: 구현 → PASS**
- [ ] **Step 3: 화면 4종 구현 + 수동 확인** (`flutter run` — 타이틀→챕터→스테이지→클리어→별 반영)
- [ ] **Step 4: 커밋** — `"저장 서비스 + 타이틀·챕터·스테이지·설정 화면"`

---

### Task 16: 힌트

**Files:**
- Create: `lib/ui/widgets/hint_overlay.dart`
- Modify: `lib/ui/game_controller.dart` (힌트 상태), `lib/ui/screens/game_screen.dart` (버튼 연결)
- Test: `test/ui/hint_test.dart`

**Interfaces:**
- Consumes: Solver
- Produces: `Future<List<Dir>?> GameController.hint()` — 현재 board를 `compute(_solveEntry, stateAscii)`로 백그라운드 풀이, 앞 5수 반환(전체가 5수 미만이면 전부). BoardView 위에 병아리 위치부터 화살표 5개 오버레이(반투명, 다음 입력 시 사라짐). 풀이 불가(데드락) 시 SpeechBubble '지금은 길이 없어… 되돌리기!'.
- compute 인자는 순수 데이터(rows 직렬화) — Board 자체를 넘기지 않는다.

- [ ] **Step 1: 테스트** — 1수 레벨에서 hint()==[Dir.right] / 데드락 보드에서 null.
- [ ] **Step 2~5:** FAIL → 구현 → PASS → 커밋 `"힌트(솔버 재사용)"`

---

### Task 17: 사운드

**Files:**
- Create: `tool/gen_sfx.py`, `assets/audio/*.wav` (9종), `lib/services/sound_service.dart`
- Modify: `lib/ui/screens/game_screen.dart` (onEvents→사운드), `pubspec.yaml`
- Test: 수동(실행 후 청취) + SoundService 단위 테스트(음소거 시 재생 호출 안 함 — player를 주입 가능하게)

**Interfaces:**
- Produces:
  - `tool/gen_sfx.py`: Python 표준 라이브러리(wave, math, struct)만으로 합성 — move(80ms 사각파 블립 660Hz), push(100ms 저음 220Hz), slide(200ms 화이트노이즈 페이드), nest(2음 딩동 880→1320), clear(4음 상승 아르페지오), unlock(반짝 1760Hz 트레몰로), button(클릭 40ms), crack(노이즈 버스트), teleport(주파수 스윕 300→900). 44.1kHz 16bit mono. 실행: `python tool/gen_sfx.py`
  - `class SoundService { SoundService({AudioPlayer Function()? playerFactory}); bool muted; Future<void> play(Sfx s); }` + `enum Sfx { move, push, slide, nest, clear, unlock, button, crack, teleport }`
  - GameEvent→Sfx 매핑: chickMoved→move, eggPushed→push, eggSlid→slide(연속 슬라이드는 1회), eggNested→nest, floorBroke→crack, chickTeleported/eggTeleported→teleport, doorOpened/doorClosed→button, cleared→clear
- 한글 경로 함정 주의: audioplayers는 asset 재생이라 경로 무관.

- [ ] **Step 1: gen_sfx.py 작성·실행** — 9개 wav 생성 확인 (Python은 `C:\Users\사용자\AppData\Local\Programs\Python\Python312\python.exe`)
- [ ] **Step 2: SoundService 테스트·구현 → PASS**
- [ ] **Step 3: 게임 화면 연결 + 실행 청취 확인**
- [ ] **Step 4: 커밋** — `"SFX 합성 + 사운드 서비스"`

---

### Task 18: 스티커북·꾸미기 보드

**Files:**
- Create: `lib/ui/screens/sticker_book_screen.dart`, `lib/ui/screens/deco_board_screen.dart`, `lib/models/sticker.dart`
- Modify: `lib/services/save_service.dart` (스티커 배치 저장), `lib/ui/screens/title_screen.dart`(뱃지)
- Test: `test/models/sticker_test.dart`

**Interfaces:**
- Consumes: SaveService.totalStars
- Produces:
  - `class StickerDef { final String id; final String asset; final int threshold; }` + `const stickers = [...]` — 24종: sticker_01~12(기존 PNG), 13~24는 chick 포즈 PNG 재활용(chick_cheer 등 11종 + 별도 1종은 sticker_01 색변형이 아니라 **chick 11종 + sticker 12종 + 로고 1종**으로 정확히 24개 구성. threshold = 순번×6 (6,12,…,144)
  - `List<StickerDef> unlockedStickers(int totalStars)`
  - 스티커북: 4×6 그리드, 미해금은 `ColorFiltered`(검정 실루엣) + '별 N개', 해금 시 원본.
  - 꾸미기 보드: creamBg 배경 한 장. 해금 스티커를 하단 트레이에서 드래그해 배치, `Draggable`+`Positioned`. 배치 저장: SaveService에 `deco.items` = jsonEncode([{id,dx,dy(0~1 비율)}]). 삭제는 트레이로 되돌리는 드래그.
- [ ] **Step 1: 테스트** — unlockedStickers 경계(5→0개, 6→1개, 144→24개), 배치 저장 왕복.
- [ ] **Step 2~4:** 구현 → PASS → 수동 확인 → 커밋 `"스티커북·꾸미기 보드"`

---

### Task 19: 데일리 퍼즐

**Files:**
- Create: `lib/services/daily_service.dart`, `assets/levels/daily_presets.json` (기본 규칙 레벨 20개), `lib/ui/screens/daily_screen.dart`
- Modify: `lib/services/save_service.dart` (달력 기록), 타이틀 연결
- Test: `test/services/daily_service_test.dart`

**Interfaces:**
- Consumes: Solver, Board, SaveService
- Produces:
  - `Level generateDaily(DateTime date)` — 시드 `y*10000+m*100+d`. 절차: ①7×7 외벽+내벽 6~10개 랜덤 ②둥지 2~3개에 알 올려둔 완성 상태 ③역방향 당기기 25~45회(알 e를 d방향으로 당김 = 병아리가 e.step(d)에 서서 e→e.step(d), 병아리→e.step(d).step(d); 두 칸 모두 빈 바닥일 때만) ④솔버 최적수 8~25면 채택, 아니면 재시도(최대 60회) ⑤실패 시 `daily_presets.json[seed % 20]`
  - 데일리 화면: 오늘 퍼즐 [도전] + 이번 달 달력(도장), 연속 출석 N일 표시. 클리어 시 `daily.<yyyy-MM-dd>`=true 저장.
  - 프리셋 20개도 검증 CLI 대상(Task 10에서 이미 포함).
- [ ] **Step 1: 테스트** — 같은 날짜 두 번 생성 시 동일 레벨(결정성), 생성 레벨 솔버 통과, 최적수 8~25, 프리셋 폴백 경로(강제 실패 시드 주입).
- [ ] **Step 2~4:** 구현 → PASS → `dart run tool/validate_levels.dart` → 커밋 `"데일리 퍼즐 생성기 + 달력"`

---

### Task 20: 챕터 2~5 레벨 40개

**Files:**
- Create: `assets/levels/chapter2.json` ~ `chapter5.json`

**Interfaces:**
- Consumes: 검증 CLI, 전 레벨 테스트(Task 11에서 자동 포함)
- Produces: 각 챕터 10개. s1~s2는 신규 기믹 단독 학습(6×6 내외, 최적 12수 미만), s10은 보스급. 챕터5는 기믹 2종 이상 조합 필수. 전체 50개 중 35개 이상은 최적 20수 미만 유지(검증 CLI 분포 출력으로 확인).

- [ ] **Step 1: 챕터2(얼음) 10개 작성** — 예시 학습 스테이지: `{"id":"c2s01","chapter":2,"title":"미끄러운 첫 알","rows":["#######","#@$iio#","#######"],"optimal":0}`. 얼음 위 정지 위치 역산이 핵심 재미가 되도록 얼음 길이·벽 배치 변주.
- [ ] **Step 2: 챕터3(굴) 10개** — 굴로 알을 보내 반대편 구역에서 마저 미는 구조. 2쌍(1↔2, 3↔4) 활용은 s07부터.
- [ ] **Step 3: 챕터4(버튼·문) 10개** — 알을 버튼에 올려 문을 열고 다른 알을 통과시키는 순서 퍼즐. 병아리가 버튼을 밟고 있는 동안만 여는 변형 포함.
- [ ] **Step 4: 챕터5(붕괴+종합) 10개** — 금 간 바닥으로 일방통행 동선 강제. s08~s10은 얼음+굴, 문+붕괴 등 조합.
- [ ] **Step 5: 검증·밸런싱** — `dart run tool/validate_levels.dart` 전 통과 + 분포 조건 충족, `flutter test` PASS
- [ ] **Step 6: 커밋** — 챕터별 커밋 4회 (`"챕터N 레벨 10개"`)

---

### Task 21: 아이콘·앱명·릴리즈 APK·실기기

**Files:**
- Create: `assets/icon/icon.png` (chick_idle을 creamBg 배경 1024×1024에 합성 — Python PIL 없으면 flutter_launcher_icons의 배경색 옵션 사용)
- Modify: `pubspec.yaml`(flutter_launcher_icons 설정), `android/app/src/main/AndroidManifest.xml`(label 삐약푸시), `android/app/build.gradle.kts`(서명은 debug 유지 — v1 사이드로드)
- Test: 실기기 설치·구동

**Interfaces:**
- Consumes: 완성된 앱
- Produces: `build\app\outputs\flutter-apk\app-release.apk`

- [ ] **Step 1: 아이콘 구성 + `dart run flutter_launcher_icons`**
- [ ] **Step 2: 앱명 한글 설정** — manifest `android:label="삐약푸시"`, iOS `Info.plist` CFBundleDisplayName 동일 적용(호환 유지)
- [ ] **Step 3: 릴리즈 빌드** — `flutter build apk --release` (GRADLE_USER_HOME 환경변수 확인)
- [ ] **Step 4: 실기기 설치** — `adb install -r build\app\outputs\flutter-apk\app-release.apk` (S20 Ultra) → 타이틀→챕터1 s01 클리어→별 저장 확인
- [ ] **Step 5: 커밋** — `"앱 아이콘·이름 + 릴리즈 빌드 설정"`

---

### Task 22: 최종 점검

- [ ] **Step 1:** `flutter test` 전체 PASS + `dart run tool/validate_levels.dart` 전체 통과
- [ ] **Step 2:** `flutter analyze` 경고 0 (불가피한 것은 사유 주석)
- [ ] **Step 3: 수동 체크리스트** — 50스테이지 잠금/해금 흐름, 데일리 클리어→달력 도장, 스티커 해금→배치→재실행 후 유지, 사운드 토글, D-패드 토글, 진행 초기화, 화면 회전/작은 화면(가로 잠금 확인 — portrait 고정 설정)
- [ ] **Step 4:** `README.md` 작성(규칙·빌드법·레벨 추가법·검증 CLI 사용법) → 커밋 `"v1 완성: README"`

---

## Self-Review 기록

- 스펙 커버리지: 규칙(T3~7), 별점(T13), 데드락(T8), 스티커(T18), 감정(T13·14), 데일리(T19), 화면 6종(T14·15·18·19), 힌트(T16), 검증 CLI(T10), 레벨 50개(T11·20), 빌드 환경(T1·21), 에러 처리(저장 실패→SaveService.load 기본값, 레벨 파싱 실패→검증 CLI 원천 차단) 모두 태스크에 매핑됨.
- 미배정 스펙 항목 없음. iOS 스토어 제출·광고·다국어는 스펙 11절대로 범위 외.
- 타입 일관성: Board/MoveOutcome/GameEvent/Solver/Level/SaveService 시그니처를 각 태스크 Interfaces에 명시해 고정.
