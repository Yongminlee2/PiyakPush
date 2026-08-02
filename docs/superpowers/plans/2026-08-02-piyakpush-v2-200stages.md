# 삐약푸시 v2 (200스테이지) 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 진행 잠금을 별에서 클리어 개수로 바꿔 "다 깼는데 막히는" 결함을 없애고, 솔버 기반 생성 파이프라인으로 어려운 150스테이지를 만들어 총 200스테이지로 확장한다.

**Architecture:** BFS 솔버를 확장해 난이도 지표(이동수·밀기수·탐색 상태수·데드락 비율)를 함께 재고, 그 지표로 생성 후보를 걸러 채택한다. 생성은 역방향 흐트러뜨리기로 풀이 가능성을 확보한 뒤 기믹 타일을 얹고 솔버로 재검증하는 순서다 — 솔버가 진실의 기준이다.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12.2 / provider / shared_preferences / audioplayers

## Global Constraints

- 스펙: `docs/superpowers/specs/2026-08-02-piyakpush-v2-200stages-design.md` (충돌 시 스펙 우선)
- 런타임 의존성 추가 금지 (`provider`, `shared_preferences`, `audioplayers` 3개 유지)
- `lib/engine/`과 `lib/services/level_generator.dart`는 **순수 Dart** — `package:flutter` import 금지 (CLI 도구에서 실행해야 한다)
- 기존 챕터 1~5의 레벨 내용은 **변경 금지** (1막으로 유지, 진행 기록 보존)
- 한국어 UI 문자열은 전부 `lib/ui/strings.dart`의 `S`를 통해서만 사용
- 솔버 탐색 상한: 레벨 생성 시 **400,000 상태**. 초과 후보는 폐기
- 챕터 해금: 현재 챕터에서 **8스테이지 이상 클리어**. "클리어"는 저장된 별 ≥ 1
- 매 셸 세션 선행 (빼먹으면 `flutter test`가 "Connection closed before test suite loaded"로 실패):
  ```powershell
  $env:Path = "C:\flutter\bin;$env:Path"; $env:PUB_CACHE = "C:\flutter\.pub-cache"; $env:GRADLE_USER_HOME = "C:\workAndroid\gradle-user-ascii"; $env:TEMP = "C:\workAndroid\tmp-ascii"; $env:TMP = "C:\workAndroid\tmp-ascii"
  ```
- 작업 디렉터리: `C:\workAndroid\PiyakPush`, 브랜치: `feature/v2-200stages`
- 커밋 메시지는 한국어 요약 + 마지막 줄 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`

## File Structure

| 파일 | 책임 | 상태 |
|---|---|---|
| `lib/models/progression.dart` | 해금 규칙(클리어 개수 기준), 챕터 20개 | 수정 |
| `lib/services/save_service.dart` | `chapterClearedCount`, `totalStars` 20챕터 | 수정 |
| `lib/ui/screens/stage_screen.dart` | 새 판정 배선 | 수정 |
| `lib/ui/strings.dart` | 챕터 이름 20개, 잠금 문구 | 수정 |
| `lib/engine/solve_report.dart` | 솔버 측정 결과 타입 | 신규 |
| `lib/engine/solver.dart` | `analyze()` 추가, `solve()`는 얇은 래퍼로 | 수정 |
| `lib/engine/board.dart` | `toAsciiRows()`가 기믹 타일까지 직렬화 | 수정 |
| `lib/services/level_generator.dart` | 기믹 포함 후보 생성 (순수 Dart) | 신규 |
| `lib/services/daily_generator.dart` | 생성 로직을 level_generator에 위임 | 수정 |
| `lib/models/sticker.dart` | 해금 간격 25 | 수정 |
| `lib/ui/theme.dart` | 챕터 테마색 20개 | 수정 |
| `lib/ui/screens/chapter_screen.dart` | 20챕터 + 막 헤더 | 수정 |
| `tool/gen_chapters.dart` | 챕터 6~20 생성 CLI | 신규 |
| `assets/levels/chapter6..20.json` | 생성된 150스테이지 | 신규 |

**의존 순서:** Task 1은 독립. Task 2 → 3 → 4 (생성 파이프라인). Task 5·6은 독립. Task 7은 전부 이후.

---

### Task 1: 진행 잠금 규칙 교체 (챕터3 막힘 버그 수정)

**Files:**
- Modify: `lib/models/progression.dart`
- Modify: `lib/services/save_service.dart`
- Modify: `lib/ui/screens/stage_screen.dart`
- Modify: `lib/ui/strings.dart`
- Modify: `test/models/progression_test.dart`
- Modify: `test/services/save_service_test.dart`

**Interfaces:**
- Produces:
  - `const int kChapterUnlockClears = 8;`
  - `const int kChapterCount = 20;`
  - `class ChapterLocked extends NextStep { final int chapter; final int clearsNeeded; }` (기존 `starsNeeded`에서 이름 변경)
  - `NextStep resolveNextStep({required int chapter, required int index, required int levelCount, required int currentChapterClears, int chapterCount = kChapterCount})`
  - `int SaveService.chapterClearedCount(int c)` — 별 ≥ 1인 스테이지 수
  - `SaveService.totalStars`가 1~20 챕터를 모두 센다
  - `S.needMoreClears(int n)`

- [ ] **Step 1: 실패하는 테스트 작성 (진행 판정)**

`test/models/progression_test.dart`를 통째로 교체한다:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/progression.dart';

void main() {
  test('챕터 중간이면 같은 챕터 다음 스테이지', () {
    final s = resolveNextStep(
        chapter: 1, index: 3, levelCount: 10, currentChapterClears: 4);
    expect(s, isA<NextInChapter>());
    expect((s as NextInChapter).index, 4);
  });

  test('챕터 마지막 + 8개 이상 클리어면 다음 챕터', () {
    final s = resolveNextStep(
        chapter: 3, index: 9, levelCount: 10, currentChapterClears: 8);
    expect(s, isA<NextChapter>());
    expect((s as NextChapter).chapter, 4);
  });

  test('챕터 마지막 + 클리어 부족이면 잠김과 부족분', () {
    final s = resolveNextStep(
        chapter: 3, index: 9, levelCount: 10, currentChapterClears: 5);
    expect(s, isA<ChapterLocked>());
    expect((s as ChapterLocked).chapter, 4);
    expect(s.clearsNeeded, 3);
  });

  test('20챕터 마지막 스테이지면 전체 클리어', () {
    final s = resolveNextStep(
        chapter: 20, index: 9, levelCount: 10, currentChapterClears: 10);
    expect(s, isA<AllChaptersCleared>());
  });

  test('19챕터 마지막은 전체 클리어가 아니라 다음 챕터', () {
    final s = resolveNextStep(
        chapter: 19, index: 9, levelCount: 10, currentChapterClears: 10);
    expect(s, isA<NextChapter>());
    expect((s as NextChapter).chapter, 20);
  });
}
```

- [ ] **Step 2: 실패하는 테스트 작성 (저장 서비스 · 회귀)**

