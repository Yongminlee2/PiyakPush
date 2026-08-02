import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/ui/widgets/board_view.dart';
import 'package:piyak_push/ui/widgets/tile_painter.dart';

void main() {
  testWidgets('BoardView ?ㅻえ?? ??셋룹븣쨌蹂묒븘由??뚮뜑留?, (tester) async {
    final board = Board.fromAscii(['#####', '#@\$o#', '#i.c#', '#####']);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: BoardView(board: board, cellSize: 48)),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(BoardView), findsOneWidget);
    expect(find.byType(EggSprite), findsOneWidget);
    expect(find.byType(Image), findsOneWidget); // 蹂묒븘由?
    expect(tester.takeException(), isNull);
  });
}
