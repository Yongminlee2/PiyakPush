import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/sticker.dart';

void main() {
  test('스티커는 24종, 임계값 6단위 오름차순', () {
    expect(kStickers.length, 24);
    for (var i = 0; i < kStickers.length; i++) {
      expect(kStickers[i].threshold, (i + 1) * 6);
    }
    expect(kStickers.last.threshold, 144); // 총 150별 이내
  });

  test('해금 경계', () {
    expect(unlockedStickers(0), isEmpty);
    expect(unlockedStickers(5), isEmpty);
    expect(unlockedStickers(6).length, 1);
    expect(unlockedStickers(143).length, 23);
    expect(unlockedStickers(150).length, 24);
  });

  test('꾸미기 배치 JSON 왕복', () {
    final items = [
      const DecoItem(id: 'sticker_01', dx: 0.25, dy: 0.5),
      const DecoItem(id: 'chick_cheer', dx: 0.7, dy: 0.1),
    ];
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    final back = (jsonDecode(json) as List)
        .map((e) => DecoItem.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(back.length, 2);
    expect(back[0].id, 'sticker_01');
    expect(back[1].dy, 0.1);
  });

  test('id로 에셋 경로 조회', () {
    expect(stickerById('sticker_01')!.asset,
        'assets/images/sticker/sticker_01.png');
    expect(stickerById('chick_cheer')!.asset,
        'assets/images/chick/chick_cheer.png');
    expect(stickerById('없는거'), null);
  });
}
