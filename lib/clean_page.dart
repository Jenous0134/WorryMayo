import 'dart:math' as math;

import 'package:flutter/material.dart';

class CleanPage extends StatefulWidget {
  const CleanPage({super.key});

  @override
  State<CleanPage> createState() => _CleanPageState();
}

class _CleanPageState extends State<CleanPage> {
  final _random = math.Random();
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final List<_CleanWorry> _worries = [];

  Offset? _brushPosition;
  bool _editorOpen = false;
  bool _completed = false;
  String _completedMessage = '조금 깨끗해졌어요';

  void _openWorryEditor() {
    setState(() => _editorOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocusNode.requestFocus();
    });
  }

  void _closeWorryEditor() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _editorOpen = false);
  }

  void _startCleaningFromEditor() {
    final phrases = _parseWorryInput(_inputController.text);

    if (phrases.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editorOpen = false;
      _completed = false;
      _completedMessage =
          _completedMessages[_random.nextInt(_completedMessages.length)];
      _brushPosition = null;
      _worries
        ..clear()
        ..addAll(_generateWorryCloud(phrases));
    });
  }

  List<_CleanWorry> _generateWorryCloud(List<String> phrases) {
    final base = phrases.take(30).toList();
    final targetCount = (22 + base.length * 4).clamp(24, 42);
    final result = <_CleanWorry>[];
    final slots = <Offset>[];
    const columns = 4;
    const rows = 7;

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        slots.add(Offset(
          (column + .12 + _random.nextDouble() * .42) / columns,
          (row + .10 + _random.nextDouble() * .52) / rows,
        ));
      }
    }
    slots.shuffle(_random);

    for (var i = 0; i < targetCount; i++) {
      final text = base[i % base.length];
      final slot = slots[i % slots.length];
      result.add(_CleanWorry(
        text: text,
        x: (slot.dx + (_random.nextDouble() - .5) * .04).clamp(.03, .82),
        y: (slot.dy + (_random.nextDouble() - .5) * .035).clamp(.04, .84),
        width: 118 + _random.nextDouble() * 86,
        height: 52 + _random.nextDouble() * 36,
        fontSize: 17 + _random.nextDouble() * 9,
        rotation: (_random.nextDouble() - .5) * .18,
        color: _worryColors[_random.nextInt(_worryColors.length)],
      ));
    }
    return result;
  }

  void _eraseAt(Offset position, Size size) {
    var changed = false;
    _brushPosition = position;

    for (final worry in _worries) {
      if (worry.cleared) continue;

      final rect = _worryRect(worry, size);
      if (!rect.inflate(18).contains(position)) continue;

      final localX = ((position.dx - rect.left) / rect.width).clamp(0.0, .999);
      final localY = ((position.dy - rect.top) / rect.height).clamp(0.0, .999);
      final column = (localX * _gridColumns).floor();
      final row = (localY * _gridRows).floor();
      worry.cleanedCells.add(row * _gridColumns + column);

      if (worry.erasePoints.isEmpty ||
          (worry.erasePoints.last - position).distance > 3) {
        worry.erasePoints.add(position);
      }

      if (worry.cleanedCells.length >= 7) {
        worry.cleared = true;
      }
      changed = true;
    }

    if (!changed) return;

    setState(() {
      if (_worries.isNotEmpty && _worries.every((worry) => worry.cleared)) {
        _completed = true;
      }
    });
  }

  void _endErase() {
    if (_brushPosition == null) return;
    setState(() => _brushPosition = null);
  }

  double get _cleanProgress {
    if (_worries.isEmpty) return 0;
    final cleaned = _worries.fold<int>(
      0,
      (sum, worry) => sum + worry.cleanedCells.length.clamp(0, _clearCells),
    );
    return (cleaned / (_worries.length * _clearCells)).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xfffffbf1),
                  Color(0xfffff3f5),
                  Color(0xffedfaff),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    _CleanHeader(onAdd: _openWorryEditor),
                    if (_worries.isNotEmpty && !_completed)
                      _ProgressChip(
                        remaining:
                            _worries.where((worry) => !worry.cleared).length,
                      ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest;
                          if (_worries.isEmpty) {
                            return _EmptyCleaner(onAdd: _openWorryEditor);
                          }
                          return Stack(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (details) =>
                                    _eraseAt(details.localPosition, size),
                                onPanUpdate: (details) =>
                                    _eraseAt(details.localPosition, size),
                                onPanEnd: (_) => _endErase(),
                                onPanCancel: _endErase,
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: _CleaningPainter(
                                    worries: _worries,
                                    brushPosition: _brushPosition,
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 260),
                                  opacity: _cleanProgress * .18,
                                  child: Container(color: Colors.white),
                                ),
                              ),
                              if (_completed)
                                _CompletedCleaning(
                                  message: _completedMessage,
                                  onRestart: _openWorryEditor,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                _WorryEditor(
                  open: _editorOpen,
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  onStart: _startCleaningFromEditor,
                  onClose: _closeWorryEditor,
                ),
              ],
            ),
          ),
        ),
      );
}

