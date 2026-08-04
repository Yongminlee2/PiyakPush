/// 설정: 언어, 소리·조작 방식, 진행 초기화.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/save_service.dart';
import '../strings.dart';
import '../strings_data.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final save = context.watch<SaveService>();
    const label = TextStyle(color: PiyakColors.outline);
    const heading = TextStyle(
        fontWeight: FontWeight.bold, color: PiyakColors.outline);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.settings, style: heading),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.language_rounded,
                color: PiyakColors.outline),
            title: Text(S.language, style: heading),
            subtitle: Text(
              save.langCode == null
                  ? S.languageSystem
                  : kLangNames[save.langCode] ?? save.langCode!,
              style: label,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickLanguage(context, save),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(S.soundOn, style: label),
            value: save.soundOn,
            onChanged: save.setSoundOn,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(S.controlScheme, style: heading),
          ),
          RadioGroup<bool>(
            groupValue: save.dpadOn,
            onChanged: (v) => save.setDpadOn(v ?? false),
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: Text(S.ctlJoystick, style: label),
                  value: false,
                ),
                RadioListTile<bool>(
                  title: Text(S.ctlDpad, style: label),
                  value: true,
                ),
              ],
            ),
          ),
          // 모든 챕터를 여는 스위치는 확인용이다. 배포판에 그냥 두면 누구나
          // 진행을 건너뛰므로, 개발자 모드를 켠 사람에게만 보인다
          // (타이틀 제목 일곱 번 두드리기).
          if (kDebugMode || save.devMode)
            SwitchListTile(
              title: Text(S.unlockAll, style: label),
              value: save.unlockAll,
              onChanged: save.setUnlockAll,
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            label: Text(S.resetAll, style: const TextStyle(color: Colors.red)),
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: Text(S.resetConfirm),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: Text(S.cancel)),
                    TextButton(
                        onPressed: () => Navigator.pop(dctx, true),
                        child: Text(S.ok)),
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

  /// 기기 언어 따르기 + 12개 수동 선택.
  Future<void> _pickLanguage(BuildContext context, SaveService save) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: PiyakColors.creamBg,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(S.languageSystem),
              trailing: save.langCode == null
                  ? const Icon(Icons.check_rounded,
                      color: PiyakColors.outline)
                  : null,
              // 기기 언어 따르기는 '값 없음'이라 취소와 구분하려고 빈 문자열로
              // 돌려보내고, 받는 쪽에서 null로 되돌린다.
              onTap: () => Navigator.pop(sheetCtx, ''),
            ),
            const Divider(),
            for (final code in kLangCodes)
              ListTile(
                title: Text(kLangNames[code]!),
                trailing: save.langCode == code
                    ? const Icon(Icons.check_rounded,
                        color: PiyakColors.outline)
                    : null,
                onTap: () => Navigator.pop(sheetCtx, code),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return; // 그냥 닫음
    await save.setLangCode(picked.isEmpty ? null : picked);
  }
}
