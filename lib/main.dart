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
        child: MaterialApp(
          title: S.appTitle,
          theme: piyakTheme(),
          debugShowCheckedModeBanner: false,
          home: const TitleScreen(),
        ),
      );
}
