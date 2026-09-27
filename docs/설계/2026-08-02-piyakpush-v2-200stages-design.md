# 삐약푸시 v2 — 200스테이지 확장과 진행 규칙 교체

- 날짜: 2026-08-02
- 상태: 승인됨
- 기반: v1(`2026-08-02-piyakpush-design.md`), v1.1(`2026-08-02-piyakpush-v11-polish-design.md`)

## 배경

v1.1 플레이 중 두 가지 문제가 나왔다.

1. **챕터3의 10스테이지를 다 깼는데 다음 챕터로 못 넘어간다.**
2. **문제가 너무 쉬운 것만 많다.** 총 200스테이지를, 좀 더 어렵게.

### 1번의 원인 — 잠금 규칙 설계 결함

다음 챕터 해금 조건이 "이전 챕터에서 별 12개"인데, 한 챕터는 10스테이지뿐이다.
**모든 스테이지를 클리어해도 별을 1개씩만 받으면 10개**여서 12개에 못 미친다.
즉 챕터를 100% 깨고도 영구히 갇힐 수 있다. 챕터3은 최적수가 2~36수로 급격히
올라(c3s10이 36수) 별 3개를 받기 어려워 이 결함이 실제로 드러났다.

별점은 실력 보상이어야지 진행 관문이 되면 안 된다.

## 1. 진행 잠금 규칙 교체

**해금 조건을 별이 아니라 클리어 개수로 바꾼다.**

- 다음 챕터 해금: 현재 챕터에서 **8스테이지 이상 클리어** (별 개수 무관)
- "클리어"는 별 1개 이상 획득을 뜻한다 — 저장된 별이 0이면 미클리어
- 별은 스티커 수집 전용이 된다

10개 중 8개라 어려운 두 판을 건너뛰어도 진행이 막히지 않고, 클리어하고도 갇히는
상황이 사라진다.

전체 별이 150개에서 **600개**(200×3)로 늘어나므로 스티커 24종의 해금 간격을
6개에서 **25개**로 조정한다(25, 50, …, 600).

## 2. 챕터 구조 — 20챕터 × 10스테이지

기존 5챕터 50스테이지는 **그대로 1막**으로 둔다(진행 기록 보존, 기믹 학습 순서 유지).

| 막 | 챕터 | 성격 | 보드 | 알 | 최적수 |
|---|---|---|---|---|---|
| 1막 | 1–5 | 기존 50개 — 기믹 하나씩 학습 | 5×3~10×7 | 1–4 | 1–36 |
| 2막 | 6–10 | 기믹 2종 조합 | 8×8 | 3 | 15–25 |
| 3막 | 11–15 | 넓은 보드, 알 4개 | 9×9 | 4 | 22–32 |
| 4막 | 16–20 | 전 기믹 조합, 알 5개 | 8×8~9×9 | 5 | 28–40 |

챕터 이름·테마색·아이콘 20종을 정의한다(6절).

## 3. 난이도 — "머리 쓰는 어려움"의 측정

이동수만으로는 난이도를 못 잡는다. 60수짜리도 일직선으로 밀기만 하면 지루할 뿐
어렵지 않다. 솔버가 답을 찾는 김에 네 가지를 함께 재고, 네 가지 모두 밴드를
통과한 후보만 채택한다.

| 지표 | 뜻 | 왜 필요한가 |
|---|---|---|
| `optimalMoves` | 최적 이동수 | 판의 길이 |
| `pushes` | 최적해에서 알을 민 횟수 | 걷기만 길고 밀기는 적은 "산책 퍼즐" 배제 |
| `statesExplored` | 솔버가 답까지 뒤진 상태 수 | 같은 수라도 갈래가 많으면 눈에 안 보인다 |
| `deadlockRatio` | 데드락으로 잘려나간 상태 비율 | 순서를 틀리면 막히는 함정의 존재 |

`deadlockRatio = deadlocksPruned / (deadlocksPruned + statesExplored)`.
데드락 판정은 기존 모서리 검사라서 실제 함정을 과소평가하지만, 상대 비교에는 쓸 만하다.