`test/services/save_service_test.dart`의 `'챕터 해금: 이전 챕터 별 12개 경계'` 테스트를 지우고 아래 셋을 넣는다. 세 번째가 이번 버그를 정확히 겨냥한 회귀 테스트다:

```dart
  test('chapterClearedCount는 별 1개 이상인 스테이지 수', () async {
    final s = await SaveService.load();
    await s.setStars('c2s01', 3);
    await s.setStars('c2s02', 1);
    await s.setStars('c2s03', 2);
    expect(s.chapterClearedCount(2), 3);
    expect(s.chapterClearedCount(1), 0);
  });

  test('챕터 해금: 클리어 8개 경계', () async {
    final s = await SaveService.load();
    for (var i = 1; i <= 7; i++) {
      await s.setStars('c1s0$i', 1);
    }
    expect(s.chapterUnlocked(2), false); // 7개로는 안 열린다
    await s.setStars('c1s08', 1);
    expect(s.chapterUnlocked(2), true); // 8개면 열린다
  });

  test('10스테이지를 별 1개씩 다 깨면 다음 챕터가 열린다 (v1.1 결함 회귀)', () async {
    final s = await SaveService.load();
    for (var i = 1; i <= 10; i++) {
      await s.setStars('c3s${i.toString().padLeft(2, '0')}', 1);
    }
    expect(s.chapterStars(3), 10); // 별로는 옛 기준 12개에 못 미친다
    expect(s.chapterUnlocked(4), true); // 그래도 열려야 한다
  });

  test('totalStars는 20챕터를 모두 센다', () async {
    final s = await SaveService.load();
    await s.setStars('c1s01', 3);
    await s.setStars('c12s01', 3);
    await s.setStars('c20s10', 2);
    expect(s.totalStars, 8);
  });
```

- [ ] **Step 3: 실행해 실패 확인**

Run: `flutter test --no-pub test/models/progression_test.dart test/services/save_service_test.dart`
Expected: FAIL — `currentChapterClears` 파라미터 없음(컴파일 에러), `chapterClearedCount` 없음

- [ ] **Step 4: progression.dart 교체**

`lib/models/progression.dart`에서 상수와 판정을 바꾼다:

```dart
/// 다음 챕터를 열려면 현재 챕터에서 몇 개를 깨야 하는가.
///
/// v1.1까지는 "별 12개"였는데, 한 챕터는 10스테이지뿐이라 전부 별 1개로
/// 클리어해도 10개여서 영구히 갇힐 수 있었다. 별은 실력 보상이지 관문이
/// 아니어야 한다 — 클리어 개수로 판정한다.
const int kChapterUnlockClears = 8;
const int kChapterCount = 20;
```

`ChapterLocked`의 필드 이름을 바꾼다:

```dart
/// [chapter] 챕터가 [clearsNeeded] 개 부족으로 잠겨 있다.
class ChapterLocked extends NextStep {
  final int chapter;
  final int clearsNeeded;
  const ChapterLocked(this.chapter, this.clearsNeeded);
}
```

`resolveNextStep`을 교체한다:

```dart
NextStep resolveNextStep({
  required int chapter,
  required int index,
  required int levelCount,
  required int currentChapterClears,
  int chapterCount = kChapterCount,
}) {
  if (index + 1 < levelCount) return NextInChapter(index + 1);
  if (chapter >= chapterCount) return const AllChaptersCleared();
  if (currentChapterClears >= kChapterUnlockClears) {
    return NextChapter(chapter + 1);
  }
  return ChapterLocked(
      chapter + 1, kChapterUnlockClears - currentChapterClears);
}
```

- [ ] **Step 5: SaveService 교체**

`lib/services/save_service.dart`에서 `chapterStars` 아래에 추가하고 `totalStars`·`chapterUnlocked`를 바꾼다:

```dart
  /// 별 1개 이상 받은 스테이지 수 — 챕터 해금 판정의 기준.
  int chapterClearedCount(int c) {
    var n = 0;
    for (var i = 1; i <= 10; i++) {
      if (starsOf('c${c}s${i.toString().padLeft(2, '0')}') > 0) n++;
    }
    return n;
  }

  int get totalStars {
    var sum = 0;
    for (var c = 1; c <= kChapterCount; c++) {
      sum += chapterStars(c);
    }
    return sum;
  }

  bool chapterUnlocked(int c) =>
      c == 1 || chapterClearedCount(c - 1) >= kChapterUnlockClears;
```

기존 `int get totalStars => [1, 2, 3, 4, 5].fold(...)` 줄과 기존 `chapterUnlocked` 줄은 삭제한다.

- [ ] **Step 6: 통과 확인**

Run: `flutter test --no-pub test/models/progression_test.dart test/services/save_service_test.dart`
Expected: PASS

- [ ] **Step 7: 문구와 화면 배선**

`lib/ui/strings.dart`에서 `needMoreStars`를 지우고 넣는다:

```dart
  static String needMoreClears(int n) => '이 챕터에서 $n개만 더 깨면 다음 챕터가 열려요';
```

`lib/ui/screens/stage_screen.dart`의 `_outcomeFor`에서 두 곳을 바꾼다:

```dart
      currentChapterClears: save.chapterClearedCount(chapter),
```

```dart
      ChapterLocked(:final clearsNeeded) =>
        ClearOutcome(note: S.needMoreClears(clearsNeeded)),
```

- [ ] **Step 8: 전체 테스트 + 정적 분석**

Run: `flutter analyze` 그리고 `flutter test --no-pub`
Expected: analyze `No issues found`, 전체 PASS

- [ ] **Step 9: 커밋**

```powershell
git add -A; git commit -m "진행 잠금을 별에서 클리어 개수로 교체 — 다 깨고도 막히던 결함 수정

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: 솔버 난이도 측정 (`analyze`)

**Files:**
- Create: `lib/engine/solve_report.dart`
- Modify: `lib/engine/solver.dart`
- Create: `test/engine/solve_report_test.dart`

**Interfaces:**
- Consumes: `Board.tryMove`, `hasCornerDeadlock` (기존)
- Produces:
  - `class SolveReport { final List<Dir>? moves; final int statesExplored; final int deadlocksPruned; final int pushes; bool get solved; int get optimalMoves; double get deadlockRatio; }`
  - `SolveReport Solver.analyze(Board start)`
  - `List<Dir>? Solver.solve(Board start)` — 이제 `analyze(start).moves`를 돌려주는 얇은 래퍼 (알고리즘은 한 벌만 둔다)

- [ ] **Step 1: 실패하는 테스트 작성**

`test/engine/solve_report_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/solver.dart';

