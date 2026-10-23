import 'dart:convert';
import 'dart:io';

import 'package:bett_box/common/path.dart';
import 'package:bett_box/models/models.dart';
import 'package:synchronized/synchronized.dart';

class SpeedTestStore {
  static const retention = Duration(days: 14);
  static const maxRecords = 200;

  final _lock = Lock();

  SpeedTestStore._();

  static final instance = SpeedTestStore._();

  static List<SpeedTestRecord> prune(
    Iterable<SpeedTestRecord> records,
    int now,
  ) {
    final minTime = now - retention.inMilliseconds;
    final result = records.where((item) => item.time >= minTime).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return result.take(maxRecords).toList();
  }

  Future<File> get _file async => File(await appPath.speedTestPath);

  Future<SpeedTestData> _read() async {
    try {
      final file = await _file;
      if (!await file.exists()) return const SpeedTestData();
      final decoded = json.decode(await file.readAsString());
      if (decoded is! Map) return const SpeedTestData();
      return SpeedTestData.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return const SpeedTestData();
    }
  }

  Future<void> _write(SpeedTestData data) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    final tempFile = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await tempFile.writeAsString(json.encode(data), flush: true);
    await tempFile.rename(file.path);
  }

  Future<SpeedTestData> _update(
    SpeedTestData Function(SpeedTestData data) transform,
  ) {
    return _lock.synchronized(() async {
      final data = await _read();
      final next = transform(data);
      final pruned = next.copyWith(
        records: prune(next.records, DateTime.now().millisecondsSinceEpoch),
      );
      if (pruned != data) {
        await _write(pruned);
      }
      return pruned;
    });
  }

  Future<SpeedTestData> load() => _update((data) => data);

  Future<SpeedTestData> addRecord(SpeedTestRecord record) {
    return _update((data) => data.copyWith(records: [record, ...data.records]));
  }

  Future<SpeedTestData> saveSettings(SpeedTestSettings settings) {
    return _update((data) => data.copyWith(settings: settings));
  }

  Future<SpeedTestData> clearRecords() {
    return _update((data) => data.copyWith(records: const []));
  }
}

final speedTestStore = SpeedTestStore.instance;
