/// 게임 화면 상단 HUD: 제목·이동수·되돌리기·재시작·힌트.
library;

import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

class GameHud extends StatelessWidget {
  final String title;
  final int moves;
  final int optimal;
  final VoidCallback onUndo;
  final VoidCallback onRestart;
  final VoidCallback? onHint;
  const GameHud({
    required this.title,
    required this.moves,
    required this.optimal,
    required this.onUndo,
    required this.onRestart,
    this.onHint,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PiyakColors.outline, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: PiyakColors.outline)),
                Text(
                  '${S.moves} $moves${optimal > 0 ? ' / ${S.optimal} $optimal' : ''}',
                  style: const TextStyle(
                      fontSize: 13, color: PiyakColors.outline),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: S.undo,
            onPressed: onUndo,
            icon: const Icon(Icons.undo_rounded, color: PiyakColors.outline),
          ),
          IconButton(
            tooltip: S.restart,
            onPressed: onRestart,
            icon: const Icon(Icons.refresh_rounded, color: PiyakColors.outline),
          ),
          if (onHint != null)
            IconButton(
              tooltip: S.hint,
              onPressed: onHint,
              icon: const Icon(Icons.lightbulb_outline_rounded,
                  color: PiyakColors.outline),
            ),
        ],
      ),
    );
  }
}