void main() {
  test('1수 레벨: 이동 1, 밀기 1', () {
    final r = Solver().analyze(Board.fromAscii(['#####', '#@\$o#', '#####']));
    expect(r.solved, true);
    expect(r.optimalMoves, 1);
    expect(r.pushes, 1);
  });

  test('걷다가 미는 레벨: 밀기는 민 횟수만 센다', () {
    // 병아리가 두 칸 걸어간 뒤 한 번 민다
    final r =
        Solver().analyze(Board.fromAscii(['######', '#@.\$o#', '######']));
    expect(r.optimalMoves, 3);
    expect(r.pushes, 1);
  });

  test('풀이 불가면 solved=false, optimalMoves=0', () {
    final r = Solver().analyze(Board.fromAscii(['####', '#@\$#', '#o.#', '####']));
    expect(r.solved, false);
    expect(r.optimalMoves, 0);
    expect(r.moves, null);
  });

  test('이미 클리어면 빈 해', () {
    final r = Solver().analyze(Board.fromAscii(['####', '#@*#', '####']));
    expect(r.solved, true);
    expect(r.optimalMoves, 0);
    expect(r.pushes, 0);
  });

  test('탐색 상태 수와 데드락 비율이 기록된다', () {
    final r = Solver().analyze(Board.fromAscii(
        ['#######', '#..o..#', '#.\$...#', '#..@..#', '#.....#', '#######']));
    expect(r.solved, true);
    expect(r.statesExplored, greaterThan(0));
    expect(r.deadlockRatio, inInclusiveRange(0.0, 1.0));
  });

  test('solve()는 analyze()의 moves와 같다', () {
    final b = Board.fromAscii(['#####', '#@\$o#', '#####']);
    expect(Solver().solve(b), Solver().analyze(b).moves);
  });
}
```

- [ ] **Step 2: 실행해 실패 확인**

Run: `flutter test --no-pub test/engine/solve_report_test.dart`
Expected: FAIL — `analyze` 메서드 없음

- [ ] **Step 3: SolveReport 작성**

`lib/engine/solve_report.dart`:

```dart
/// 솔버가 답을 찾으며 함께 잰 난이도 지표.
///
/// 이동수만으로는 난이도를 못 잡는다 — 일직선으로 밀기만 하는 60수짜리는
/// 길 뿐 어렵지 않다. 밀기 횟수·탐색 상태 수·데드락 비율을 같이 본다.
library;

import 'geometry.dart';

class SolveReport {
  /// null이면 풀이 불가(또는 탐색 상한 초과).
  final List<Dir>? moves;

  /// 답을 찾기까지 펼쳐 본 상태 수 — 갈래가 많을수록 눈에 안 보인다.
  final int statesExplored;

  /// 데드락으로 판단해 잘라낸 상태 수 — 함정의 양.
  final int deadlocksPruned;

  /// 최적해에서 알을 실제로 민 횟수.
  final int pushes;

  const SolveReport({
    required this.moves,
    required this.statesExplored,
    required this.deadlocksPruned,
    required this.pushes,
  });

  bool get solved => moves != null;
  int get optimalMoves => moves?.length ?? 0;

  double get deadlockRatio {
    final total = deadlocksPruned + statesExplored;
    return total == 0 ? 0 : deadlocksPruned / total;
  }
}
```

- [ ] **Step 4: Solver에 analyze 구현**

`lib/engine/solver.dart`의 `solve`를 아래로 교체한다(기존 `_reconstruct`는 그대로 둔다). `import 'solve_report.dart';`와 `import 'move.dart';`가 필요하다:

```dart
  /// 최적 이동열. 이미 클리어면 빈 목록, 풀이 불가·상한 초과면 null.
  List<Dir>? solve(Board start) => analyze(start).moves;

  /// 최적해와 난이도 지표를 함께 낸다.
  SolveReport analyze(Board start) {
    if (start.isCleared) {
      return const SolveReport(
          moves: [], statesExplored: 0, deadlocksPruned: 0, pushes: 0);
    }
    if (hasCornerDeadlock(start)) {
      return const SolveReport(
          moves: null, statesExplored: 0, deadlocksPruned: 1, pushes: 0);
    }

    final startKey = start.stateKey;
    final parent = <String, (String, Dir)>{};
    final seen = <String>{startKey};
    final queue = Queue<Board>()..add(start);
    var explored = 0;
    var pruned = 0;

    while (queue.isNotEmpty) {
      final b = queue.removeFirst();
      explored++;
      final bKey = b.stateKey;
      for (final d in Dir.values) {
        final o = b.tryMove(d);
        if (o.blocked) continue;
        final nb = o.board!;
        final key = nb.stateKey;
        if (!seen.add(key)) continue;
        parent[key] = (bKey, d);
        if (nb.isCleared) {
          final moves = _reconstruct(parent, startKey, key);
          return SolveReport(
            moves: moves,
            statesExplored: explored,
            deadlocksPruned: pruned,
            pushes: _countPushes(start, moves),
          );
        }
        if (hasCornerDeadlock(nb)) {
          pruned++;
          continue;
        }
        if (explored + queue.length > maxStates) {
          return SolveReport(
              moves: null,
              statesExplored: explored,
              deadlocksPruned: pruned,
              pushes: 0);
        }
        queue.add(nb);
      }
    }
    return SolveReport(
        moves: null,
        statesExplored: explored,
        deadlocksPruned: pruned,
        pushes: 0);
  }

  /// 해를 되짚어 재생하며 알이 움직인 이동만 센다.
  int _countPushes(Board start, List<Dir> moves) {
    var b = start;
    var pushes = 0;
    for (final d in moves) {
      final o = b.tryMove(d);
      if (o.blocked) break;
      if (o.events.any((e) => e.type == GameEventType.eggPushed)) pushes++;
      b = o.board!;
    }
    return pushes;
  }
```

- [ ] **Step 5: 통과 확인**

Run: `flutter test --no-pub test/engine/`
Expected: PASS (기존 solver_test.dart 포함 — `solve()` 동작이 그대로여야 한다)

- [ ] **Step 6: 커밋**

```powershell
git add -A; git commit -m "솔버 난이도 측정: analyze()로 이동수·밀기수·탐색상태·데드락비율 산출

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: 기믹 포함 레벨 생성기

**Files:**
- Modify: `lib/engine/board.dart` (`toAsciiRows` 확장)
- Create: `lib/services/level_generator.dart`
- Modify: `lib/services/daily_generator.dart` (생성 로직 위임)
- Create: `test/services/level_generator_test.dart`

**Interfaces:**
- Consumes: Task 2의 `Solver.analyze`, `SolveReport`
- Produces:
  - `enum Gimmick { ice, portal, door, cracked }`
  - `class GenSpec { final int width, height, eggCount, wallCount; final List<Gimmick> gimmicks; final int minOptimal, maxOptimal, minPushes, minStates; final double minDeadlockRatio; final int maxStates; const GenSpec({...}); }`
  - `List<String>? generateRows(Random rng, GenSpec spec, {int maxAttempts = 400})` — 조건을 모두 만족하는 보드의 ASCII 행. 실패하면 null
  - `SolveReport? lastReportOf(List<String> rows, GenSpec spec)` 대신 **생성 결과와 지표를 함께 돌려준다**: `class GenResult { final List<String> rows; final SolveReport report; }`, `GenResult? generate(Random rng, GenSpec spec, {int maxAttempts = 400})`
  - `Board randomSolvedBoard(Random rng, int size, int wallCount, int eggCount)` — 데일리도 함께 쓴다
  - `Board reverseScramble(Board b, Random rng, {required int steps})` — 데일리도 함께 쓴다
