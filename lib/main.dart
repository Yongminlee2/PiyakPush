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
  await TileArt.load();
  final save = await SaveService.load();
  final sound = SoundService(isMuted: () => !save.soundOn);
  await sound.init(); // 효과음 선로드 — 첫 입력부터 지연 없이
  runApp(PiyakPushApp(save: save, sound: sound));
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
