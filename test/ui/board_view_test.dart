import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/ui/widgets/board_view.dart';
import 'package:piyak_push/ui/widgets/tile_painter.dart';

void main() {
  testWidgets('BoardView 스모크: 타일·알·병아리 렌더링', (tester) async {
    final board = Board.fromAscii(['#####', '#@\$o#', '#i.c#', '#####']);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: BoardView(board: board, cellSize: 48)),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(BoardView), findsOneWidget);
    expect(find.byType(EggSprite), findsOneWidget);
    // 알은 그림 대신 코드로 그리게 되돌렸고(EggSprite), 타일 그림은
    // TileArt.load()를 부르지 않아 안 뜬다 — 남는 Image는 병아리뿐.
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