- `Board.toAsciiRows()`가 얼음·굴·버튼·문·금 간 바닥까지 직렬화한다. 기믹 타일 위에 알이나 병아리가 있으면 표현할 수 없으므로 `StateError`를 던진다.

- [ ] **Step 1: 실패하는 테스트 작성**

`test/services/level_generator_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/solver.dart';
import 'package:piyak_push/engine/tile.dart';
import 'package:piyak_push/services/level_generator.dart';

const _easySpec = GenSpec(
  width: 7,
  height: 7,
  eggCount: 2,
  wallCount: 6,
  gimmicks: [],
  minOptimal: 8,
  maxOptimal: 30,
  minPushes: 3,
  minStates: 50,
  minDeadlockRatio: 0.0,
  maxStates: 200000,
);

void main() {
  test('기본 규격으로 생성하면 풀이 가능하고 밴드를 지킨다', () {
    final g = generate(Random(1), _easySpec);
    expect(g, isNotNull);
    final report = Solver().analyze(Board.fromAscii(g!.rows));
    expect(report.solved, true);
    expect(report.optimalMoves, g.report.optimalMoves);
    expect(report.optimalMoves, inInclusiveRange(8, 30));
    expect(report.pushes, greaterThanOrEqualTo(3));
  });

  test('같은 시드는 같은 결과 (재현 가능)', () {
    final a = generate(Random(7), _easySpec);
    final b = generate(Random(7), _easySpec);
    expect(a!.rows, b!.rows);
  });

  test('기믹을 요구하면 보드에 실제로 들어간다', () {
    const spec = GenSpec(
      width: 8,
      height: 8,
      eggCount: 2,
      wallCount: 6,
      gimmicks: [Gimmick.ice, Gimmick.portal],
      minOptimal: 8,
      maxOptimal: 40,
      minPushes: 3,
      minStates: 50,
      minDeadlockRatio: 0.0,
      maxStates: 200000,
    );
    final g = generate(Random(3), spec);
    expect(g, isNotNull);
    final board = Board.fromAscii(g!.rows);
    final tiles = board.tiles.toSet();
    // 얼음이나 굴 중 적어도 하나는 실제로 놓여야 한다
    expect(
        tiles.contains(Tile.ice) ||
            (tiles.contains(Tile.portal1) && tiles.contains(Tile.portal2)),
        true);
  });

  test('toAsciiRows는 기믹 타일을 직렬화하고 왕복한다', () {
    final rows = ['########', '#@\$iio.#', '#1..2bB#', '#c....o#', '########'];
    final board = Board.fromAscii(rows);
    expect(Board.fromAscii(board.toAsciiRows()).stateKey, board.stateKey);
  });
}
```

- [ ] **Step 2: 실행해 실패 확인**

Run: `flutter test --no-pub test/services/level_generator_test.dart`
Expected: FAIL — `level_generator.dart` 없음

- [ ] **Step 3: toAsciiRows 확장**

`lib/engine/board.dart`의 `toAsciiRows`를 교체한다:

```dart
  /// 보드를 ASCII 행으로 직렬화한다. 기믹 타일 위에 알·병아리가 있으면
  /// 표현할 수 없으므로 던진다 — 레벨 저장 시점엔 그런 배치를 만들지 않는다.
  List<String> toAsciiRows() {
    const base = {
      Tile.wall: '#',
      Tile.floor: '.',
      Tile.nest: 'o',
      Tile.ice: 'i',
      Tile.cracked: 'c',
      Tile.hole: '#',
      Tile.portal1: '1',
      Tile.portal2: '2',
      Tile.portal3: '3',
      Tile.portal4: '4',
      Tile.buttonB: 'b',
      Tile.buttonD: 'd',
      Tile.doorB: 'B',
      Tile.doorD: 'D',
    };
    final rows = <String>[];
    for (var y = 0; y < height; y++) {
      final sb = StringBuffer();
      for (var x = 0; x < width; x++) {
        final p = Point(x, y);
        final t = tileAt(p);
        if (eggs.contains(p)) {
          if (t == Tile.floor) {
            sb.write('\$');
          } else if (t == Tile.nest) {
            sb.write('*');
          } else {
            throw StateError('기믹 타일 위의 알은 직렬화 불가: $t at $p');
          }
        } else if (chick == p) {
          if (t == Tile.floor) {
            sb.write('@');
          } else if (t == Tile.nest) {
            sb.write('+');
          } else {
            throw StateError('기믹 타일 위의 병아리는 직렬화 불가: $t at $p');
          }
        } else {
          sb.write(base[t]!);
        }
      }
      rows.add(sb.toString());
    }
    return rows;
  }
```

- [ ] **Step 4: 생성기 구현**

`lib/services/level_generator.dart`:

