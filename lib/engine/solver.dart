/// 이동수 최적 BFS 솔버. 레벨 검증(풀이 가능 + 최적수)과 게임 내 힌트 겸용.
///
/// 상태 = Board.stateKey (병아리·알·남은 금 간 바닥). 한 이동이 간선 1이므로
/// BFS 도달 순서가 곧 최적 이동수다. 모서리 데드락 상태는 큐에 넣지 않는다.
library;

import 'dart:collection';

import 'board.dart';
import 'deadlock.dart';
import 'geometry.dart';
import 'move.dart';
import 'solve_report.dart';

class Solver {
  final int maxStates;
  Solver({this.maxStates = 2000000});

  /// 최적 이동열. 이미 클리어면 빈 목록, 풀이 불가·상한 초과면 null.
  List<Dir>? solve(Board start) => analyze(start).moves;

  /// 최적해와 난이도 지표를 함께 낸다. 레벨 생성기가 후보를 거르는 데 쓴다.
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

  List<Dir> _reconstruct(
      Map<String, (String, Dir)> parent, String startKey, String endKey) {
    final moves = <Dir>[];
    var k = endKey;
    while (k != startKey) {
      final (pk, d) = parent[k]!;
      moves.add(d);
      k = pk;
    }
    return moves.reversed.toList();
  }
}
