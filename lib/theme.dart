import 'package:flutter/material.dart';

import 'theme/skin.dart';

/// 颜色令牌。全部转发到当前主题（SujianSkin），
/// 切换主题时所有引用 C.xxx 的地方自动跟着变。
class C {
  static SujianSkin get s => SkinStore.instance.current;

  // 环境光
  static Color get ambient0 => s.ambient0;
  static Color get ambient1 => s.ambient1;
  static Color get ambient2 => s.ambient2;
  static Color get surfaceCard =>
      s.dark ? const Color(0xFF2E2A26) : const Color(0xFFFCFAF4);
  static Color get surfaceGlass =>
      s.dark ? const Color(0xCC2A2724) : const Color(0xD1FAF7F0);

  // 纸
  static Color get paperCream => s.paperCream;
  static Color get paperGrid => s.paperGrid;
  static Color get paperKraft => s.paperKraft;
  static Color get paperSketch => s.paperSketch;
  static Color get paperVintage => s.paperVintage;

  // 墨（三色是内容，不随主题变）
  static const Color inkBlack = Color(0xFF2A2825);
  static const Color inkBlue = Color(0xFF1E3A5F);
  static const Color inkGreen = Color(0xFF263B31);

  // 文字
  static Color get text1 => s.text1;
  static Color get text2 => s.text2;
  static Color get text3 => s.text3;

  // 点睛
  static Color get accent => s.accent;
  static Color get hairline => s.text1.withAlpha(26);

  static const String ui = 'HarmonyOS Sans SC';
  static const String serif = 'Noto Serif SC';
}

class SujianTheme {
  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);
    final dark = SkinStore.instance.current.dark;
    return base.copyWith(
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: C.ambient1,
      colorScheme: base.colorScheme.copyWith(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: C.text1,
        secondary: C.accent,
        surface: C.surfaceCard,
        onSurface: C.text1,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: C.text1,
        displayColor: C.text1,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
    );
  }

  /// 环境光：三个停靠点的极缓渐变，边界几乎看不出
  static BoxDecoration get ambientBg => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [C.ambient0, C.ambient1, C.ambient2],
          stops: const [0.0, 0.45, 1.0],
        ),
      );

  static const List<BoxShadow> paperShadow = [
    BoxShadow(color: Color(0x0D3C3223), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x383C3223), blurRadius: 18, offset: Offset(0, 8), spreadRadius: -8),
    BoxShadow(color: Color(0x523C3223), blurRadius: 56, offset: Offset(0, 28), spreadRadius: -26),
  ];

  static const List<BoxShadow> paperShadowLifted = [
    BoxShadow(color: Color(0x1A3C3223), blurRadius: 3, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x6B3C3223), blurRadius: 38, offset: Offset(0, 20), spreadRadius: -18),
    BoxShadow(color: Color(0x6B3C3223), blurRadius: 80, offset: Offset(0, 52), spreadRadius: -46),
  ];
}
