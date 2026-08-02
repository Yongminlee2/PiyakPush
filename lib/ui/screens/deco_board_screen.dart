/// 꾸미기 보드 — T18에서 드래그 배치·저장으로 완성한다.
library;

import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

class DecoBoardScreen extends StatelessWidget {
  const DecoBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.decoBoard,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: PiyakColors.outline)),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: const Center(
        child: Text('스티커를 모아 보드를 꾸며보세요!',
            style: TextStyle(color: PiyakColors.outline)),
      ),
    );
  }
}
