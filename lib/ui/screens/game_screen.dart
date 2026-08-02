/// 게임 화면: 스와이프 입력 + HUD + 보드 + 병아리 무드 + 클리어 오버레이.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../engine/geometry.dart';
import '../../engine/move.dart';
import '../../models/level.dart';
import '../game_controller.dart';
import '../strings.dart';
import '../widgets/board_view.dart';
import '../widgets/clear_popup.dart';
import '../widgets/dpad.dart';
import '../widgets/hud.dart';
import '../widgets/speech_bubble.dart';

/// 클리어 팝업이 무엇을 보여줄지 — 진행 판정 결과를 화면이 이해하는 형태로 옮긴 것.
class ClearOutcome {
  final String? nextLabel;
  final VoidCallback? onNext;
  final String? note;
  const ClearOutcome({this.nextLabel, this.onNext, this.note});
}

class GameScreen extends StatefulWidget {
  final Level level;
  final VoidCallback? onNext;
  final void Function(int stars)? onCleared;

  /// 방향키가 기본 조작 (스와이프도 계속 동작).
  final bool showDpad;
  final Future<List<Dir>?> Function(GameController)? hintProvider;
  final void Function(List<GameEvent> events, bool cleared)? onEvents;

  /// 팝업을 그리는 시점에 호출된다 — 이 스테이지의 별이 저장된 뒤라야
  /// 다음 챕터 해금 여부를 정확히 판정할 수 있기 때문이다.
  final ClearOutcome Function()? clearOutcome;
  const GameScreen({
    required this.level,
    this.onNext,
    this.onCleared,
    this.showDpad = true,
    this.hintProvider,
    this.onEvents,
    this.clearOutcome,
    super.key,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController c;
  Timer? _t10, _t30;
  Offset _drag = Offset.zero;
  bool _clearedNotified = false;
  List<Dir>? _hintMoves;

  @override
  void initState() {
    super.initState();
    c = GameController(widget.level)..addListener(_onChange);
    _resetIdleTimers();
  }

  @override
  void dispose() {
    _t10?.cancel();
    _t30?.cancel();
    c.dispose();
    super.dispose();
  }

  void _onChange() {
    if (c.cleared && !_clearedNotified) {
      _clearedNotified = true;
      widget.onCleared?.call(c.stars);
    }
    setState(() {});
  }

  void _resetIdleTimers() {
    _t10?.cancel();
    _t30?.cancel();
    _t10 = Timer(const Duration(seconds: 10), c.markIdle10s);
    _t30 = Timer(const Duration(seconds: 30), c.markIdle30s);
  }

  void _input(Dir d) {
    _resetIdleTimers();
    _hintMoves = null;
    final ok = c.move(d);
    if (ok) {
      widget.onEvents?.call(c.lastEvents, c.cleared);
    }
  }

  void _restart() {
    _resetIdleTimers();
    _hintMoves = null;
    _clearedNotified = false;
    c.restart();
  }

  void _undo() {
    _resetIdleTimers();
    _hintMoves = null;
    c.undo();
  }

  Future<void> _hint() async {
    if (widget.hintProvider == null) return;
    _resetIdleTimers();
    final moves = await widget.hintProvider!.call(c);
    if (!mounted) return;
    setState(() => _hintMoves = moves);
  }

  String? get _bubbleText {
    if (c.deadlocked) return S.deadlockHint;
    switch (widget.level.id) {
      case 'c1s01':
        return S.tutorial1;
      case 'c1s02':
        return S.tutorial2;
      case 'c1s03':
        return S.tutorial3;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bubble = _bubbleText;
    final mood =
        (bubble != null && !c.deadlocked && !c.cleared) ? 'speak' : c.mood.name;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                GameHud(
                  title: widget.level.title,
                  moves: c.moves,
                  optimal: widget.level.optimal,
                  onUndo: _undo,
                  onRestart: _restart,
                  onHint: widget.hintProvider != null ? _hint : null,
                ),
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
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final b = c.board;
                        final cell = (box.maxWidth - 24) / b.width <
                                (box.maxHeight - 24) / b.height
                            ? (box.maxWidth - 24) / b.width
                            : (box.maxHeight - 24) / b.height;
                        return Center(
                          child: BoardView(
                            board: b,
                            cellSize: cell.clamp(20.0, 72.0),
                            chickMood: mood,
                            hintMoves: _hintMoves,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (widget.showDpad)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: DPad(onDir: _input),
                  ),
                if (bubble != null) SpeechBubble(text: bubble),
                const SizedBox(height: 8),
              ],
            ),
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
          ],
        ),
      ),
    );
  }
}
