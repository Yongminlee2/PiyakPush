/// 플로팅 가상 조이스틱 — 하단 밴드 아무 데나 눌러 그 자리에서 조작한다.
///
/// 드래그가 데드존(18px)을 넘으면 상하좌우 중 가까운 방향으로 스냅해
/// onDir을 부르고, 데드존으로 돌아오거나 손을 떼면 onRelease를 부른다.
library;

import 'package:flutter/material.dart';

import '../../engine/geometry.dart';
import '../strings.dart';
import '../theme.dart';

const _kDead = 18.0;
const _kKnobMax = 56.0;

class Joystick extends StatefulWidget {
  final void Function(Dir) onDir;
  final VoidCallback onRelease;
  const Joystick({required this.onDir, required this.onRelease, super.key});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset? _base;
  Offset _knob = Offset.zero;

  void _update(Offset local) {
    if (_base == null) return;
    var d = local - _base!;
    if (d.distance > _kKnobMax) d = d / d.distance * _kKnobMax;
    setState(() => _knob = d);
    if (d.distance < _kDead) {
      widget.onRelease();
      return;
    }
    widget.onDir(d.dx.abs() > d.dy.abs()
        ? (d.dx > 0 ? Dir.right : Dir.left)
        : (d.dy > 0 ? Dir.down : Dir.up));
  }

  void _end() {
    widget.onRelease();
    setState(() {
      _base = null;
      _knob = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (e) => setState(() {
        _base = e.localPosition;
        _knob = Offset.zero;
      }),
      onPanUpdate: (e) => _update(e.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: SizedBox.expand(
        child: _base == null
            ? Align(
                // 이제 화면 전체가 조작 영역이라, 안내는 하단에만 살짝 둔다
                alignment: const Alignment(0, 0.92),
                child: Text(
                  S.joystickHint,
                  style: TextStyle(
                    fontSize: 13,
                    color: PiyakColors.outline.withValues(alpha: 0.35),
                  ),
                ),
              )
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: _base!.dx - 52,
                    top: _base!.dy - 52,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.45),
                        border: Border.all(
                            color: PiyakColors.outline.withValues(alpha: 0.5),
                            width: 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _base!.dx + _knob.dx - 30,
                    top: _base!.dy + _knob.dy - 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PiyakColors.chickYellow,
                        border:
                            Border.all(color: PiyakColors.outline, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
