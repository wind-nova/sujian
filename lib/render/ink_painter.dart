import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../model.dart';
import 'rng.dart';

/// 一个字形在纸上的最终落点（不含抖动，抖动在绘制时才施加）
class GlyphSlot {
  final String ch;
  final double x;
  final double baseY;
  final double cw;
  final int page;
  final int index;

  const GlyphSlot({
    required this.ch,
    required this.x,
    required this.baseY,
    required this.cw,
    required this.page,
    required this.index,
  });
}

class PageLayout {
  final List<GlyphSlot> slots;
  final int pageCount;

  const PageLayout(this.slots, this.pageCount);
}

class _Glyph {
  final TextPainter tp;
  final double baseline;

  const _Glyph(this.tp, this.baseline);
}

/// 不能出现在行首的标点（避头尾）
const Set<String> _hang = {
  '，', '。', '、', '；', '：', '？', '！', '）', '】', '》', '」', '』', '”', '’', '…', '·',
  ',', '.', '!', '?', ':', ';', ')', ']', '}', '%',
};

const List<int> _alphaLevels = [214, 240, 255];

/// ─────────────────────────────────────────────────────────────
/// 墨层（L3）：逐字变换 + 两遍晕染合成
/// ─────────────────────────────────────────────────────────────
class SujianInk {
  static final Map<String, _Glyph> _glyphs = {};
  static String? _layoutKey;
  static PageLayout? _layoutCache;
  static const int _maxGlyphCache = 4000;
  static const int _maxGlyphs = 24000;

  static String _layoutKeyOf(PageDoc d) =>
      '${d.text}|${d.paper.index}|${d.style.index}';

  static PageLayout _layout(PageDoc doc) {
    final key = _layoutKeyOf(doc);
    if (_layoutKey == key && _layoutCache != null) return _layoutCache!;

    final spec = doc.paper.spec;
    final fontPx = spec.lineH * 0.735 * doc.style.sizeScale;
    final right = kPageW - spec.side;
    final perPage = max(1, spec.lines);

    final slots = <GlyphSlot>[];
    var x = spec.side;
    var line = 0;
    var index = 0;

    for (final rune in doc.text.runes) {
      if (index > _maxGlyphs) break;
      final ch = String.fromCharCode(rune);

      if (ch == '\r') {
        index++;
        continue;
      }
      if (ch == '\n') {
        x = spec.side;
        line++;
        index++;
        continue;
      }
      if (ch == ' ' || ch == '\u3000') {
        x += fontPx * 0.38;
        index++;
        continue;
      }

      final g = _glyphAt(ch, doc, fontPx, 0);
      final cw = g.tp.width;

      // 避头尾：收尾标点允许悬挂出界
      if (x + cw > right && !_hang.contains(ch)) {
        x = spec.side;
        line++;
      }

      final page = line ~/ perPage;
      final lineInPage = line % perPage;
      final baseY = spec.top + lineInPage * spec.lineH + spec.lineH * 0.855;

      slots.add(GlyphSlot(
        ch: ch,
        x: x,
        baseY: baseY,
        cw: cw,
        page: page,
        index: index,
      ));

      x += cw + fontPx * 0.04;
      index++;
    }

    final pages = slots.isEmpty ? 1 : (slots.last.page + 1);
    final layout = PageLayout(slots, pages);
    _layoutKey = key;
    _layoutCache = layout;
    return layout;
  }

  static int pageCount(PageDoc doc) => _layout(doc).pageCount;

  static _Glyph _glyphAt(String ch, PageDoc doc, double fontPx, int level) {
    final key = '$ch|${doc.style.family}|${fontPx.toStringAsFixed(1)}|$level|${doc.ink.name}';
    final hit = _glyphs[key];
    if (hit != null) return hit;

    final tp = TextPainter(
      text: TextSpan(
        text: ch,
        style: TextStyle(
          fontFamily: doc.style.family,
          fontSize: fontPx,
          height: 1.0,
          color: doc.ink.color.withAlpha(_alphaLevels[level]),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final baseline =
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic) ?? fontPx * 0.8;

    if (_glyphs.length > _maxGlyphCache) _glyphs.clear();
    final g = _Glyph(tp, baseline);
    _glyphs[key] = g;
    return g;
  }

  /// 把一页墨迹画到 [canvas]（坐标系已是 900×1200）
  static void paintPage(Canvas canvas, PageDoc doc, int page) {
    final layout = _layout(doc);
    if (layout.slots.isEmpty) return;

    final spec = doc.paper.spec;
    final r = doc.realism;
    final fontPx = spec.lineH * 0.735 * doc.style.sizeScale;

    final tiltSpan = (0.25 + 3.4 * r) * pi / 180;
    final jx = 0.55 + 2.4 * r;
    final jy = 0.45 + 1.8 * r;
    final seedBase = fnv1a(
          '${doc.text}|${doc.style.name}|${doc.paper.name}|${doc.ink.name}',
        ) ^
        doc.seed;

    // 先录成 Picture，两遍复用（录一次，重放很便宜）
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);

    for (final s in layout.slots) {
      if (s.page != page) continue;

      final rng = Mulberry32((seedBase ^ s.index) & 0xFFFFFFFF);
      final level = (rng.next() * 3).floor().clamp(0, 2).toInt();
      final g = _glyphAt(s.ch, doc, fontPx, level);

      // 整行起伏：模拟手肘摆动，同一行的字共用同一位相
      final wave = sin(s.baseY * 0.0132 + 0.6) * (0.5 + 1.2 * r);

      final dx = rng.centered() * jx;
      final dy = rng.centered() * jy + wave;
      final rot = rng.centered() * tiltSpan;
      final sc = 1 + rng.centered() * 0.055 * r;

      c.save();
      c.translate(s.x + s.cw / 2 + dx, s.baseY + dy);
      c.rotate(rot);
      c.scale(sc, sc);
      g.tp.paint(c, Offset(-s.cw / 2, -g.baseline));
      c.restore();
    }

    final pic = rec.endRecording();
    const rect = Rect.fromLTWH(0, 0, kPageW, kPageH);
    final bleed = 1.9 * r;

    // ① 晕染：整层做一次模糊，不逐字（逐字会为每个字新建 SaveLayer，必卡）
    if (bleed > 0.08) {
      canvas.saveLayer(
        rect,
        Paint()
          ..blendMode = BlendMode.multiply
          ..color = const Color(0x80000000)
          ..imageFilter = ui.ImageFilter.blur(sigmaX: bleed, sigmaY: bleed),
      );
      canvas.drawPicture(pic);
      canvas.restore();
    }

    // ② 实笔：墨乘算到纸上，纸纹会透出来
    canvas.saveLayer(rect, Paint()..blendMode = BlendMode.multiply);
    canvas.drawPicture(pic);
    canvas.restore();
  }
}

/// 预览层
class InkPainter extends CustomPainter {
  final PageDoc doc;
  final int page;

  const InkPainter(this.doc, {this.page = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / kPageW;
    canvas.save();
    canvas.scale(s);
    SujianInk.paintPage(canvas, doc, page);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant InkPainter old) => old.doc != doc || old.page != page;
}
