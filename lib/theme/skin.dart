import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// 一套「世界」：环境光 + 五张纸 + 墨/文字色 + 朱红。
/// UI 的骨架（间距、圆角、阴影）不随主题变，只有"纸和光"在变。
@immutable
class SujianSkin {
  final String id;
  final String name;
  final String desc;
  final String hint;

  final Color ambient0;
  final Color ambient1;
  final Color ambient2;

  final Color paperCream;
  final Color paperGrid;
  final Color paperKraft;
  final Color paperSketch;
  final Color paperVintage;

  final Color accent;
  final Color text1;
  final Color text2;
  final Color text3;

  /// 暗角 / 颗粒强度系数（1.0 为基准）
  final double vignette;
  final double grain;
  final bool dark;

  // ── 玻璃层（L1 桌面）：仅用于抽屉、面板、操作栏，纸层不受影响 ──
  final double glassBlur;
  final Color glassTint;
  final double glassRadius;
  final double glassEdge;

  const SujianSkin({
    required this.id,
    required this.name,
    required this.desc,
    required this.hint,
    required this.ambient0,
    required this.ambient1,
    required this.ambient2,
    required this.paperCream,
    required this.paperGrid,
    required this.paperKraft,
    required this.paperSketch,
    required this.paperVintage,
    required this.accent,
    required this.text1,
    required this.text2,
    required this.text3,
    this.vignette = 1.0,
    this.grain = 1.0,
    this.dark = false,
    this.glassBlur = 18,
    this.glassTint = const Color(0xB8FAF7F0),
    this.glassRadius = 24,
    this.glassEdge = 0.82,
  });
}

class Skins {
  /// 01 素笺 · 默认：暖白、木桌、一盏灯
  static const sujian = SujianSkin(
    id: 'sujian',
    name: '素笺',
    desc: '暖白 · 木桌 · 一盏灯',
    hint: '最接近你手边那张纸',
    ambient0: Color(0xFFEFEBE1),
    ambient1: Color(0xFFE9E5DB),
    ambient2: Color(0xFFDED8CA),
    paperCream: Color(0xFFF7F4EA),
    paperGrid: Color(0xFFFAF8F1),
    paperKraft: Color(0xFFC9A171),
    paperSketch: Color(0xFFFBFAF6),
    paperVintage: Color(0xFFF2E6CE),
    accent: Color(0xFFC2453A),
    text1: Color(0xFF3E3A34),
    text2: Color(0xFF6F6A61),
    text3: Color(0xFF9C968B),
  );

  /// 02 夜灯：熄了主灯，只剩台灯那一圈
  static const yedeng = SujianSkin(
    id: 'yedeng',
    name: '夜灯',
    desc: '深夜 · 台灯 · 纸质发黄',
    hint: '睡前写，眼睛不累',
    ambient0: Color(0xFF2E2A26),
    ambient1: Color(0xFF262220),
    ambient2: Color(0xFF1B1917),
    paperCream: Color(0xFFE9DFC7),
    paperGrid: Color(0xFFEDE4CF),
    paperKraft: Color(0xFFA8875C),
    paperSketch: Color(0xFFF1EBDA),
    paperVintage: Color(0xFFDCCBA6),
    accent: Color(0xFFCE7150),
    text1: Color(0xFFE9E3D7),
    text2: Color(0xFFAAA39A),
    text3: Color(0xFF736D67),
    vignette: 1.35,
    grain: 1.2,
    dark: true,
    glassBlur: 26,
    glassTint: Color(0xB82A2622),
    glassRadius: 24,
    glassEdge: 0.22,
  );

