/// 确定性伪随机：同一份内容 + 同一套参数，永远渲出同一张纸。
/// FNV-1a 散列 + mulberry32（与 Web 原型同款，保证两端结果一致）。
library;

int fnv1a(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

class Mulberry32 {
  int _a;

  Mulberry32(int seed) : _a = seed & 0xFFFFFFFF;

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

  double next() {
    _a = (_a + 0x6D2B79F5) & 0xFFFFFFFF;
    final t = _imul(_a ^ (_a >> 15), 1 | _a);
    final u = (t + _imul(t ^ (t >> 7), 61 | t)) ^ t;
    return ((u ^ (u >> 14)) & 0xFFFFFFFF) / 4294967296.0;
  }

  /// [-1, 1)
  double centered() => next() * 2 - 1;
}
