import 'package:flutter/material.dart';

/// 素笺 · 设计令牌（与《UI 设计规范》§1.2 / 附录 A 一一对应）
class C {
  // 环境
  static const ambient0 = Color(0xFFEFEBE1);
  static const ambient1 = Color(0xFFE9E5DB);
  static const ambient2 = Color(0xFFDED8CA);
  static const surfaceCard = Color(0xFFFCFAF4);
  static const surfaceGlass = Color(0xD1FAF7F0);

  // 纸
  static const paperCream = Color(0xFFF7F4EA);
  static const paperGrid = Color(0xFFFAF8F1);
  static const paperKraft = Color(0xFFC9A171);
  static const paperSketch = Color(0xFFFBFAF6);
  static const paperVintage = Color(0xFFF2E6CE);

  // 墨
  static const inkBlack = Color(0xFF2A2825);
  static const inkBlue = Color(0xFF1E3A5F);
  static const inkGreen = Color(0xFF263B31);

  // 文字
  static const text1 = Color(0xFF3E3A34);
  static const text2 = Color(0xFF6F6A61);
  static const text3 = Color(0xFF9C968B);

  // 点睛
  static const accent = Color(0xFFC2453A);
  static const hairline = Color(0x1A3E3A34);

  static const ui = 'HarmonyOS Sans SC';
  static const serif = 'Noto Serif SC';
}

class SujianTheme {
  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: C.ambient1,
      colorScheme: base.colorScheme.copyWith(
        primary: C.text1,
        secondary: C.accent,
        surface: C.surfaceCard,
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

  /// 页面环境光：左上偏亮，底部偏暗
  static const BoxDecoration ambientBg = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [C.ambient0, C.ambient1, C.ambient2],
      stops: [0.0, 0.45, 1.0],
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
