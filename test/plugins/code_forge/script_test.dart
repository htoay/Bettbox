import 'dart:convert';
import 'dart:io';

import 'package:code_forge/script.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late Directory directory;

  setUpAll(() async {
    await initEditorNative();
    directory = await Directory.systemTemp.createTemp('script_test');
  });

  tearDownAll(() async {
    await directory.delete(recursive: true);
  });

  File write(String name, String content) {
    return File('${directory.path}/$name')..writeAsStringSync(content);
  }

  test('evaluates a script from file to file', () async {
    final input = write(
      'input.json',
      json.encode({
        'mode': 'rule',
        'rule': ['MATCH,DIRECT'],
        'proxy-providers': null,
      }),
    );
    final output = File('${directory.path}/output.json');

    final result = await evaluateScriptFile(
      script:
          'const ruleOptionsEnable = { ads: true };\n'
          'function main(config) {\n'
          "  console.log('rules', config.rules.length);\n"
          '  config.flags = ruleOptionsEnable;\n'
          "  config.mode = 'global';\n"
          '  return config;\n'
          '}',
      inputPath: input.path,
      outputPath: output.path,
      customOptions: json.encode({'ads': false}),
      token: 1,
    );

    expect(json.decode(output.readAsStringSync()), {
      'mode': 'global',
      'rules': ['MATCH,DIRECT'],
      'proxy-providers': <String, dynamic>{},
      'flags': {'ads': false},
    });
    expect(result.logs.single.text, 'rules 1');
  });

  test('reports a failing script without writing output', () async {
    final input = write('failing.json', '{}');
    final output = File('${directory.path}/failing-output.json');

    await expectLater(
      evaluateScriptFile(
        script: "function main() { throw new Error('boom') }",
        inputPath: input.path,
        outputPath: output.path,
        token: 2,
      ),
      throwsA(
        isA<ScriptError>()
            .having((e) => e.kind, 'kind', ScriptErrorKind.runtime)
            .having((e) => e.message, 'message', contains('boom')),
      ),
    );
    expect(output.existsSync(), isFalse);
  });

  test('extracts script options', () async {
    final options = json.decode(
      await extractScriptOptions(
        script:
            'const ruleOptionsEnable = { ai: true };\n'
            "const serviceConfigs = [{ name: 'AI', icon: 'ai.png' }];\n"
            "const Compatible_With_Bettbox = { policyGroupOptions: ['AI'] };\n"
            'function main(config) { return config }',
      ),
    );

    expect(options, {
      'options': {'ai': true},
      'icons': {'AI': 'ai.png'},
      'policyGroupOptions': ['AI'],
    });
  });
}
