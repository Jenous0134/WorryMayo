import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'main.dart';

class EmotionDrawer extends StatefulWidget {
  const EmotionDrawer({
    super.key,
    required this.database,
    required this.onSelect,
    required this.onAdd,
    required this.onLog,
    required this.onDeleted,
    required this.onRenamed,
    this.selectedEmotionId,
  });

  final MindDatabase database;
  final int? selectedEmotionId;
  final ValueChanged<Emotion> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Emotion> onLog;
  final ValueChanged<int> onDeleted;
  final ValueChanged<Emotion> onRenamed;

  @override
  State<EmotionDrawer> createState() => _EmotionDrawerState();
}

class _EmotionDrawerState extends State<EmotionDrawer> {
  String query = '';
  late Future<List<Emotion>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.database.emotions();
  }

  void _reload() => setState(() => _future = widget.database.emotions());

  Future<void> _renameEmotion(Emotion emotion) async {
    final controller = TextEditingController(text: emotion.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감정 이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: '감정 이름'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('저장')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || name.trim() == emotion.name)
      return;
    await widget.database.renameEmotion(emotion.id, name);
    final renamed = Emotion(id: emotion.id, name: name.trim());
    widget.onRenamed(renamed);
    _reload();
  }

  Future<void> _deleteEmotion(Emotion emotion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감정 삭제'),
        content: Text('`${emotion.name}` 감정과 기록을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffff5c7c)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.database.deleteEmotion(emotion.id);
    widget.onDeleted(emotion.id);
    _reload();
  }

  Future<void> _showEmotionActions(Emotion emotion) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xfffff4f7),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Color(0xffc64a68)),
              title: const Text('이름 변경'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_rounded, color: Color(0xffff5c7c)),
              title: const Text('삭제'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'rename') await _renameEmotion(emotion);
    if (action == 'delete') await _deleteEmotion(emotion);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Drawer(
      backgroundColor: const Color(0xffffeef2),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 26, 24, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '감정',
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff783247)),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Emotion>>(
                future: _future,
                builder: (_, snap) {
                  final items = (snap.data ?? [])
                      .where((e) =>
                          e.name.toLowerCase().contains(query.toLowerCase()))
                      .toList();
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        '등록된 감정이 없습니다',
                        style: TextStyle(
                            color: Color(0xffa75a6c),
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final emotion = items[i];
                      final selected = emotion.id == widget.selectedEmotionId;
                      return Material(
                        color: selected
                            ? const Color(0xffffccd7)
                            : Colors.white.withOpacity(.64),
                        borderRadius: BorderRadius.circular(18),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          leading: const Icon(Icons.favorite_rounded,
                              color: Color(0xffff6f8f)),
                          title: Text(
                            emotion.name,
                            style: const TextStyle(
                                color: Color(0xff593041),
                                fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text(
                            '길게 눌러 수정/삭제',
                            style: TextStyle(
                                color: Color(0xffb26b7d), fontSize: 11),
                          ),
                          onTap: () => widget.onSelect(emotion),
                          onLongPress: () => _showEmotionActions(emotion),
                          trailing: IconButton(
                            tooltip: '로그',
                            icon: const Icon(Icons.show_chart_rounded,
                                color: Color(0xffc64a68)),
                            onPressed: () => widget.onLog(emotion),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 18 + bottomInset),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => query = value),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(
                          color: Color(0xff593041),
                          fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: '감정 검색',
                        hintStyle: const TextStyle(color: Color(0xffb26b7d)),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xffc64a68)),
                        filled: true,
                        fillColor: const Color(0xffffdbe4),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xffff7f9d), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: widget.onAdd,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffff6f8f),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum LogRange { hour, day, week, month }

class LogPage extends StatefulWidget {
  const LogPage({super.key, required this.emotion});
  final Emotion emotion;

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  LogRange range = LogRange.hour;
  int? selected;
  DateTime selectedDate = DateTime.now();

  DateTime get now => DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

  DateTime get start {
    final n = now;
    switch (range) {
      case LogRange.hour:
        return DateTime(n.year, n.month, n.day);
      case LogRange.day:
        return DateTime(n.year, n.month, n.day)
            .subtract(const Duration(days: 13));
      case LogRange.week:
        return DateTime(n.year, n.month, n.day)
            .subtract(const Duration(days: 83));
      case LogRange.month:
        return DateTime(n.year, n.month - 11, 1);
    }
  }

  int get count => switch (range) {
        LogRange.hour => 24,
        LogRange.day => 14,
        LogRange.week => 12,
        LogRange.month => 12,
      };

  String label(int i) {
    switch (range) {
      case LogRange.hour:
        return '${i}시';
      case LogRange.day:
        final d = start.add(Duration(days: i));
        return '${d.month}/${d.day}';
      case LogRange.week:
        final d = start.add(Duration(days: i * 7));
        return '${d.month}/${d.day}';
      case LogRange.month:
        final d = DateTime(start.year, start.month + i);
        return '${d.year}.${d.month}';
    }
  }

  List<int> bucket(List<int> taps) {
    final result = List<int>.filled(count, 0);
    for (final stamp in taps) {
      final d = DateTime.fromMillisecondsSinceEpoch(stamp);
      final i = switch (range) {
        LogRange.hour => d.hour,
        LogRange.day => d.difference(start).inDays,
        LogRange.week => d.difference(start).inDays ~/ 7,
        LogRange.month => (d.year - start.year) * 12 + d.month - start.month,
      };
      if (i >= 0 && i < result.length) result[i]++;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('${widget.emotion.name} 로그'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: '날짜 선택',
              icon: const Icon(Icons.calendar_month_rounded),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null)
                  setState(() {
                    selectedDate = picked;
                    selected = null;
                  });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<int>>(
            future: MindDatabase.instance.tapsFor(
                widget.emotion.id, start, now.add(const Duration(days: 1))),
            builder: (_, snap) {
              final data = bucket(snap.data ?? []);
              final total = data.fold(0, (a, b) => a + b);
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('총 $total회',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xff783247))),
                    const SizedBox(height: 6),
                    Text(
                      selected == null
                          ? '그래프의 지점을 눌러 정확한 횟수를 확인하세요'
                          : '${label(selected!)}  ${data[selected!]}회',
                      style: const TextStyle(
                          color: Color(0xffc64a68),
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 26),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, box) => GestureDetector(
                          onTapDown: (d) {
                            final i = (d.localPosition.dx /
                                    box.maxWidth *
                                    data.length)
                                .floor()
                                .clamp(0, data.length - 1);
                            setState(() => selected = i);
                          },
                          child: CustomPaint(
                              size: Size.infinite,
                              painter: _LineGraphPainter(data, selected)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(4, (i) {
                        final j = (i * (data.length - 1) / 3).round();
                        return Text(label(j),
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xffa75a6c)));
                      }),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<LogRange>(
                      segments: const [
                        ButtonSegment(value: LogRange.hour, label: Text('시간')),
                        ButtonSegment(value: LogRange.day, label: Text('일')),
                        ButtonSegment(value: LogRange.week, label: Text('주')),
                        ButtonSegment(value: LogRange.month, label: Text('월')),
                      ],
                      selected: {range},
                      onSelectionChanged: (v) => setState(() {
                        range = v.first;
                        selected = null;
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
}

class _LineGraphPainter extends CustomPainter {
  _LineGraphPainter(this.data, this.selected);
  final List<int> data;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = data.fold<int>(1, (a, b) => a > b ? a : b);
    final grid = Paint()
      ..color = const Color(0x22a75a6c)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : i * size.width / (data.length - 1);
      final y = size.height - (data[i] / maxValue * (size.height - 22)) - 8;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xffff5c7c)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : i * size.width / (data.length - 1);
      final y = size.height - (data[i] / maxValue * (size.height - 22)) - 8;
      canvas.drawCircle(
          Offset(x, y),
          i == selected ? 8 : 4,
          Paint()
            ..color = i == selected
                ? const Color(0xff783247)
                : const Color(0xffff5c7c));
    }
  }

  @override
  bool shouldRepaint(covariant _LineGraphPainter old) =>
      old.data != data || old.selected != selected;
}