### 막별 밴드

| 막 | optimalMoves | pushes ≥ | statesExplored ≥ | deadlockRatio ≥ |
|---|---|---|---|---|
| 2막 | 15–25 | 8 | 1500 | 0.03 |
| 3막 | 22–32 | 12 | 4000 | 0.05 |
| 4막 | 28–40 | 16 | 8000 | 0.06 |

챕터 내 10스테이지는 최적수 오름차순으로 정렬해 배치한다.

## 4. 레벨 생성 파이프라인

150개를 손으로 만드는 건 비현실적이다 — v1에서 손으로 만든 50개 중 5개가 풀이
불가였고 난이도도 들쭉날쭉했다. **생성하고 솔버로 거른다.**

한 후보를 만드는 절차:

1. **기본 배치 역방향 생성** — 벽·바닥·둥지만으로 완성 상태(알이 전부 둥지 위)를
   만들고, 역방향 이동(걷기·당기기)을 무작위로 적용해 흐트러뜨린다. 역방향으로
   만든 상태는 완성 상태로 가는 순방향 경로가 반드시 있으므로 풀이 가능하다.
   (데일리 퍼즐에서 이미 검증된 방식)
2. **기믹 타일 뿌리기** — 알·병아리·둥지가 없는 바닥 칸에 기믹 타일을 무작위 배치.
   얼음·굴·버튼과 문·금 간 바닥 중 그 막의 조합을 쓴다.
3. **솔버로 재검증·측정** — 기믹을 얹으면 풀이가 막힐 수 있다. 솔버가 진실의
   기준이다. 풀이 불가면 폐기하고, 가능하면 3절의 네 지표를 측정한다.
4. **밴드 통과 시 채택** — 하나라도 벗어나면 폐기하고 다음 후보로.

시드를 챕터별로 고정해 **재현 가능**하게 한다. 같은 시드는 같은 200스테이지를 만든다.

탐색 상한은 **400,000 상태**로 둔다. 상한을 넘는 후보는 폐기한다 — 사람에게 너무
어렵기도 하고, 앱 안의 힌트 기능도 같은 솔버를 쓰므로 응답이 느려지면 안 된다.

## 5. 아키텍처

| 파일 | 책임 | 상태 |
|---|---|---|
| `lib/engine/solve_report.dart` | 솔버 측정 결과 타입 | 신규 |
| `lib/engine/solver.dart` | `analyze()` 추가 (기존 `solve()` 유지) | 수정 |
| `lib/services/level_generator.dart` | 기믹 포함 후보 생성 (순수 Dart) | 신규 |
| `lib/models/progression.dart` | 해금 규칙 교체, 챕터 20개 | 수정 |
| `lib/services/save_service.dart` | `chapterClearedCount` 추가, `totalStars` 20챕터 순회 | 수정 |
| `lib/models/sticker.dart` | 해금 간격 25 | 수정 |
| `lib/ui/theme.dart` | 챕터 테마색 20개 | 수정 |
| `lib/ui/strings.dart` | 챕터 이름 20개, 잠금 문구 | 수정 |
| `lib/ui/screens/chapter_screen.dart` | 20챕터 목록 + 막 구분 헤더 | 수정 |
| `tool/gen_chapters.dart` | 챕터 6~20 생성 CLI | 신규 |
| `assets/levels/chapter6..20.json` | 생성된 150스테이지 | 신규 |

`lib/services/daily_generator.dart`의 역방향 생성 로직은 `level_generator.dart`로
옮겨 일반화하고, 데일리는 그것을 호출한다 — 같은 코드를 두 벌 두지 않는다.

`LevelRepository`는 이미 `chapter{c}.json`을 로드하므로 수정이 필요 없다.

### 핵심 인터페이스

