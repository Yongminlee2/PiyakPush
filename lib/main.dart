import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';

import 'services/ad_service.dart';
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

  // 광고는 없으면 없는 대로 — 초기화가 실패해도 게임은 그대로 시작한다.
  final ads = AdService();
  await _tryInit(ads.init);

  runApp(PiyakPushApp(save: save, sound: sound, ads: ads));
  // 첫 화면이 뜬 뒤에 묻는다 — Play의 업데이트 화면은 앱 화면 위에 뜬다.
  WidgetsBinding.instance.addPostFrameCallback((_) => _offerUpdate());
}

/// 스토어에 새 버전이 있으면 Play의 업데이트 화면을 띄운다.
///
/// 사용자가 "업데이트"를 누르면 Play가 받아서 설치하고 앱을 다시 켠다.
/// 닫으면 그냥 지금 버전으로 계속한다 — 억지로 막지 않는다.
/// Play 스토어에서 설치한 릴리스에서만 동작한다. 디버그나 직접 깐 APK,
/// 인터넷이 없을 때는 조용히 넘어간다.
Future<void> _offerUpdate() async {
  if (!kReleaseMode || !Platform.isAndroid) return;
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability == UpdateAvailability.updateAvailable &&
        info.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate();
    }
  } catch (_) {
    // 업데이트 확인이 실패해도 게임은 그대로 한다.
  }
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
  final AdService ads;
  const PiyakPushApp({
    required this.save,
    required this.sound,
    required this.ads,
    super.key,
  });

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: save),
          Provider.value(value: sound),
          Provider.value(value: ads),
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
