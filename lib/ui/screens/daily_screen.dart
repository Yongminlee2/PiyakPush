/// 데일리 퍼즐 — T19에서 생성기·달력으로 완성한다.
library;

import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.dailyTitle,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: PiyakColors.outline)),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: const Center(
        child: Text('오늘의 퍼즐이 곧 준비돼요!',
            style: TextStyle(color: PiyakColors.outline)),
      ),
    );
  }
}
