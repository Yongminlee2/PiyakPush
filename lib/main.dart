import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/save_service.dart';
import 'services/sound_service.dart';
import 'ui/screens/title_screen.dart';
import 'ui/strings.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final save = await SaveService.load();
  runApp(PiyakPushApp(save: save));
}

class PiyakPushApp extends StatelessWidget {
  final SaveService save;
  const PiyakPushApp({required this.save, super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: save),
          Provider(
              create: (_) => SoundService(isMuted: () => !save.soundOn)),
        ],
        child: MaterialApp(
          title: S.appTitle,
          theme: piyakTheme(),
          debugShowCheckedModeBanner: false,
          home: const TitleScreen(),
        ),
      );
}
