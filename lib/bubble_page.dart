import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class MindBubblePage extends StatefulWidget {
  const MindBubblePage({super.key});

  @override
  State<MindBubblePage> createState() => _MindBubblePageState();
}

class _MindBubblePageState extends State<MindBubblePage>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _textFocusNode = FocusNode();
  final _random = math.Random();
  late final AnimationController _backgroundController;
  final List<_BubbleItem> _bubbles = [];

  @override
  void initState() {
    super.initState();
    _backgroundController =
        AnimationController(vsync: this, duration: const Duration(seconds: 9))
          ..repeat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _textFocusNode.requestFocus();
      return;
    }

    _textController.clear();
    _launchBubble(text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textFocusNode.requestFocus();
    });
  }

  void _launchBubble(String text) {
    final chunks = _splitThought(text);
    if (chunks.isEmpty) return;

    setState(() {
      for (var index = 0; index < chunks.length; index++) {
        _bubbles.add(_BubbleItem(
          id: '${DateTime.now().microsecondsSinceEpoch}-$index',
          text: chunks[index],
          left: (.24 + _random.nextDouble() * .52).clamp(.12, .88),
          size: (112 + chunks[index].length * 2.9).clamp(118, 224).toDouble(),
          drift: -42 + _random.nextDouble() * 84,
          duration: Duration(milliseconds: 5200 + _random.nextInt(2100)),
        ));
      }
      if (_bubbles.length > 14) _bubbles.removeRange(0, _bubbles.length - 14);
    });
  }

  List<String> _splitThought(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return [];
    if (normalized.length <= 70) return [normalized];

    final result = <String>[];
    var rest = normalized;
    while (rest.isNotEmpty && result.length < 3) {
      final target = (rest.length / (3 - result.length)).ceil().clamp(42, 90);
      var cut = rest.length <= target ? rest.length : target;
      final slice = rest.substring(0, cut);
      final space = slice.lastIndexOf(' ');
      if (space > 28) cut = space;
      result.add(rest.substring(0, cut).trim());
      rest = rest.substring(cut).trim();
    }
    return result.where((e) => e.isNotEmpty).toList();
  }

  void _removeBubble(String id) {
    if (!mounted) return;
    setState(() => _bubbles.removeWhere((bubble) => bubble.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, _) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xffe8fbff),
                  Color(0xfff3eeff),
                  Color(0xfffff7e8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                ...List.generate(9, (i) {
                  final phase = (_backgroundController.value + i * .131) % 1;
                  return Positioned(
                    left: (i * 47 % 340).toDouble(),
                    top: 650 - phase * 820,
                    child: Opacity(
                      opacity: .08 + (i % 3) * .025,
                      child: Container(
                        width: 34 + (i % 4) * 16,
                        height: 34 + (i % 4) * 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
                Column(
                  children: [
                    const _BubbleHeader(),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final bubble in _bubbles)
                              _FloatingBubble(
                                item: bubble,
                                onDone: () => _removeBubble(bubble.id),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: _InputPanel(
                        textController: _textController,
                        textFocusNode: _textFocusNode,
                        onSendText: _sendText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleHeader extends StatelessWidget {
  const _BubbleHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Color(0xff8ebfce)),
                ),
              ),
              const Text(
                'Troubley Bubbley',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff86b8c9),
                ),
              ),
            ],
          ),
        ),
      );
}

class _InputPanel extends StatelessWidget {
  const _InputPanel({
    required this.textController,
    required this.textFocusNode,
    required this.onSendText,
  });

  final TextEditingController textController;
  final FocusNode textFocusNode;
  final VoidCallback onSendText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffb5e9f7).withOpacity(.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              focusNode: textFocusNode,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onEditingComplete: () {},
              onSubmitted: (_) => onSendText(),
              decoration: InputDecoration(
                hintText: '떠나보낼 고민을 적어보세요',
                filled: true,
                fillColor: const Color(0xfff6fdff),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onSendText,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(15),
              backgroundColor: const Color(0xff9dddf0),
            ),
            child: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}

class _FloatingBubble extends StatefulWidget {
  const _FloatingBubble({required this.item, required this.onDone});
  final _BubbleItem item;
  final VoidCallback onDone;

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.item.duration)
          ..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(milliseconds: 360), widget.onDone);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final popping = _controller.value > .9;
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
          final x = width * widget.item.left +
              math.sin(t * math.pi * 3) * 14 +
              widget.item.drift * t;
          final y = height * .74 - t * height * .72;
          final textLength = widget.item.text.characters.length;
          final fontSize = textLength <= 28
              ? 18.0
              : textLength <= 55
                  ? 16.0
                  : textLength <= 90
                      ? 14.0
                      : 12.5;
          return Positioned(
            left: x - widget.item.size / 2,
            top: y,
            child: Opacity(
              opacity: popping
                  ? (1 - (_controller.value - .9) / .1).clamp(0, 1)
                  : .96,
              child: Transform.scale(
                scale: popping
                    ? 1.0 + (_controller.value - .9) * 2.2
                    : .94 + t * .08,
                child: Container(
                  width: widget.item.size,
                  height: widget.item.size,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(.92),
                        const Color(0xffd9f8ff).withOpacity(.68),
                        const Color(0xffe4dcff).withOpacity(.54),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(.7)),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xffb5e9f7).withOpacity(.24),
                          blurRadius: 22),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.item.text,
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xff86b8c9),
                        fontSize: fontSize,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _BubbleItem {
  const _BubbleItem({
    required this.id,
    required this.text,
    required this.left,
    required this.size,
    required this.drift,
    required this.duration,
  });

  final String id;
  final String text;
  final double left;
  final double size;
  final double drift;
  final Duration duration;
}
