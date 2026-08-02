/// 스티커북 — T18에서 해금 로직·실루엣 그리드로 완성한다.
library;

import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

class StickerBookScreen extends StatelessWidget {
  const StickerBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.stickerBook,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: PiyakColors.outline)),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: const Center(
        child: Text('별을 모아 스티커를 열어보세요!',
            style: TextStyle(color: PiyakColors.outline)),
      ),
    );
  }
}