```dart
/// 레벨 후보 생성 — 순수 Dart(CLI에서 실행). Flutter import 금지.
///
/// 절차: ①벽·둥지만으로 완성 상태를 만들고 역방향으로 흐트러뜨려 풀이
/// 가능성을 확보한 뒤 ②기믹 타일을 빈 바닥에 얹고 ③솔버로 재검증·측정해
/// ④밴드를 통과한 것만 채택한다. 기믹을 얹으면 막힐 수 있으므로 솔버가
/// 진실의 기준이다.
library;

import 'dart:math';

import '../engine/board.dart';
import '../engine/geometry.dart';
import '../engine/solve_report.dart';
import '../engine/solver.dart';
import '../engine/tile.dart';

enum Gimmick { ice, portal, door, cracked }

class GenSpec {
  final int width, height, eggCount, wallCount;
  final List<Gimmick> gimmicks;
  final int minOptimal, maxOptimal, minPushes, minStates;
  final double minDeadlockRatio;
  final int maxStates;
  const GenSpec({
    required this.width,
    required this.height,
    required this.eggCount,
    required this.wallCount,
    required this.gimmicks,
    required this.minOptimal,
    required this.maxOptimal,
    required this.minPushes,
    required this.minStates,
    required this.minDeadlockRatio,
    this.maxStates = 400000,
  });
}

class GenResult {
  final List<String> rows;
  final SolveReport report;
  const GenResult(this.rows, this.report);
}

GenResult? generate(Random rng, GenSpec spec, {int maxAttempts = 400}) {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final solved = randomSolvedBoard(
        rng, spec.width, spec.height, spec.wallCount, spec.eggCount);
    if (solved == null) continue;
    var board = reverseScramble(solved, rng,
        steps: spec.width * spec.height + rng.nextInt(20));
    if (board.isCleared) continue;
    board = _sprinkleGimmicks(board, rng, spec);

    final report = Solver(maxStates: spec.maxStates).analyze(board);
    if (!report.solved) continue;
    if (report.optimalMoves < spec.minOptimal) continue;
    if (report.optimalMoves > spec.maxOptimal) continue;
    if (report.pushes < spec.minPushes) continue;
    if (report.statesExplored < spec.minStates) continue;
    if (report.deadlockRatio < spec.minDeadlockRatio) continue;

    try {
      return GenResult(board.toAsciiRows(), report);
    } on StateError {
      continue; // 기믹 위에 알이 올라간 배치 — 표현 불가라 폐기
    }
  }
  return null;
}

/// 테두리 벽 + 내벽 + 둥지(알을 올려 완성 상태) + 병아리.
Board? randomSolvedBoard(
    Random rng, int width, int height, int wallCount, int eggCount) {
  final tiles = List<Tile>.generate(width * height, (i) {
    final x = i % width, y = i ~/ width;
    return (x == 0 || y == 0 || x == width - 1 || y == height - 1)
        ? Tile.wall
        : Tile.floor;
  });
  final inner = <int>[
    for (var y = 1; y < height - 1; y++)
      for (var x = 1; x < width - 1; x++) y * width + x
  ]..shuffle(rng);
  if (inner.length < wallCount + eggCount + 1) return null;
  var k = 0;
  for (var i = 0; i < wallCount; i++) {
    tiles[inner[k++]] = Tile.wall;
  }
  final eggs = <Point>{};
  for (var i = 0; i < eggCount; i++) {
    final idx = inner[k++];
    tiles[idx] = Tile.nest;
    eggs.add(Point(idx % width, idx ~/ width));
  }
  final chickIdx = inner[k++];
  return Board(
    width: width,
    height: height,
    tiles: tiles,
    eggs: eggs,
    chick: Point(chickIdx % width, chickIdx ~/ width),
  );
}

Dir _opposite(Dir d) => switch (d) {
      Dir.up => Dir.down,
      Dir.down => Dir.up,
      Dir.left => Dir.right,
      Dir.right => Dir.left,
    };

/// 역방향 이동(역-걷기·당기기)을 무작위 적용. 당기기가 드물게 나오므로
/// 가능할 땐 70% 확률로 당기기를 골라 알이 충분히 움직이게 한다.
Board reverseScramble(Board b, Random rng, {required int steps}) {
  var cur = b;
  for (var i = 0; i < steps; i++) {
    final walks = <Board>[];
    final pulls = <Board>[];
    for (final d in Dir.values) {
      final to = cur.chick.step(d);
      if (!cur.inBounds(to)) continue;
      if (cur.tileAt(to) == Tile.wall || cur.eggs.contains(to)) continue;
      walks.add(cur.copyWith(chick: to));
      final eggPos = cur.chick.step(_opposite(d));
      if (cur.eggs.contains(eggPos)) {
        final eggs = Set<Point>.from(cur.eggs)
          ..remove(eggPos)
          ..add(cur.chick);
        pulls.add(cur.copyWith(chick: to, eggs: eggs));
      }
    }
    if (walks.isEmpty && pulls.isEmpty) break;
    final usePull =
        pulls.isNotEmpty && (walks.isEmpty || rng.nextDouble() < 0.7);
    final pool = usePull ? pulls : walks;
    cur = pool[rng.nextInt(pool.length)];
  }
  return cur;
}

/// 알·병아리·둥지가 없는 바닥 칸에만 기믹을 놓는다. 굴과 문은 짝을 이뤄야
/// 의미가 있으므로 쌍으로 배치한다.
Board _sprinkleGimmicks(Board b, Random rng, GenSpec spec) {
  if (spec.gimmicks.isEmpty) return b;
  final free = <int>[];
  for (var i = 0; i < b.tiles.length; i++) {
    final p = Point(i % b.width, i ~/ b.width);
    if (b.tiles[i] != Tile.floor) continue;
    if (b.eggs.contains(p) || b.chick == p) continue;
    free.add(i);
  }
  free.shuffle(rng);
  final tiles = List<Tile>.from(b.tiles);
  var k = 0;

  bool take(int n) => free.length - k >= n;

  for (final g in spec.gimmicks) {
    switch (g) {
      case Gimmick.ice:
        final n = 2 + rng.nextInt(3);
        if (!take(n)) break;
        for (var i = 0; i < n; i++) {
          tiles[free[k++]] = Tile.ice;
        }
      case Gimmick.portal:
        if (!take(2)) break;
        tiles[free[k++]] = Tile.portal1;
        tiles[free[k++]] = Tile.portal2;
      case Gimmick.door:
        if (!take(2)) break;
        tiles[free[k++]] = Tile.buttonB;
        tiles[free[k++]] = Tile.doorB;
      case Gimmick.cracked:
        final n = 1 + rng.nextInt(3);
        if (!take(n)) break;
        for (var i = 0; i < n; i++) {
          tiles[free[k++]] = Tile.cracked;
        }
    }
  }
  return b.copyWith(tiles: tiles);
}
```

- [ ] **Step 5: 데일리 생성기가 공용 코드를 쓰게 한다**

`lib/services/daily_generator.dart`에서 `_randomSolvedBoard`, `_reverseScramble`, `_opposite` 세 함수를 **삭제**하고, 상단에 `import 'level_generator.dart';`를 추가한 뒤 `tryGenerateDaily` 안의 호출을 공용 함수로 바꾼다:

```dart
    final solved = randomSolvedBoard(rng, 7, 7, 6 + rng.nextInt(5), 2 + rng.nextInt(2));
    if (solved == null) continue;
    final scrambled =
        reverseScramble(solved, rng, steps: 25 + rng.nextInt(21));
```

`import 'dart:math';`와 `import '../engine/tile.dart';`가 더 이상 필요 없으면 지운다(analyze가 알려준다).

- [ ] **Step 6: 통과 확인**

Run: `flutter test --no-pub test/services/ test/engine/`
Expected: PASS — 특히 기존 `daily_service_test.dart`의 결정성·난이도 밴드 테스트가 그대로 통과해야 한다

- [ ] **Step 7: 정적 분석 + 커밋**

Run: `flutter analyze`
Expected: No issues found

```powershell
git add -A; git commit -m "기믹 포함 레벨 생성기 + toAsciiRows 전체 타일 직렬화

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: 챕터 6~20 생성 (150스테이지)

**Files:**
- Create: `tool/gen_chapters.dart`
- Create: `assets/levels/chapter6.json` ~ `chapter20.json`
- Modify: `test/levels/all_levels_solvable_test.dart`

**Interfaces:**
- Consumes: Task 3의 `generate`, `GenSpec`, `Gimmick`
- Produces: 챕터 6~20 각 10스테이지. id는 `c{N}s01`~`c{N}s10`, 제목은 `<챕터 이름> <번호>`, `optimal`은 실측값. 챕터 안에서 최적수 오름차순.

- [ ] **Step 1: 생성 CLI 작성**

`tool/gen_chapters.dart`:

```dart
/// 챕터 6~20(150스테이지) 생성. 프로젝트 루트에서:
///
///     dart run tool/gen_chapters.dart          # 전부
///     dart run tool/gen_chapters.dart 6        # 한 챕터만 (밴드 조율용)
///
/// 시드가 챕터 번호로 고정돼 있어 같은 명령은 같은 레벨을 만든다.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/services/level_generator.dart';

