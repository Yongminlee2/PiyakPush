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

/// 화면 아래 조작 영역의 높이. 방향키(버튼 3줄 240 + 아래 여백 36)에 맞췄고,
/// 조이스틱일 때도 같은 높이를 비워 둬 보드 크기가 조작 방식에 따라 달라지지
/// 않게 한다.
const double kControlAreaHeight = 276;

/// 클리어 팝업이 무엇을 보여줄지 — 진행 판정 결과를 화면이 이해하는 형태로 옮긴 것.
class ClearOutcome {
  final String? nextLabel;
  final VoidCallback? onNext;
  final String? note;
  const ClearOutcome({this.nextLabel, this.onNext, this.note});
}

class GameScreen extends StatefulWidget {
  final Level level;

  /// 화면에 띄울 스테이지 이름. 레벨 파일의 제목은 한국어라, 다른 언어에서는
  /// 챕터명으로 만든 이름이 들어온다.
  final String? title;
  final VoidCallback? onNext;
  final void Function(int stars)? onCleared;

  final Future<List<Dir>?> Function(GameController)? hintProvider;
  final void Function(List<GameEvent> events, bool cleared)? onEvents;

  /// 팝업을 그리는 시점에 호출된다 — 이 스테이지의 별이 저장된 뒤라야
  /// 다음 챕터 해금 여부를 정확히 판정할 수 있기 때문이다.
  final ClearOutcome Function()? clearOutcome;

  /// 설정의 조작 방식 — true면 십자 방향키, false면 조이스틱.
  final bool useDpad;

  /// 남은 힌트 개수. null이면 배지를 숨긴다.
  final int? hintsLeft;

  /// 힌트를 한 개 소모한다. 못 쓰면 false. null이면 제한 없이 쓴다 —
  /// 화면이 저장소를 직접 붙들지 않게 콜백으로 받는다.
  final Future<bool> Function()? onSpendHint;

