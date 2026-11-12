import 'package:flutter/material.dart';

import 'theme.dart';
import 'theme/skin.dart';

/// 画布设计坐标系：900 × 1200（3:4）
const double kPageW = 900;
const double kPageH = 1200;

enum PaperType { ruled, grid, kraft, sketch, vintage }

enum HandStyle { shouji, juanxiu, xingkai, gongzheng, shaonv }

enum InkTone { black, blue, green }

class PaperSpec {
  final Color base;
  final double lineH;
  final double top;
  final double bottom;
  final double side;

  const PaperSpec({
    required this.base,
    required this.lineH,
    required this.top,
    required this.bottom,
    required this.side,
  });

  /// 每页可容纳的行数
  int get lines => ((kPageH - top - bottom) / lineH).floor();
}

/// 纸的度量是固定的，纸色随主题变——所以按当前主题缓存一份
String? _paperCacheSkin;
Map<PaperType, PaperSpec>? _paperCache;

Map<PaperType, PaperSpec> get kPapers {
  final id = SkinStore.instance.current.id;
  if (_paperCacheSkin == id && _paperCache != null) return _paperCache!;
  final m = <PaperType, PaperSpec>{
    PaperType.ruled: PaperSpec(base: C.paperCream, lineH: 64, top: 96, bottom: 110, side: 74),
    PaperType.grid: PaperSpec(base: C.paperGrid, lineH: 48, top: 84, bottom: 100, side: 72),
    PaperType.kraft: PaperSpec(base: C.paperKraft, lineH: 62, top: 96, bottom: 110, side: 76),
    PaperType.sketch: PaperSpec(base: C.paperSketch, lineH: 66, top: 100, bottom: 120, side: 80),
    PaperType.vintage: PaperSpec(base: C.paperVintage, lineH: 60, top: 122, bottom: 118, side: 78),
  };
  _paperCacheSkin = id;
  _paperCache = m;
  return m;
}

extension PaperTypeX on PaperType {
  PaperSpec get spec => kPapers[this]!;

  String get label => switch (this) {
        PaperType.ruled => '横线本',
        PaperType.grid => '方格纸',
        PaperType.kraft => '牛皮纸',
        PaperType.sketch => '素描纸',
        PaperType.vintage => '复古信纸',
      };
}

extension HandStyleX on HandStyle {
  String get label => switch (this) {
        HandStyle.shouji => '日常',
        HandStyle.juanxiu => '娟秀',
        HandStyle.xingkai => '行楷',
        HandStyle.gongzheng => '工整',
        HandStyle.shaonv => '少女',
      };

  /// pubspec.yaml 中声明的字体族名
  String get family => switch (this) {
        HandStyle.shouji => 'KaiXin',
        HandStyle.juanxiu => 'MaShanZheng',
        HandStyle.xingkai => 'ZhiMangXing',
        HandStyle.gongzheng => 'LongCang',
        HandStyle.shaonv => 'ZCOOLKuaiLe',
      };

  /// 不同字库的字面高度差异较大，用一个系数把它压回同一视觉重量
  double get sizeScale => switch (this) {
        HandStyle.shouji => 1.00,
        HandStyle.juanxiu => 1.04,
        HandStyle.xingkai => 1.06,
        HandStyle.gongzheng => 0.98,
        HandStyle.shaonv => 1.02,
      };
}

extension InkToneX on InkTone {
  String get label => switch (this) {
        InkTone.black => '墨黑',
        InkTone.blue => '深蓝',
        InkTone.green => '墨绿',
      };

  Color get color => switch (this) {
        InkTone.black => C.inkBlack,
        InkTone.blue => C.inkBlue,
        InkTone.green => C.inkGreen,
      };
}

/// 一次渲染的完整描述（不可变，用于 shouldRepaint 判等）
@immutable
class PageDoc {
  final String text;
  final PaperType paper;
  final HandStyle style;
  final InkTone ink;
  final double realism;
  final int seed;

  const PageDoc({
    required this.text,
    this.paper = PaperType.ruled,
    this.style = HandStyle.shouji,
    this.ink = InkTone.black,
    this.realism = 0.62,
    this.seed = 0,
  });

  PageDoc copyWith({
    String? text,
    PaperType? paper,
    HandStyle? style,
    InkTone? ink,
    double? realism,
    int? seed,
  }) {
    return PageDoc(
      text: text ?? this.text,
      paper: paper ?? this.paper,
      style: style ?? this.style,
      ink: ink ?? this.ink,
      realism: realism ?? this.realism,
      seed: seed ?? this.seed,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PageDoc &&
      other.text == text &&
      other.paper == paper &&
      other.style == style &&
      other.ink == ink &&
      other.realism == realism &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(text, paper, style, ink, realism, seed);
}
