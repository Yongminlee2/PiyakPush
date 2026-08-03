import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/tile.dart';
import 'package:piyak_push/services/tile_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('타일 PNG가 없으면 null (페인터 폴백)', () async {
    await TileArt.load();
    // 지형·기믹은 화풍을 맞추려고 전부 코드 렌더링으로 되돌렸고,
    // 그림이 남아 있는 건 둥지뿐이다.
    expect(TileArt.of(Tile.wall), null);
    expect(TileArt.of(Tile.ice), null);
    expect(TileArt.of(Tile.doorB), null);
    expect(TileArt.of(Tile.portal1), null);
    expect(TileArt.of(Tile.nest), isNotNull);
  });
}