const _names = {
  6: '얼음 굴',
  7: '미끄럼 자물쇠',
  8: '부서지는 얼음',
  9: '굴과 자물쇠',
  10: '무너지는 통로',
  11: '넓은 들판',
  12: '알 넷의 방',
  13: '얼어붙은 광장',
  14: '굴 미로',
  15: '잠긴 정원',
  16: '뒤엉킨 길',
  17: '삐약의 시험',
  18: '다섯 알의 탑',
  19: '마지막 관문',
  20: '삐약 마스터',
};

const _gimmicks = {
  6: [Gimmick.ice, Gimmick.portal],
  7: [Gimmick.ice, Gimmick.door],
  8: [Gimmick.ice, Gimmick.cracked],
  9: [Gimmick.portal, Gimmick.door],
  10: [Gimmick.portal, Gimmick.cracked],
  11: <Gimmick>[],
  12: [Gimmick.cracked],
  13: [Gimmick.ice],
  14: [Gimmick.portal],
  15: [Gimmick.door],
  16: [Gimmick.ice, Gimmick.portal, Gimmick.door],
  17: [Gimmick.ice, Gimmick.door, Gimmick.cracked],
  18: [Gimmick.portal, Gimmick.door, Gimmick.cracked],
  19: [Gimmick.ice, Gimmick.portal, Gimmick.cracked],
  20: [Gimmick.ice, Gimmick.portal, Gimmick.door, Gimmick.cracked],
};

GenSpec specFor(int chapter) {
  final g = _gimmicks[chapter]!;
  if (chapter <= 10) {
    // 2막: 기믹 2종 조합
    return GenSpec(
      width: 8,
      height: 8,
      eggCount: 3,
      wallCount: 8,
      gimmicks: g,
      minOptimal: 15,
      maxOptimal: 25,
      minPushes: 8,
      minStates: 1500,
      minDeadlockRatio: 0.03,
    );
  }
  if (chapter <= 15) {
    // 3막: 넓은 보드, 알 4개
    return GenSpec(
      width: 9,
      height: 9,
      eggCount: 4,
      wallCount: 10,
      gimmicks: g,
      minOptimal: 22,
      maxOptimal: 32,
      minPushes: 12,
      minStates: 4000,
      minDeadlockRatio: 0.05,
    );
  }
  // 4막: 전 기믹, 알 5개
  return GenSpec(
    width: chapter == 16 ? 8 : 9,
    height: chapter == 16 ? 8 : 9,
    eggCount: 5,
    wallCount: 10,
    gimmicks: g,
    minOptimal: 28,
    maxOptimal: 40,
    minPushes: 16,
    minStates: 8000,
    minDeadlockRatio: 0.06,
  );
}

void main(List<String> args) {
  final chapters = args.isEmpty
      ? [for (var c = 6; c <= 20; c++) c]
      : args.map(int.parse).toList();

  for (final chapter in chapters) {
    final spec = specFor(chapter);
    final sw = Stopwatch()..start();
    final results = <GenResult>[];
    var seed = chapter * 1000;
    var giveUp = 0;
    while (results.length < 10) {
      final g = generate(Random(seed++), spec);
      if (g == null) {
        if (++giveUp > 200) {
          stderr.writeln('챕터 $chapter: 후보 확보 실패 (${results.length}/10) — '
              '밴드를 완화해야 한다');
          exit(1);
        }
        continue;
      }
      // 같은 배치가 두 번 나오면 버린다
      if (results.any((r) => r.rows.join('|') == g.rows.join('|'))) continue;
      results.add(g);
      stdout.writeln('  ${results.length}/10  '
          '${g.report.optimalMoves}수 밀기${g.report.pushes} '
          '상태${g.report.statesExplored} '
          '함정${(g.report.deadlockRatio * 100).round()}%');
    }
    results.sort((a, b) => a.report.optimalMoves - b.report.optimalMoves);

    final levels = <Map<String, dynamic>>[];
    for (var i = 0; i < results.length; i++) {
      levels.add(Level(
        id: 'c${chapter}s${(i + 1).toString().padLeft(2, '0')}',
        chapter: chapter,
        title: '${_names[chapter]} ${i + 1}',
        rows: results[i].rows,
        optimal: results[i].report.optimalMoves,
      ).toJson());
    }
    const enc = JsonEncoder.withIndent('  ');
    File('assets/levels/chapter$chapter.json')
        .writeAsStringSync('${enc.convert(levels)}\n');
    stdout.writeln('챕터 $chapter (${_names[chapter]}) 완료 — '
        '${sw.elapsed.inSeconds}초');
  }
}
```

- [ ] **Step 2: 파일럿 — 챕터 6 하나만 생성해 시간 측정**

Run: `dart run tool/gen_chapters.dart 6`
Expected: 10개 생성 후 `챕터 6 (얼음 굴) 완료 — N초`

판단 기준:
- **N ≤ 120초**: 그대로 전체 실행으로 넘어간다
- **N > 120초 또는 "후보 확보 실패"**: `specFor`의 `minStates`를 절반으로, `minDeadlockRatio`를 0.02 낮춰 다시 파일럿. 밴드를 완화한 값은 그대로 전체 실행에 쓴다
- 로그의 지표가 밴드 하한에 딱 붙어 있으면(예: 상태 수가 전부 1500~1600) 후보가 빠듯한 것이므로 하한을 20% 낮춘다

- [ ] **Step 3: pubspec에 새 챕터 에셋 등록 확인**

`pubspec.yaml`의 `assets:`에 `- assets/levels/`가 디렉터리째 등록돼 있으므로 **수정이 필요 없다**. 다음으로 확인한다:

Run: `Select-String -Path pubspec.yaml -Pattern "assets/levels"`
Expected: `- assets/levels/` 한 줄이 출력됨

- [ ] **Step 4: 전체 생성** (오래 걸리므로 백그라운드 실행)

Run: `dart run tool/gen_chapters.dart`
Expected: 챕터 6~20 각각 `완료` 로그, `assets/levels/chapter6.json`~`chapter20.json` 생성

- [ ] **Step 5: 전수 검증**

Run: `dart run tool/validate_levels.dart`
Expected: 풀이 불가 0건. 챕터별 최적수 분포에서 2막 15~25, 3막 22~32, 4막 28~40 범위 확인

- [ ] **Step 6: 전 레벨 테스트를 200개 규모에 맞게 조정**

`test/levels/all_levels_solvable_test.dart`를 교체한다. 200개를 전부 BFS로 푸는 건 테스트로는 느리므로, **파싱은 전부 검사하고 솔버 검증은 챕터별 첫·마지막**만 한다. 전수 검증은 `tool/validate_levels.dart`가 커밋 전에 담당한다:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/solver.dart';
import 'package:piyak_push/models/level.dart';

/// 파싱은 전 레벨, 솔버 검증은 챕터별 첫·마지막만 — 200개를 모두 BFS로
/// 푸는 건 테스트로는 느리다. 전수 검증은 tool/validate_levels.dart 담당.
void main() {
  final files = Directory('assets/levels')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final f in files) {
    final levels = (jsonDecode(f.readAsStringSync()) as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();

    test('${f.uri.pathSegments.last}: 전 레벨 파싱 + optimal 기록됨', () {
      expect(levels, isNotEmpty);
      for (final lv in levels) {
        expect(() => lv.toBoard(), returnsNormally, reason: lv.id);
        expect(lv.optimal, greaterThan(0), reason: '${lv.id} optimal 미기록');
      }
    });

    for (final lv in [levels.first, levels.last]) {
      test('${lv.id} 풀이 가능 + optimal 일치', () {
        final sol = Solver().solve(lv.toBoard());
        expect(sol, isNotNull, reason: '${lv.id} 풀이 불가');
        expect(lv.optimal, sol!.length, reason: '${lv.id} optimal 불일치');
      });
    }
  }
}
```

