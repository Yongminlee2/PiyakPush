import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/tile.dart';
import 'package:piyak_push/services/tile_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('타일 PNG가 없으면 null (페인터 폴백)', () async {
    await TileArt.load();
    // 아직 codex 그림이 없으므로 전부 null이어야 한다
    expect(TileArt.of(Tile.wall), null);
    expect(TileArt.of(Tile.ice), null);
    expect(TileArt.logo, null);
  });
}
