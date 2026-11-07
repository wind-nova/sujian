import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 程序化纸纹所需要的位图（启动时生成一次，全程复用）
class TextureKit {
  static ui.Image? grain;
  static ui.ImageShader? grainShader;

  static const int _tile = 190;

  static Future<void> init() async {
    if (grain != null) return;

    // 高频颗粒：190×190 的灰度噪声，平铺后按 overlay 叠到纸上
    final rnd = Random(20261024);
    final bytes = Uint8List(_tile * _tile * 4);
    for (var i = 0; i < _tile * _tile; i++) {
      final v = (128 + (rnd.nextDouble() - 0.5) * 46).round().clamp(0, 255);
      bytes[i * 4] = v;
      bytes[i * 4 + 1] = v;
      bytes[i * 4 + 2] = v;
      bytes[i * 4 + 3] = 255;
    }

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final desc = ui.ImageDescriptor.raw(
      buffer,
      width: _tile,
      height: _tile,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await desc.instantiateCodec();
    final frame = await codec.getNextFrame();
    grain = frame.image;

    grainShader = ui.ImageShader(
      grain!,
      TileMode.repeated,
      TileMode.repeated,
      Matrix4.identity().storage,
    );
  }
}