- [ ] **Step 7: 테스트 + 커밋**

Run: `flutter test --no-pub`
Expected: 전체 PASS

```powershell
git add -A; git commit -m "챕터 6~20 생성: 어려운 150스테이지 (솔버 난이도 필터 통과)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: 스티커 해금 간격 25로 조정

**Files:**
- Modify: `lib/models/sticker.dart`
- Modify: `test/models/sticker_test.dart`

**Interfaces:**
- Consumes: 없음
- Produces: 스티커 24종의 임계값이 25, 50, …, 600. `unlockedStickers(int totalStars)` 시그니처 불변.

- [ ] **Step 1: 실패하는 테스트 작성**

`test/models/sticker_test.dart`에서 처음 두 테스트를 교체한다:

```dart
  test('스티커는 24종, 임계값 25단위 오름차순', () {
    expect(kStickers.length, 24);
    for (var i = 0; i < kStickers.length; i++) {
      expect(kStickers[i].threshold, (i + 1) * 25);
    }
    expect(kStickers.last.threshold, 600); // 200스테이지 × 별 3개
  });

  test('해금 경계', () {
    expect(unlockedStickers(0), isEmpty);
    expect(unlockedStickers(24), isEmpty);
    expect(unlockedStickers(25).length, 1);
    expect(unlockedStickers(599).length, 23);
    expect(unlockedStickers(600).length, 24);
  });
```

- [ ] **Step 2: 실행해 실패 확인**

Run: `flutter test --no-pub test/models/sticker_test.dart`
Expected: FAIL — 임계값이 6단위

- [ ] **Step 3: 구현**

`lib/models/sticker.dart`의 리스트 생성 마지막 줄에서 간격을 바꾼다:

```dart
  return [
    for (var i = 0; i < defs.length; i++)
      StickerDef(defs[i].$1, defs[i].$2, defs[i].$3, (i + 1) * 25),
  ];
```

주석도 함께 고친다: 파일 상단 `/// 해금: 누적 별 6개마다 1종 (6, 12, …, 144 — 총 150별).` 을
`/// 해금: 누적 별 25개마다 1종 (25, 50, …, 600 — 200스테이지 × 별 3개).` 로.

- [ ] **Step 4: 통과 확인**

Run: `flutter test --no-pub test/models/sticker_test.dart`
Expected: PASS

- [ ] **Step 5: 커밋**

```powershell
git add -A; git commit -m "스티커 해금 간격 25로 조정 (총 별 600개 기준)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: 20챕터 UI (이름·색·아이콘·막 헤더)

**Files:**
- Modify: `lib/ui/strings.dart`
- Modify: `lib/ui/theme.dart`
- Modify: `lib/ui/screens/chapter_screen.dart`
- Modify: `lib/ui/screens/title_screen.dart` (별 총량 600)
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: Task 1의 `kChapterCount`
- Produces: `S.chapterNames` 20개, `PiyakColors.chapterColors` 20개, 챕터 화면이 20개를 막 헤더와 함께 보여준다.

- [ ] **Step 1: 문구 확장**

`lib/ui/strings.dart`의 `chapterNames`를 20개로 바꾸고 막 이름을 추가한다:

```dart
  static const chapterNames = [
    '풀밭', '얼음길', '비밀 굴', '단추와 문', '금 간 바닥',
    '얼음 굴', '미끄럼 자물쇠', '부서지는 얼음', '굴과 자물쇠', '무너지는 통로',
    '넓은 들판', '알 넷의 방', '얼어붙은 광장', '굴 미로', '잠긴 정원',
    '뒤엉킨 길', '삐약의 시험', '다섯 알의 탑', '마지막 관문', '삐약 마스터',
  ];

  /// 5챕터씩 묶은 막 이름 — 20개 목록이 평평해 보이지 않게 한다.
  static const actNames = ['1막 · 배우기', '2막 · 뒤섞기', '3막 · 넓어지기', '4막 · 시험'];
```

- [ ] **Step 2: 테마색 20개**

`lib/ui/theme.dart`의 `chapterColors`를 교체한다:

```dart
  /// 챕터 1~20 테마색. 막마다 색 계열이 옮겨간다
  /// (1막 자연색 → 2막 청록 → 3막 보라·분홍 → 4막 주황·자주).
  static const chapterColors = [
    Color(0xFF8FD16A), Color(0xFF7FC8E8), Color(0xFFB98FD6),
    Color(0xFFF08FB0), Color(0xFFC49A6C),
    Color(0xFF6FC9A8), Color(0xFF5FBFC4), Color(0xFF7FB3E0),
    Color(0xFF9FA8DC), Color(0xFFB79ED0),
    Color(0xFFD19ADC), Color(0xFFDE9BC0), Color(0xFFE8A0A8),
    Color(0xFFEDAA92), Color(0xFFF0B87F),
    Color(0xFFF2A25C), Color(0xFFEE8F5C), Color(0xFFE87D6B),
    Color(0xFFDC6F7E), Color(0xFFC96B92),
  ];
```

- [ ] **Step 3: 챕터 화면 20개 + 막 헤더**

`lib/ui/screens/chapter_screen.dart`에서 `_icons`를 20개로 늘리고, `ListView.builder`의 `itemCount: 5`를 막 헤더 포함 개수로 바꾼다.

`_icons` 교체:

```dart
  static const _icons = [
    Icons.grass_rounded, Icons.ac_unit_rounded, Icons.blur_circular_rounded,
    Icons.radio_button_checked_rounded, Icons.broken_image_rounded,
    Icons.severe_cold_rounded, Icons.lock_open_rounded, Icons.icecream_rounded,
    Icons.vpn_key_rounded, Icons.warning_amber_rounded,
    Icons.landscape_rounded, Icons.egg_rounded, Icons.snowing_rounded,
    Icons.route_rounded, Icons.local_florist_rounded,
    Icons.shuffle_rounded, Icons.school_rounded, Icons.filter_5_rounded,
    Icons.door_front_door_rounded, Icons.emoji_events_rounded,
  ];
