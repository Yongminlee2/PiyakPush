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
