import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// 红色小图钉
void drawPin(Canvas c, Offset o, double r, double angle) {
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(angle);

  // 投影
  c.drawOval(
    Rect.fromCenter(center: Offset(r * 0.16, r * 0.34), width: r * 2, height: r * 1.8),
    Paint()
      ..color = const Color(0x4D4E301C)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6),
  );

  // 帽体
  final body = Rect.fromCircle(center: Offset.zero, radius: r);
  c.drawCircle(
    Offset.zero,
    r,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.36, -0.42),
        radius: 0.95,
        colors: [Color(0xFFE2705C), Color(0xFFC2453A), Color(0xFF8B2A21)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(body),
  );

  // 边缘
  c.drawCircle(
    Offset.zero,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09
      ..color = const Color(0x6B581811),
  );

  // 高光
  c.drawOval(
    Rect.fromCenter(
      center: Offset(-r * 0.34, -r * 0.38),
      width: r * 0.46,
      height: r * 0.30,
    ),
    Paint()..color = const Color(0xB8FFECDE),
  );

  c.restore();
}

/// 五瓣小红花
void drawFlower(Canvas c, Offset o, double r, double angle, {double opacity = 0.80}) {
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(angle);

  final petal = Paint()..color = C.accent.withAlpha((opacity * 255).round());
  for (var i = 0; i < 5; i++) {
    c.save();
    c.rotate(i * 2 * pi / 5);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, -r * 0.56),
        width: r * 0.72,
        height: r * 1.10,
      ),
      petal,
    );
    c.restore();
  }
  c.drawCircle(Offset.zero, r * 0.22, Paint()..color = const Color(0xFFF6E2BE));
  c.restore();
}

/// 首页四角装饰用的小组件
class CornerPin extends StatelessWidget {
  final double size;
  final double angle;
  const CornerPin({super.key, this.size = 22, this.angle = -0.15});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _PinPainter(angle),
      );
}

class CornerFlower extends StatelessWidget {
  final double size;
  final double angle;
  final double opacity;
  const CornerFlower({
    super.key,
    this.size = 22,
    this.angle = 0.3,
    this.opacity = 0.70,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _FlowerPainter(angle, opacity),
      );
}

class _PinPainter extends CustomPainter {
  final double angle;
  _PinPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) =>
      drawPin(canvas, size.center(Offset.zero), size.width * 0.42, angle);

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.angle != angle;
}

class _FlowerPainter extends CustomPainter {
  final double angle;
  final double opacity;
  _FlowerPainter(this.angle, this.opacity);

  @override
  void paint(Canvas canvas, Size size) =>
      drawFlower(canvas, size.center(Offset.zero), size.width * 0.38, angle, opacity: opacity);

  @override
  bool shouldRepaint(covariant _FlowerPainter old) =>
      old.angle != angle || old.opacity != opacity;
}
