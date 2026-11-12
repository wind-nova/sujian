import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../model.dart';
import '../render/exporter.dart';
import '../render/ink_painter.dart';
import '../render/scene.dart';
import '../theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/hand_button.dart';
import 'result_page.dart';

class EditorPage extends StatefulWidget {
  final Entry? entry;
  const EditorPage({super.key, this.entry});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late Entry _entry;
  PageDoc _doc = const PageDoc(text: '');
  int _page = 0;
  bool _busy = false;
  bool _dirty = false;
  Timer? _debounce;
  DateTime _savedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _entry = widget.entry ?? Entry.create();
    _doc = _entry.toDoc();
    _savedAt = _entry.updatedAt;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_doc.text.trim().isEmpty) _editText();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_dirty) _persist();
    super.dispose();
  }

  // ─────────── 自动保存 ───────────
  void _touch() {
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _persist);
  }

  void _persist() {
    _entry = _entry.copyWith(
      text: _doc.text,
      paper: _doc.paper,
      style: _doc.style,
      ink: _doc.ink,
      realism: _doc.realism,
      updatedAt: DateTime.now(),
    );
    _savedAt = _entry.updatedAt;
    _dirty = false;
    EntryStore.instance.upsert(_entry);
  }

  void _setDoc(PageDoc d) {
    setState(() {
      _doc = d;
      final n = SujianInk.pageCount(d);
      if (_page >= n) _page = n - 1;
      if (_page < 0) _page = 0;
    });
    _touch();
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

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    if (_doc.text.trim().isEmpty) {
      _toast('先写点什么吧');
      return;
    }
    _debounce?.cancel();
    _persist();
    setState(() => _busy = true);
    try {
      final img = await renderPageImage(_doc, _page, 1620);
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() => _busy = false);
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultPage(
          entry: _entry,
          initialImage: img,
          initialPage: _page,
          fromEditor: true,
        ),
      ));
      if (mounted) img.dispose();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('生成失败');
    }
  }

  Future<void> _editText() async {
    final controller = TextEditingController(text: _doc.text);
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: C.text1.withAlpha(46),
      builder: (ctx) => _TextSheet(controller: controller),
    );
    controller.dispose();
    if (text == null) return;
    _setDoc(_doc.copyWith(text: text));
    setState(() => _page = 0);
  }

  void _swipe(DragEndDetails d) {
    final n = SujianInk.pageCount(_doc);
    if (n <= 1) return;
    final v = d.velocity.pixelsPerSecond.dx;
    if (v < -140 && _page < n - 1) setState(() => _page++);
    if (v > 140 && _page > 0) setState(() => _page--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.ambient1,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: SujianTheme.ambientBg,
        child: SafeArea(
          child: Column(
            children: [
              _appBar(),
              Expanded(child: _preview()),
              _drawer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    final chars = _doc.text.replaceAll(RegExp(r'\s'), '').length;
    return SizedBox(
      height: 52,
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
                  '编辑 · 已写 $chars 字',
                  style: TextStyle(fontSize: 12.5, letterSpacing: 2.2, color: C.text2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: _busy ? null : _generate,
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: C.surfaceCard.withAlpha(184),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: C.accent.withAlpha(107)),
                  ),
                  child: Center(
                    child: _busy
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.4, color: C.accent),
                          )
                        : Text(
                            '生成',
                            style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: C.accent),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    final pages = SujianInk.pageCount(_doc);
    final hasPrev = _page > 0;
    final hasNext = _page < pages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 4, 34, 4),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _editText,
                onHorizontalDragEnd: _swipe,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: SujianTheme.paperShadow,
                  ),
                  child: Stack(
                    children: [
                      SujianSheet(doc: _doc, page: _page),
                      if (pages > 1)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: C.surfaceCard.withAlpha(220),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${_page + 1} / $pages',
                                style: TextStyle(fontSize: 9, letterSpacing: 1.0, color: C.text2),
                              ),
                            ),
                          ),
                        ),
                      if (hasPrev)
                        Positioned(
                          left: 2,
                          top: 0,
                          bottom: 0,
                          child: Center(child: HandGlyph(HandIcon.back, size: 14, opacity: 0.16)),
                        ),
                      if (hasNext)
                        Positioned(
                          right: 2,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Transform.flip(
                              flipX: true,
                              child: HandGlyph(HandIcon.back, size: 14, opacity: 0.16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _pageDots(pages),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _pageDots(int pages) {
    if (pages <= 1) {
      return Text(
        '· 点纸面重写 · 左右滑动翻页 ·',
        style: TextStyle(fontSize: 9, letterSpacing: 1.4, color: C.text3.withAlpha(150)),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < pages && i < 8; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _page ? 14 : 4,
            height: 4,
            decoration: BoxDecoration(
              color: i == _page ? C.text1.withAlpha(140) : C.text1.withAlpha(46),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _drawer() {
    return GlassPanel(
      topOnly: true,
      radius: 18,
      blur: 18,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
        height: 286,
        child: Column(
          children: [
            Container(
              width: 34,
              height: 3,
              decoration: BoxDecoration(
                color: C.text1.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            _paperRow(),
            _styleRow(),
            _inkRow(),
            _realismRow(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    '已自动保存 · ${_two(_savedAt.hour)}:${_two(_savedAt.minute)}',
                    style: TextStyle(fontSize: 9, letterSpacing: 1.2, color: C.text3.withAlpha(160)),
                  ),
                  const Spacer(),
                  Text('↑', style: TextStyle(fontSize: 11, color: C.text3.withAlpha(160))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _two(int v) => v < 10 ? '0$v' : '$v';

  Widget _section(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                label,
                style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: C.text3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _paperRow() => _section(
        '纸张',
        _chips<PaperType>(
          PaperType.values,
          _doc.paper,
          (v) => v.label,
          (v) => _setDoc(_doc.copyWith(paper: v)),
        ),
      );

  Widget _styleRow() => _section(
        '笔迹',
        _chips<HandStyle>(
          HandStyle.values,
          _doc.style,
          (v) => v.label,
          (v) => _setDoc(_doc.copyWith(style: v)),
        ),
      );

  Widget _inkRow() {
    return _section(
      '墨水',
      SizedBox(
        height: 31,
        child: Row(
          children: [
            for (final ink in InkTone.values)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _setDoc(_doc.copyWith(ink: ink));
                },
                child: SizedBox(
                  width: 31,
                  height: 31,
                  child: Center(
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: ink.color,
                        shape: BoxShape.circle,
                        border: _doc.ink == ink
                            ? Border.all(color: C.text1.withAlpha(90), width: 1)
                            : null,
                        boxShadow: _doc.ink == ink
                            ? [
                                BoxShadow(
                                  color: C.text1.withAlpha(60),
                                  blurRadius: 0,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _realismRow() {
    return _section(
      '真实感',
      SizedBox(
        height: 31,
        child: Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  activeTrackColor: C.text1.withAlpha(140),
                  inactiveTrackColor: C.text1.withAlpha(33),
                  thumbColor: C.surfaceCard,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.5),
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Slider(
                  value: _doc.realism,
                  onChanged: (v) => _setDoc(_doc.copyWith(realism: v)),
                ),
              ),
            ),
            SizedBox(
              width: 26,
              child: Text(
                (_doc.realism * 100).round().toString(),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10.5,
                  color: C.text2,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips<T>(
    List<T> items,
    T value,
    String Function(T) label,
    ValueChanged<T> onTap,
  ) {
    return SizedBox(
      height: 31,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final it = items[i];
          final on = it == value;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(it);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: on ? C.surfaceCard : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: on ? C.text1.withAlpha(56) : Colors.transparent,
                ),
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: C.text1.withAlpha(20),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label(it),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: on ? C.text1 : C.text3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 全屏文字编辑面板
class _TextSheet extends StatelessWidget {
  final TextEditingController controller;

  const _TextSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: h * 0.72,
        decoration: BoxDecoration(
          color: C.paperCream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 34,
              height: 3,
              decoration: BoxDecoration(
                color: C.text1.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 6),
              child: Row(
                children: [
                  Text(
                    '写下此刻',
                    style: TextStyle(
                      fontFamily: 'KaiXin',
                      fontSize: 19,
                      color: C.text1,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      final t = data?.text;
                      if (t != null && t.isNotEmpty) {
                        controller.text = t;
                        controller.selection = TextSelection.collapsed(offset: t.length);
                      }
                    },
                    child: Text('粘贴', style: TextStyle(fontSize: 12, color: C.text2)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(controller.text),
                    child: Text(
                      '完成',
                      style: TextStyle(
                        fontSize: 12,
                        color: C.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: C.hairline),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(fontSize: 15, height: 1.85, color: C.text1),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '今天下了很大的雨……',
                    hintStyle: TextStyle(fontSize: 15, color: C.text1.withAlpha(102)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
