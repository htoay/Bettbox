import 'dart:convert';
import 'dart:io';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory home;

  setUpAll(() async {
    home = await Directory.systemTemp.createTemp('bettbox_profiles_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => home.path,
        );
  });

  tearDownAll(() => home.delete(recursive: true));

  test('an unchanged update leaves the profile file untouched', () async {
    const profile = Profile(id: 'p', autoUpdateDuration: Duration(hours: 1));
    final file = File(await appPath.getProfilePath(profile.id));
    final first = utf8.encode('proxies: []\n');
    final second = utf8.encode('proxies: []\nrules: []\n');

    await profile.saveFile(first, validate: false);
    final stamp = DateTime(2020);
    await file.setLastModified(stamp);

    await profile.saveFile(first, validate: false);
    expect(await file.lastModified(), stamp);

    await profile.saveFile(second, validate: false);
    expect(await file.lastModified(), isNot(stamp));
    expect(await file.readAsString(), 'proxies: []\nrules: []\n');
  });
}
