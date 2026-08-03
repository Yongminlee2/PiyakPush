/// UI 문자열. 실제 값은 [kStrings]에 언어별로 들어 있고, 여기서는 현재
/// 언어의 값을 꺼내 준다.
///
/// 전부 getter라 언어를 바꾸면 다음 빌드부터 바로 반영된다. 대신 `const Text(S.x)`
/// 처럼 상수 자리에는 쓸 수 없다 — 호출부에서 `const`를 떼야 한다.
library;

import 'dart:ui' show PlatformDispatcher;

import 'strings_data.dart';

abstract final class S {
  static String _code = 'ko';

  /// 지금 쓰는 언어 코드.
  static String get code => _code;

  /// 저장된 설정값(`null`이거나 모르는 코드면 기기 언어)을 적용한다.
  static void use(String? code) {
    if (code != null && kStrings.containsKey(code)) {
      _code = code;
      return;
    }
    _code = _deviceCode();
  }

  /// 기기 언어 중 우리가 가진 것 하나. 없으면 영어.
  static String _deviceCode() {
    for (final l in PlatformDispatcher.instance.locales) {
      if (kStrings.containsKey(l.languageCode)) return l.languageCode;
    }
    return 'en';
  }

  /// 빠진 키는 영어로 메운다 — 번역이 덜 돼도 화면이 비지 않게.
  static String _(String k) =>
      kStrings[_code]?[k] ?? kStrings['en']![k] ?? k;

  static String get appTitle => _('appTitle');
  static String get start => _('start');
  static String get daily => _('daily');
  static String get stickerBook => _('stickerBook');
  static String get decoBoard => _('decoBoard');
  static String get settings => _('settings');

  static String get chapterTitle => _('chapterTitle');
  static List<String> get chapterNames =>
      [for (var i = 1; i <= 20; i++) _('ch$i')];
  static List<String> get actNames => [for (var i = 1; i <= 4; i++) _('act$i')];
  static String get lockedChapter => _('lockedChapter');
  static String needMoreClears(int n) =>
      _('needMoreClears').replaceAll('{n}', '$n');

  /// 스테이지 이름. 한국어는 레벨 파일에 손으로 붙인 이름을 그대로 쓰고,
  /// 다른 언어에서는 챕터명과 번호로 만든다 — 300개를 다 번역할 순 없다.
  static String stageTitle(int chapter, int index, String rawTitle) {
    if (_code == 'ko') return rawTitle;
    if (index > 10) return '${_('challenge')} ${index - 10}';
    return '${_('ch$chapter')} $index';
  }

  static String get moves => _('moves');
  static String get optimal => _('optimal');
  static String get undo => _('undo');
  static String get restart => _('restart');
  static String get hint => _('hint');
  static String get next => _('next');
  static String get list => _('list');
  static String get clear => _('clear');
  static String get nextChapter => _('nextChapter');
  static String get chapterCleared => _('chapterCleared');
  static String get allCleared => _('allCleared');
  static String get toTitle => _('toTitle');

  static String get tutorial1 => _('tutorial1');
  static String get tutorial1Dpad => _('tutorial1Dpad');
  static String get tutorial2 => _('tutorial2');
  static String get tutorial3 => _('tutorial3');
  static String get deadlockHint => _('deadlockHint');
  static String get noHint => _('noHint');

  static String get soundOn => _('soundOn');
  static String get joystickHint => _('joystickHint');
  static String get controlScheme => _('controlScheme');
  static String get unlockAll => _('unlockAll');
  static String get ctlJoystick => _('ctlJoystick');
  static String get ctlDpad => _('ctlDpad');
  static String get resetAll => _('resetAll');
  static String get resetConfirm => _('resetConfirm');
  static String get cancel => _('cancel');
  static String get ok => _('ok');
  static String get language => _('language');
  static String get languageSystem => _('languageSystem');

  static String get dailyTitle => _('dailyTitle');
  static String get dailyPlay => _('dailyPlay');
  static String get dailyDone => _('dailyDone');
  static String get dailyChallenge => _('dailyChallenge');
  static String get streak => _('streak');
  static String get day => _('day');

  static String get stickerLocked => _('stickerLocked');
  static String get stickerCount => _('stickerCount');

  static String get hintsLeft => _('hintsLeft');
  static String get hintEmpty => _('hintEmpty');
  static String get hintHowTo => _('hintHowTo');
  static String hintGot(int n) => _('hintGot').replaceAll('{n}', '$n');
}
