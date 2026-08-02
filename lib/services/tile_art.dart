/// "PNG가 있으면 그림, 없으면 페인터" 계층. codex 그림이 도착하기 전에도
/// 앱이 동작하고, assets/images/tiles/에 파일을 넣고 빌드만 다시 하면 적용된다.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../engine/tile.dart';

class TileArt {
  static const _dir = 'assets/images/tiles';

  static const _names = {
    Tile.floor: 'tile_grass',
    Tile.wall: 'tile_wall',
    Tile.nest: 'tile_nest',
    Tile.ice: 'tile_ice',
    Tile.portal1: 'tile_portal_purple',
    Tile.portal2: 'tile_portal_purple',
    Tile.portal3: 'tile_portal_orange',
    Tile.portal4: 'tile_portal_orange',
    Tile.buttonB: 'tile_button_pink',
    Tile.doorB: 'tile_door_pink',
    Tile.buttonD: 'tile_button_blue',
    Tile.doorD: 'tile_door_blue',
    Tile.cracked: 'tile_cracked',
  };

  static Map<Tile, ImageProvider>? _map;
  static ImageProvider? logo;

  static Future<void> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();
    _map = {
      for (final e in _names.entries)
        if (assets.contains('$_dir/${e.value}.png'))
          e.key: AssetImage('$_dir/${e.value}.png'),
    };
    logo = assets.contains('$_dir/logo.png')
        ? const AssetImage('$_dir/logo.png')
        : null;
  }

  static ImageProvider? of(Tile t) => _map?[t];
}
