import 'package:flutter/material.dart';

import '../model.dart';
import 'ink_painter.dart';
import 'paper_painter.dart';

/// 一张纸：纸层被 RepaintBoundary 缓存，只有墨层随参数重绘
class SujianSheet extends StatelessWidget {
  final PageDoc doc;
  final int page;
  final bool ornaments;

  const SujianSheet({
    super.key,
    required this.doc,
    this.page = 0,
    this.ornaments = true,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kPageW / kPageH,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: PaperPainter(doc.paper, ornaments: ornaments),
              ),
            ),
            CustomPaint(painter: InkPainter(doc, page: page)),
          ],
        ),
      ),
    );
  }
}
