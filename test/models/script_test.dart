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
    home = await Directory.systemTemp.createTemp('bettbox_scripts_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => home.path,
        );
  });

  tearDownAll(() => home.delete(recursive: true));

  test('legacy inline content moves to files and leaves the config', () async {
    final large = 'x' * 100000;
    final legacy = ScriptProps.fromJson({
      'currentId': 'a',
      'scripts': [
        {
          'id': 'a',
          'label': 'A',
          'content': '// Compatible_With_Bettbox\nfunction main(c){return c}',
        },
        {'id': 'b', 'label': 'B', 'content': large},
      ],
    });

    final props = await legacy.externalize();

    expect(props.currentId, 'a');
    expect(props.scripts.every((script) => script.content.isEmpty), isTrue);
    expect(json.encode(props).length, lessThan(600));
    expect(props.scripts[0].compatible, isTrue);
    expect(props.scripts[1].compatible, isFalse);
    expect(props.scripts[1].volatile, isFalse);
    expect(props.scripts[1].digest, large.toMd5());
    expect(await props.scripts[1].readContent(), large);
    expect(await props.externalize(), same(props));
  });

  test('saved content is read back and tracked by digest', () async {
    final draft = Script.create(label: 'C');
    final first = await draft.writeContent('function main(c){return c}');
    final second = await first.writeContent('function main(c){return {}}');

    final timed = await Script.create(
      label: 'D',
    ).writeContent('const now = new Date()');

    expect(first.content, isEmpty);
    expect(first.volatile, isFalse);
    expect(timed.volatile, isTrue);
    expect(second.digest, isNot(first.digest));
    expect(await second.readContent(), 'function main(c){return {}}');

    await second.deleteContent();

    expect(
      await File(await appPath.getScriptPath(second.id)).exists(),
      isFalse,
    );
    expect(await second.readContent(), isEmpty);
  });

  test('script ids cannot escape the scripts directory', () async {
    final path = await appPath.getScriptPath('../../outside');

    expect(File(path).parent.path, '${home.path}/scripts');
  });
}
