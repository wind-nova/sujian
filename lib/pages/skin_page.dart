import 'package:flutter/material.dart';

import '../theme.dart';
import '../theme/skin.dart';
import '../widgets/hand_button.dart';

/// 主题选择：每张卡预览的是「那个世界」——环境光 + 纸
class SkinPage extends StatelessWidget {
  const SkinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SkinStore.instance,
      builder: (context, _) {
        final current = SkinStore.instance.current;
        return Scaffold(
          backgroundColor: C.ambient1,
          body: Container(
            decoration: SujianTheme.ambientBg,
            child: SafeArea(
              child: Column(
                children: [
                  _header(context),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: Skins.all.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _card(Skins.all[i], current),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
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
                  '主题',
                  style: TextStyle(fontSize: 12, letterSpacing: 2.4, color: C.text2),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _card(SujianSkin skin, SujianSkin current) {
    final selected = skin.id == current.id;
    return GestureDetector(
      onTap: () => SkinStore.instance.select(skin),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 96,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? C.surfaceCard.withAlpha(220) : C.surfaceCard.withAlpha(120),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? C.accent.withAlpha(120) : C.text1.withAlpha(16),
            width: selected ? 1.2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x143C3223),
              blurRadius: 12,
              offset: Offset(0, 6),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          children: [
            _preview(skin),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skin.name,
                    style: TextStyle(fontSize: 14, letterSpacing: 3.0, color: C.text1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    skin.desc,
                    style: TextStyle(fontSize: 10, letterSpacing: 1.0, color: C.text2),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    skin.hint,
                    style: TextStyle(fontSize: 9, letterSpacing: 0.6, color: C.text3),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: C.accent.withAlpha(180), width: 1.2),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: C.accent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 微缩预览：环境光渐变底 + 一张小纸
  Widget _preview(SujianSkin skin) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 62,
        height: 76,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [skin.ambient0, skin.ambient2],
            ),
          ),
          child: Center(
            child: Container(
              width: 34,
              height: 46,
              decoration: BoxDecoration(
                color: skin.paperCream,
                boxShadow: const [
                  BoxShadow(color: Color(0x333C3223), blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 9),
                  for (var i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 6),
                      child: Container(height: 0.8, color: const Color(0x337E9EB6)),
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