```

`body`를 교체한다 — 인덱스 24개(막 헤더 4 + 챕터 20)를 매핑한다:

```dart
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kChapterCount + S.actNames.length,
        itemBuilder: (context, row) {
          // 5챕터마다 막 헤더가 하나씩 앞에 붙는다: 0,6,12,18번 행이 헤더
          final act = row ~/ 6;
          if (row % 6 == 0) {
            return Padding(
              padding: EdgeInsets.only(top: act == 0 ? 0 : 20, bottom: 8),
              child: Text(
                S.actNames[act],
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: PiyakColors.outline),
              ),
            );
          }
          final c = act * 5 + (row % 6);
          final i = c - 1;
          final unlocked = save.chapterUnlocked(c);
          final stars = save.chapterStars(c);
          // ... 기존 Container/Material/Row 카드 코드를 그대로 둔다
        },
      ),
```

기존 카드 코드에서 `final c = i + 1;`, `final unlocked = ...`, `final stars = ...` 세 줄은 위로 옮겼으므로 삭제한다. `import '../../models/progression.dart';`를 추가한다.

- [ ] **Step 4: 타이틀 화면 별 총량**

`lib/ui/screens/title_screen.dart`에서 `150`을 `600`으로 바꾼다 (진행바 `value`와 표시 문자열 두 곳):

```dart
                            value: save.totalStars / 600,
```
```dart
                          Text(' ${save.totalStars} / 600',
```

- [ ] **Step 5: 위젯 테스트 갱신**

`test/widget_test.dart`의 자물쇠 개수 기대값을 바꾼다. 초기 상태에선 챕터 1만 열리므로 나머지 19개가 잠겨 있지만, `ListView`는 화면에 보이는 것만 만든다. 개수를 세는 대신 **1챕터가 열려 있고 2챕터가 잠겨 있음**을 확인한다:

```dart
    await tester.tap(find.text('시작'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterScreen), findsOneWidget);
    expect(find.text('1막 · 배우기'), findsOneWidget);
    expect(find.textContaining('풀밭'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets); // 잠긴 챕터가 보인다
```

기존 `expect(find.byIcon(Icons.lock_rounded), findsNWidgets(4));` 줄은 삭제한다.

- [ ] **Step 6: 테스트 + 정적 분석**

Run: `flutter analyze` 그리고 `flutter test --no-pub`
Expected: analyze `No issues found`, 전체 PASS

- [ ] **Step 7: 커밋**

```powershell
git add -A; git commit -m "20챕터 UI: 이름·테마색·아이콘 확장 + 막 구분 헤더

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: 전체 점검 · 릴리즈 · 실기기

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: Task 1~6 전부

- [ ] **Step 1: 전체 테스트 + 정적 분석**

```powershell
flutter analyze
flutter test --no-pub
```
Expected: analyze `No issues found`, 전체 PASS

- [ ] **Step 2: 레벨 전수 검증**

```powershell
dart run tool/validate_levels.dart
```
Expected: 풀이 불가 0건, 200개 + 데일리 프리셋 20개 분포 출력

- [ ] **Step 3: README 갱신**

`README.md`의 메타 항목을 교체한다:

```markdown
- 별 누적 25개마다 스티커 1종 해금 (총 24종) → 스티커북·꾸미기 보드(드래그 배치, 저장됨)
- 데일리 퍼즐: 날짜 시드로 매일 새 퍼즐(항상 풀이 가능 보장), 달력 도장·연속 출석
- 챕터 해금: 이전 챕터에서 8스테이지 클리어 (별 개수와 무관)
```

기존 "별 누적 6개마다…"와 "챕터 해금: 이전 챕터에서 별 12개" 줄을 지운다.

"## 레벨 추가법" 아래에 생성 도구 설명을 덧붙인다:

```markdown
챕터 6~20은 손으로 만들지 않고 생성한다. 시드가 챕터 번호로 고정돼 있어 재현된다:

```bash
dart run tool/gen_chapters.dart 6    # 한 챕터만 (난이도 밴드 조율용)
dart run tool/gen_chapters.dart      # 6~20 전부
```

난이도는 최적 이동수만이 아니라 밀기 횟수·솔버 탐색 상태 수·데드락 비율까지
네 지표로 거른다. 밴드는 `tool/gen_chapters.dart`의 `specFor`에 있다.
```

- [ ] **Step 4: 릴리즈 빌드**

```powershell
flutter build apk --release
```
Expected: `√ Built build\app\outputs\flutter-apk\app-release.apk`

- [ ] **Step 5: 실기기 설치·확인**

```powershell
C:\workAndroid\android-sdk-ascii\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-release.apk
```

육안 체크리스트 (스크린샷으로 근거를 남길 것):
1. 챕터 목록에 20개와 막 헤더 4개가 보이는가
2. 타이틀의 별 표시가 `/ 600`인가
3. 챕터3 10스테이지 클리어 상태에서 챕터4가 열려 있는가 — **이번 수정의 핵심**
4. 6막 이후 레벨을 하나 열어 실제로 어려운지, 힌트 버튼이 몇 초 안에 응답하는지

- [ ] **Step 6: 커밋**

```powershell
git add -A; git commit -m "v2: README 갱신 및 실기기 확인

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Self-Review 기록

- **스펙 커버리지**: 1절 진행 규칙→Task 1 / 2절 챕터 구조→Task 4·6 / 3절 난이도 지표→Task 2, 밴드→Task 4 / 4절 생성 파이프라인→Task 3·4 / 5절 아키텍처→Task 1~4·6 / 6절 이름·색→Task 6 / 7절 테스트→각 Task + Task 7. 스티커 25 간격(1절)→Task 5. `totalStars` 20챕터(5절)→Task 1. 누락 없음.
- **타입 일관성**: `SolveReport`(Task 2)의 필드명을 Task 3의 `generate`와 Task 4의 CLI 로그가 그대로 쓴다(`optimalMoves`, `pushes`, `statesExplored`, `deadlockRatio`). `GenSpec`/`Gimmick`/`GenResult`(Task 3)를 Task 4가 소비. `ChapterLocked.clearsNeeded`(Task 1)를 같은 Task의 `stage_screen` 배선이 소비. `kChapterCount`(Task 1)를 Task 6의 `chapter_screen`이 소비.
- **의존 순서**: 2 → 3 → 4는 필수. 1·5·6은 서로 독립이며 4와도 독립(다만 Task 6의 위젯 테스트는 Task 1의 해금 규칙에 의존하므로 1 → 6).
- **위험**: Task 4의 생성 시간이 가장 불확실하다. Step 2에서 챕터 하나로 파일럿을 돌려 측정하고 밴드를 조정한 뒤 전체를 돌리도록 절차에 넣었다. 밴드 완화 기준도 수치로 적었다.
- **범위**: 엔진 규칙·저장 키 포맷 불변 → 기존 진행 기록이 재설치 후에도 유지된다.
