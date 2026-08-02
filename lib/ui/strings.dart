/// 한국어 UI 문자열 전부. 추후 다국어 대비 단일 파일.
library;

abstract final class S {
  static const appTitle = '삐약푸시';
  static const start = '시작';
  static const daily = '데일리';
  static const stickerBook = '스티커북';
  static const decoBoard = '꾸미기';
  static const settings = '설정';

  static const chapterTitle = '챕터';
  static const chapterNames = [
    '풀밭', '얼음길', '비밀 굴', '단추와 문', '금 간 바닥', //
    '얼음 굴', '미끄럼 자물쇠', '부서지는 얼음', '굴과 자물쇠', '무너지는 통로', //
    '넓은 들판', '알 넷의 방', '얼어붙은 광장', '굴 미로', '잠긴 정원', //
    '뒤엉킨 길', '삐약의 시험', '다섯 알의 탑', '마지막 관문', '삐약 마스터', //
  ];

  /// 5챕터씩 묶은 막 이름 — 20개 목록이 평평해 보이지 않게 한다.
  static const actNames = ['1막 · 배우기', '2막 · 뒤섞기', '3막 · 넓어지기', '4막 · 시험'];
  static const lockedChapter = '이전 챕터에서 별 12개를 모으면 열려요';

  static const moves = '이동';
  static const optimal = '최적';
  static const undo = '되돌리기';
  static const restart = '다시';
  static const hint = '힌트';
  static const next = '다음';
  static const list = '목록';
  static const clear = '클리어!';
  static const nextChapter = '다음 챕터';
  static const chapterCleared = '챕터 클리어!';
  static const allCleared = '모든 챕터 클리어! 대단해요!';
  static const toTitle = '처음으로';

  static String needMoreClears(int n) => '이 챕터에서 $n개만 더 깨면 다음 챕터가 열려요';

  static const tutorial1 = '아래쪽을 누른 채 기울여서 삐약이를 움직여요!';
  static const tutorial1Dpad = '방향 버튼을 눌러서 삐약이를 움직여요!';
  static const tutorial2 = '알을 밀어서 둥지에 쏙! 넣어주세요';
  static const tutorial3 = '실수했다면 되돌리기를 눌러요';
  static const deadlockHint = '알이 구석에 끼었어요… 되돌리기를 눌러볼까?';
  static const noHint = '지금은 길이 없어요… 되돌리기!';

  static const soundOn = '소리';
  static const joystickHint = '아무 데나 누르고 기울여 보세요';
  static const controlScheme = '조작 방식';
  static const ctlJoystick = '조이스틱 — 아무 데나 눌러서 기울이기';
  static const ctlDpad = '방향키 — 십자 버튼 누르기';
  static const resetAll = '진행 기록 지우기';
  static const resetConfirm = '정말 모든 기록을 지울까요?';
  static const cancel = '취소';
  static const ok = '확인';

  static const dailyTitle = '오늘의 퍼즐';
  static const dailyPlay = '도전!';
  static const dailyDone = '오늘 퍼즐 완료!';
  static const streak = '연속 출석';
  static const day = '일';

  static const stickerLocked = '별을 모으면 열려요';
  static const stickerCount = '개';
}
