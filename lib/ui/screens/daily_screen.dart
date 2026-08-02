/// 데일리: 오늘의 퍼즐 도전 + 이번 달 달력 도장 + 연속 출석.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/level.dart';
import '../../services/daily_service.dart';
import '../../services/hint_service.dart';
import '../../services/save_service.dart';
import '../../services/sound_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'game_screen.dart';

class DailyScreen extends StatelessWidget {
  /// 테스트 주입용 — null이면 오늘.
  final DateTime? todayOverride;
  const DailyScreen({this.todayOverride, super.key});

  DateTime get _today {
    final now = todayOverride ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _play(BuildContext context) async {
    final save = context.read<SaveService>();
    final sound = context.read<SoundService>();
    final today = _today;
    final Level level = await DailyService.levelFor(today);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          level: level,
          showDpad: save.dpadOn,
          hintProvider: (c) => hintFor(c.board),
          onEvents: sound.playForEvents,
          onCleared: (_) => save.setDailyCleared(today),
          onNext: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final save = context.watch<SaveService>();
    final today = _today;
    final cleared = save.dailyCleared(today);
    final streak = save.dailyStreak(today);
    final first = DateTime(today.year, today.month, 1);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final leadingBlanks = first.weekday % 7; // 일요일 시작

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.dailyTitle,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: PiyakColors.outline)),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: PiyakColors.outline, width: 2.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset(
                    cleared
                        ? 'assets/images/chick/chick_cheer.png'
                        : 'assets/images/chick/chick_think.png',
                    height: 100,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${today.month}월 ${today.day}일',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: PiyakColors.outline),
                  ),
                  Text('${S.streak} $streak${S.day}',
                      style: const TextStyle(
                          fontSize: 14, color: PiyakColors.outline)),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: cleared
                          ? Colors.white
                          : PiyakColors.chickYellow,
                      foregroundColor: PiyakColors.outline,
                      minimumSize: const Size(180, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                            color: PiyakColors.outline, width: 2),
                      ),
                    ),
                    onPressed: () => _play(context),
                    child: Text(cleared ? S.dailyDone : S.dailyPlay,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final w in ['일', '월', '화', '수', '목', '금', '토'])
                Center(
                    child: Text(w,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: PiyakColors.outline))),
              for (var i = 0; i < leadingBlanks; i++) const SizedBox(),
              for (var d = 1; d <= daysInMonth; d++)
                _DayCell(
                  day: d,
                  isToday: d == today.day,
                  stamped: save
                      .dailyCleared(DateTime(today.year, today.month, d)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool stamped;
  const _DayCell(
      {required this.day, required this.isToday, required this.stamped});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: stamped ? PiyakColors.chickYellow : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PiyakColors.outline,
          width: isToday ? 2.5 : 1,
        ),
      ),
      child: Center(
        child: stamped
            ? Image.asset('assets/images/sticker/sticker_01.png', width: 22)
            : Text('$day',
                style: const TextStyle(
                    fontSize: 12, color: PiyakColors.outline)),
      ),
    );
  }
}
