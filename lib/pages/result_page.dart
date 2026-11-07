import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model.dart';
import '../render/exporter.dart';
import '../render/ink_painter.dart';
import '../theme.dart';
import '../widgets/hand_button.dart';

class ResultPage extends StatefulWidget {
  final PageDoc doc;
  final ui.Image image;
  final int page;

  const ResultPage({
    super.key,
    required this.doc,
    required this.image,
    this.page = 0,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Uint8List? _png;
  bool _busy = false;
  bool _stamp = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final bytes = await encodePng(widget.image);
    if (!mounted) return;
    setState(() => _png = bytes);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontSize: 13, letterSpacing: 0.6)),
          backgroundColor: const Color(0xF23E3A34),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(40, 0, 40, 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _save() async {
    final bytes = _png;
    if (bytes == null) {
      _toast('还在渲染，稍等一下');
      return;
    }
    setState(() => _busy = true);
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      await Gal.putImageBytes(bytes, album: '素笺');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _stamp = true;
      });
      Future.delayed(const Duration(milliseconds: 950), () {
        if (mounted) setState(() => _stamp = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('相册不可用，改用分享保存');
    }
  }

  Future<File> _writeTemp(String suffix, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/sujian_${DateTime.now().millisecondsSinceEpoch}.$suffix');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  Future<void> _share() async {
    final bytes = _png;
    if (bytes == null) return;
    final f = await _writeTemp('png', bytes);
    await Share.shareXFiles([XFile(f.path)], text: '素笺 · 写于 ${DateTime.now().year}');
  }

  Future<void> _exportPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await buildPdf(widget.doc);
      if (!mounted) return;
      setState(() => _busy = false);
      final f = await _writeTemp('pdf', bytes);
      await Share.shareXFiles([XFile(f.path, mimeType: 'application/pdf')], text: '素笺 · PDF');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('导出失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = SujianInk.pageCount(widget.doc);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: C.ambient1,
      body: Container(
        decoration: SujianTheme.ambientBg,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _topBar(now),
                  Expanded(child: _stage()),
                  _actionBar(pages),
                ],
              ),
              if (_stamp)
                const Center(
                  child: _Stamp(text: '已 存'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(DateTime now) {
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Center(child: HandGlyph(Glyph.back, opacity: 0.85)),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${now.month} 月 ${now.day} 日',
                  style: const TextStyle(fontSize: 12, letterSpacing: 2.4, color: C.text2),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _share,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Center(child: HandGlyph(Glyph.share, size: 20, opacity: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Center(
        child: Transform.rotate(
          angle: -0.55 * 3.14159 / 180,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              boxShadow: SujianTheme.paperShadowLifted,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: RawImage(image: widget.image, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBar(int pages) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xCCFCFAF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(204)),
          boxShadow: const [
            BoxShadow(color: Color(0x2E3C3023), blurRadius: 30, offset: Offset(0, 16), spreadRadius: -22),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _act(Glyph.save, '保存图片', _busy ? null : _save),
            _act(Glyph.pdf, pages > 1 ? 'PDF · $pages 页' : '导出 PDF', _busy ? null : _exportPdf),
            _act(Glyph.share, '分享', _share),
            _act(Glyph.pen, '重写', () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }

  Widget _act(Glyph glyph, String label, VoidCallback? onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HandGlyph(glyph, size: 21),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 9.5, letterSpacing: 0.9, color: C.text2),
            ),
          ],
        ),
      ),
    );
  }
}

/// 保存成功的朱红印章
class _Stamp extends StatefulWidget {
  final String text;

  const _Stamp({required this.text});

  @override
  State<_Stamp> createState() => _StampState();
}

class _StampState extends State<_Stamp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          final opacity = t < 0.22 ? t / 0.22 : (t > 0.72 ? (1 - t) / 0.28 : 1.0);
          final eased = Curves.easeOutBack.transform(t.clamp(0.0, 1.0).toDouble());
          final scale = 1.9 - 0.95 * eased;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0).toDouble(),
            child: Transform.rotate(
              angle: -9 * 3.14159 / 180,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: C.accent.withAlpha(217), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: C.accent.withAlpha(36), width: 3),
                      ),
                      child: Center(
                        child: Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 18,
                            letterSpacing: 3,
                            color: C.accent,
                            fontFamily: 'Noto Serif SC',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
