/// 클리어 오버레이 — 별 1~3개 순차 등장 + 다음/다시/목록.
library;

import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

class ClearPopup extends StatefulWidget {
  final int stars;
  final int moves;
  final int optimal;
  final VoidCallback? onNext;
  final VoidCallback onRetry;
  final VoidCallback? onList;
  const ClearPopup({
    required this.stars,
    required this.moves,
    required this.optimal,
    this.onNext,
    required this.onRetry,
    this.onList,
    super.key,
  });

  @override
  State<ClearPopup> createState() => _ClearPopupState();
}

class _ClearPopupState extends State<ClearPopup>
    with TickerProviderStateMixin {
  late final List<AnimationController> _starCtrls;

  @override
  void initState() {
    super.initState();
    _starCtrls = List.generate(
      3,
      (i) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 350)),
    );
    for (var i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 250 + i * 280), () {
        if (mounted) _starCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _starCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PiyakColors.creamBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: PiyakColors.outline, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(S.clear,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: PiyakColors.outline)),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return ScaleTransition(
                    scale: CurvedAnimation(
                        parent: _starCtrls[i], curve: Curves.elasticOut),
                    child: Icon(
                      Icons.star_rounded,
                      size: 52,
                      color: i < widget.stars
                          ? PiyakColors.starYellow
                          : PiyakColors.outline.withValues(alpha: 0.2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text('${S.moves} ${widget.moves} / ${S.optimal} ${widget.optimal}',
                  style: const TextStyle(
                      fontSize: 14, color: PiyakColors.outline)),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onList != null)
                    TextButton(
                        onPressed: widget.onList, child: const Text(S.list)),
                  TextButton(
                      onPressed: widget.onRetry, child: const Text(S.restart)),
                  if (widget.onNext != null)
                    FilledButton(
                        onPressed: widget.onNext, child: const Text(S.next)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
