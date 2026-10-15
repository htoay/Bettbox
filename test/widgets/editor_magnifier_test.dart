import 'package:bett_box/widgets/code_editor.dart';
import 'package:code_forge/code_forge.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../plugins/code_forge/support.dart';

void main() {
  setUpAll(initEditorNative);

  testWidgets('the magnifier keeps the colors of the whole highlighted line', (
    tester,
  ) async {
    const key = 'name';
    const value = ': "a long quoted value here"';
    final controller = CodeForgeController()
      ..text = '$key$value'
      ..selection = const TextSelection.collapsed(offset: 20);
    const red = Color(0xFFFF0000);
    final info = ValueNotifier(
      const MagnifierInfo(
        globalGesturePosition: Offset(100, 200),
        caretRect: Rect.fromLTWH(100, 190, 2, 20),
        fieldBounds: Rect.fromLTWH(0, 0, 400, 600),
        currentLineBoundaries: Rect.fromLTWH(0, 190, 400, 20),
      ),
    );
    addTearDown(info.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            EditorMagnifier(
              controller: controller,
              magnifierInfo: info,
              textStyle: const TextStyle(fontSize: 14),
              backgroundColor: Colors.white,
              borderColor: Colors.grey,
              caretColor: Colors.blue,
              lineSpan: (_, text) => TextSpan(
                children: [
                  TextSpan(text: text.substring(0, key.length)),
                  TextSpan(
                    text: text.substring(key.length),
                    style: const TextStyle(color: red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(EditorMagnifier),
        matching: find.byType(RichText),
      ),
    );
    final pieces = <(String, Color?)>[];
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        pieces.add((span.text!, span.style?.color));
      }
      return true;
    });

    expect(
      pieces.map((piece) => piece.$1).join(),
      '$key$value'.substring(10, 30),
    );
    expect(pieces.every((piece) => piece.$2 == red), isTrue);
  });
}
