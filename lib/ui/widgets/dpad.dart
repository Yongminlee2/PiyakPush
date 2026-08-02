/// 십자 방향키 — 설정에서 조이스틱 대신 선택할 수 있는 조작 방식.
///
/// 자체 반복 타이머는 없다. 누르는 동안 onDirDown, 떼면 onRelease를 불러
/// 게임 화면의 연속 이동(홀드 등속)이 조이스틱과 동일하게 걸린다.
library;

import 'package:flutter/material.dart';

import '../../engine/geometry.dart';
import '../theme.dart';

const double _kBtn = 72;
const double _kIcon = 44;

class DPad extends StatelessWidget {
  final void Function(Dir) onDirDown;
  final VoidCallback onRelease;
  const DPad({required this.onDirDown, required this.onRelease, super.key});

  Widget _btn(IconData icon, Dir d) =>
      _DPadButton(icon: icon, onDown: () => onDirDown(d), onUp: onRelease);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.keyboard_arrow_up_rounded, Dir.up),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn(Icons.keyboard_arrow_left_rounded, Dir.left),
            const SizedBox(width: _kBtn),
            _btn(Icons.keyboard_arrow_right_rounded, Dir.right),
          ],
        ),
        _btn(Icons.keyboard_arrow_down_rounded, Dir.down),
      ],
    );
  }
}

class _DPadButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onDown;
  final VoidCallback onUp;
  const _DPadButton(
      {required this.icon, required this.onDown, required this.onUp});

  @override
  State<_DPadButton> createState() => _DPadButtonState();
}

class _DPadButtonState extends State<_DPadButton> {
  bool _pressed = false;

  void _down(PointerDownEvent _) {
    setState(() => _pressed = true);
    widget.onDown();
  }

  void _up() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onUp();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: _kBtn,
          height: _kBtn,
          decoration: BoxDecoration(
            color: _pressed
                ? PiyakColors.chickYellow
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PiyakColors.outline, width: 2.5),
            boxShadow: _pressed
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x335D4037),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Icon(widget.icon, size: _kIcon, color: PiyakColors.outline),
        ),
      ),
    );
  }
}
