import 'dart:math';

import 'package:flutter/material.dart';

import '../render/ornaments.dart';
import '../theme.dart';
import '../widgets/hand_button.dart';
import 'editor_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _caret;

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

  void _openEditor() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, __, ___) => const EditorPage(),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: const Cubic(0.22, 1.2, 0.36, 1),
          );
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(curved), child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: SujianTheme.ambientBg,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                      child: Center(
                        child: AspectRatio(aspectRatio: 0.5, child: _paper()),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      child: HandOvalButton(
                        label: '书 写',
                        latin: 'Write',
                        onTap: _openEditor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 34,
                child: Center(
                  child: Text(
                    '今天还没有留下任何文字',
                    style: TextStyle(fontSize: 9.5, letterSpacing: 1.9, color: Color(0x613E3A34)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _iconButton(const HandGlyph(Glyph.menu), () {}),
            Text(
              '· 素 笺 ·',
              style: TextStyle(
                fontSize: 15,
                letterSpacing: 5.2,
                color: const Color(0xFF4A443B),
                fontFamily: 'Noto Serif SC',
                fontWeight: FontWeight.w300,
              ),
            ),
            _iconButton(const HandGlyph(Glyph.drafts), () {}),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(Widget glyph, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 48, height: 48, child: Center(child: glyph)),
    );
  }

  Widget _paper() {
    return GestureDetector(
      onTap: _openEditor,
      child: Container(
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

              // 四角装饰
              const Positioned(left: 14, top: 13, child: CornerPin(size: 21, angle: -0.14)),
              const Positioned(right: 15, top: 15, child: CornerFlower(size: 21, angle: 0.42)),
              const Positioned(left: 16, bottom: 14, child: CornerFlower(size: 18, angle: 0.9, opacity: 0.5)),
              const Positioned(right: 13, bottom: 12, child: CornerPin(size: 19, angle: 0.16)),

              // 内容
              Column(
                children: [
                  const SizedBox(height: 116),
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: CustomPaint(painter: _PenIllustration()),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '记录此刻的心情',
                        style: TextStyle(
                          fontFamily: 'KaiXin',
                          fontSize: 26,
                          color: Color(0xFF4C463C),
                          letterSpacing: 1.6,
                          height: 1.2,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _caret,
                        builder: (_, __) {
                          final t = _caret.value;
                          final visible = t < 0.52;
                          return Container(
                            width: 1.6,
                            height: 22,
                            margin: const EdgeInsets.only(left: 4),
                            color: visible ? const Color(0xFF8A8377) : Colors.transparent,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '粘 贴 你 的 文 字 …',
                    style: TextStyle(fontSize: 12, letterSpacing: 2.6, color: C.text3),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 74, right: 26),
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
      ),
    );
  }
}

/// 空白信纸：极淡横线 + 暗角
class _HomePaperPainter extends CustomPainter {
  const _HomePaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final line = Paint()
      ..color = const Color(0xFF7E9EB6).withAlpha(48)
      ..strokeWidth = 1;
    for (var y = 96.0; y < h; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(w, y), line);
    }

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          radius: 1.02,
          colors: [Colors.transparent, const Color(0xFF4A3A24).withAlpha(33)],
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
    canvas.drawPath(
      Path()
        ..moveTo(29, 31.5)
        ..lineTo(29, 37.1)
        ..lineTo(35, 36),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// 手绘钢笔
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

    // 纸面基线
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

    // 笔握分割线
    canvas.drawLine(const Offset(69.5, 84), const Offset(81.5, 84), stroke);
    // 墨水中缝
    canvas.drawLine(const Offset(75.6, 60), const Offset(75.6, 70), stroke);
    // 笔夹
    canvas.drawPath(
      Path()
        ..moveTo(82.6, 38)
        ..quadraticBezierTo(88.4, 40, 87.8, 50),
      stroke,
    );

    canvas.restore();

    // 墨点
    final dot = Paint()..color = const Color(0x804E483E);
    canvas.drawCircle(const Offset(103, 103), 2.1, dot);
    canvas.drawCircle(const Offset(34, 96), 1.5, dot..color = const Color(0x594E483E));
    canvas.drawCircle(const Offset(41, 30), 1.2, dot..color = const Color(0x484E483E));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
