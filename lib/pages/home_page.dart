import 'dart:math';

import 'package:flutter/material.dart';

import '../data/store.dart';
import '../render/exporter.dart';
import '../render/ornaments.dart';
import '../theme.dart';
import '../theme/skin.dart';
import '../widgets/hand_button.dart';
import 'editor_page.dart';
import 'gallery_page.dart';
import 'result_page.dart';
import 'skin_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _caret;
  final GlobalKey<ScaffoldState> _scaffold = GlobalKey<ScaffoldState>();
  bool _flipping = false;

  @override
  void initState() {
    super.initState();
    _caret = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))
      ..repeat();
  }

  @override
  void dispose() {
    _caret.dispose();
    super.dispose();
  }

  // ───────────── 导航 ─────────────
  void _openEditor({Entry? entry}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, __, ___) => EditorPage(entry: entry),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: const Cubic(0.22, 1.2, 0.36, 1));
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.97, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openGallery() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GalleryPage()));
  }

  void _openSkin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SkinPage()));
  }

  /// 随便翻一篇：随机打开以前写过的某一页（不会再抽到最近那篇）
  Future<void> _flipRandom() async {
    final store = EntryStore.instance;
    if (store.isEmpty || _flipping) return;
    final pool = store.count > 1 ? store.entries.skip(1).toList() : store.entries;
    final e = pool[Random().nextInt(pool.length)];
    setState(() => _flipping = true);
    try {
      final img = await renderPageImage(e.toDoc(), 0, 1620);
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() => _flipping = false);
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultPage(
          entry: e,
          initialImage: img,
          initialPage: 0,
          fromEditor: false,
        ),
      ));
      if (mounted) img.dispose();
    } catch (_) {
      if (mounted) setState(() => _flipping = false);
    }
  }

  void _about() {
    showDialog<void>(context: context, builder: (_) => _AboutDialog());
  }

  @override
  Widget build(BuildContext context) {
    final store = EntryStore.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([store, SkinStore.instance]),
      builder: (context, _) {
        return Scaffold(
          key: _scaffold,
          drawer: _MenuDrawer(
            count: store.count,
            onGallery: () {
              Navigator.of(context).pop();
              _openGallery();
            },
            onSkin: () {
              Navigator.of(context).pop();
              _openSkin();
            },
            onAbout: () {
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 180), _about);
            },
          ),
          body: Container(
            decoration: SujianTheme.ambientBg,
            child: SafeArea(
              child: Column(
                children: [
                  _topBar(store),
                  Expanded(child: _stage(store)),
                  _footer(store),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(EntryStore store) {
    final hasHistory = store.isNotEmpty;
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _iconButton(
              HandGlyph(HandIcon.menu, opacity: 0.78),
              () => _scaffold.currentState?.openDrawer(),
            ),
            Text(
              '· 素 笺 ·',
              style: TextStyle(
                fontSize: 15,
                letterSpacing: 5.2,
                color: C.text1.withAlpha(230),
                fontFamily: C.serif,
                fontWeight: FontWeight.w300,
              ),
            ),
            _iconButton(
              HandGlyph(HandIcon.bookmark, opacity: hasHistory ? 0.72 : 0.22),
              hasHistory && !_flipping ? _flipRandom : null,
              busy: _flipping,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(Widget glyph, VoidCallback? onTap, {bool busy = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.3, color: C.text3),
                )
              : glyph,
        ),
      ),
    );
  }

  Widget _stage(EntryStore store) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 34),
          child: Center(
            child: AspectRatio(
              aspectRatio: 0.5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (store.count > 1)
                    Positioned(left: 16, right: 16, top: 20, bottom: -20, child: _underSheet(2)),
                  if (store.count > 0)
                    Positioned(left: 8, right: 8, top: 10, bottom: -10, child: _underSheet(1)),
                  Positioned.fill(
                    child: GestureDetector(onTap: () => _openEditor(), child: _paper()),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          child: HandOvalButton(
            label: '书 写',
            latin: 'Write',
            onTap: () => _openEditor(),
          ),
        ),
      ],
    );
  }

  /// 纸堆：越往下越淡，暗示"我写过东西"
  Widget _underSheet(int depth) {
    return Container(
      decoration: BoxDecoration(
        color: Color.lerp(C.paperCream, C.ambient1, depth * 0.10),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(color: Color(0x263C3223), blurRadius: 14, offset: Offset(0, 6), spreadRadius: -6),
        ],
      ),
    );
  }

  Widget _paper() {
    return Container(
      decoration: BoxDecoration(
        color: C.paperCream,
        borderRadius: BorderRadius.circular(3),
        boxShadow: SujianTheme.paperShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _HomePaperPainter())),

            const Positioned(left: 14, top: 13, child: CornerPin(size: 21, angle: -0.14)),
            const Positioned(right: 15, top: 15, child: CornerFlower(size: 21, angle: 0.42)),
            const Positioned(left: 16, bottom: 14, child: CornerFlower(size: 18, angle: 0.9, opacity: 0.45)),
            const Positioned(right: 13, bottom: 12, child: CornerPin(size: 19, angle: 0.16)),

            Column(
              children: [
                const SizedBox(height: 116),
                SizedBox(width: 132, height: 132, child: CustomPaint(painter: _PenIllustration())),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '记录此刻的心情',
                      style: TextStyle(
                        fontFamily: 'KaiXin',
                        fontSize: 26,
                        color: C.text1.withAlpha(240),
                        letterSpacing: 1.6,
                        height: 1.2,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _caret,
                      builder: (_, __) => Container(
                        width: 1.6,
                        height: 22,
                        margin: const EdgeInsets.only(left: 4),
                        color: _caret.value < 0.52 ? C.text2 : Colors.transparent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '粘 贴 你 的 文 字 …',
                  style: TextStyle(fontSize: 12, letterSpacing: 2.6, color: C.text3),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 74, right: 26),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 52,
                      height: 40,
                      child: CustomPaint(painter: _ArrowPainter()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(EntryStore store) {
    final has = store.isNotEmpty;
    final latest = store.latest;
    final text = has
        ? '已写下 ${store.count} 篇 · 上次是 ${latest!.updatedAt.month} 月 ${latest.updatedAt.day} 日'
        : '今天还没有留下任何文字';
    return SizedBox(
      height: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: has ? _openGallery : null,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 1.7,
                  color: has ? C.text2 : C.text3.withAlpha(140),
                ),
              ),
              if (has) ...[
                const SizedBox(width: 5),
                Text('›', style: TextStyle(fontSize: 13, color: C.text3, height: 1)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── 左侧抽屉 ─────────────────────────
class _MenuDrawer extends StatelessWidget {
  final int count;
  final VoidCallback onGallery;
  final VoidCallback onSkin;
  final VoidCallback onAbout;

  const _MenuDrawer({
    required this.count,
    required this.onGallery,
    required this.onSkin,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    final skin = SkinStore.instance.current;
    return Drawer(
      width: 268,
      backgroundColor: C.surfaceCard,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 20),
              child: Text(
                '· 素 笺 ·',
                style: TextStyle(
                  fontFamily: C.serif,
                  fontSize: 13,
                  letterSpacing: 3.4,
                  color: C.text1.withAlpha(210),
                ),
              ),
            ),
            Divider(height: 1, color: C.hairline),
            _item('作品集', count > 0 ? '$count 篇' : '空', onGallery),
            _item('主题', skin.name, onSkin),
            _item('关于素笺', '', onAbout),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 22),
              child: Text(
                '你的文字只存在这台手机上。\n不联网 · 不上传 · 不需要权限',
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.9,
                  letterSpacing: 1.1,
                  color: C.text3.withAlpha(190),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String label, String note, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 12.5, letterSpacing: 1.2, color: C.text1)),
            const Spacer(),
            if (note.isNotEmpty)
              Text(note, style: TextStyle(fontSize: 10, letterSpacing: 0.4, color: C.text3)),
          ],
        ),
      ),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: C.surfaceCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '素笺',
              style: TextStyle(fontFamily: C.serif, fontSize: 20, letterSpacing: 6, color: C.text1),
            ),
            const SizedBox(height: 10),
            Text(
              '把心事写回纸上。',
              style: TextStyle(fontSize: 12, height: 2, color: C.text2, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            Text(
              'v1.1 · 全部本地渲染\n'
              '不联网 · 不上传 · Android 10 以上不需要任何权限\n'
              '手写字库：KaiXin（待授权）/ 马善政 / 志莽行书 / 龙藏 / 站酷快乐体（后四款 SIL OFL）',
              style: TextStyle(fontSize: 10.5, height: 1.9, color: C.text3),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('好', style: TextStyle(fontSize: 12, color: C.accent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 背景绘制 ─────────────────────────
class _HomePaperPainter extends CustomPainter {
  const _HomePaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final line = Paint()
      ..color = const Color(0xFF7E9EB6).withAlpha(46)
      ..strokeWidth = 1;
    for (var y = 96.0; y < h; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(w, y), line);
    }

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          radius: 1.02,
          colors: [Colors.transparent, const Color(0xFF4A3A24).withAlpha(31)],
          stops: const [0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 56;
    canvas.scale(s);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xA67A7368);
    canvas.drawPath(
      Path()
        ..moveTo(6, 6)
        ..quadraticBezierTo(26, 8, 32, 20)
        ..quadraticBezierTo(36.6, 29, 29, 36),
      p,
    );
    canvas.drawPath(Path()..moveTo(29, 31.5)..lineTo(29, 37.1)..lineTo(35, 36), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PenIllustration extends CustomPainter {
  const _PenIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 140;
    canvas.scale(s);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xE64E483E);

    canvas.drawPath(
      Path()
        ..moveTo(20, 118)
        ..quadraticBezierTo(70, 114.5, 120, 118.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x524E483E),
    );

    canvas.save();
    canvas.translate(70, 72);
    canvas.rotate(-26 * pi / 180);
    canvas.translate(-70, -72);

    final body = Path()
      ..moveTo(68.6, 32)
      ..quadraticBezierTo(75.5, 27.4, 82.4, 32)
      ..lineTo(82.0, 96)
      ..quadraticBezierTo(75.8, 107, 75.6, 116)
      ..quadraticBezierTo(75.4, 107, 69.0, 96)
      ..close();

    canvas.drawPath(body, Paint()..color = const Color(0x66F7F4EA));
    canvas.drawPath(body, stroke);
    canvas.drawLine(const Offset(69.5, 84), const Offset(81.5, 84), stroke);
    canvas.drawLine(const Offset(75.6, 60), const Offset(75.6, 70), stroke);
    canvas.drawPath(
      Path()
        ..moveTo(82.6, 38)
        ..quadraticBezierTo(88.4, 40, 87.8, 50),
      stroke,
    );

    canvas.restore();

    canvas.drawCircle(const Offset(103, 103), 2.1, Paint()..color = const Color(0x804E483E));
    canvas.drawCircle(const Offset(34, 96), 1.5, Paint()..color = const Color(0x594E483E));
    canvas.drawCircle(const Offset(41, 30), 1.2, Paint()..color = const Color(0x484E483E));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
