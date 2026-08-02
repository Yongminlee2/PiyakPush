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
    expect(find.byType(Image), findsOneWidget); // 병아리
    expect(tester.takeException(), isNull);
  });
}
