/// 선택형 D-패드 (설정에서 켜면 표시). 스와이프가 기본 조작.
library;

import 'package:flutter/material.dart';

import '../../engine/geometry.dart';
import '../theme.dart';

class DPad extends StatelessWidget {
  final void Function(Dir) onDir;
  const DPad({required this.onDir, super.key});

  Widget _btn(IconData icon, Dir d) => IconButton(
        onPressed: () => onDir(d),
        icon: Icon(icon, size: 30, color: PiyakColors.outline),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.75),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: PiyakColors.outline, width: 2),
          ),
        ),
      );

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
            const SizedBox(width: 44),
            _btn(Icons.keyboard_arrow_right_rounded, Dir.right),
          ],
        ),
        _btn(Icons.keyboard_arrow_down_rounded, Dir.down),
      ],
    );
  }
}
