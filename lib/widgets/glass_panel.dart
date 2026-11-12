import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/skin.dart';

/// 玻璃面板：只用于抽屉 / 参数面板 / 操作栏。
/// 没有实边框，只有一圈极淡的高光；内容是真实模糊的。
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final double? blur;
  final double? edge;
  final bool topOnly;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.blur,
    this.edge,
    this.topOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final skin = SkinStore.instance.current;
    final r = radius ?? skin.glassRadius;
    final br = topOnly
        ? BorderRadius.vertical(top: Radius.circular(r))
        : BorderRadius.circular(r);
    final sigma = blur ?? skin.glassBlur;
    final e = edge ?? skin.glassEdge;

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: skin.glassTint,
            borderRadius: br,
            border: Border.all(
              color: Colors.white.withAlpha((e * 96).round()),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
