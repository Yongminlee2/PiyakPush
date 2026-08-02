/// 병아리 말풍선 — 튜토리얼·데드락 안내용.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class SpeechBubble extends StatelessWidget {
  final String text;
  const SpeechBubble({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PiyakColors.outline, width: 2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: PiyakColors.outline,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
