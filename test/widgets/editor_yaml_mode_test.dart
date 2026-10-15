import 'package:bett_box/widgets/code_editor.dart';
import 'package:code_forge/code_forge.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

void main() {
  final highlighter = SyntaxHighlighter(
    language: editorYamlMode,
    editorTheme: atomOneLightTheme,
  );
  final comment = atomOneLightTheme['comment']?.color;

  Map<String, Color?> colors(String line) {
    final result = <String, Color?>{};
    highlighter.lineSpan(line)?.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        result[span.text ?? ''] = span.style?.color;
      }
      return true;
    });
    return result;
  }

  test('a hash inside a value is not a comment', () {
    for (final line in [
      '    - 114.114.114.114#DIRECT',
      '    - tls://223.5.5.5#DIRECT',
      'port: 7890#x',
    ]) {
      expect(colors(line).values, isNot(contains(comment)), reason: line);
    }
    expect(colors('    - 114.114.114.114#DIRECT').keys, [
      '    ',
      '-',
      ' ',
      '114.114.114.114#DIRECT',
    ]);
  });

  test('a hash after whitespace or at the line start is a comment', () {
    expect(colors('port: 7890 # mixed')['# mixed'], comment);
    expect(colors('# whole line')['# whole line'], comment);
    expect(colors('  # indented')['# indented'], comment);
  });

  test('numbers keep their color on their own', () {
    final number = atomOneLightTheme['number']?.color;
    expect(colors('port: 7890')['7890'], number);
    expect(colors('ports: [80, 443]')['80'], number);
  });
}
