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

  /// 남은 힌트 개수 — 버튼 위에 배지로 띄운다. null이면 배지를 숨긴다.
  final int? hintsLeft;
  const GameHud({
    required this.title,
    required this.moves,
    required this.optimal,
    required this.onUndo,
    required this.onRestart,
    this.onHint,
    this.hintsLeft,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: hintsLeft == null ? S.hint : '${S.hint} ($hintsLeft)',
                  onPressed: onHint,
                  icon: Icon(Icons.lightbulb_outline_rounded,
                      color: (hintsLeft ?? 1) > 0
                          ? PiyakColors.outline
                          : PiyakColors.outline.withValues(alpha: 0.35)),
                ),
                // 몇 개 남았는지 보여야 아껴 쓸지 판단할 수 있다.
                if (hintsLeft != null)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: hintsLeft! > 0
                            ? PiyakColors.starYellow
                            : PiyakColors.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(9),
                        border:
                            Border.all(color: PiyakColors.outline, width: 1.5),
                      ),
                      child: Text('$hintsLeft',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: PiyakColors.outline)),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