  /// 03 青瓷：雨后窗台的那种冷
  static const qingci = SujianSkin(
    id: 'qingci',
    name: '青瓷',
    desc: '冷青 · 雨后 · 窗台',
    hint: '适合写安静的东西',
    ambient0: Color(0xFFE9EFEB),
    ambient1: Color(0xFFDFE7E3),
    ambient2: Color(0xFFD2DDD9),
    paperCream: Color(0xFFF4F7F3),
    paperGrid: Color(0xFFF7FAF6),
    paperKraft: Color(0xFFB6A88E),
    paperSketch: Color(0xFFFAFCFA),
    paperVintage: Color(0xFFEDECE0),
    accent: Color(0xFFA8543F),
    text1: Color(0xFF35403B),
    text2: Color(0xFF6B7772),
    text3: Color(0xFF99A39E),
    vignette: 0.85,
    glassBlur: 20,
    glassTint: Color(0xB4F4F8F6),
    glassRadius: 24,
    glassEdge: 0.80,
  );

  /// 04 旧册：从旧书里翻出来的一页
  static const jiuce = SujianSkin(
    id: 'jiuce',
    name: '旧册',
    desc: '泛黄 · 藏书 · 铁锈红',
    hint: '像从箱底翻出来的',
    ambient0: Color(0xFFE6DDCB),
    ambient1: Color(0xFFDCD3C0),
    ambient2: Color(0xFFCEC4AF),
    paperCream: Color(0xFFF0E7D2),
    paperGrid: Color(0xFFF3EBD8),
    paperKraft: Color(0xFFB08E63),
    paperSketch: Color(0xFFF5EFDF),
    paperVintage: Color(0xFFE4D2AE),
    accent: Color(0xFF8C4A32),
    text1: Color(0xFF3A3226),
    text2: Color(0xFF6E6555),
    text3: Color(0xFF9C9382),
    vignette: 1.15,
    grain: 1.25,
    glassBlur: 20,
    glassTint: Color(0xBCF2EBDE),
    glassRadius: 24,
    glassEdge: 0.70,
  );

  /// 05 雪：极亮，纸上什么都不用加
  static const xue = SujianSkin(
    id: 'xue',
    name: '雪',
    desc: '冷白 · 极亮 · 一点朱',
    hint: '最克制的一套',
    ambient0: Color(0xFFF4F6F8),
    ambient1: Color(0xFFEFF2F5),
    ambient2: Color(0xFFE5E9EE),
    paperCream: Color(0xFFFAFBFC),
    paperGrid: Color(0xFFFCFDFE),
    paperKraft: Color(0xFFB9A98F),
    paperSketch: Color(0xFFFFFFFF),
    paperVintage: Color(0xFFF0EEE6),
    accent: Color(0xFFC2453A),
    text1: Color(0xFF2F353B),
    text2: Color(0xFF676F78),
    text3: Color(0xFF98A0A8),
    vignette: 0.7,
    grain: 0.8,
    glassBlur: 28,
    glassTint: Color(0xC2FFFFFF),
    glassRadius: 26,
    glassEdge: 0.95,
  );

  static const List<SujianSkin> all = [sujian, yedeng, qingci, jiuce, xue];

  static SujianSkin byId(String? id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return sujian;
  }
}

/// 当前主题。切换时通知整棵树重建，同时让纸层重绘。
class SkinStore extends ChangeNotifier {
  SkinStore._();

  static final SkinStore instance = SkinStore._();

  SujianSkin _current = Skins.sujian;
  SujianSkin get current => _current;

  int indexOf(SujianSkin s) => Skins.all.indexOf(s);

  File? _file;

  Future<File> _resolve() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory('${dir.path}/sujian');
    if (!await d.exists()) await d.create(recursive: true);
    _file = File('${d.path}/settings.json');
    return _file!;
  }

  Future<void> load() async {
    try {
      final f = await _resolve();
      if (await f.exists()) {
        final raw = await f.readAsString();
        if (raw.trim().isNotEmpty) {
          final m = jsonDecode(raw);
          if (m is Map && m['skin'] is String) {
            _current = Skins.byId(m['skin'] as String);
          }
        }
      }
    } catch (_) {
      // 读不到就用默认
    }
    notifyListeners();
  }

  void select(SujianSkin s) {
    if (s.id == _current.id) return;
    _current = s;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final f = await _resolve();
      await f.writeAsString(jsonEncode({'skin': _current.id}), flush: true);
    } catch (_) {}
  }
}
