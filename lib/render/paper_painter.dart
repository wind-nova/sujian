import 'dart:math';

import 'package:flutter/material.dart';

import '../model.dart';
import 'ornaments.dart';
import 'texture.dart';

/// 纸层（L1 纸基 + L2 印刷 + L4 光照 + L5 装饰）
/// 这一层是静态的：换纸才重绘，被 RepaintBoundary 缓存。
class PaperPainter extends CustomPainter {
  final PaperType type;
  final bool ornaments;

  const PaperPainter(this.type, {this.ornaments = true});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / kPageW;
    canvas.save();
    canvas.scale(s);
    paintPaper(canvas, type, const Size(kPageW, kPageH), ornaments: ornaments);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PaperPainter old) =>
      old.type != type || old.ornaments != ornaments;

  // ────────────────────────────────────────────────────────────
  static void paintPaper(
    Canvas c,
    PaperType type,
    Size size, {
    bool ornaments = true,
  }) {
    final spec = type.spec;
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    c.drawRect(rect, Paint()..color = spec.base);

    _mottle(c, size, type);
    switch (type) {
      case PaperType.ruled:
        _ruled(c, size);
        break;
      case PaperType.grid:
        _grid(c, size);
        break;
      case PaperType.kraft:
        _kraft(c, size);
        break;
      case PaperType.vintage:
        _vintage(c, size);
        break;
      case PaperType.sketch:
        break;
    }
    _grain(c, size, type);
    _edge(c, size, type);
    _light(c, size);

    if (ornaments) {
      drawPin(c, const Offset(40, 42), 9.5, -0.18);
      drawFlower(c, Offset(w - 40, 44), 8.5, 0.30);
      drawFlower(c, Offset(42, h - 42), 7.2, 0.80, opacity: 0.55);
      drawPin(c, Offset(w - 40, h - 40), 8.6, 0.14);
    }
  }

  /// 低频云斑：模拟纸浆纤维分布的明暗不匀
  static void _mottle(Canvas c, Size size, PaperType type) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final strength = type == PaperType.kraft ? 0.11 : 0.07;

    const spots = <List<double>>[
      [0.18, 0.12, 0.55, 1],
      [0.82, 0.20, 0.46, 0],
      [0.34, 0.52, 0.62, 1],
      [0.76, 0.70, 0.52, 1],
      [0.24, 0.88, 0.44, 0],
      [0.58, 0.36, 0.38, 0],
      [0.50, 0.96, 0.40, 1],
      [0.90, 0.88, 0.32, 0],
    ];

    for (final s in spots) {
      final center = Offset(s[0] * w, s[1] * h);
      final radius = s[2] * w;
      final base = s[3] > 0.5 ? Colors.white : const Color(0xFF6A5436);
      final color = base.withAlpha((strength * 255).round());
      final shader = RadialGradient(
        colors: [color, color.withAlpha(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      c.drawRect(rect, Paint()..shader = shader..blendMode = BlendMode.overlay);
    }
  }

  /// 横线本：蓝灰横线 + 朱红页边线
  static void _ruled(Canvas c, Size size) {
    final spec = PaperType.ruled.spec;
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..color = const Color(0xFF7E9EB6).withAlpha(107)
      ..strokeWidth = 1.15;

    for (var y = spec.top + spec.lineH; y < h - spec.bottom + 20; y += spec.lineH) {
      c.drawLine(Offset(spec.side - 26, y), Offset(w - spec.side + 26, y), stroke);
    }

    c.drawLine(
      Offset(spec.side - 34, spec.top - 24),
      Offset(spec.side - 34, h - spec.bottom + 26),
      Paint()
        ..color = const Color(0xFFC66054).withAlpha(97)
        ..strokeWidth = 1.2,
    );
  }

  /// 方格纸
  static void _grid(Canvas c, Size size) {
    final spec = PaperType.grid.spec;
    final w = size.width;
    final h = size.height;
    const step = 48.0;

    final stroke = Paint()
      ..color = const Color(0xFF8CA8B8).withAlpha(87)
      ..strokeWidth = 0.9;

    for (var y = spec.top; y < h - spec.bottom + 24; y += step) {
      c.drawLine(Offset(spec.side - 26, y), Offset(w - spec.side + 26, y), stroke);
    }
    for (var x = spec.side - 26; x < w - spec.side + 28; x += step) {
      c.drawLine(Offset(x, spec.top - 20), Offset(x, h - spec.bottom + 24), stroke);
    }
  }

  /// 牛皮纸：纤维丝 + 上下压暗
  static void _kraft(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final rnd = Random(7712);

    for (var i = 0; i < 900; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * h;
      final len = 4 + rnd.nextDouble() * 26;
      final ang = (rnd.nextDouble() - 0.5) * 0.5;
      final light = rnd.nextBool();
      c.drawLine(
        Offset(x, y),
        Offset(x + cos(ang) * len, y + sin(ang) * len),
        Paint()
          ..color = (light ? const Color(0xFFFFF0D6) : const Color(0xFF60442A))
              .withAlpha(light ? 40 : 34)
          ..strokeWidth = rnd.nextDouble() * 0.9 + 0.25,
      );
    }

    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF583A1E).withAlpha(41),
            const Color(0xFF583A1E).withAlpha(0),
            const Color(0xFF583A1E).withAlpha(0),
            const Color(0xFF583A1E).withAlpha(51),
          ],
          stops: const [0.0, 0.12, 0.88, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  /// 复古信纸：霉斑 + 顶部小纹章
  static void _vintage(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final rnd = Random(3391);

    for (var i = 0; i < 26; i++) {
      final center = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
      final r = 12 + rnd.nextDouble() * 74;
      final alpha = ((0.02 + rnd.nextDouble() * 0.045) * 255).round();
      final color = const Color(0xFF966834).withAlpha(alpha);
      c.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withAlpha(0)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    final ink = Paint()
      ..color = const Color(0xFF8C6840).withAlpha(107)
      ..strokeWidth = 0.9;
    c.drawLine(Offset(w / 2 - 74, 74), Offset(w / 2 + 74, 74), ink);

    final diamond = Path()
      ..moveTo(w / 2 - 4, 70)
      ..lineTo(w / 2 + 4, 74)
      ..lineTo(w / 2 - 4, 78)
      ..close();
    c.drawPath(diamond, Paint()..color = const Color(0xFF8C6840).withAlpha(107));
  }

  /// 高频颗粒
  static void _grain(Canvas c, Size size, PaperType type) {
    final shader = TextureKit.grainShader;
    if (shader == null) return;
    final alpha = type == PaperType.sketch
        ? 0.30
        : (type == PaperType.kraft ? 0.22 : 0.17);
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.overlay
        ..color = Colors.white.withAlpha((alpha * 255).round()),
    );
  }

  /// 纸边毛边
  static void _edge(Canvas c, Size size, PaperType type) {
    final w = size.width;
    final h = size.height;
    const e = 22.0;
    final col = (type == PaperType.kraft
            ? const Color(0xFF3C2614)
            : const Color(0xFF786448))
        .withAlpha(33);

    void band(Rect r, Alignment from, Alignment to) {
      c.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: from,
            end: to,
            colors: [col, col.withAlpha(0)],
          ).createShader(r),
      );
    }

    band(Rect.fromLTWH(0, 0, e, h), Alignment.centerLeft, Alignment.centerRight);
    band(Rect.fromLTWH(w - e, 0, e, h), Alignment.centerRight, Alignment.centerLeft);
    band(Rect.fromLTWH(0, 0, w, e), Alignment.topCenter, Alignment.bottomCenter);
    band(Rect.fromLTWH(0, h - e, w, e), Alignment.bottomCenter, Alignment.topCenter);
  }

  /// 暗角 + 暖光
  static void _light(Canvas c, Size size) {
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.1, -0.14),
          radius: 1.05,
          colors: [
            Colors.transparent,
            const Color(0xFF46372B).withAlpha(9),
            const Color(0xFF3A2C1A).withAlpha(43),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(Offset.zero & size),
    );

    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(0.72, 0.86),
          colors: [
            const Color(0xFFFFF7E2).withAlpha(51),
            const Color(0xFFFFF7E2).withAlpha(10),
            const Color(0xFFFFF7E2).withAlpha(0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Offset.zero & size),
    );
  }
}
