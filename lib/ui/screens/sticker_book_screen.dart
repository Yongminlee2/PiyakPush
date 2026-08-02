/// 스티커북: 4열 그리드 — 해금은 원본, 미해금은 검정 실루엣 + 필요 별 수.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sticker.dart';
import '../../services/save_service.dart';
import '../strings.dart';
import '../theme.dart';

class StickerBookScreen extends StatelessWidget {
  const StickerBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = context.watch<SaveService>().totalStars;
    return Scaffold(
      appBar: AppBar(
        title: Text('${S.stickerBook}  (${unlockedStickers(total).length}/${kStickers.length})',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: PiyakColors.outline)),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: kStickers.length,
        itemBuilder: (context, i) {
          final st = kStickers[i];
          final unlocked = total >= st.threshold;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PiyakColors.outline, width: 2),
            ),
            padding: const EdgeInsets.all(6),
            child: unlocked
                ? Tooltip(
                    message: st.name, child: Image.asset(st.asset))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                              Color(0xFFBDB4A5), BlendMode.srcIn),
                          child: Image.asset(st.asset),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 12, color: PiyakColors.starYellow),
                          Text('${st.threshold}',
                              style: const TextStyle(
                                  fontSize: 11, color: PiyakColors.outline)),
                        ],
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
