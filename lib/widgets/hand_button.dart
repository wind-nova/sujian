import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

// ─────────────────────────────────────────────────────────────
// 手绘按钮：一颗不闭合的椭圆，笔画有粗细变化
// ─────────────────────────────────────────────────────────────

class HandOvalButton extends StatelessWidget {
  final String label;
  final String? latin;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const HandOvalButton({
    super.key,
    required this.label,
    this.latin,
    this.onTap,
    this.width = 206,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: CustomPaint(painter: _OvalPainter())),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 4.2,
                    color: C.text1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (latin != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    latin!,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: C.text2,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rnd = Random(4211);

    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final a = t * 2 * pi - pi / 2;
      final wobble = 1 + (sin(a * 2.3) * 0.012 + (rnd.nextDouble() - 0.5) * 0.008);
      final taper = 0.985 + 0.015 * sin(t * pi);
      final rx = (w / 2 - 1.2) * wobble * taper;
      final ry = (h / 2 - 1.2) * wobble * taper;
      final px = w / 2 + cos(a) * rx;
      final py = h / 2 + sin(a) * ry;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = C.surfaceCard.withAlpha(252),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..color = C.text1.withAlpha(140),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ─────────────────────────────────────────────────────────────
// 手绘图标
// ─────────────────────────────────────────────────────────────

enum HandIcon { menu, drafts, back, arrow, save, pdf, share, pen, bookmark, plus, trash }

class HandGlyph extends StatelessWidget {
  final HandIcon type;
  final double size;
  final Color? color;
  final double opacity;

  const HandGlyph(
    this.type, {
    super.key,
    this.size = 22,
    this.color,
    this.opacity = 0.78,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? C.text1;
    return CustomPaint(
      size: Size(size, size),
      painter: _GlyphPainter(type, c.withAlpha((opacity * 255).round())),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  final HandIcon type;
  final Color color;

  _GlyphPainter(this.type, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    switch (type) {
      case HandIcon.menu:
        canvas.drawPath(
          Path()
            ..moveTo(4.6, 8.1)
            ..quadraticBezierTo(11.4, 7.7, 19.4, 8.2),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4.9, 12.1)
            ..quadraticBezierTo(11.8, 11.6, 19.1, 12.2),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4.7, 16.1)
            ..quadraticBezierTo(10.2, 15.6, 16.4, 16.2),
          stroke,
        );
        break;

      case HandIcon.drafts:
        canvas.drawPath(
          Path()
            ..moveTo(7.2, 5.2)
            ..lineTo(16.3, 5.4)
            ..lineTo(16.8, 17.6)
            ..lineTo(7.5, 17.9)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5.1, 7.4)
            ..lineTo(14.3, 7.6)
            ..lineTo(14.8, 19.7)
            ..lineTo(5.3, 19.9)
            ..close(),
          stroke,
        );
        break;

      case HandIcon.back:
        canvas.drawPath(
          Path()
            ..moveTo(14.9, 6.1)
            ..quadraticBezierTo(10.8, 9.2, 6.9, 12.1)
            ..quadraticBezierTo(10.9, 15.0, 15.0, 18.0),
          stroke,
        );
        break;

      case HandIcon.arrow:
        canvas.drawPath(
          Path()
            ..moveTo(5.2, 16.4)
            ..quadraticBezierTo(12.6, 15.4, 17.6, 8.4),
          stroke,
        );
        canvas.drawLine(const Offset(13.1, 6.9), const Offset(18, 11.8), stroke);
        break;

      case HandIcon.save:
        canvas.drawLine(const Offset(12, 4.4), const Offset(12, 15.2), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(8, 11.2)
            ..lineTo(12, 15.3)
            ..lineTo(16, 11.0),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5.0, 17.2)
            ..lineTo(5.0, 18.6)
            ..lineTo(19.0, 18.6)
            ..lineTo(19.0, 17.2),
          stroke,
        );
        break;

      case HandIcon.pdf:
        canvas.drawPath(
          Path()
            ..moveTo(6.4, 4.0)
            ..lineTo(13.6, 4.2)
            ..lineTo(17.8, 8.6)
            ..lineTo(17.6, 20.0)
            ..lineTo(6.4, 20.0)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(13.3, 4.4)
            ..lineTo(13.2, 8.7)
            ..lineTo(17.4, 8.8),
          stroke,
        );
        canvas.drawLine(const Offset(9.0, 13.4), const Offset(15.0, 13.4), stroke);
        canvas.drawLine(const Offset(9.0, 16.4), const Offset(13.0, 16.4), stroke);
        break;

      case HandIcon.share:
        canvas.drawCircle(const Offset(17.6, 5.9), 2.5, stroke);
        canvas.drawCircle(const Offset(6.4, 12.1), 2.5, stroke);
        canvas.drawCircle(const Offset(17.6, 18.3), 2.5, stroke);
        canvas.drawLine(const Offset(8.7, 10.9), const Offset(15.3, 7.2), stroke);
        canvas.drawLine(const Offset(8.7, 13.3), const Offset(15.3, 17.0), stroke);
        break;

      case HandIcon.pen:
        canvas.drawPath(
          Path()
            ..moveTo(14.4, 4.6)
            ..lineTo(19.4, 9.6)
            ..lineTo(10.6, 18.5)
            ..lineTo(5.1, 19.6)
            ..lineTo(6.1, 14.0)
            ..close(),
          stroke,
        );
        canvas.drawLine(const Offset(13.1, 6.9), const Offset(18, 11.8), stroke);
        break;

      case HandIcon.bookmark:
        // 手绘书签：底端缺口略不对称，像随手剪的
        canvas.drawPath(
          Path()
            ..moveTo(7.8, 3.8)
            ..lineTo(16.1, 4.2)
            ..lineTo(16.0, 19.6)
            ..lineTo(12.1, 16.2)
            ..lineTo(7.9, 19.8)
            ..close(),
          stroke,
        );
        break;

      case HandIcon.plus:
        canvas.drawLine(const Offset(12, 5.2), const Offset(12, 18.8), stroke);
        canvas.drawLine(const Offset(5.2, 12), const Offset(18.8, 12), stroke);
        break;

      case HandIcon.trash:
        canvas.drawLine(const Offset(5.4, 7.2), const Offset(18.6, 7.0), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(9.4, 7.0)
            ..lineTo(9.6, 4.4)
            ..lineTo(14.4, 4.6)
            ..lineTo(14.6, 7.0),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(7.0, 8.6)
            ..lineTo(7.8, 19.6)
            ..lineTo(16.4, 19.4)
            ..lineTo(17.0, 8.6),
          stroke,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.type != type || old.color != color;
}
