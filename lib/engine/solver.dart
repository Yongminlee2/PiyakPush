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

class Solver {
  final int maxStates;
  Solver({this.maxStates = 2000000});

  /// 최적 이동열. 이미 클리어면 빈 목록, 풀이 불가·상한 초과면 null.
  List<Dir>? solve(Board start) {
    if (start.isCleared) return const [];
    if (hasCornerDeadlock(start)) return null;

    final startKey = start.stateKey;
    final parent = <String, (String, Dir)>{};
    final seen = <String>{startKey};
    final queue = Queue<Board>()..add(start);
    var states = 0;

    while (queue.isNotEmpty) {
      final b = queue.removeFirst();
      final bKey = b.stateKey;
      for (final d in Dir.values) {
        final o = b.tryMove(d);
        if (o.blocked) continue;
        final nb = o.board!;
        final key = nb.stateKey;
        if (!seen.add(key)) continue;
        parent[key] = (bKey, d);
        if (nb.isCleared) return _reconstruct(parent, startKey, key);
        if (hasCornerDeadlock(nb)) continue;
        if (++states > maxStates) return null;
        queue.add(nb);
      }
    }
    return null;
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
