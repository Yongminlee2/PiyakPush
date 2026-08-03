/// 스티커 정의 24종 + 꾸미기 보드 배치 모델.
///
/// 해금: 누적 별 25개마다 1종 (25, 50, …, 600).
///
/// 별 만점은 900개(300스테이지 × 3)지만 마지막 스티커는 600에서 열린다.
/// 만점을 요구하면 전 판을 3별로 깨야 해서 사실상 아무도 못 받는다.
/// 3분의 2쯤에서 다 모이고, 남은 별은 순수한 기록 경쟁으로 둔다.
library;

class StickerDef {
  final String id;
  final String name;
  final String asset;
  final int threshold;
  const StickerDef(this.id, this.name, this.asset, this.threshold);
}

String _st(String f) => 'assets/images/sticker/$f.png';
String _ch(String f) => 'assets/images/chick/$f.png';

final List<StickerDef> kStickers = List.unmodifiable(() {
  final defs = <(String, String, String)>[
    // (id, 이름, 에셋 경로) — 순서 = 해금 순서
    ('sticker_01', '반짝 별', _st('sticker_01')),
    ('sticker_02', '스티커 2', _st('sticker_02')),
    ('sticker_03', '스티커 3', _st('sticker_03')),
    ('sticker_04', '스티커 4', _st('sticker_04')),
    ('sticker_05', '스티커 5', _st('sticker_05')),
    ('sticker_06', '스티커 6', _st('sticker_06')),
    ('chick_idle', '삐약이', _ch('chick_idle')),
    ('sticker_07', '스티커 7', _st('sticker_07')),
    ('sticker_08', '스티커 8', _st('sticker_08')),
    ('chick_cheer', '만세 삐약', _ch('chick_cheer')),
    ('sticker_09', '스티커 9', _st('sticker_09')),
    ('sticker_10', '스티커 10', _st('sticker_10')),
    ('chick_clap', '박수 삐약', _ch('chick_clap')),
    ('sticker_11', '스티커 11', _st('sticker_11')),
    ('sticker_12', '스티커 12', _st('sticker_12')),
    ('chick_book', '책 읽는 삐약', _ch('chick_book')),
    ('chick_think', '생각 삐약', _ch('chick_think')),
    ('chick_speak', '수다 삐약', _ch('chick_speak')),
    ('chick_listen', '경청 삐약', _ch('chick_listen')),
    ('chick_write', '필기 삐약', _ch('chick_write')),
    ('chick_sleep', '쿨쿨 삐약', _ch('chick_sleep')),
    ('chick_sad', '시무룩 삐약', _ch('chick_sad')),
    ('chick_cheerup', '힘내 삐약', _ch('chick_cheerup')),
    ('sticker_crown', '황금 왕관', _st('sticker_crown')),
  ];
  return [
    for (var i = 0; i < defs.length; i++)
      StickerDef(defs[i].$1, defs[i].$2, defs[i].$3, (i + 1) * 25),
  ];
}());

List<StickerDef> unlockedStickers(int totalStars) =>
    kStickers.where((s) => totalStars >= s.threshold).toList();

StickerDef? stickerById(String id) {
  for (final s in kStickers) {
    if (s.id == id) return s;
  }
  return null;
}

/// 꾸미기 보드에 붙인 스티커 하나. 좌표는 보드 크기 대비 0~1 비율.
class DecoItem {
  final String id;
  final double dx, dy;
  const DecoItem({required this.id, required this.dx, required this.dy});

  Map<String, dynamic> toJson() => {'id': id, 'dx': dx, 'dy': dy};

  factory DecoItem.fromJson(Map<String, dynamic> j) => DecoItem(
        id: j['id'] as String,
        dx: (j['dx'] as num).toDouble(),
        dy: (j['dy'] as num).toDouble(),
      );
}
