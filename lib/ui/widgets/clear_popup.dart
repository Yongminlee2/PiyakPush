/// 클리어 오버레이 — 별 1~3개 순차 등장 + 다음/다시/목록.
library;

import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import 'confetti.dart';

class ClearPopup extends StatefulWidget {
  final int stars;
  final int moves;
  final int optimal;
  final VoidCallback? onNext;

  /// 다음 버튼 라벨 — 챕터 마지막에선 '다음 챕터'/'처음으로'가 된다.
  /// null이면 기본값('다음'). 언어가 바뀔 수 있어 상수 기본값을 못 쓴다.
  final String? nextLabel;

  /// 챕터 클리어 축하나 별 부족 안내 같은 한 줄 문구.
  final String? note;
  final VoidCallback onRetry;
  final VoidCallback? onList;
  const ClearPopup({
    required this.stars,
    required this.moves,
    required this.optimal,
    this.onNext,
    this.nextLabel,
    this.note,
    required this.onRetry,
    this.onList,
    super.key,
  });

  @override
  State<ClearPopup> createState() => _ClearPopupState();
}

class _ClearPopupState extends State<ClearPopup>
    with SingleTickerProviderStateMixin {
  // 별마다 컨트롤러를 두고 Future.delayed로 시작하던 구조는 리빌드에 취약해
  // 실기기에서 별이 하나도 안 보이는 일이 있었다. 컨트롤러 하나를 즉시
  // 돌리고 Interval로 순서를 나눈다.
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// i번째 별이 튀어나오는 구간.
  Animation<double> _starAnim(int i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0.10 + i * 0.16, 0.10 + i * 0.16 + 0.34,
            curve: Curves.elasticOut),
      );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: Stack(
        children: [
          Positioned.fill(child: ConfettiOverlay(progress: _ctrl)),
          Center(
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.30, curve: Curves.elasticOut),
          ),
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
              Text(S.clear,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: PiyakColors.outline)),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final earned = i < widget.stars;
                  final star = Icon(
                    Icons.star_rounded,
                    size: 56,
                    color: earned
                        ? PiyakColors.starYellow
                        : PiyakColors.outline.withValues(alpha: 0.18),
                  );
                  // 미획득 별은 연출로 감싸지 않는다 — 늘 자리에 보여야 한다.
                  if (!earned) return star;
                  return ScaleTransition(scale: _starAnim(i), child: star);
                }),
              ),
              const SizedBox(height: 8),
              Text('${S.moves} ${widget.moves} / ${S.optimal} ${widget.optimal}',
                  style: const TextStyle(
                      fontSize: 14, color: PiyakColors.outline)),
              if (widget.note != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.note!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PiyakColors.outline),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onList != null)
                    TextButton(
                        onPressed: widget.onList, child: Text(S.list)),
                  TextButton(
                      onPressed: widget.onRetry, child: Text(S.restart)),
                  if (widget.onNext != null)
                    FilledButton(
                        onPressed: widget.onNext,
                        child: Text(widget.nextLabel ?? S.next)),
                ],
              ),
            ],
          ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
