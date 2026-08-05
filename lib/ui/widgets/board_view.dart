/// 보드 렌더링: 바닥 CustomPaint + 알(AnimatedPositioned) + 병아리 이미지.
///
/// 알 애니메이션 연속성: 한 이동에 알은 최대 1개만 움직이므로,
/// 이전 프레임과 비교해 "사라진 위치→나타난 위치"를 같은 id로 매칭한다.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../../engine/geometry.dart';
import '../../engine/move.dart';
import '../../engine/tile.dart';
import '../../services/tile_art.dart';
import '../theme.dart';
import 'tile_painter.dart';

/// 한 칸 이동 시간. DPad 연속 간격(170ms)과 거의 맞물려야 꾹 눌러 이동할 때
/// 칸마다 멈칫하지 않는다.
const kMoveAnim = Duration(milliseconds: 160);

class BoardView extends StatefulWidget {
  final Board board;
  final double cellSize;

  /// 'idle' | 'think' | 'sleep' | 'cheer' | 'sad' | 'speak' ...
  final String chickMood;

  /// 힌트: 다음 이동들 — 실제 tryMove 시뮬레이션으로 병아리 경로에 화살표 표시.
  final List<Dir>? hintMoves;

  /// 막힌 입력 피드백: 토큰이 바뀌면 병아리가 그 방향으로 살짝 밀렸다 돌아온다.
  final Dir? bumpDir;
  final int bumpToken;

  /// 홀드 연속 이동 중 — 곡선을 등속으로 바꿔 칸 경계에서 멈칫하지 않게 한다.
  final bool gliding;

