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

class GameScreen extends StatefulWidget {
  final Level level;
  final VoidCallback? onNext;
  final void Function(int stars)? onCleared;
  final bool showDpad;
  final Future<List<Dir>?> Function(GameController)? hintProvider;
  final void Function(List<GameEvent> events, bool cleared)? onEvents;
  const GameScreen({
    required this.level,
    this.onNext,
    this.onCleared,
    this.showDpad = false,
    this.hintProvider,
    this.onEvents,
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
                if (bubble != null) SpeechBubble(text: bubble),
                const SizedBox(height: 8),
              ],
            ),
            if (widget.showDpad)
              Positioned(
                right: 16,
                bottom: 24,
                child: DPad(onDir: _input),
              ),
            if (c.cleared)
              Positioned.fill(
                child: ClearPopup(
                  stars: c.stars,
                  moves: c.moves,
                  optimal: widget.level.optimal,
                  onNext: widget.onNext,
                  onRetry: _restart,
                  onList: Navigator.canPop(context)
                      ? () => Navigator.pop(context)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
