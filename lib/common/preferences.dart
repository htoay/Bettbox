import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:bett_box/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'constant.dart';
import 'path.dart';
import 'print.dart';

class Preferences {
  static Preferences? _instance;
  Completer<SharedPreferences?> sharedPreferencesCompleter = Completer();

  Future<bool> get isInit async =>
      await sharedPreferencesCompleter.future != null;

  Preferences._internal() {
    if (appPath.isPortable) {
      SharedPreferencesStorePlatform.instance = _FilePreferencesStore(
        appPath.sharedPreferencesPath,
      );
    }
    SharedPreferences.getInstance()
        .then((value) => sharedPreferencesCompleter.complete(value))
        .onError((_, _) => sharedPreferencesCompleter.complete(null));
  }

  factory Preferences() {
    _instance ??= Preferences._internal();
    return _instance!;
  }

  Future<ClashConfig?> getClashConfig() async {
    final preferences = await sharedPreferencesCompleter.future;
    final clashConfigString = preferences?.getString(clashConfigKey);
    if (clashConfigString == null) return null;
    try {
      final clashConfigMap = json.decode(clashConfigString);
      return ClashConfig.fromJson(clashConfigMap);
    } catch (e, stackTrace) {
      commonPrint.error(
        'Failed to parse clash config from preferences: $e\n$stackTrace',
      );
      return null;
    }
  }

  Future<Config?> getConfig() async {
    final preferences = await sharedPreferencesCompleter.future;

    Config? fileConfig;
    try {
      final configFilePath = await appPath.appConfigPath;
      final configFile = File(configFilePath);
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        if (content.isNotEmpty) {
          final configMap = json.decode(content);
          fileConfig = Config.compatibleFromJson(configMap);
        }
      }
    } catch (e, stackTrace) {
      commonPrint.error('Failed to parse config from file: $e\n$stackTrace');
    }

    Config? prefsConfig;
    if (fileConfig == null || fileConfig.profiles.isEmpty) {
      try {
        final configString = preferences?.getString(configKey);
        if (configString != null && configString.isNotEmpty) {
          final configMap = json.decode(configString);
          prefsConfig = Config.compatibleFromJson(configMap);
        }
      } catch (e, stackTrace) {
        commonPrint.error(
          'Failed to parse config from preferences: $e\n$stackTrace',
        );
      }
    }

    Config? selectedConfig;
    if (fileConfig != null && prefsConfig != null) {
      if (fileConfig.profiles.isEmpty && prefsConfig.profiles.isNotEmpty) {
        selectedConfig = prefsConfig;
        await saveConfig(prefsConfig);
      } else {
        selectedConfig = fileConfig;
      }
    } else {
      selectedConfig = fileConfig ?? prefsConfig;
      if (selectedConfig != null && fileConfig == null) {
        await saveConfig(selectedConfig);
      }
    }

    if (selectedConfig != null &&
        preferences?.getBool('autoLaunch') !=
            selectedConfig.appSetting.autoLaunch) {
      await preferences?.setBool(
        'autoLaunch',
        selectedConfig.appSetting.autoLaunch,
      );
    }

    if (Platform.isMacOS &&
        selectedConfig != null &&
        preferences?.getBool('keepDockIcon') !=
            selectedConfig.appSetting.keepDockIcon) {
      await preferences?.setBool(
        'keepDockIcon',
        selectedConfig.appSetting.keepDockIcon,
      );
    }

    return selectedConfig;
  }

  Future<bool> saveConfig(Config config) async {
    final preferences = await sharedPreferencesCompleter.future;
    await preferences?.setBool('autoLaunch', config.appSetting.autoLaunch);
    if (Platform.isMacOS) {
      await preferences?.setBool(
        'keepDockIcon',
        config.appSetting.keepDockIcon,
      );
    }

    final jsonStr = await Isolate.run(() => json.encode(config));

    try {
      await preferences?.setString(configKey, jsonStr);
    } catch (e) {
      commonPrint.warn('Failed to mirror config to preferences: $e');
    }

    try {
      final configFilePath = await appPath.appConfigPath;
      final tempFile = File(
        '$configFilePath.${DateTime.now().microsecondsSinceEpoch}.tmp',
      );
      await tempFile.parent.create(recursive: true);
      await tempFile.writeAsString(jsonStr, flush: true);
      try {
        await tempFile.rename(configFilePath);
      } catch (_) {
        if (await tempFile.exists()) {
          await tempFile.copy(configFilePath);
          await tempFile.delete();
        }
      }
      return true;
    } catch (e, stackTrace) {
      commonPrint.error('Failed to save config to file: $e\n$stackTrace');
      return false;
    }
  }

  Future<void> clearClashConfig() async {
    final preferences = await sharedPreferencesCompleter.future;
    preferences?.remove(clashConfigKey);
  }

  Future<void> clearPreferences() async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.clear();
    try {
      final file = File(await appPath.appConfigPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    try {
      final ipFile = File(await appPath.ipCacheFilePath);
      if (await ipFile.exists()) {
        await ipFile.delete();
      }
    } catch (_) {}
  }
}

final preferences = Preferences();

class _FilePreferencesStore extends SharedPreferencesStorePlatform {
  _FilePreferencesStore(this._path);

  static const _defaultPrefix = 'flutter.';

  final Future<String> _path;
  Map<String, Object>? _cache;

  Future<Map<String, Object>> _read() async {
    final cached = _cache;
    if (cached != null) return cached;
    final file = File(await _path);
    var data = <String, Object>{};
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      if (content.isNotEmpty) {
        final decoded = json.decode(content);
        if (decoded is Map) {
          data = decoded.cast<String, Object>();
        }
      }
    }
    return _cache ??= data;
  }

  Future<bool> _write(Map<String, Object> data) async {
    try {
      final file = File(await _path);
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      file.writeAsStringSync(json.encode(data), flush: true);
      return true;
    } catch (e) {
      commonPrint.warn('Failed to write preferences: $e');
      return false;
    }
  }

  bool _matches(String key, PreferencesFilter filter) =>
      key.startsWith(filter.prefix) &&
      (filter.allowList?.contains(key) ?? true);

  @override
  Future<bool> remove(String key) async {
    final data = await _read();
    data.remove(key);
    return _write(data);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final data = await _read();
    data[key] = value;
    return _write(data);
  }

  @override
  Future<bool> clear() => clearWithParameters(
    ClearParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
  );

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) async {
    final data = await _read();
    data.removeWhere((key, _) => _matches(key, parameters.filter));
    return _write(data);
  }

  @override
  Future<Map<String, Object>> getAll() => getAllWithParameters(
    GetAllParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
  );

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    final data = Map<String, Object>.from(await _read());
    data.removeWhere((key, _) => !_matches(key, parameters.filter));
    return data;
  }
}