  /// 벽에 막혀 못 움직였을 때. 튕기는 연출에 맞춰 소리를 낸다.
  final VoidCallback? onBlocked;
  const GameScreen({
    required this.level,
    this.title,
    this.onNext,
    this.onCleared,
    this.hintProvider,
    this.onEvents,
    this.clearOutcome,
    this.useDpad = false,
    this.hintsLeft,
    this.onSpendHint,
    this.onBlocked,
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

  /// 한 걸음이 그려지는 [kMoveAnim] 동안 살아 있는 타이머.
  ///
  /// 이게 없으면 걸음 도중에 들어온 입력이 애니메이션의 목적지만 바꿔치기해서
  /// **첫 칸이 안 보인 채 두 칸을 한 번에** 미끄러진다(빠르게 두 번 누를 때).
  /// 걸음이 끝날 때까지 다음 걸음을 미뤄, 누른 만큼 한 칸씩 보이게 한다.
  ///
  /// 연속 이동도 이 타이머가 몰고 간다 — 따로 주기 타이머를 두면 둘이
  /// 같은 간격으로 어긋나 박자가 흔들린다.
  Timer? _stepCooldown;

  /// 걷는 중에 들어와 미뤄 둔 걸음 (하나만 기억한다).
  Dir? _queuedDir;

  bool get _gliding => _heldDir != null;

  /// 조이스틱이 방향을 잡거나 바꿀 때. 같은 방향이면 무시.
  void holdDir(Dir d) {
    if (_heldDir == d) return;
    _heldDir = d;
    _requestMove(d);
    setState(() {});
  }

  /// 걸음 요청. 직전 걸음이 아직 그려지는 중이면 끝날 때까지 미룬다.
  void _requestMove(Dir d) {
    if (_stepCooldown != null) {
      _queuedDir = d; // 입력을 버리지 않는다 — 반드시 한 칸으로 이어진다
      return;
    }
    _step(d);
  }

  /// 한 걸음이 끝났다. 미뤄 둔 게 있으면 그걸, 아직 누르고 있으면 이어서.
  void _afterStep() {
    _stepCooldown = null;
    if (!mounted) return;
    final queued = _queuedDir;
    _queuedDir = null;
    final next = queued ?? _heldDir;
    if (next != null) _step(next);
  }

  /// 손을 뗐거나 데드존으로 돌아왔을 때 — 마지막 칸은 easeOut으로 감속.
  ///
  /// 진행 중인 걸음과 미뤄 둔 걸음은 그대로 둔다. 누른 건 이미 누른 것이다.
  void releaseDir() {
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
    _stepCooldown?.cancel();
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

  void _step(Dir d) {
    _stepCooldown = Timer(kMoveAnim, _afterStep);
    _resetIdleTimers();
    _hintMoves = null;
    if (c.move(d)) {
      widget.onEvents?.call(c.lastEvents, c.cleared);
    } else {
      // 막힌 입력에 아무 반응이 없으면 조작이 뻣뻣하게 느껴진다.
      widget.onBlocked?.call();
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
    if ((widget.hintsLeft ?? 1) <= 0) {
      await _sayNoHints();
      return;
    }
    final moves = await widget.hintProvider!.call(c);
    if (!mounted) return;
    // 길을 못 찾았으면(탐색 상한 초과 등) 힌트를 깎지 않는다 —
    // 아무것도 못 받고 잃으면 억울하다.
    if (moves == null || moves.isEmpty) {
      setState(() => _hintMoves = null);
      return;
    }
    await widget.onSpendHint?.call();
    if (!mounted) return;
    setState(() => _hintMoves = moves);
  }

  Future<void> _sayNoHints() => showDialog<void>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(S.hintEmpty),
      content: Text(S.hintHowTo),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: Text(S.ok)),
      ],
    ),
  );

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
    final mood = (bubble != null && !c.deadlocked && !c.cleared)
        ? 'speak'
        : c.mood.name;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 조작 방식에 따라 배경을 다르게 두면(한쪽만 늘리면) 같은 게임인데
            // 화면이 달라 보인다. 두 모드 모두 그림 비율 그대로 깐다.
            ActBackground(chapter: widget.level.chapter),
            Column(
              children: [
                GameHud(
                  title: widget.title ?? widget.level.title,
                  moves: c.moves,
                  optimal: widget.level.optimal,
                  onUndo: _undo,
                  onRestart: _restart,
                  onHint: widget.hintProvider != null ? _hint : null,
                  hintsLeft: widget.hintsLeft,
                ),
                // HUD 아래 전체를 한 겹으로 묶는다. 조이스틱이 보드와 조작
                // 영역을 함께 덮어야 "화면 아무 데나 눌러서 조작"이 성립한다.
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: LayoutBuilder(
                                    builder: (context, box) {
                                      final b = c.board;
                                      // 패널 안쪽 여백(10*2)과 화면 여백(12*2)을 뺀 뒤 나눈다
                                      final avail = Size(
                                        box.maxWidth - 44,
                                        box.maxHeight - 44,
                                      );
                                      // 기준 44 고정 — 판이 그보다 커서 안 들어갈 때만 줄인다.
                                      // (레벨마다 크기가 널뛰지 않게)
                                      final fit =
                                          (avail.width / b.width <
                                              avail.height / b.height)
                                          ? avail.width / b.width
                                          : avail.height / b.height;
                                      final cell = fit < 44.0 ? fit : 44.0;
                                      return Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: PiyakColors.boardPanel,
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                            border: Border.all(
                                              color: PiyakColors.outline,
                                              width: 3,
                                            ),
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
                                // 말풍선은 겹쳐 띄운다 — 나타났다 사라져도 조작부가 밀리지 않도록.
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
                          // 조작 영역은 두 방식 모두 같은 높이를 차지한다.
                          // 조이스틱일 때만 비워 두면 보드에 남는 공간이 달라져
                          // 같은 판인데 칸 크기가 바뀐다.
                          SizedBox(
                            height: kControlAreaHeight,
                            child: widget.useDpad
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 36),
                                    child: DPad(
                                      onDirDown: holdDir,
                                      onRelease: releaseDir,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      if (!widget.useDpad)
                        Positioned.fill(
                          child: Joystick(
                            onDir: holdDir,
                            onRelease: releaseDir,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (c.cleared)
              Builder(
                builder: (context) {
                  final outcome =
                      widget.clearOutcome?.call() ??
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
                },
              ),
          ],
        ),
      ),
    );
  }
}