```dart
// lib/engine/solve_report.dart
class SolveReport {
  final List<Dir>? moves;      // null이면 풀이 불가
  final int statesExplored;
  final int deadlocksPruned;
  final int pushes;            // 최적해에서 알을 민 횟수
  bool get solved => moves != null;
  int get optimalMoves => moves?.length ?? 0;
  double get deadlockRatio;    // deadlocksPruned / (deadlocksPruned + statesExplored)
}

// lib/engine/solver.dart
SolveReport analyze(Board start);   // Solver의 메서드

// lib/services/level_generator.dart
class GenSpec {
  final int width, height, eggCount, wallCount, gimmickCount;
  final List<Tile> gimmicks;
  final int minOptimal, maxOptimal, minPushes, minStates;
  final double minDeadlockRatio;
}
Level? generateLevel(Random rng, GenSpec spec, {int maxAttempts = 400});

// lib/models/progression.dart
const int kChapterUnlockClears = 8;
const int kChapterCount = 20;
NextStep resolveNextStep({
  required int chapter,
  required int index,
  required int levelCount,
  required int currentChapterClears,   // 별이 아니라 클리어 개수
  int chapterCount = kChapterCount,
});
```

`ChapterLocked`의 필드는 `starsNeeded`에서 `clearsNeeded`로 바꾼다.

## 6. 챕터 이름·색

| # | 이름 | # | 이름 |
|---|---|---|---|
| 1 | 풀밭 | 11 | 넓은 들판 |
| 2 | 얼음길 | 12 | 알 넷의 방 |
| 3 | 비밀 굴 | 13 | 얼어붙은 광장 |
| 4 | 단추와 문 | 14 | 굴 미로 |
| 5 | 금 간 바닥 | 15 | 잠긴 정원 |
| 6 | 얼음 굴 | 16 | 뒤엉킨 길 |
| 7 | 미끄럼 자물쇠 | 17 | 삐약의 시험 |
| 8 | 부서지는 얼음 | 18 | 다섯 알의 탑 |
| 9 | 굴과 자물쇠 | 19 | 마지막 관문 |
| 10 | 무너지는 통로 | 20 | 삐약 마스터 |

테마색은 막별 색 계열로 20개를 정의한다: 1막 기존 5색 유지, 2막 청록~남색,
3막 보라~분홍, 4막 주황~자주.

챕터 화면에는 막 구분 헤더("1막 · 배우기", "2막 · 뒤섞기", "3막 · 넓어지기",
"4막 · 시험")를 넣어 20개 목록이 평평하게 보이지 않게 한다.

## 7. 테스트 전략

- `resolveNextStep` 단위 테스트를 새 규칙으로 갱신: 챕터 중간 / 마지막+8클리어 이상 /
  마지막+클리어 부족(부족분 확인) / 20챕터 마지막.
- **회귀 테스트 추가**: 10스테이지를 전부 별 1개로 클리어한 상태에서 다음 챕터가
  열려야 한다. 이번 결함을 정확히 겨냥한다.
- `SaveService.chapterClearedCount` 단위 테스트, 그리고 `totalStars`가 20챕터를
  모두 세는지 확인 — 현재 구현은 1~5만 순회하므로 고치지 않으면 6막 이후 별이
  스티커 해금에 반영되지 않는다.
- 스티커 해금 임계값 테스트를 25 간격으로 갱신.
- `Solver.analyze` 단위 테스트: 알려진 레벨에서 `pushes`와 `optimalMoves`가 맞는지,
  풀이 불가 레벨에서 `solved == false`인지.
- 전 레벨 검증 테스트(`test/levels/`)는 200개로 늘어난다. 생성 단계에서 40만 상태
  상한을 통과한 것만 채택하므로 각 레벨의 솔브 시간에는 상한이 있다.
- `tool/validate_levels.dart`는 그대로 200개를 검증하고 `optimal`을 재기록한다.

## 8. 범위 제외

- 기존 50스테이지의 내용 변경 (1막으로 유지)
- 새 기믹 추가 (기존 5종 조합으로 충분)
- 광고·결제·다국어
- 레벨 에디터
