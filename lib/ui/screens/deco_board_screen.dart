/// 꾸미기 보드: 해금 스티커를 트레이에서 드래그해 자유 배치. 배치는 저장된다.
/// 붙인 스티커를 드래그해 옮기고, 트레이로 끌어내리면 제거.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sticker.dart';
import '../../services/save_service.dart';
import '../strings.dart';
import '../theme.dart';

const _kDecoKey = 'deco.items';
const _stickerSize = 72.0;

class DecoBoardScreen extends StatefulWidget {
  const DecoBoardScreen({super.key});

  @override
  State<DecoBoardScreen> createState() => _DecoBoardScreenState();
}

class _DecoBoardScreenState extends State<DecoBoardScreen> {
  late List<DecoItem> _items;

  @override
  void initState() {
    super.initState();
    final raw = context.read<SaveService>().getString(_kDecoKey);
    _items = raw == null
        ? []
        : (jsonDecode(raw) as List)
            .map((e) => DecoItem.fromJson(e as Map<String, dynamic>))
            .toList();
  }

  void _save() {
    context.read<SaveService>().setString(
        _kDecoKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  void _place(String id, Offset local, Size boardSize) {
    setState(() {
      _items.add(DecoItem(
        id: id,
        dx: ((local.dx - _stickerSize / 2) / boardSize.width).clamp(0.0, 0.9),
        dy: ((local.dy - _stickerSize / 2) / boardSize.height).clamp(0.0, 0.9),
      ));
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final total = context.watch<SaveService>().totalStars;
    final unlocked = unlockedStickers(total);
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.decoBoard,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: PiyakColors.outline)),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final size = Size(box.maxWidth, box.maxHeight);
                return DragTarget<String>(
                  onAcceptWithDetails: (d) {
                    final render =
                        context.findRenderObject() as RenderBox?;
                    final local =
                        render?.globalToLocal(d.offset) ?? Offset.zero;
                    _place(d.data, local, size);
                  },
                  builder: (context, _, _) => Container(
                    color: PiyakColors.creamBg,
                    child: Stack(
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          Positioned(
                            left: _items[i].dx * size.width,
                            top: _items[i].dy * size.height,
                            child: Draggable<int>(
                              data: i,
                              feedback: _stickerImage(_items[i].id, 1.1),
                              childWhenDragging: const SizedBox.shrink(),
                              onDragEnd: (d) {
                                final render = context.findRenderObject()
                                    as RenderBox?;
                                if (render == null) return;
                                final local = render.globalToLocal(d.offset);
                                setState(() {
                                  if (local.dy > size.height - 20) {
                                    _items.removeAt(i); // 트레이로 → 제거
                                  } else {
                                    _items[i] = DecoItem(
                                      id: _items[i].id,
                                      dx: (local.dx / size.width)
                                          .clamp(0.0, 0.9),
                                      dy: (local.dy / size.height)
                                          .clamp(0.0, 0.9),
                                    );
                                  }
                                });
                                _save();
                              },
                              child: _stickerImage(_items[i].id, 1.0),
                            ),
                          ),
                        if (_items.isEmpty)
                          const Center(
                            child: Text('아래에서 스티커를 끌어다 붙여보세요!',
                                style:
                                    TextStyle(color: PiyakColors.outline)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 96,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: PiyakColors.outline, width: 2)),
            ),
            child: unlocked.isEmpty
                ? const Center(
                    child: Text(S.stickerLocked,
                        style: TextStyle(color: PiyakColors.outline)))
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final st in unlocked)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Draggable<String>(
                            data: st.id,
                            feedback: _stickerImage(st.id, 1.1),
                            child: _stickerImage(st.id, 1.0),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stickerImage(String id, double scale) {
    final def = stickerById(id);
    if (def == null) return const SizedBox.shrink();
    return Image.asset(def.asset,
        width: _stickerSize * scale, height: _stickerSize * scale);
  }
}
