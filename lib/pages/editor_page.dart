import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model.dart';
import '../render/exporter.dart';
import '../render/ink_painter.dart';
import '../render/scene.dart';
import '../theme.dart';
import '../widgets/hand_button.dart';
import 'result_page.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  PageDoc _doc = const PageDoc(text: '');
  int _page = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _editText());
  }

  // ────────────────────────── 生成 ──────────────────────────
  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    if (_doc.text.trim().isEmpty) {
      _toast('先写点什么吧');
      return;
    }
    setState(() => _busy = true);
    try {
      final img = await renderPageImage(_doc, _page, 1620);
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() => _busy = false);
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultPage(doc: _doc, image: img, page: _page)),
      );
      if (mounted) img.dispose();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('生成失败：$e');
    }
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

  // ────────────────────────── 文本编辑 ──────────────────────────
  Future<void> _editText() async {
    final controller = TextEditingController(text: _doc.text);
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x2E3E3A34),
      builder: (ctx) => _TextSheet(controller: controller),
    );
    controller.dispose();
    if (text == null) return;
    setState(() {
      _doc = _doc.copyWith(text: text);
      _page = 0;
    });
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
                  style: const TextStyle(fontSize: 12.5, letterSpacing: 2.2, color: C.text2),
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
                    color: const Color(0xB8FCFAF4),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: C.accent.withAlpha(107)),
                  ),
                  child: Center(
                    child: _busy
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.4, color: C.accent),
                          )
                        : const Text(
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 4, 34, 8),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _editText,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: SujianTheme.paperShadow,
                  ),
                  child: SujianSheet(doc: _doc, page: _page),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: pages > 1
                ? () => setState(() => _page = (_page + 1) % pages)
                : null,
            child: Text(
              '· 第 ${_page + 1} / $pages 页 · 3:4 ·',
              style: const TextStyle(fontSize: 9.5, letterSpacing: 1.7, color: Color(0x613E3A34)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawer() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xE0FAF7F0),
            border: Border(top: BorderSide(color: Colors.white.withAlpha(217))),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 34,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0x333E3A34),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              _section(
                '纸张',
                _chips<PaperType>(
                  PaperType.values,
                  _doc.paper,
                  (v) => v.label,
                  (v) => setState(() => _doc = _doc.copyWith(paper: v)),
                ),
              ),
              _section(
                '笔迹',
                _chips<HandStyle>(
                  HandStyle.values,
                  _doc.style,
                  (v) => v.label,
                  (v) => setState(() => _doc = _doc.copyWith(style: v)),
                ),
              ),
              _section('墨水', _inks()),
              _section('真实感', _realism()),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '轻触更换 · 文字区可点开重写',
                  style: TextStyle(fontSize: 9, letterSpacing: 1.6, color: Color(0x613E3A34)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, letterSpacing: 1.2, color: C.text3),
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
                color: on ? const Color(0xFFFFFDF7) : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: on ? const Color(0x383E3A34) : Colors.transparent,
                ),
                boxShadow: on
                    ? const [
                        BoxShadow(color: Color(0x1A3C3023), blurRadius: 2, offset: Offset(0, 1))
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

  Widget _inks() {
    return SizedBox(
      height: 31,
      child: Row(
        children: [
          for (final ink in InkTone.values)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _doc = _doc.copyWith(ink: ink));
              },
              child: Container(
                width: 31,
                height: 31,
                alignment: Alignment.center,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: ink.color,
                    shape: BoxShape.circle,
                    border: _doc.ink == ink
                        ? Border.all(color: const Color(0x573E3A34), width: 1)
                        : null,
                    boxShadow: _doc.ink == ink
                        ? const [BoxShadow(color: Color(0x663C3023), blurRadius: 0, spreadRadius: 4)]
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _realism() {
    return SizedBox(
      height: 31,
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                activeTrackColor: const Color(0x8C3E3A34),
                inactiveTrackColor: const Color(0x213E3A34),
                thumbColor: const Color(0xFFFCFAF4),
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.5),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: _doc.realism,
                onChanged: (v) => setState(() => _doc = _doc.copyWith(realism: v)),
              ),
            ),
          ),
          SizedBox(
            width: 26,
            child: Text(
              (_doc.realism * 100).round().toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10.5,
                color: C.text2,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
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
        decoration: const BoxDecoration(
          color: Color(0xFFF7F4EA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 34,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0x333E3A34),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 6),
              child: Row(
                children: [
                  const Text(
                    '写下此刻',
                    style: TextStyle(
                      fontFamily: 'KaiXin',
                      fontSize: 19,
                      color: Color(0xFF4C463C),
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
                        controller.selection =
                            TextSelection.collapsed(offset: t.length);
                      }
                    },
                    child: const Text('粘贴', style: TextStyle(fontSize: 12, color: C.text2)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(controller.text),
                    child: const Text(
                      '完成',
                      style: TextStyle(fontSize: 12, color: C.accent, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: C.hairline),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 15, height: 1.85, color: C.text1),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '今天下了很大的雨……',
                    hintStyle: TextStyle(fontSize: 15, color: Color(0x663E3A34)),
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
