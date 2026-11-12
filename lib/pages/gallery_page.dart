import 'package:flutter/material.dart';

import '../data/store.dart';
import '../render/paper_painter.dart';
import '../theme.dart';
import '../theme/skin.dart';
import '../widgets/hand_button.dart';
import 'editor_page.dart';

/// 作品集：写过的每一页都堆在这里
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = EntryStore.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([store, SkinStore.instance]),
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
                      _header(context, store),
                      Expanded(
                        child: store.isEmpty ? _empty(context) : _grid(context, store),
                      ),
                    ],
                  ),
                  if (store.isNotEmpty)
                    Positioned(right: 22, bottom: 30, child: _fab(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, EntryStore store) {
    return SizedBox(
      height: 56,
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
                  store.isEmpty ? '作品集' : '作品集 · ${store.count} 篇',
                  style: TextStyle(fontSize: 12, letterSpacing: 2.0, color: C.text2),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, EntryStore store) {
    final items = store.entries;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _card(context, items[i]),
    );
  }

  Widget _card(BuildContext context, Entry e) {
    final snippet = e.text.length > 140 ? e.text.substring(0, 140) : e.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditorPage(entry: e)),
            ),
            onLongPress: () => _confirmDelete(context, e),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                boxShadow: SujianTheme.paperShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(painter: PaperPainter(e.paper, ornaments: false)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 10, 8),
                      child: ClipRect(
                        child: Text(
                          snippet,
                          maxLines: 16,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: e.style.family,
                            fontSize: 9.5,
                            height: 1.72,
                            color: e.ink.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(
              '${e.updatedAt.month} 月 ${e.updatedAt.day} 日',
              style: TextStyle(fontSize: 9, letterSpacing: 0.6, color: C.text2),
            ),
            const Spacer(),
            Text(
              '${e.charCount} 字',
              style: TextStyle(fontSize: 9, letterSpacing: 0.6, color: C.text3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140,
            height: 187,
            decoration: BoxDecoration(
              color: C.paperCream.withAlpha(150),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: C.text1.withAlpha(18)),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            '还没有写过任何东西',
            style: TextStyle(fontSize: 11, letterSpacing: 2.0, color: C.text3),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const EditorPage()),
            ),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: C.text1.withAlpha(60)),
              ),
              child: Center(
                child: Text(
                  '写第一页',
                  style: TextStyle(fontSize: 11.5, letterSpacing: 2.0, color: C.text1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fab(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EditorPage()),
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: C.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(color: C.text1.withAlpha(30)),
          boxShadow: const [
            BoxShadow(color: Color(0x1A3C3223), blurRadius: 2, offset: Offset(0, 1)),
            BoxShadow(color: Color(0x663C3223), blurRadius: 22, offset: Offset(0, 10), spreadRadius: -8),
          ],
        ),
        child: Center(child: HandGlyph(HandIcon.plus, size: 20, opacity: 0.8)),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Entry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.surfaceCard,
        insetPadding: const EdgeInsets.symmetric(horizontal: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '删掉这一页？',
                style: TextStyle(fontSize: 14, letterSpacing: 1.2, color: C.text1),
              ),
              const SizedBox(height: 10),
              Text(
                '${e.updatedAt.month} 月 ${e.updatedAt.day} 日 · ${e.charCount} 字，删除后无法恢复。',
                style: TextStyle(fontSize: 11, height: 1.8, color: C.text3),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('留着', style: TextStyle(fontSize: 12, color: C.text2)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('删除', style: TextStyle(fontSize: 12, color: C.accent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) await EntryStore.instance.remove(e.id);
  }
}
