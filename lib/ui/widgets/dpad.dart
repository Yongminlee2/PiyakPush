/// D-패드 — 기본 조작 수단 (스와이프도 계속 동작).
///
/// 꾹 누르면 연속 이동: 320ms 후부터 160ms 간격 반복.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../engine/geometry.dart';
import '../theme.dart';

class DPad extends StatelessWidget {
  final void Function(Dir) onDir;
  const DPad({required this.onDir, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DPadButton(
            icon: Icons.keyboard_arrow_up_rounded,
            onFire: () => onDir(Dir.up)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DPadButton(
                icon: Icons.keyboard_arrow_left_rounded,
                onFire: () => onDir(Dir.left)),
            const SizedBox(width: 60),
            _DPadButton(
                icon: Icons.keyboard_arrow_right_rounded,
                onFire: () => onDir(Dir.right)),
          ],
        ),
        _DPadButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onFire: () => onDir(Dir.down)),
      ],
    );
  }
}

class _DPadButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onFire;
  const _DPadButton({required this.icon, required this.onFire});

  @override
  State<_DPadButton> createState() => _DPadButtonState();
}

class _DPadButtonState extends State<_DPadButton> {
  Timer? _delay, _repeat;
  bool _pressed = false;

  void _down(PointerDownEvent _) {
    setState(() => _pressed = true);
    widget.onFire();
    _delay = Timer(const Duration(milliseconds: 320), () {
      _repeat = Timer.periodic(
          const Duration(milliseconds: 160), (_) => widget.onFire());
    });
  }

  void _up() {
    setState(() => _pressed = false);
    _delay?.cancel();
    _repeat?.cancel();
  }

  @override
  void dispose() {
    _delay?.cancel();
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _pressed
              ? PiyakColors.chickYellow
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PiyakColors.outline, width: 2.5),
          boxShadow: _pressed
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x335D4037),
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Icon(widget.icon, size: 40, color: PiyakColors.outline),
      ),
    );
  }
}
