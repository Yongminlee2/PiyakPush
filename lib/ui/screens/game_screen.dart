/// 게임 화면: 스와이프 입력 + HUD + 보드 + 병아리 무드 + 클리어 오버레이.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../engine/geometry.dart';
import '../../engine/move.dart';
import '../../models/level.dart';
import '../game_controller.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/act_background.dart';
import '../widgets/board_view.dart';
import '../widgets/clear_popup.dart';
import '../widgets/dpad.dart';
import '../widgets/hud.dart';
import '../widgets/joystick.dart';
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

  final Future<List<Dir>?> Function(GameController)? hintProvider;
  final void Function(List<GameEvent> events, bool cleared)? onEvents;

  /// 팝업을 그리는 시점에 호출된다 — 이 스테이지의 별이 저장된 뒤라야
  /// 다음 챕터 해금 여부를 정확히 판정할 수 있기 때문이다.
  final ClearOutcome Function()? clearOutcome;

  /// 설정의 조작 방식 — true면 십자 방향키, false면 조이스틱.
  final bool useDpad;
  const GameScreen({
    required this.level,
    this.onNext,
    this.onCleared,
    this.hintProvider,
    this.onEvents,
    this.clearOutcome,
    this.useDpad = false,
    super.key,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController c;
  Timer? _t10, _t30;
  bool _clearedNotified = false;
  List<Dir>? _hintMoves;
  Dir? _bumpDir;
  int _bumpToken = 0;
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
    _glide?.cancel();
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
    if (c.move(d)) {
      widget.onEvents?.call(c.lastEvents, c.cleared);
    } else {
      // 막힌 입력에 아무 반응이 없으면 조작이 뻣뻣하게 느껴진다.
      setState(() {
        _bumpDir = d;
        _bumpToken++;
      });
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
        return widget.useDpad ? S.tutorial1Dpad : S.tutorial1;
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
            ActBackground(chapter: widget.level.chapter),
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
                  child: Stack(
                      children: [
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final b = c.board;
                              // 패널 안쪽 여백(10*2)과 화면 여백(12*2)을 뺀 뒤 나눈다
                              final avail = Size(
                                  box.maxWidth - 44, box.maxHeight - 44);
                              // 기준 44 고정 — 판이 그보다 커서 안 들어갈 때만 줄인다.
                              // (레벨마다 크기가 널뛰지 않게)
                              final fit = (avail.width / b.width <
                                      avail.height / b.height)
                                  ? avail.width / b.width
                                  : avail.height / b.height;
                              final cell = fit < 44.0 ? fit : 44.0;
                              return Center(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: PiyakColors.boardPanel,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                        color: PiyakColors.outline, width: 3),
                                  ),
                                  child: BoardView(
                                    board: b,
                                    cellSize: cell.clamp(20.0, 44.0),
                                    chickMood: mood,
                                    hintMoves: _hintMoves,
                                    bumpDir: _bumpDir,
                                    bumpToken: _bumpToken,
                                    gliding: _gliding,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // 말풍선은 겹쳐 띄운다 — 나타났다 사라져도 조이스틱이 밀리지 않도록.
                        if (bubble != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: SpeechBubble(text: bubble),
                          ),
                      ],
                  ),
                ),
                // 방향키는 제 키(약 240px)대로 두고 아래 여백으로 띄운다 —
                // 고정 높이 띠에 넣으면 잘리고 너무 바닥에 붙는다.
                widget.useDpad
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 36),
                        child: DPad(onDirDown: holdDir, onRelease: releaseDir),
                      )
                    : SizedBox(
                        height: 180,
                        child:
                            Joystick(onDir: holdDir, onRelease: releaseDir),
                      ),
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
