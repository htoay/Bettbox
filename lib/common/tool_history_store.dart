import 'dart:convert';
import 'dart:io';

import 'package:bett_box/common/path.dart';
import 'package:synchronized/synchronized.dart';

class ToolHistoryStore {
  static const maxItems = 10;

  final _lock = Lock();
  Map<String, List<String>>? _cache;

  ToolHistoryStore._();

  static final instance = ToolHistoryStore._();

  Future<File> get _file async => File(await appPath.toolHistoryPath);

  Future<Map<String, List<String>>> _read() async {
    final cache = _cache;
    if (cache != null) return cache;
    final result = <String, List<String>>{};
    try {
      final file = await _file;
      if (await file.exists()) {
        final decoded = json.decode(await file.readAsString());
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final value = entry.value;
            if (entry.key is String && value is List) {
              result[entry.key as String] = value
                  .whereType<String>()
                  .take(maxItems)
                  .toList();
            }
          }
        }
      }
    } catch (_) {}
    _cache = result;
    return result;
  }

  Future<void> _write(Map<String, List<String>> data) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    final tempFile = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await tempFile.writeAsString(json.encode(data), flush: true);
    await tempFile.rename(file.path);
  }

  Future<List<String>> load(String key) => _lock.synchronized(
    () async => List.unmodifiable((await _read())[key] ?? const <String>[]),
  );

  Future<List<String>> add(String key, String value) =>
      _lock.synchronized(() async {
        final data = await _read();
        final items = [
          value,
          ...(data[key] ?? const <String>[]).where((item) => item != value),
        ].take(maxItems).toList();
        data[key] = items;
        try {
          await _write(data);
        } catch (_) {}
        return List.unmodifiable(items);
      });

  Future<void> clear(String key) => _lock.synchronized(() async {
    final data = await _read();
    if (data.remove(key) == null) return;
    try {
      await _write(data);
    } catch (_) {}
  });
}
