import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/store.dart';
import '../model.dart';
import '../render/exporter.dart';
import '../render/ink_painter.dart';
import '../theme.dart';
import '../theme/skin.dart';
import '../widgets/glass_panel.dart';
import '../widgets/hand_button.dart';
import 'editor_page.dart';

class ResultPage extends StatefulWidget {
  final Entry entry;
  final ui.Image initialImage;
  final int initialPage;

  /// 从编辑页进来时，「重写」只是返回；从作品集/随机翻进来时要推入编辑页
  final bool fromEditor;

  const ResultPage({
    super.key,
    required this.entry,
    required this.initialImage,
    this.initialPage = 0,
    this.fromEditor = true,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final Map<int, ui.Image> _images = {};
  final Map<int, Uint8List> _pngs = {};
  late int _page;
  bool _busy = false;
  bool _stamp = false;

  PageDoc get _doc => widget.entry.toDoc();
  int get _total => SujianInk.pageCount(_doc);

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(0, _total - 1).toInt();
    _images[_page] = widget.initialImage;
    _encode(_page);
  }

  @override
  void dispose() {
    for (final img in _images.values) {
      img.dispose();
    }
    _images.clear();
    super.dispose();
  }

  Future<void> _encode(int i) async {
    if (_pngs.containsKey(i)) return;
    final img = _images[i];
    if (img == null) return;
    final bytes = await encodePng(img);
    if (!mounted) return;
    _pngs[i] = bytes;
  }

  Future<void> _ensure(int i) async {
    if (i < 0 || i >= _total || _images.containsKey(i)) {
      _encode(i);
      return;
    }
    final img = await renderPageImage(_doc, i, 1620);
    if (!mounted) {
      img.dispose();
      return;
    }
    setState(() => _images[i] = img);
    _encode(i);
  }

  void _go(int delta) {
    final next = _page + delta;
    if (next < 0 || next >= _total) return;
    setState(() => _page = next);
    _ensure(next);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13, letterSpacing: 0.6)),
        backgroundColor: C.text1.withAlpha(242),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(40, 0, 40, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
  }

  Future<Uint8List> _bytesOf(int i) async {
    final cached = _pngs[i];
    if (cached != null) return cached;
    final bytes = await renderPng(_doc, i, width: 1620);
    _pngs[i] = bytes;
    return bytes;
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    var saved = 0;
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      for (var i = 0; i < _total; i++) {
        await Gal.putImageBytes(await _bytesOf(i), album: '素笺');
        saved++;
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _stamp = true;
      });
      _toast(_total > 1 ? '已保存 $saved 张到相册' : '已保存到相册');
      Future.delayed(const Duration(milliseconds: 950), () {
        if (mounted) setState(() => _stamp = false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(saved > 0 ? '已保存 $saved 张，其余失败' : '相册不可用，改用分享保存');
    }
  }

  Future<File> _writeTemp(String suffix, Uint8List bytes, {int index = 0}) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/sujian_${DateTime.now().millisecondsSinceEpoch}_$index.$suffix');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = <XFile>[];
      for (var i = 0; i < _total; i++) {
        final f = await _writeTemp('png', await _bytesOf(i), index: i);
        files.add(XFile(f.path));
      }
      if (!mounted) return;
      setState(() => _busy = false);
      await Share.shareXFiles(files, text: '素笺 · 写于 ${DateTime.now().year}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('分享失败');
    }
  }

  Future<void> _exportPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await buildPdf(_doc);
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

  void _rewrite() {
    if (widget.fromEditor) {
      Navigator.of(context).maybePop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => EditorPage(entry: widget.entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AnimatedBuilder(
      animation: SkinStore.instance,
      builder: (context, _) {
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
                      _actionBar(),
                    ],
                  ),
                  if (_stamp) Center(child: _Stamp(text: '已 存')),
                ],
              ),
            ),
          ),
        );
      },
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
                child: Center(child: HandGlyph(HandIcon.back, opacity: 0.85)),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${now.month} 月 ${now.day} 日',
                  style: TextStyle(fontSize: 12, letterSpacing: 2.4, color: C.text2),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _share,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Center(child: HandGlyph(HandIcon.share, size: 20, opacity: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stage() {
    final img = _images[_page];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (d) {
        final v = d.velocity.pixelsPerSecond.dx;
        if (v < -140) _go(1);
        if (v > 140) _go(-1);
      },
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Transform.rotate(
                angle: -0.55 * 3.1415926535 / 180,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: SujianTheme.paperShadowLifted,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: img == null
                        ? SizedBox(
                            width: 200,
                            height: 266,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.3,
                                  color: C.text3,
                                ),
                              ),
                            ),
                          )
                        : RawImage(image: img, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _pageBar(),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _pageBar() {
    if (_total <= 1) {
      return Text(
        '· 1 页 ·',
        style: TextStyle(fontSize: 9, letterSpacing: 1.8, color: C.text3.withAlpha(150)),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _total && i < 8; i++)
          GestureDetector(
            onTap: () {
              setState(() => _page = i);
              _ensure(i);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 14 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: i == _page ? C.text1.withAlpha(150) : C.text1.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: 10),
        Text(
          '${_page + 1} / $_total · 左右滑动',
          style: TextStyle(fontSize: 9, letterSpacing: 1.2, color: C.text3.withAlpha(160)),
        ),
      ],
    );
  }

  Widget _actionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: GlassPanel(
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _act(
              HandIcon.save,
              _busy ? '处理中…' : (_total > 1 ? '保存全部 $_total' : '保存图片'),
              _busy ? null : _save,
            ),
            _act(HandIcon.pdf, _total > 1 ? 'PDF · $_total 页' : '导出 PDF', _busy ? null : _exportPdf),
            _act(HandIcon.share, _total > 1 ? '分享全部' : '分享', _busy ? null : _share),
            _act(HandIcon.pen, '重写', _rewrite),
          ],
        ),
      ),
    );
  }

  Widget _act(HandIcon glyph, String label, VoidCallback? onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HandGlyph(glyph, size: 21),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(fontSize: 9.5, letterSpacing: 0.7, color: C.text2),
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
              angle: -9 * 3.1415926535 / 180,
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
                          style: TextStyle(
                            fontSize: 18,
                            letterSpacing: 3,
                            color: C.accent,
                            fontFamily: C.serif,
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