  /// 이번 이동이 굴 순간이동이었는가 (병아리/알 따로). true면 그 칸은
  /// 미끄러져 가지 않고 즉시 나타난다 — 굴은 순간이동이지 미끄럼이 아니다.
  final bool chickTeleported;
  final bool eggTeleported;
  const BoardView({
    required this.board,
    required this.cellSize,
    this.chickMood = 'idle',
    this.hintMoves,
    this.bumpDir,
    this.bumpToken = 0,
    this.gliding = false,
    this.chickTeleported = false,
    this.eggTeleported = false,
    super.key,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  late List<Point> _eggOrder; // index = 안정 id

  @override
  void initState() {
    super.initState();
    _eggOrder = widget.board.eggs.toList();
  }

  @override
  void didUpdateWidget(BoardView old) {
    super.didUpdateWidget(old);
    final now = widget.board.eggs;
    final removed = _eggOrder.where((p) => !now.contains(p)).toList();
    final added = now.where((p) => !_eggOrder.contains(p)).toList();
    if (removed.length == 1 && added.length == 1) {
      _eggOrder = _eggOrder
          .map((p) => p == removed.single ? added.single : p)
          .toList();
    } else if (removed.isNotEmpty || added.isNotEmpty) {
      _eggOrder = now.toList(); // 재시작·레벨 교체 등은 리셋
    }
  }

  @override
  Widget build(BuildContext context) {
    final cell = widget.cellSize;
    final b = widget.board;
    return SizedBox(
      width: b.width * cell,
      height: b.height * cell,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(b.width * cell, b.height * cell),
            painter: BoardPainter(b, cell, skip: {
              for (final t in b.tiles)
                if (TileArt.of(t) != null) t,
            }),
          ),
          for (var i = 0; i < b.tiles.length; i++)
            if (TileArt.of(b.tiles[i]) != null)
              Positioned(
                left: (i % b.width) * cell,
                top: (i ~/ b.width) * cell,
                width: cell,
                height: cell,
                child: Image(
                    image: TileArt.of(b.tiles[i])!, fit: BoxFit.contain),
              ),
          for (var i = 0; i < _eggOrder.length; i++)
            SmoothPositioned(
              key: ValueKey('egg$i'),
              duration: widget.eggTeleported ? Duration.zero : kMoveAnim,
              curve: widget.gliding ? Curves.linear : Curves.easeOut,
              left: _eggOrder[i].x * cell,
              top: _eggOrder[i].y * cell,
              width: cell,
              height: cell,
              child: EggSprite(
                pos: _eggOrder[i],
                size: cell,
                onNest: b.tileAt(_eggOrder[i]) == Tile.nest,
              ),
            ),
          SmoothPositioned(
            key: const ValueKey('chick'),
            duration: widget.chickTeleported ? Duration.zero : kMoveAnim,
            curve: widget.gliding ? Curves.linear : Curves.easeOut,
            left: b.chick.x * cell,
            top: b.chick.y * cell - cell * 0.12, // 살짝 위로 — 입체감
            width: cell,
            height: cell * 1.12,
            child: ChickSprite(
              pos: b.chick,
              cell: cell,
              mood: widget.chickMood,
              bumpDir: widget.bumpDir,
              bumpToken: widget.bumpToken,
            ),
          ),
          // 힌트는 "몇 번째로 어디에 서야 하는지"를 번호로 보여 준다.
          // 방향 화살표만 띄우면 어느 칸 얘기인지 헷갈린다.
          // 가까운 수가 위에 오도록 뒤에서부터 그린다.
          for (final (i, step) in _hintSteps.indexed.toList().reversed)
            Positioned(
              left: step.x * cell,
              top: step.y * cell,
              width: cell,
              height: cell,
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: (1.0 - i * 0.13).clamp(0.45, 1.0),
                    child: Container(
                      width: cell * 0.56,
                      height: cell * 0.56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: PiyakColors.starYellow,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: PiyakColors.outline, width: 2.5),
                      ),
                      child: FittedBox(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: PiyakColors.outline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 힌트 이동을 실제 엔진으로 시뮬레이션해, 병아리가 차례로 서게 될 칸을 낸다.
  List<Point> get _hintSteps {
    final moves = widget.hintMoves;
    if (moves == null) return const [];
    final steps = <Point>[];
    var b = widget.board;
    for (final d in moves) {
      final o = b.tryMove(d);
      if (o.blocked) break;
      b = o.board!;
      steps.add(b.chick);
    }
    return steps;
  }
}

/// [AnimatedPositioned]와 같은 일을 하되, **폰의 "애니메이션 끄기" 설정에
/// 끌려가지 않는다.**
///
/// 안드로이드의 애니메이터 배율을 끄거나(개발자 옵션) 절전 모드가 켜지면
/// OS가 앱에 "애니메이션을 꺼 달라"고 알린다. 그러면 Flutter는 기본값인
/// [AnimationBehavior.normal]에 따라 **모든 애니메이션을 5% 길이로 줄인다.**
/// 160ms짜리 걸음이 8ms — 한 프레임 — 이 되어 병아리가 칸에서 칸으로
/// 순간이동하듯 딱딱 끊긴다. 기기마다 이 설정이 달라, 같은 앱인데
/// 어떤 폰은 부드럽고 어떤 폰은 끊기는 일이 실제로 있었다.
///
/// 병아리가 걸어가는 모습은 장식이 아니라 "방금 무슨 일이 일어났는지"를
/// 보여 주는 게임의 핵심 피드백이다. 한 칸을 걸었는지 두 칸을 갔는지,
/// 알을 밀었는지가 그 움직임으로만 보인다. 그래서
/// [AnimationBehavior.preserve]로 OS 설정과 무관하게 지킨다.
/// 일부러 즉시 옮겨야 할 때(굴 순간이동)는 [duration]을 0으로 준다.
class SmoothPositioned extends StatefulWidget {
  final double left;
  final double top;
  final double width;
  final double height;
  final Duration duration;
  final Curve curve;
  final Widget child;
  const SmoothPositioned({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.duration,
    required this.curve,
    required this.child,
    super.key,
  });

  @override
  State<SmoothPositioned> createState() => _SmoothPositionedState();
}

class _SmoothPositionedState extends State<SmoothPositioned>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
    animationBehavior: AnimationBehavior.preserve,
  );

  late Offset _from = Offset(widget.left, widget.top);
  late Offset _to = _from;

  @override
  void initState() {
    super.initState();
    _c.value = 1.0; // 시작할 땐 이미 제자리에 있다
  }

  @override
  void didUpdateWidget(SmoothPositioned old) {
    super.didUpdateWidget(old);
    final target = Offset(widget.left, widget.top);
    if (target == _to) return;
    // 걷는 도중에 목적지가 바뀌면 지금 있는 자리에서 이어 간다 —
    // 시작점으로 되돌아가면 튀어 보인다.
    _from = _at(_c.value);
    _to = target;
    if (widget.duration <= Duration.zero) {
      _c.value = 1.0; // 순간이동
    } else {
      _c.duration = widget.duration;
      _c.forward(from: 0);
    }
  }

  Offset _at(double t) =>
      Offset.lerp(_from, _to, widget.curve.transform(t.clamp(0.0, 1.0)))!;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final p = _at(_c.value);
        return Positioned(
          left: p.dx,
          top: p.dy,
          width: widget.width,
          height: widget.height,
          child: child!,
        );
      },
    );
  }
}

