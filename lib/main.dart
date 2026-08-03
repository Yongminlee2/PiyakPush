import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/save_service.dart';
import 'services/sound_service.dart';
import 'services/tile_art.dart';
import 'ui/screens/title_screen.dart';
import 'ui/strings.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 그림·소리 준비는 실패해도 게임은 돌아가야 한다. 여기서 예외가 나면
  // runApp까지 못 가서 검은 화면만 남는데, 오디오 초기화는 기기·제조사마다
  // 동작이 달라 실제로 터질 수 있는 자리다. 없으면 없는 대로 시작한다
  // (타일은 코드 렌더링으로, 소리는 무음으로 물러난다).
  await _tryInit(TileArt.load);

  final save = await SaveService.load();
  final sound = SoundService(isMuted: () => !save.soundOn);
  await _tryInit(sound.init); // 효과음 선로드 — 첫 입력부터 지연 없이

  runApp(PiyakPushApp(save: save, sound: sound));
}

Future<void> _tryInit(Future<void> Function() step) async {
  try {
    await step();
  } catch (e, st) {
    debugPrint('시작 준비 중 하나가 실패했지만 계속 진행한다: $e\n$st');
  }
}

class PiyakPushApp extends StatelessWidget {
  final SaveService save;
  final SoundService sound;
  const PiyakPushApp({required this.save, required this.sound, super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: save),
          Provider.value(value: sound),
        ],
        // 언어 설정이 바뀌면 save가 알려 주고, 여기서 다시 적용한 뒤
        // 아래 화면 전체가 새 언어로 다시 그려진다.
        child: Consumer<SaveService>(builder: (context, s, _) {
          S.use(s.langCode);
          return _app();
        }),
      );

  Widget _app() => MaterialApp(
        title: S.appTitle,
        theme: piyakTheme(lang: S.code),
        debugShowCheckedModeBanner: false,
        home: const TitleScreen(),
      );
}
