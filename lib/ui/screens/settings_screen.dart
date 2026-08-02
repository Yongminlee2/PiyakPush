/// 설정: 소리·D-패드 토글, 진행 초기화.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/save_service.dart';
import '../strings.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final save = context.watch<SaveService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.settings,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: PiyakColors.outline)),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text(S.soundOn,
                style: TextStyle(color: PiyakColors.outline)),
            value: save.soundOn,
            onChanged: (v) => save.setSoundOn(v),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            label: const Text(S.resetAll,
                style: TextStyle(color: Colors.red)),
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: const Text(S.resetConfirm),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: const Text(S.cancel)),
                    TextButton(
                        onPressed: () => Navigator.pop(dctx, true),
                        child: const Text(S.ok)),
                  ],
                ),
              );
              if (yes == true && context.mounted) {
                await context.read<SaveService>().resetAll();
              }
            },
          ),
        ],
      ),
    );
  }
}
