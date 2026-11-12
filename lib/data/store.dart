import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../model.dart';

/// 一篇记录。写过的每一篇都留在这里，作品集就是它们的堆叠。
class Entry {
  final String id;
  final String text;
  final PaperType paper;
  final HandStyle style;
  final InkTone ink;
  final double realism;
  final int seed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Entry({
    required this.id,
    required this.text,
    required this.paper,
    required this.style,
    required this.ink,
    required this.realism,
    required this.seed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Entry.create() {
    final now = DateTime.now();
    return Entry(
      id: now.microsecondsSinceEpoch.toRadixString(36),
      text: '',
      paper: PaperType.ruled,
      style: HandStyle.shouji,
      ink: InkTone.black,
      realism: 0.62,
      seed: now.millisecondsSinceEpoch % 100000,
      createdAt: now,
      updatedAt: now,
    );
  }

  PageDoc toDoc() => PageDoc(
        text: text,
        paper: paper,
        style: style,
        ink: ink,
        realism: realism,
        seed: seed,
      );

  Entry copyWith({
    String? text,
    PaperType? paper,
    HandStyle? style,
    InkTone? ink,
    double? realism,
    DateTime? updatedAt,
  }) {
    return Entry(
      id: id,
      text: text ?? this.text,
      paper: paper ?? this.paper,
      style: style ?? this.style,
      ink: ink ?? this.ink,
      realism: realism ?? this.realism,
      seed: seed,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// 首行摘要，用于列表与首页
  String get preview {
    final first = text.trim().split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    return first.isEmpty ? '（空白的一页）' : first;
  }

  int get charCount => text.replaceAll(RegExp(r'\s'), '').length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'paper': paper.name,
        'style': style.name,
        'ink': ink.name,
        'realism': realism,
        'seed': seed,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory Entry.fromJson(Map<String, dynamic> j) {
    final created = DateTime.fromMillisecondsSinceEpoch(
      (j['createdAt'] as num?)?.toInt() ?? 0,
    );
    return Entry(
      id: j['id'] as String? ?? created.microsecondsSinceEpoch.toRadixString(36),
      text: j['text'] as String? ?? '',
      paper: _pick(PaperType.values, j['paper'], PaperType.ruled),
      style: _pick(HandStyle.values, j['style'], HandStyle.shouji),
      ink: _pick(InkTone.values, j['ink'], InkTone.black),
      realism: (j['realism'] as num?)?.toDouble() ?? 0.62,
      seed: (j['seed'] as num?)?.toInt() ?? 0,
      createdAt: created,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (j['updatedAt'] as num?)?.toInt() ?? created.millisecondsSinceEpoch,
      ),
    );
  }

  static T _pick<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}

/// 本地存储。全部落盘在应用私有目录，不联网。
class EntryStore extends ChangeNotifier {
  EntryStore._();

  static final EntryStore instance = EntryStore._();

  static const _fileName = 'sujian_entries.json';

  List<Entry> _entries = [];
  bool _loaded = false;
  File? _file;

  List<Entry> get entries => List.unmodifiable(_entries);
  bool get loaded => _loaded;
  int get count => _entries.length;
  bool get isEmpty => _entries.isEmpty;

  Entry? get latest => _entries.isEmpty ? null : _entries.first;

  Entry? byId(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<File> _resolveFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory('${dir.path}/sujian');
    if (!await d.exists()) await d.create(recursive: true);
    _file = File('${d.path}/$_fileName');
    return _file!;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final f = await _resolveFile();
      if (await f.exists()) {
        final raw = await f.readAsString();
        if (raw.trim().isNotEmpty) {
          final list = jsonDecode(raw);
          if (list is List) {
            _entries = list
                .whereType<Map>()
                .map((m) => Entry.fromJson(Map<String, dynamic>.from(m)))
                .where((e) => e.text.trim().isNotEmpty)
                .toList();
            _sort();
          }
        }
      }
    } catch (_) {
      _entries = [];
    }
    _loaded = true;
    notifyListeners();
  }

  void _sort() => _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  /// 有内容才入库；空白条目自动丢弃
  Future<void> upsert(Entry entry) async {
    final blank = entry.text.trim().isEmpty;
    final idx = _entries.indexWhere((e) => e.id == entry.id);

    if (blank) {
      if (idx >= 0) _entries.removeAt(idx);
    } else if (idx >= 0) {
      _entries[idx] = entry;
    } else {
      _entries.add(entry);
    }
    _sort();
    notifyListeners();
    await _flush();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _flush();
  }

  Future<void> _flush() async {
    try {
      final f = await _resolveFile();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(
        jsonEncode(_entries.map((e) => e.toJson()).toList()),
        flush: true,
      );
      await tmp.rename(f.path);
    } catch (_) {
      // 落盘失败不打断写作，下次编辑会再试
    }
  }
}
