/// 게임 한 판의 상태: 보드 히스토리(undo 무제한) + 이동수 + 별점 + 병아리 무드.
///
/// think/sleep 타이머는 화면이 소유한다 — 컨트롤러는 markIdle10s/30s 호출만
/// 받는다(테스트 용이성).
library;

import 'package:flutter/foundation.dart';

import '../engine/board.dart';
import '../engine/deadlock.dart';
import '../engine/geometry.dart';
import '../engine/move.dart';
import '../models/level.dart';

enum ChickMood { idle, think, sleep, cheer, sad, speak }

class GameController extends ChangeNotifier {
  final Level level;
  final List<Board> _history;
  List<GameEvent> lastEvents = const [];
  ChickMood _restMood = ChickMood.idle;

  GameController(this.level) : _history = [level.toBoard()];

  Board get board => _history.last;
  int get moves => _history.length - 1;
  bool get cleared => board.isCleared;
  bool get deadlocked => hasCornerDeadlock(board);

  ChickMood get mood {
    if (cleared) return ChickMood.cheer;
    if (deadlocked) return ChickMood.sad;
    return _restMood;
  }

  bool move(Dir d) {
    if (cleared) return false;
    final o = board.tryMove(d);
    if (o.blocked) return false;
    _history.add(o.board!);
    lastEvents = o.events;
    _restMood = ChickMood.idle;
    notifyListeners();
    return true;
  }

  void undo() {
    if (_history.length <= 1) return;
    _history.removeLast();
    lastEvents = const [];
    _restMood = ChickMood.idle;
    notifyListeners();
  }

  void restart() {
    if (_history.length <= 1) return;
    _history.removeRange(1, _history.length);
    lastEvents = const [];
    _restMood = ChickMood.idle;
    notifyListeners();
  }

  /// 클리어 시 1~3, 아니면 0. 최적수 기록이 없으면(0) 클리어=1★.
  int get stars {
    if (!cleared) return 0;
    if (level.optimal > 0) {
      if (moves <= level.optimal) return 3;
      if (moves <= (level.optimal * 1.5).ceil()) return 2;
    }
    return 1;
  }

  void markIdle10s() {
    if (cleared || deadlocked || _restMood != ChickMood.idle) return;
    _restMood = ChickMood.think;
    notifyListeners();
  }

  void markIdle30s() {
    if (cleared || deadlocked || _restMood == ChickMood.sleep) return;
    _restMood = ChickMood.sleep;
    notifyListeners();
  }
}