class _CleanHeader extends StatelessWidget {
  const _CleanHeader({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
        child: SizedBox(
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xffd3a35a),
                  ),
                ),
              ),
              const Text(
                '고민 싹싹밀기',
                style: TextStyle(
                  color: Color(0xffd3a35a),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: '고민 추가',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, color: Color(0xffffb755)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '남은 고민 조각 $remaining개 · 천천히 문질러 보세요',
          style: const TextStyle(
            color: Color(0xffd0a071),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _EmptyCleaner extends StatelessWidget {
  const _EmptyCleaner({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cleaning_services_rounded,
                size: 42,
                color: Color(0xffffbc69),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '지우고 싶은 고민을 풀어놓아 보세요',
              style: TextStyle(
                color: Color(0xffd3a35a),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('고민 적기'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xffffae5c),
              ),
            ),
          ],
        ),
      );
}

class _CompletedCleaning extends StatelessWidget {
  const _CompletedCleaning({
    required this.message,
    required this.onRestart,
  });
  final String message;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Container(
          color: const Color(0xfffffbf1).withOpacity(.7),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(28),
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffffd58f).withOpacity(.25),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xffffbd63),
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      color: const Color(0xffd3a35a),
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '오늘은 이만큼이면 충분해요',
                    style: TextStyle(color: Color(0xffd8b58e)),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: onRestart,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('새 고민 적기'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xffffae5c),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _WorryEditor extends StatelessWidget {
  const _WorryEditor({
    required this.open,
    required this.controller,
    required this.focusNode,
    required this.onStart,
    required this.onClose,
  });

  final bool open;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          ignoring: !open,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: open ? 1 : 0,
            child: Stack(
              children: [
                Positioned.fill(
                  top: 64,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: Container(color: Colors.black.withOpacity(.04)),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  top: open ? 58 : -260,
                  left: 14,
                  right: 14,
                  child: Material(
                    color: const Color(0xfffffbf5),
                    elevation: 10,
                    borderRadius: BorderRadius.circular(26),
                    shadowColor: const Color(0xffffd58f).withOpacity(.28),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '지우고 싶은 고민 적기',
                            style: TextStyle(
                              color: Color(0xffd3a35a),
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '쉼표(,)로 구분해서 여러 개를 한 번에 적을 수 있어요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xffd8b58e),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final sample in _sampleWorries)
                                ActionChip(
                                  label: Text(sample),
                                  labelStyle: const TextStyle(
                                    color: Color(0xffc99866),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  backgroundColor: Colors.white,
                                  side: BorderSide.none,
                                  onPressed: () {
                                    final current = controller.text.trim();
                                    controller.text = current.isEmpty
                                        ? sample
                                        : '$current, $sample';
                                    controller.selection =
                                        TextSelection.collapsed(
                                      offset: controller.text.length,
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: controller,
                            focusNode: focusNode,
                            maxLength: 240,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => onStart(),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '예: 내일 발표, 인간관계, 잠이 안 옴',
                              hintStyle:
                                  const TextStyle(color: Color(0xffdfc4a2)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: controller,
                            builder: (context, value, _) {
                              final count = _parseWorryInput(value.text).length;
                              return Column(
                                children: [
                                  Text(
                                    count == 0
                                        ? '쉼표로 구분해서 고민을 적어주세요'
                                        : '$count개의 고민이 준비됐어요',
                                    style: const TextStyle(
                                      color: Color(0xffd8b58e),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: count == 0 ? null : onStart,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xffffb95f),
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            const Color(0xffffdfb0),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                      ),
                                      child: const Text(
                                        '청소 시작',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _CleanWorry {
  _CleanWorry({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.rotation,
    required this.color,
  });

  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final double fontSize;
  final double rotation;
  final Color color;
  final Set<int> cleanedCells = {};
  final List<Offset> erasePoints = [];
  bool cleared = false;
}

Rect _worryRect(_CleanWorry worry, Size size) {
  final width = worry.width;
  final height = worry.height;
  final left = (worry.x * size.width).clamp(8.0, size.width - width - 8);
  final top = (worry.y * size.height).clamp(18.0, size.height - height - 12);
  return Rect.fromLTWH(left, top, width, height);
}

class _CleaningPainter extends CustomPainter {
  const _CleaningPainter({
    required this.worries,
    required this.brushPosition,
  });
  final List<_CleanWorry> worries;
  final Offset? brushPosition;

  @override
  void paint(Canvas canvas, Size size) {
    for (final worry in worries) {
      if (worry.cleared) continue;

      final rect = _worryRect(worry, size);
      final textPainter = TextPainter(
        text: TextSpan(
          text: worry.text,
          style: TextStyle(
            color: worry.color,
            fontSize: worry.fontSize,
            fontWeight: FontWeight.w900,
            height: 1.16,
          ),
        ),
        maxLines: 3,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width);

      canvas.saveLayer(rect.inflate(22), Paint());

      final opacity =
          (1 - (worry.cleanedCells.length / _clearCells) * .42).clamp(.42, 1.0);
      textPainter.text = TextSpan(
        text: worry.text,
        style: TextStyle(
          color: worry.color.withOpacity(opacity),
          fontSize: worry.fontSize,
          fontWeight: FontWeight.w900,
          height: 1.16,
        ),
      );
      textPainter.layout(maxWidth: rect.width);
      textPainter.paint(canvas, Offset(rect.left, rect.top + 8));

      final erasePaint = Paint()
        ..blendMode = BlendMode.clear
        ..color = Colors.transparent;
      for (final point in worry.erasePoints) {
        canvas.drawCircle(point, 16, erasePaint);
      }

      canvas.restore();
    }

    if (brushPosition != null) {
      final center = brushPosition!;
      final brushPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xffffc67a).withOpacity(.52);
      canvas.drawCircle(center, 21, brushPaint);

      final glowPaint = Paint()
        ..color = const Color(0xffffe2ad).withOpacity(.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, 18, glowPaint);

      final sparklePaint = Paint()
        ..color = const Color(0xffffc67a).withOpacity(.45);
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final point = center + Offset(math.cos(angle), math.sin(angle)) * 28;
        canvas.drawCircle(point, 1.6, sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CleaningPainter oldDelegate) => true;
}

const _gridColumns = 5;
const _gridRows = 3;
const _clearCells = 7;

List<String> _parseWorryInput(String text) => text
    .split(RegExp(r'[,，、\n]+'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .map((item) => item.characters.take(42).toString())
    .toList();

const _sampleWorries = <String>[
  '내일 발표',
  '잠이 안 옴',
  '괜히 불안함',
  '해야 할 일',
];

const _completedMessages = <String>[
  '조금 깨끗해졌어요',
  '마음 한쪽이 정리됐어요',
  '오늘은 이만큼이면 충분해요',
  '숨 쉴 자리가 생겼어요',
];

const _worryColors = <Color>[
  Color(0xffd9a1aa),
  Color(0xffa8b9dc),
  Color(0xffd5af7e),
  Color(0xffa9c8bd),
  Color(0xffc3a8d5),
];