/// 살아있는 병아리: 평소엔 숨쉬기 보브, 이동할 때마다 총총 뛰는 홉 +
/// 이동 방향으로 살짝 기울어진다.
class ChickSprite extends StatefulWidget {
  final Point pos;
  final double cell;
  final String mood;

  /// 벽·알에 막혔을 때 밀리는 방향. [bumpToken]이 바뀔 때만 반응한다.
  final Dir? bumpDir;
  final int bumpToken;
  const ChickSprite({
    required this.pos,
    required this.cell,
    required this.mood,
    this.bumpDir,
    this.bumpToken = 0,
    super.key,
  });

  @override
  State<ChickSprite> createState() => _ChickSpriteState();
}

class _ChickSpriteState extends State<ChickSprite>
    with TickerProviderStateMixin {
  // 넷 다 preserve — 폰의 "애니메이션 끄기"를 켜 두면 기본값(normal)은
  // 길이를 5%로 줄여서, 총총 뛰는 홉도 착지도 한 프레임 만에 끝나 버린다.
  // 병아리가 걷는 동작 자체가 사라지는 셈이라 [SmoothPositioned]와 같이 지킨다.
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    animationBehavior: AnimationBehavior.preserve,
  )..repeat(reverse: true);
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    animationBehavior: AnimationBehavior.preserve,
  );
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    animationBehavior: AnimationBehavior.preserve,
  );
  late final AnimationController _land = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    animationBehavior: AnimationBehavior.preserve,
  );
  int _tiltSign = 0;
  int _stepParity = 1;
  Dir? _lastBumpDir;

  @override
  void initState() {
    super.initState();
    _hop.addStatusListener((s) {
      if (s == AnimationStatus.completed) _land.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(ChickSprite old) {
    super.didUpdateWidget(old);
    if (old.pos != widget.pos) {
      // 좌우 이동은 진행 방향으로, 상하 이동은 걸음마다 교차로 기울여 뒤뚱거린다.
      final dx = widget.pos.x - old.pos.x;
      _stepParity = -_stepParity;
      _tiltSign = dx != 0 ? (dx > 0 ? 1 : -1) : _stepParity;
      _hop.forward(from: 0);
    }
    if (widget.bumpToken != old.bumpToken && widget.bumpDir != null) {
      _lastBumpDir = widget.bumpDir;
      _bump.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _hop.dispose();
    _bump.dispose();
    _land.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _hop, _bump, _land]),
      builder: (context, child) {
        final hopT = _hop.value;
        final arc = math.sin(math.pi * hopT);
        final hopY = -arc * widget.cell * 0.22;
        final tilt = _tiltSign * 0.12 * arc;
        // 숨쉬기: 세로로 살짝 늘었다 줄었다
        final breathe = 1.0 + 0.03 * _bob.value;
        // 착지: 홉이 끝나는 순간 살짝 눌린다
        final landT = math.sin(math.pi * _land.value);
        final squashY = 1.0 - 0.08 * landT;
        // 막힘: 그 방향으로 밀렸다 제자리로
        final push = widget.cell * 0.12 * math.sin(math.pi * _bump.value);
        final bump = switch (_lastBumpDir) {
          Dir.up => Offset(0, -push),
          Dir.down => Offset(0, push),
          Dir.left => Offset(-push, 0),
          Dir.right => Offset(push, 0),
          null => Offset.zero,
        };
        return Transform.translate(
          offset: Offset(bump.dx, hopY + bump.dy),
          child: Transform.rotate(
            angle: tilt,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(
                  (2.0 - breathe) / squashY, breathe * squashY, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        'assets/images/chick/chick_${widget.mood}.png',
        gaplessPlayback: true,
        fit: BoxFit.contain,
      ),
    );
  }
}
