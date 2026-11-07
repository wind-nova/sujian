import 'package:flutter/material.dart';

import '../theme.dart';

/// 手绘椭圆按钮（首页「书写」）
class HandOvalButton extends StatefulWidget {
  final String label;
  final String? latin;
  final VoidCallback onTap;

  const HandOvalButton({
    super.key,
    required this.label,
    required this.onTap,
    this.latin,
  });

  @override
  State<HandOvalButton> createState() => _HandOvalButtonState();
}

class _HandOvalButtonState extends State<HandOvalButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 214,
          height: 58,
          child: CustomPaint(
            painter: _OvalPainter(),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A443B),
                    ),
                  ),
                  if (widget.latin != null) const SizedBox(width: 8),
                  if (widget.latin != null)
                    Text(
                      widget.latin!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: C.text2,
                      ),
                    ),
                ],
              ),
            ),
          ),
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

    final path = Path()
      ..moveTo(w * 0.5, 2.6)
      ..cubicTo(w * 0.79, 3.8, w - 3.2, h * 0.29, w - 3.0, h * 0.51)
      ..cubicTo(w - 2.8, h * 0.74, w * 0.75, h - 3.0, w * 0.49, h - 3.2)
      ..cubicTo(w * 0.23, h - 3.4, 3.2, h * 0.75, 3.0, h * 0.50)
      ..cubicTo(2.8, h * 0.27, w * 0.21, 3.2, w * 0.5, 2.6)
      ..close();

    canvas.drawShadow(path, const Color(0x334A3820), 10, true);
    canvas.drawPath(path, Paint()..color = const Color(0xFFFCFAF4));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x8C4A443B),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// 手绘图标集
// ─────────────────────────────────────────────────────────────

enum HandIcon { menu, drafts, back, arrow, save, pdf, share, pen }

class HandGlyph extends StatelessWidget {
  final HandIcon type;
  final double size;
  final Color color;
  final double opacity;

  const HandGlyph(
    this.type, {
    super.key,
    this.size = 22,
    this.color = C.text1,
    this.opacity = 0.78,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _GlyphPainter(type, color.withAlpha((opacity * 255).round())),
      );
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
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    switch (type) {
      case HandIcon.menu:
        for (final y in [8.1, 12.1, 16.1]) {
          final right = y > 16 ? 16.4 : 19.2;
          canvas.drawPath(
            Path()
              ..moveTo(4.7, y)
              ..quadraticBezierTo(12, y - 0.5, right, y + 0.15),
            stroke,
          );
        }
        break;

      case HandIcon.drafts:
        canvas.drawRRect(
          RRect.fromLTRBR(7.2, 5.2, 16.3, 17.4, const Radius.circular(1)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..color = color.withAlpha(90),
        );
        canvas.drawRRect(
          RRect.fromLTRBR(5.1, 7.4, 14.3, 19.5, const Radius.circular(1)),
          stroke,
        );
        break;

      case HandIcon.back:
        canvas.drawPath(
          Path()
            ..moveTo(15.1, 5.9)
            ..quadraticBezierTo(10.9, 9.1, 6.9, 12.1)
            ..quadraticBezierTo(11, 15.1, 15.2, 18.2),
          stroke,
        );
        break;

      case HandIcon.arrow:
        canvas.drawPath(
          Path()
            ..moveTo(3, 3)
            ..quadraticBezierTo(16, 4, 19, 11)
            ..quadraticBezierTo(21.5, 16.5, 15.5, 19.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(15.2, 14.6)
            ..lineTo(15.5, 19.8)
            ..lineTo(20.4, 18.6),
          stroke,
        );
        break;

      case HandIcon.save:
        canvas.drawLine(const Offset(12, 3.6), const Offset(12, 14.4), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(8, 10.6)
            ..lineTo(12, 14.7)
            ..lineTo(16, 10.4),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4.6, 17.2)
            ..lineTo(4.6, 18.8)
            ..quadraticBezierTo(4.6, 20.4, 6.3, 20.4)
            ..lineTo(17.7, 20.4)
            ..quadraticBezierTo(19.4, 20.4, 19.4, 18.8)
            ..lineTo(19.4, 17.2),
          stroke,
        );
        break;

      case HandIcon.pdf:
        canvas.drawPath(
          Path()
            ..moveTo(6.2, 3.6)
            ..lineTo(13.6, 3.6)
            ..lineTo(18, 8.1)
            ..lineTo(18, 20.4)
            ..lineTo(6.2, 20.4)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(13.4, 3.8)
            ..lineTo(13.4, 8.2)
            ..lineTo(17.7, 8.2),
          stroke,
        );
        canvas.drawLine(const Offset(9, 13.6), const Offset(15, 13.6), stroke);
        canvas.drawLine(const Offset(9, 16.6), const Offset(13.2, 16.6), stroke);
        break;

      case HandIcon.share:
        for (final o in const [
          Offset(17.6, 5.9),
          Offset(6.4, 12.1),
          Offset(17.6, 18.3),
        ]) {
          canvas.drawCircle(o, 2.5, stroke);
        }
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
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.type != type || old.color != color;
}
