import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'bubble_page.dart';
import 'clean_page.dart';
import 'extras.dart';

void main() => runApp(const MindCheckerApp());

class MindCheckerApp extends StatelessWidget {
  const MindCheckerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '걱정마요',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xffff6f8f),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xfffff7f8),
          useMaterial3: true,
          fontFamilyFallback: const ['Noto Sans CJK KR', 'Roboto'],
        ),
        home: const FeatureHomePage(),
      );
}

class Emotion {
  const Emotion({required this.id, required this.name});
  final int id;
  final String name;

  factory Emotion.fromMap(Map<String, Object?> row) =>
      Emotion(id: row['id'] as int, name: row['name'] as String);
}

class MindDatabase {
  MindDatabase._();
  static final instance = MindDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final databasePath = path.join(await getDatabasesPath(), 'mind_checker.db');
    _db = await openDatabase(databasePath, version: 1, onCreate: (db, _) async {
      await db.execute(
          'CREATE TABLE emotions (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, created_at INTEGER NOT NULL)');
      await db.execute(
          'CREATE TABLE taps (id INTEGER PRIMARY KEY AUTOINCREMENT, emotion_id INTEGER NOT NULL, timestamp INTEGER NOT NULL)');
      await db.execute(
          'CREATE INDEX taps_emotion_time ON taps(emotion_id, timestamp)');
    });
    return _db!;
  }

  Future<List<Emotion>> emotions() async {
    final db = await database;
    final rows = await db.query('emotions', orderBy: 'name COLLATE NOCASE');
    return rows.map(Emotion.fromMap).toList();
  }

  Future<Emotion> addEmotion(String name) async {
    final db = await database;
    final trimmed = name.trim();
    final id = await db.insert('emotions',
        {'name': trimmed, 'created_at': DateTime.now().millisecondsSinceEpoch});
    return Emotion(id: id, name: trimmed);
  }

  Future<void> renameEmotion(int id, String name) async {
    final db = await database;
    await db.update('emotions', {'name': name.trim()},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEmotion(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('taps', where: 'emotion_id = ?', whereArgs: [id]);
      await txn.delete('emotions', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> addTap(int emotionId, int timestamp) async {
    final db = await database;
    await db.insert('taps', {'emotion_id': emotionId, 'timestamp': timestamp});
  }

  Future<List<int>> tapsFor(int emotionId, DateTime from, DateTime to) async {
    final db = await database;
    final rows = await db.query(
      'taps',
      columns: ['timestamp'],
      where: 'emotion_id = ? AND timestamp >= ? AND timestamp < ?',
      whereArgs: [
        emotionId,
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch
      ],
      orderBy: 'timestamp',
    );
    return rows.map((row) => row['timestamp'] as int).toList();
  }
}

class FeatureHomePage extends StatefulWidget {
  const FeatureHomePage({super.key});

  @override
  State<FeatureHomePage> createState() => _FeatureHomePageState();
}

class _FeatureHomePageState extends State<FeatureHomePage>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  String? _launching;

  @override
  void initState() {
    super.initState();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _openFeature(
      String id, Duration delay, WidgetBuilder builder) async {
    if (_launching != null) return;
    setState(() => _launching = id);
    await Future<void>.delayed(delay);
    if (!mounted) return;
    setState(() => _launching = null);
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              final wave = math.sin(_floatController.value * math.pi * 2);
              return Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xfffff7f8),
                      Color(0xffffedf2),
                      Color(0xffedfaff),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 72,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(0, wave * 5),
                          child: _FeatureCard(
                            title: '고민 노크',
                            subtitle: 'Mind Check',
                            logoAsset: 'assets/images/logo/mind_check_logo.png',
                            color: const Color(0xffffa9bc),
                            shadowColor: const Color(0xffffb4c6),
                            launching: _launching == 'knock',
                            launchKind: _FeatureLaunchKind.knock,
                            onTap: () => _openFeature(
                                'knock',
                                const Duration(milliseconds: 1120),
                                (_) => const HomePage()),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Transform.translate(
                          offset: Offset(0, -wave * 4),
                          child: _FeatureCard(
                            title: '고민 버블',
                            subtitle: 'Troubley-Bubbley',
                            logoAsset:
                                'assets/images/logo/troubley_bubbley_logo.png',
                            color: const Color(0xffaeeeff),
                            shadowColor: const Color(0xffb5e9f7),
                            launching: _launching == 'bubble',
                            launchKind: _FeatureLaunchKind.bubble,
                            onTap: () => _openFeature(
                                'bubble',
                                const Duration(milliseconds: 1080),
                                (_) => const MindBubblePage()),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Transform.translate(
                          offset: Offset(0, wave * 3),
                          child: _FeatureCard(
                            title: '고민 싹싹밀기',
                            subtitle: 'trouble truncate',
                            logoAsset:
                                'assets/images/logo/trouble_truncate_logo.png',
                            color: const Color(0xffffd58f),
                            shadowColor: const Color(0xffffe1ad),
                            launching: _launching == 'clean',
                            launchKind: _FeatureLaunchKind.clean,
                            onTap: () => _openFeature(
                                'clean',
                                const Duration(milliseconds: 760),
                                (_) => const CleanPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

enum _FeatureLaunchKind { knock, bubble, clean }

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.logoAsset,
    required this.color,
    required this.shadowColor,
    required this.launching,
    required this.launchKind,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String logoAsset;
  final Color color;
  final Color shadowColor;
  final bool launching;
  final _FeatureLaunchKind launchKind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: launching ? 1 : 0),
          duration: Duration(
            milliseconds: launchKind == _FeatureLaunchKind.knock ? 980 : 920,
          ),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            final scale = launchKind == _FeatureLaunchKind.knock
                ? 1 + math.sin(t * math.pi * 4) * .045
                : t < .62
                    ? 1 - Curves.easeInOut.transform(t / .62) * .18
                    : .82 + Curves.easeOutBack.transform((t - .62) / .38) * .36;
            return CustomPaint(
              painter: _FeatureEffectPainter(
                progress: t,
                color: color,
                kind: launchKind,
              ),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 320,
                  height: 108,
                  padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(.88), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withOpacity(.38),
                        blurRadius: 34,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.78),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Image.asset(logoAsset, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(.86),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: .2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.white.withOpacity(.82), size: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _FeatureEffectPainter extends CustomPainter {
  const _FeatureEffectPainter({
    required this.progress,
    required this.color,
    required this.kind,
  });

  final double progress;
  final Color color;
  final _FeatureLaunchKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    if (kind == _FeatureLaunchKind.knock) {
      for (var i = 0; i < 2; i++) {
        final local = ((progress - i * .42) / .42).clamp(0.0, 1.0);
        if (local <= 0 || local >= 1) continue;
        canvas.drawCircle(
          center,
          94 + local * 54,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 * (1 - local)
            ..color = color.withOpacity((1 - local) * .5),
        );
      }
    } else {
      if (progress < .62) {
        final pull = Curves.easeIn.transform(progress / .62);
        for (var i = 0; i < 12; i++) {
          final angle = i / 12 * math.pi * 2;
          final distance = 78 * (1 - pull);
          final dot =
              center + Offset(math.cos(angle), math.sin(angle)) * distance;
          canvas.drawCircle(
              dot, 3 + pull * 2, Paint()..color = color.withOpacity(.45));
        }
      } else {
        final pop = Curves.easeOut.transform((progress - .62) / .38);
        for (var i = 0; i < 18; i++) {
          final angle = i / 18 * math.pi * 2;
          final wobble = math.sin(i * 1.7) * 10;
          final distance = 22 + pop * (72 + wobble);
          final dot =
              center + Offset(math.cos(angle), math.sin(angle)) * distance;
          canvas.drawCircle(
            dot,
            (1 - pop) * 6 + 1.2,
            Paint()..color = color.withOpacity((1 - pop) * .85),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FeatureEffectPainter old) =>
      old.progress != progress || old.color != color || old.kind != kind;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _db = MindDatabase.instance;
  final _menuSearchController = TextEditingController();
  final _menuFocusNode = FocusNode();
  late final AnimationController _orbController;
  Emotion? _selected;
  DateTime? _lastTap;
  Timer? _decay;
  double _energy = .08;
  int _pulse = 0;
  bool _menuOpen = false;
  String _menuQuery = '';
  late Future<List<Emotion>> _emotionFuture;

  @override
  void initState() {
    super.initState();
    _emotionFuture = _db.emotions();
    _orbController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
    _startDecayLoop();
  }

  void _reloadEmotions() => setState(() => _emotionFuture = _db.emotions());

  void _startDecayLoop() {
    _decay = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      final next = _energy + (.08 - _energy) * .035;
      if ((next - _energy).abs() > .003) setState(() => _energy = next);
    });
  }

  void _tap() {
    final emotion = _selected;
    if (emotion == null) return;

    final now = DateTime.now();
    final interval =
        _lastTap == null ? 650 : now.difference(_lastTap!).inMilliseconds;
    _lastTap = now;

    HapticFeedback.selectionClick();
    _db.addTap(emotion.id, now.millisecondsSinceEpoch);

    final impulse = interval < 140
        ? .13
        : interval < 260
            ? .105
            : interval < 480
                ? .075
                : .045;

    setState(() {
      _energy = (_energy + impulse).clamp(.08, .82);
      _pulse++;
    });
  }

  Future<void> _addEmotion() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감정 추가'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 8,
          decoration: const InputDecoration(hintText: '예: 불안'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('추가'))
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await _db.addEmotion(name.trim().characters.take(8).toString());
    if (!mounted) return;
    setState(() {
      _emotionFuture = _db.emotions();
    });
  }

  Future<void> _renameEmotion(Emotion emotion) async {
    final controller = TextEditingController(text: emotion.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감정 이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 8,
          decoration: const InputDecoration(hintText: '감정 이름'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('저장'))
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    final trimmed = name.trim().characters.take(8).toString();
    await _db.renameEmotion(emotion.id, trimmed);
    final renamed = Emotion(id: emotion.id, name: trimmed);
    if (!mounted) return;
    if (_selected?.id == emotion.id) _selected = renamed;
    _reloadEmotions();
  }

  Future<void> _deleteEmotion(Emotion emotion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감정 삭제'),
        content: Text('${emotion.name} 감정과 기록을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteEmotion(emotion.id);
    if (!mounted) return;
    setState(() {
      if (_selected?.id == emotion.id) _selected = null;
      _emotionFuture = _db.emotions();
    });
  }

  void _closeMenu() {
    _menuFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _menuOpen = false;
    });
  }

  Future<void> _selectEmotion(Emotion emotion) async {
    _menuFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selected = emotion;
      _menuQuery = '';
      _menuSearchController.clear();
    });
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    setState(() => _menuOpen = false);
  }

  @override
  void dispose() {
    _menuSearchController.dispose();
    _menuFocusNode.dispose();
    _decay?.cancel();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: true,
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                    child: SizedBox(
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: '뒤로',
                              color: const Color(0xffd9829d),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          ),
                          const Center(
                            child: Text(
                              '마인드 체커',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xffd9829d)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_selected != null)
                                  IconButton(
                                    tooltip: '로그',
                                    color: const Color(0xffd9829d),
                                    icon: const Icon(Icons.show_chart_rounded),
                                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                LogPage(emotion: _selected!))),
                                  ),
                                IconButton(
                                  tooltip: '감정 선택',
                                  color: const Color(0xffff6f8f),
                                  icon: Icon(_menuOpen
                                      ? Icons.favorite
                                      : Icons.favorite_border_rounded),
                                  onPressed: () {
                                    if (_menuOpen) {
                                      _closeMenu();
                                    } else {
                                      setState(() => _menuOpen = true);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _tap,
                      child: Center(
                        child: _selected == null
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  '하트 버튼을 눌러 감정을 선택하세요',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Color(0xffd99aae),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              )
                            : Orb(
                                controller: _orbController,
                                energy: _energy,
                                pulse: _pulse,
                                label: _selected!.name,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              _TopEmotionMenu(
                open: _menuOpen,
                future: _emotionFuture,
                query: _menuQuery,
                selectedId: _selected?.id,
                searchController: _menuSearchController,
                searchFocusNode: _menuFocusNode,
                onQueryChanged: (value) => setState(() => _menuQuery = value),
                onAdd: _addEmotion,
                onSelect: _selectEmotion,
                onLog: (emotion) => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LogPage(emotion: emotion))),
                onRename: _renameEmotion,
                onDelete: _deleteEmotion,
                onClose: _closeMenu,
              ),
            ],
          ),
        ),
      );
}

class _TopEmotionMenu extends StatelessWidget {
  const _TopEmotionMenu({
    required this.open,
    required this.future,
    required this.query,
    required this.selectedId,
    required this.searchController,
    required this.searchFocusNode,
    required this.onQueryChanged,
    required this.onAdd,
    required this.onSelect,
    required this.onLog,
    required this.onRename,
    required this.onDelete,
    required this.onClose,
  });

  final bool open;
  final Future<List<Emotion>> future;
  final String query;
  final int? selectedId;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onAdd;
  final Future<void> Function(Emotion) onSelect;
  final ValueChanged<Emotion> onLog;
  final ValueChanged<Emotion> onRename;
  final ValueChanged<Emotion> onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !open,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: open ? 1 : 0,
          child: Stack(
            children: [
              Positioned.fill(
                top: 64,
                child: GestureDetector(
                    onTap: onClose,
                    child: Container(color: Colors.black.withOpacity(.04))),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                top: open ? 58 : -330,
                left: 14,
                right: 14,
                child: Material(
                  color: const Color(0xfffff6f9),
                  elevation: 10,
                  borderRadius: BorderRadius.circular(26),
                  shadowColor: const Color(0xffff8fab).withOpacity(.22),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                focusNode: searchFocusNode,
                                onChanged: onQueryChanged,
                                decoration: InputDecoration(
                                  hintText: '감정 검색',
                                  prefixIcon: const Icon(Icons.search_rounded,
                                      color: Color(0xffff9ab3)),
                                  filled: true,
                                  fillColor: const Color(0xffffeaf1),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: onAdd,
                              style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xffff6f8f),
                                  foregroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(14)),
                              child: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: FutureBuilder<List<Emotion>>(
                            future: future,
                            builder: (context, snapshot) {
                              final items = (snapshot.data ?? [])
                                  .where((e) => e.name
                                      .toLowerCase()
                                      .contains(query.toLowerCase()))
                                  .toList();
                              if (items.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('등록된 감정이 없습니다',
                                      style: TextStyle(
                                          color: Color(0xffd99aae),
                                          fontWeight: FontWeight.w700)),
                                );
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final emotion = items[index];
                                  final selected = selectedId == emotion.id;
                                  return Material(
                                    color: selected
                                        ? const Color(0xffffccd7)
                                        : Colors.white.withOpacity(.72),
                                    borderRadius: BorderRadius.circular(16),
                                    child: ListTile(
                                      dense: true,
                                      leading: const Icon(
                                          Icons.favorite_rounded,
                                          color: Color(0xffff6f8f)),
                                      title: Text(emotion.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Color(0xffc9899d),
                                              fontWeight: FontWeight.w800)),
                                      onTap: () => onSelect(emotion),
                                      trailing: Wrap(
                                        spacing: 0,
                                        children: [
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.show_chart_rounded,
                                                  color: Color(0xffff9ab3)),
                                              onPressed: () => onLog(emotion)),
                                          PopupMenuButton<String>(
                                            icon: const Icon(
                                                Icons.more_vert_rounded,
                                                color: Color(0xffd99aae)),
                                            onSelected: (value) {
                                              if (value == 'rename')
                                                onRename(emotion);
                                              if (value == 'delete')
                                                onDelete(emotion);
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                  value: 'rename',
                                                  child: Text('이름 변경')),
                                              PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('삭제')),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class Orb extends StatelessWidget {
  const Orb(
      {super.key,
      required this.controller,
      required this.energy,
      required this.pulse,
      required this.label});
  final AnimationController controller;
  final double energy;
  final int pulse;
  final String label;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(end: energy),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, smoothEnergy, _) {
          final base = Color.lerp(
              const Color(0xff8ecbff), const Color(0xffff9daf), smoothEnergy)!;
          return AnimatedBuilder(
            animation: controller,
            builder: (_, __) => SizedBox(
              width: 310,
              height: 310,
              child: Transform.scale(
                scale: 1 + smoothEnergy * .16,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(280, 280),
                      painter: _OrbPainter(
                        progress: controller.value,
                        energy: smoothEnergy,
                        color: base,
                        pulse: pulse,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(pulse),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
                      builder: (context, beat, child) {
                        final pop = math.sin(beat * math.pi);
                        return Transform.scale(
                          scale: 1 + pop * .13 + smoothEnergy * .08,
                          child: Opacity(
                            opacity: .86 + pop * .14,
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 132,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.94),
                            fontSize: (label.characters.length > 5 ? 21 : 25) +
                                smoothEnergy * 4,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                            shadows: [
                              Shadow(
                                color: const Color(0xffff8fab).withOpacity(.35),
                                blurRadius: 16,
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
        },
      );
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(
      {required this.progress,
      required this.energy,
      required this.color,
      required this.pulse});
  final double progress;
  final double energy;
  final Color color;
  final int pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = (progress + pulse * .137) % 1.0;
    final glowPaint = Paint()
      ..color = color.withOpacity(.15 + energy * .16)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 26 + energy * 28);
    canvas.drawCircle(center, 78 + energy * 18, glowPaint);

    for (var i = 0; i < 3; i++) {
      final phase = ((t + i / 3) % 1.0);
      final radius = 78 + phase * (70 + energy * 42);
      final opacity = (1 - phase).clamp(0.0, 1.0) * (.20 + energy * .20);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = color.withOpacity(opacity),
      );
    }

    final bodyGradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(.96),
        color.withOpacity(.92),
        color.withOpacity(.55)
      ],
      stops: const [.0, .55, 1],
    ).createShader(Rect.fromCircle(center: center, radius: 86));
    canvas.drawCircle(center, 72 + energy * 10, Paint()..shader = bodyGradient);

    canvas.drawCircle(center.translate(-22, -28), 13 + energy * 3,
        Paint()..color = Colors.white.withOpacity(.62));
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.progress != progress ||
      old.energy != energy ||
      old.color != color ||
      old.pulse != pulse;
}
