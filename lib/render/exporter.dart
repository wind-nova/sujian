import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../model.dart';
import 'ink_painter.dart';
import 'paper_painter.dart';

/// 离屏渲染：把一页纸渲成位图（不经过 widget 树，因此预览是什么样，导出就是什么样）
Future<ui.Image> renderPageImage(PageDoc doc, int page, int width) async {
  final height = (width * kPageH / kPageW).round();
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final s = width / kPageW;
  canvas.scale(s, s);

  PaperPainter.paintPaper(canvas, doc.paper, const Size(kPageW, kPageH));
  SujianInk.paintPage(canvas, doc, page);

  final pic = rec.endRecording();
  return pic.toImage(width, height);
}

Future<Uint8List> encodePng(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// 渲染 + 编码，一步到位
Future<Uint8List> renderPng(PageDoc doc, int page, {int width = 1620}) async {
  final img = await renderPageImage(doc, page, width);
  final bytes = await encodePng(img);
  img.dispose();
  return bytes;
}

/// 多页 PDF：页面比例与纸一致（3:4），打印时不会裁掉边缘
Future<Uint8List> buildPdf(PageDoc doc, {double widthMm = 210}) async {
  final pages = SujianInk.pageCount(doc);
  final pdf = pw.Document(creator: '素笺 SuJian');

  final wPt = widthMm * 72 / 25.4;
  final format = PdfPageFormat(wPt, wPt * 4 / 3);

  for (var i = 0; i < pages; i++) {
    final img = await renderPageImage(doc, i, 2000);
    final png = await encodePng(img);
    img.dispose();
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.fill),
      ),
    );
  }

  return pdf.save();
}
