import 'dart:async';

import 'package:code_forge/code_forge.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  setUpAll(initEditorNative);
  group('editing', _editing);
  group('indent', _indent);
  group('comment', _comment);
  group('block comment', _blockComment);
  group('undo redo', _undoRedo);
  group('ime selection', _imeSelection);
  group('keyboard', _keyboard);
  group('clipboard', _clipboard);
  group('completion', _completion);
  group('snippet', _snippet);
  group('find', _find);
}

const _document = 'proxies:\n  - name: a\n    port: 80\nrules:\n  - MATCH,a';

void _editing() {
  testWidgets('typing through the input client inserts at the caret', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = _document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(1) + '  - name: a'.length,
    );
    await typeText(tester, controller, 'bc');

    expect(controller.getLineText(1), '  - name: abc');
    expect(controller.lineCount, 5);
    expect(
      controller.selection,
      TextSelection.collapsed(
        offset: controller.getLineStartOffset(1) + '  - name: abc'.length,
      ),
    );
  });

  testWidgets('a typed newline splits the line and keeps its indentation', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = _document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(2) + '    port: 80'.length,
    );
    await typeText(tester, controller, '\n');
    await typeText(tester, controller, 'udp: true');

    expect(controller.lineCount, 6);
    expect(controller.getLineText(2), '    port: 80');
    expect(controller.getLineText(3), '    udp: true');
    expect(controller.getLineText(4), 'rules:');
  });

  testWidgets('undo and redo walk the edit history', (tester) async {
    final controller = CodeForgeController()..text = _document;
    final undo = UndoRedoController();
    addTearDown(undo.dispose);
    await pumpEditor(tester, controller, undoController: undo);
    await focusEditor(tester);

    controller.selection = TextSelection.collapsed(offset: controller.length);
    await typeText(tester, controller, '\n');
    await typeText(tester, controller, '- DIRECT');
    final edited = controller.text;
    expect(controller.lineCount, 6);
    expect(undo.canUndo, isTrue);

    while (undo.canUndo) {
      undo.undo();
      await settle(tester, 2);
    }
    expect(controller.text, _document);
    expect(controller.lineCount, 5);
    expect(undo.canRedo, isTrue);

    while (undo.canRedo) {
      undo.redo();
      await settle(tester, 2);
    }
    expect(controller.text, edited);
    expect(controller.lineCount, 6);
  });

  testWidgets('replaceRange edits are undoable as one step', (tester) async {
    final controller = CodeForgeController()..text = _document;
    final undo = UndoRedoController();
    addTearDown(undo.dispose);
    await pumpEditor(tester, controller, undoController: undo);
    await focusEditor(tester);

    final start = controller.getLineStartOffset(3);
    controller.replaceRange(start, start, 'dns:\n  enable: true\n');
    await settle(tester, 2);
    expect(controller.lineCount, 7);
    expect(controller.getLineText(3), 'dns:');
    expect(controller.getLineText(5), 'rules:');

    expect(undo.undo(), isTrue);
    await settle(tester, 2);
    expect(controller.text, _document);

    expect(undo.redo(), isTrue);
    await settle(tester, 2);
    expect(controller.getLineText(4), '  enable: true');
  });

  testWidgets('backspace deletes before the caret and joins lines', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = _document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(2) + '    port: 80'.length,
    );
    controller.backspace();
    controller.backspace();
    await settle(tester, 2);
    expect(controller.getLineText(2), '    port: ');

    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(3),
    );
    controller.backspace();
    await settle(tester, 2);
    expect(controller.lineCount, 4);
    expect(controller.getLineText(2), '    port: rules:');
  });

  testWidgets('read-only opens no input connection and rejects edits', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = _document;
    await pumpEditor(tester, controller, readOnly: true);
    await focusEditor(tester);

    expect(
      tester.testTextInput.log.where(
        (call) => call.method == 'TextInput.setClient',
      ),
      isEmpty,
    );
    controller.selection = TextSelection.collapsed(offset: controller.length);
    controller.insertAtCurrentCursor('x\ny');
    controller.backspace();
    await settle(tester, 2);

    expect(controller.text, _document);
    expect(controller.lineCount, 5);
  });

  testWidgets('delete removes after the caret, joins lines and undoes', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = _document;
    final undo = UndoRedoController();
    addTearDown(undo.dispose);
    await pumpEditor(tester, controller, undoController: undo);
    await focusEditor(tester);

    final lineEnd = controller.getLineStartOffset(2) + '    port: 80'.length;
    controller.selection = TextSelection.collapsed(offset: lineEnd - 2);
    controller.delete();
    controller.delete();
    controller.delete();
    await settle(tester, 2);
    expect(controller.getLineText(2), '    port: rules:');
    expect(controller.lineCount, 4);
    expect(controller.selection, TextSelection.collapsed(offset: lineEnd - 2));

    while (undo.canUndo) {
      undo.undo();
    }
    await settle(tester, 2);
    expect(controller.text, _document);
  });

  testWidgets('deleting a word stops where CJK meets punctuation', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = 'a: \u4f60\u597d!!';
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    controller.selection = TextSelection.collapsed(offset: controller.length);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await settle(tester, 2);
    expect(controller.text, 'a: \u4f60\u597d');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester, 2);
    expect(controller.text, 'a: ');
  });

  testWidgets('typed quotes and brackets pair, close over and skip words', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = '';
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    controller.selection = const TextSelection.collapsed(offset: 0);
    await typeText(tester, controller, 'a: "abc"');
    expect(controller.text, 'a: "abc"');
    await typeText(tester, controller, " # don't [x] 'q'");
    expect(controller.text, 'a: "abc" # don\'t [x] \'q\'');
    expect(controller.selection.extentOffset, controller.length);

    await typeText(tester, controller, ' (');
    expect(controller.text, endsWith(' ()'));
    expect(controller.selection.extentOffset, controller.length - 1);
  });

  testWidgets('a closer typed at the end of an edited line is not skipped', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = 'ab\n)x';
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    controller.selection = const TextSelection.collapsed(offset: 2);
    await typeText(tester, controller, 'c)');

    expect(controller.text, 'abc)\n)x');
    expect(controller.selection, const TextSelection.collapsed(offset: 4));
  });

  testWidgets('indenting an upward selection keeps it on the same text', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = _document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    final tab = controller.tabSpace.length;

    final base = controller.getLineStartOffset(2) + '    port'.length;
    final extent = controller.getLineStartOffset(1) + '  - '.length;
    controller.selection = TextSelection(
      baseOffset: base,
      extentOffset: extent,
    );
    controller.indent();
    await settle(tester, 2);
    expect(
      controller.selection,
      TextSelection(baseOffset: base + 2 * tab, extentOffset: extent + tab),
    );

    controller.unindent();
    await settle(tester, 2);
    expect(controller.text, _document);
    expect(
      controller.selection,
      TextSelection(baseOffset: base, extentOffset: extent),
    );
  });

  testWidgets('a batch of deltas maps each one in the window it was sent in', (
    tester,
  ) async {
    final controller = CodeForgeController()
      ..text = List.generate(8, (i) => 'l$i').join('\n');
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(3) + 2,
    );
    await tester.pump();
    final value = controller.currentTextEditingValue;
    final caret = value.selection.extentOffset;
    final afterNewline = value.text.replaceRange(caret, caret, '\n');
    await sendDeltas(tester, [
      textDelta(value.text, '\n', caret, caret),
      textDelta(afterNewline, '', caret - 1, caret),
    ]);
    await settle(tester, 2);

    expect(controller.text, 'l0\nl1\nl2\nl\n\nl4\nl5\nl6\nl7');
  });

  testWidgets('the IME sees unflushed typing on a line past its window', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = 'k: ${'a' * 5000}';
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    final value = controller.currentTextEditingValue;
    final caret = value.selection.extentOffset;
    await sendDeltas(tester, [textDelta(value.text, 'x', caret, caret)]);

    final projected = controller.currentTextEditingValue;
    expect(projected.text, startsWith('k: xa'));
    expect(projected.selection, const TextSelection.collapsed(offset: 4));
    await settle(tester, 2);
  });

  testWidgets('getLinesRange includes typing not yet flushed to the rope', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = 'a\nb\nc';
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    final value = controller.currentTextEditingValue;
    final caret = value.selection.extentOffset;
    await sendDeltas(tester, [textDelta(value.text, 'x', caret, caret)]);

    expect(controller.getLinesRange(0, 3), ['a', 'bx', 'c']);
    await settle(tester, 2);
  });

  testWidgets('select all hands the IME a window at the caret', (tester) async {
    final controller = CodeForgeController()
      ..text = List.generate(20000, (i) => 'line $i').join('\n');
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    controller.selectAll();
    await tester.pump();
    final value = controller.currentTextEditingValue;
    expect(value.text.length, lessThan(controller.text.length ~/ 10));
    expect(controller.text, endsWith(value.text));
    expect(
      value.selection,
      TextSelection(baseOffset: 0, extentOffset: value.text.length),
    );
    await settle(tester, 2);
  });

  testWidgets('a caret the input method moves out of its window gets the '
      'new window', (tester) async {
    final controller = CodeForgeController()
      ..text = List.generate(20, (i) => 'line $i').join('\n');
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(10) + 3,
    );
    await tester.pump();

    final value = controller.currentTextEditingValue;
    expect(value.text, isNot(contains('line 14')));
    final moved = value.text.indexOf('line 12') + 3;
    final logged = tester.testTextInput.log.length;
    await sendDeltas(tester, [
      {
        ...textDelta(value.text, '', -1, -1),
        'selectionBase': moved,
        'selectionExtent': moved,
      },
    ]);
    expect(
      controller.selection,
      TextSelection.collapsed(offset: controller.getLineStartOffset(12) + 3),
    );
    final sent = tester.testTextInput.log
        .skip(logged)
        .lastWhere((call) => call.method == 'TextInput.setEditingState');
    final state = sent.arguments as Map;
    expect(state['text'], contains('line 14'));

    final caret = state['selectionExtent'] as int;
    await sendDeltas(tester, [
      textDelta(state['text'] as String, '', caret - 1, caret),
    ]);
    expect(controller.getLineText(12), 'lie 12');
    await settle(tester, 2);
  });

  group('a selection the IME window cuts short', () {
    final document = List.generate(2000, (i) => 'line $i').join('\n');
    late CodeForgeController controller;
    late UndoRedoController undo;
    late String window;

    Future<void> selectAll(WidgetTester tester) async {
      controller = CodeForgeController()..text = document;
      undo = UndoRedoController();
      addTearDown(undo.dispose);
      await pumpEditor(tester, controller, undoController: undo);
      await focusEditor(tester);
      controller.selectAll();
      await tester.pump();
      window = controller.currentTextEditingValue.text;
      expect(window.length, lessThan(document.length));
    }

    void expectOneUndoRestoresIt([TextSelection? selection]) {
      expect(undo.undo(), isTrue);
      expect(controller.text, document);
      expect(
        controller.selection,
        selection ??
            TextSelection(baseOffset: 0, extentOffset: document.length),
      );
      expect(undo.canUndo, isFalse);
    }

    testWidgets('is replaced whole by typed text', (tester) async {
      await selectAll(tester);
      await sendDeltas(tester, [textDelta(window, 'x', 0, window.length)]);

      expect(controller.text, 'x');
      expect(controller.selection, const TextSelection.collapsed(offset: 1));
      expectOneUndoRestoresIt();
      await settle(tester, 2);
    });

    testWidgets('is replaced whole by text that repeats its start', (
      tester,
    ) async {
      await selectAll(tester);
      await sendDeltas(tester, [
        textDelta(window, window[0], 0, window.length),
      ]);

      expect(controller.text, window[0]);
      expectOneUndoRestoresIt();
      await settle(tester, 2);
    });

    testWidgets('is replaced whole by a composition', (tester) async {
      await selectAll(tester);
      await sendDeltas(tester, [
        {
          ...textDelta(window, 'k', 0, window.length),
          'composingBase': 0,
          'composingExtent': 1,
        },
      ]);
      expect(controller.imeComposition?.displayText, 'k');
      expect(controller.text, isEmpty);

      await sendDeltas(tester, [textDelta('k', '可', 0, 1)]);
      expect(controller.text, '可');
      expectOneUndoRestoresIt();
      await settle(tester, 2);
    });

    testWidgets('is replaced whole by a composition begun after the input '
        'method collapsed it', (tester) async {
      await selectAll(tester);
      await sendDeltas(tester, [
        {
          ...textDelta(window, '', -1, -1),
          'selectionBase': window.length,
          'selectionExtent': window.length,
        },
      ]);
      expect(
        controller.selection,
        TextSelection.collapsed(offset: document.length),
      );

      final value = controller.currentTextEditingValue;
      final caret = value.selection.extentOffset;
      await sendDeltas(tester, [
        {
          ...textDelta(value.text, 'k', caret, caret),
          'composingBase': caret,
          'composingExtent': caret + 1,
        },
      ]);
      expect(controller.imeComposition?.displayText, 'k');
      expect(controller.text, isEmpty);
      await settle(tester, 2);
    });

    Map<String, Object> caretDelta(String text, int caret, [int? extent]) => {
      ...textDelta(text, '', -1, -1),
      'selectionBase': caret,
      'selectionExtent': extent ?? caret,
    };

    Map<String, Object> composingDelta(String text, String typed, int at) => {
      ...textDelta(text, typed, at, at),
      'composingBase': at,
      'composingExtent': at + typed.length,
    };

    testWidgets('cut by the platform reaches the clipboard whole', (
      tester,
    ) async {
      final clipboard = mockClipboard(tester);
      await selectAll(tester);
      clipboard.text = window;

      await sendDeltas(tester, [textDelta(window, '', 0, window.length)]);
      await settle(tester, 2);

      expect(controller.text, isEmpty);
      expect(clipboard.text, document);
    });

    testWidgets('deleted by an input method that collapses it first leaves '
        'the clipboard alone', (tester) async {
      final clipboard = mockClipboard(tester);
      await selectAll(tester);
      clipboard.text = window;

      await sendDeltas(tester, [
        caretDelta(window, window.length),
        textDelta(window, '', 0, window.length),
      ]);
      await settle(tester, 2);

      expect(controller.text, isEmpty);
      expect(clipboard.text, window);
      expectOneUndoRestoresIt();
    });

    testWidgets('is replaced whole by an input method that collapses it, '
        'deletes what it saw, then composes', (tester) async {
      await selectAll(tester);
      await sendDeltas(tester, [
        caretDelta(window, window.length),
        textDelta(window, '', 0, window.length),
      ]);
      expect(controller.text, isEmpty);

      await sendDeltas(tester, [composingDelta('', 'k', 0)]);
      expect(controller.imeComposition?.displayText, 'k');
      expect(controller.text, isEmpty);

      await sendDeltas(tester, [textDelta('k', '可', 0, 1)]);
      expect(controller.text, '可');
      expectOneUndoRestoresIt();
      await settle(tester, 2);
    });

    testWidgets('outlives an input method that collapses it and then deletes '
        'a character', (tester) async {
      await selectAll(tester);
      await sendDeltas(tester, [caretDelta(window, window.length)]);
      final value = controller.currentTextEditingValue;
      final caret = value.selection.extentOffset;
      await sendDeltas(tester, [textDelta(value.text, '', caret - 1, caret)]);

      expect(controller.text, document.substring(0, document.length - 1));
      await settle(tester, 2);
    });

    testWidgets('outlives an input method that collapses it to its middle, '
        'moves the caret and then composes', (tester) async {
      await selectAll(tester);
      final middle = window.length ~/ 2;
      await sendDeltas(tester, [
        caretDelta(window, middle, window.length),
        caretDelta(window, middle),
      ]);
      var value = controller.currentTextEditingValue;
      var caret = value.selection.extentOffset;
      await sendDeltas(tester, [
        caretDelta(value.text, caret - 1, caret),
        caretDelta(value.text, caret - 1),
      ]);
      value = controller.currentTextEditingValue;
      caret = value.selection.extentOffset;
      await sendDeltas(tester, [composingDelta(value.text, 'k', caret)]);

      expect(controller.imeComposition?.displayText, 'k');
      expect(controller.text, document);
      await settle(tester, 2);
    });

    testWidgets('takes what the input method typed into the window it had '
        'before the new one reached it', (tester) async {
      await selectAll(tester);
      final kept = document.substring(0, document.indexOf('line 10'));
      controller.selection = TextSelection(
        baseOffset: kept.length,
        extentOffset: document.length,
      );
      await tester.pump();
      window = controller.currentTextEditingValue.text;
      await sendDeltas(tester, [
        caretDelta(window, window.length),
        textDelta(window, '', 0, window.length),
      ]);
      expect(controller.text, kept);
      final resent = controller.currentTextEditingValue;
      expect(resent.text, isNotEmpty);

      await sendDeltas(tester, [composingDelta('', 'q', 0)]);
      expect(controller.text, '${kept}q');
      expect(controller.imeComposition, isNull);

      await sendDeltas(tester, [
        caretDelta(resent.text, resent.selection.extentOffset),
      ]);
      expect(
        controller.selection,
        TextSelection.collapsed(offset: kept.length + 1),
      );

      await typeText(tester, controller, 'w');
      expect(controller.text, '${kept}qw');
    });

    testWidgets('takes what the input method typed into that window after '
        'hiding its keyboard', (tester) async {
      await selectAll(tester);
      final kept = document.substring(0, document.indexOf('line 10'));
      controller.selection = TextSelection(
        baseOffset: kept.length,
        extentOffset: document.length,
      );
      await tester.pump();
      window = controller.currentTextEditingValue.text;
      await sendDeltas(tester, [
        caretDelta(window, window.length),
        textDelta(window, '', 0, window.length),
      ]);

      await sendDeltas(tester, []);
      await sendDeltas(tester, [composingDelta('', 'q', 0)]);

      expect(controller.text, '${kept}q');
      expectOneUndoRestoresIt(
        TextSelection(baseOffset: kept.length, extentOffset: document.length),
      );
      await settle(tester, 2);
    });

    testWidgets('takes what the input method went on typing into that '
        'window', (tester) async {
      await selectAll(tester);
      final kept = document.substring(0, document.indexOf('line 10'));
      controller.selection = TextSelection(
        baseOffset: kept.length,
        extentOffset: document.length,
      );
      await tester.pump();
      window = controller.currentTextEditingValue.text;
      await sendDeltas(tester, [
        caretDelta(window, window.length),
        textDelta(window, '', 0, window.length),
      ]);

      await sendDeltas(tester, [composingDelta('', 'q', 0)]);
      await sendDeltas(tester, [
        {...composingDelta('q', 'w', 1), 'composingBase': 0},
      ]);

      expect(controller.text, '${kept}qw');
      await settle(tester, 2);
    });

    testWidgets('is replaced whole by a whole editing value', (tester) async {
      await selectAll(tester);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'x',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();

      expect(controller.text, 'x');
      expectOneUndoRestoresIt();
      await settle(tester, 2);
    });
  });

  testWidgets('moving the caret mid-composition commits it in scalars', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = _document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    final anchor = controller.getLineStartOffset(1) + '  - name: '.length;
    controller.selection = TextSelection.collapsed(offset: anchor);
    await tester.pump();
    final setClient = tester.testTextInput.log.lastWhere(
      (call) => call.method == 'TextInput.setClient',
    );
    final client = (setClient.arguments as List)[0] as int;
    final value = controller.currentTextEditingValue;
    final caret = value.selection.extentOffset;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall('TextInputClient.updateEditingStateWithDeltas', [
          client,
          {
            'deltas': [
              {
                'oldText': value.text,
                'deltaText': '\u{1F600}',
                'deltaStart': caret,
                'deltaEnd': caret,
                'selectionBase': caret + 2,
                'selectionExtent': caret + 2,
                'selectionAffinity': 'TextAffinity.downstream',
                'selectionIsDirectional': false,
                'composingBase': caret,
                'composingExtent': caret + 2,
              },
            ],
          },
        ]),
      ),
      (_) {},
    );
    await tester.pump();
    expect(controller.isComposingActive, isTrue);

    final lineEnd = controller.getLineStartOffset(1) + '  - name: a'.length;
    controller.selection = TextSelection.collapsed(offset: lineEnd);
    await settle(tester, 2);
    expect(controller.getLineText(1), '  - name: \u{1F600}a');
    expect(controller.selection, TextSelection.collapsed(offset: lineEnd + 1));
  });

  group('an interrupted composition', () {
    Future<CodeForgeController> composeThenMoveCaret(
      WidgetTester tester,
      List<String> shown,
    ) async {
      final controller = CodeForgeController()..text = 'ab';
      await pumpEditor(tester, controller);
      await focusEditor(tester);
      controller.selection = const TextSelection.collapsed(offset: 1);
      await tester.pump();
      final base = controller.currentTextEditingValue;
      final caret = base.selection.extentOffset;
      var composing = '';
      for (final next in shown) {
        await sendDeltas(tester, [
          {
            ...textDelta(
              base.text.replaceRange(caret, caret, composing),
              next,
              caret,
              caret + composing.length,
            ),
            'composingBase': caret,
            'composingExtent': caret + next.length,
          },
        ]);
        composing = next;
      }
      expect(controller.imeComposition?.displayText, shown.last);
      controller.selection = const TextSelection.collapsed(offset: 0);
      await settle(tester, 2);
      return controller;
    }

    testWidgets('commits kana as shown', (tester) async {
      final controller = await composeThenMoveCaret(tester, [
        'k',
        'か',
        'かn',
        'かな',
      ]);
      expect(controller.text, 'aかなb');
    });

    testWidgets('commits pinyin as typed, without the separators', (
      tester,
    ) async {
      final controller = await composeThenMoveCaret(tester, [
        'n',
        'ni',
        "ni'h",
        "ni'ha",
        "ni'hao",
      ]);
      expect(controller.text, 'anihaob');
    });

    testWidgets('commits a word taken up whole with its apostrophe', (
      tester,
    ) async {
      final controller = CodeForgeController()..text = "x: don't";
      await pumpEditor(tester, controller);
      await focusEditor(tester);
      await sendDeltas(tester, [
        {
          ...textDelta("x: don't", '', -1, -1),
          'selectionBase': 8,
          'selectionExtent': 8,
          'composingBase': 3,
          'composingExtent': 8,
        },
        {
          ...textDelta("x: don't", "don'ts", 3, 8),
          'composingBase': 3,
          'composingExtent': 9,
        },
      ]);
      expect(controller.imeComposition?.displayText, "don'ts");

      controller.selection = const TextSelection.collapsed(offset: 0);
      await settle(tester, 2);
      expect(controller.text, "x: don'ts");
    });
  });

  group('composing after a selection', () {
    Future<CodeForgeController> selectHello(WidgetTester tester) async {
      final controller = CodeForgeController()..text = 'hello world';
      await pumpEditor(tester, controller);
      await focusEditor(tester);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );
      await tester.pump();
      return controller;
    }

    Future<void> composeAtCaret(
      WidgetTester tester,
      CodeForgeController controller,
    ) async {
      final value = controller.currentTextEditingValue;
      final caret = value.selection.extentOffset;
      await sendDeltas(tester, [
        {
          ...textDelta(value.text, 'n', caret, caret),
          'composingBase': caret,
          'composingExtent': caret + 1,
        },
      ]);
      expect(controller.isComposingActive, isTrue);
    }

    testWidgets('the input method already deleted keeps the rest', (
      tester,
    ) async {
      final controller = await selectHello(tester);
      final value = controller.currentTextEditingValue;
      await sendDeltas(tester, [textDelta(value.text, '', 0, 5)]);
      expect(controller.text, ' world');

      await composeAtCaret(tester, controller);
      expect(controller.text, ' world');
      await settle(tester, 2);
    });

    testWidgets('the input method only collapsed is replaced', (tester) async {
      final controller = await selectHello(tester);
      final value = controller.currentTextEditingValue;
      await sendDeltas(tester, [
        {
          ...textDelta(value.text, '', -1, -1),
          'selectionBase': 5,
          'selectionExtent': 5,
        },
      ]);
      expect(controller.selection, const TextSelection.collapsed(offset: 5));

      await composeAtCaret(tester, controller);
      expect(controller.text, ' world');
      await settle(tester, 2);
    });

    // Android reports a caret the input method sets as two selections, the
    // first still reaching back to where the old one ended.
    Future<void> moveCaret(
      WidgetTester tester,
      CodeForgeController controller,
      int caret,
    ) async {
      final value = controller.currentTextEditingValue;
      await sendDeltas(tester, [
        for (final extent in [value.selection.end, caret])
          {
            ...textDelta(value.text, '', -1, -1),
            'selectionBase': caret,
            'selectionExtent': extent,
          },
      ]);
      expect(controller.selection, TextSelection.collapsed(offset: caret));
    }

    testWidgets('the input method only collapsed gets the caret after what '
        'is committed over it', (tester) async {
      final controller = await selectHello(tester);
      await moveCaret(tester, controller, 5);
      await composeAtCaret(tester, controller);

      await sendDeltas(tester, [
        {
          ...textDelta('hellon world', '', -1, -1),
          'selectionBase': 6,
          'selectionExtent': 6,
        },
      ]);
      expect(controller.isComposingActive, isFalse);
      expect(controller.text, 'n world');
      expect(controller.selection, const TextSelection.collapsed(offset: 1));
      await settle(tester, 2);
    });

    testWidgets('the input method only collapsed takes Enter after what is '
        'composed over it', (tester) async {
      final controller = await selectHello(tester);
      await moveCaret(tester, controller, 5);
      await composeAtCaret(tester, controller);

      await sendDeltas(tester, [textDelta('hellon world', '\n', 6, 6)]);
      expect(controller.text, 'n\n world');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
      await settle(tester, 2);
    });

    testWidgets('the input method collapsed to its start stays replaced', (
      tester,
    ) async {
      final controller = await selectHello(tester);
      await moveCaret(tester, controller, 0);
      await composeAtCaret(tester, controller);
      expect(controller.text, ' world');

      await sendDeltas(tester, [
        {
          ...textDelta('nhello world', '', -1, -1),
          'selectionBase': 1,
          'selectionExtent': 1,
        },
      ]);
      expect(controller.text, 'n world');
      expect(controller.selection, const TextSelection.collapsed(offset: 1));
      await settle(tester, 2);
    });

    testWidgets(
      'the input method collapsed and moved the caret within is kept',
      (tester) async {
        final controller = await selectHello(tester);
        await moveCaret(tester, controller, 5);
        await moveCaret(tester, controller, 3);

        await composeAtCaret(tester, controller);
        expect(controller.text, 'hello world');
        await settle(tester, 2);
      },
    );

    testWidgets('the input method collapsed to its middle is kept', (
      tester,
    ) async {
      final controller = await selectHello(tester);
      await moveCaret(tester, controller, 2);

      await composeAtCaret(tester, controller);
      expect(controller.text, 'hello world');
      await settle(tester, 2);
    });

    testWidgets('the input method composes over before the same text '
        'leaves that text', (tester) async {
      final controller = CodeForgeController()..text = 'aa';
      await pumpEditor(tester, controller);
      await focusEditor(tester);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 1,
      );
      await tester.pump();
      await sendDeltas(tester, [
        {
          ...textDelta('aa', 'n', 0, 1),
          'composingBase': 0,
          'composingExtent': 1,
        },
      ]);
      expect(controller.imeComposition?.displayText, 'n');
      expect(controller.text, 'a');

      controller.commitComposition();
      await settle(tester, 2);
      expect(controller.text, 'na');
    });
  });

  group('a composition in progress', () {
    Future<CodeForgeController> composeE(
      WidgetTester tester, {
      UndoRedoController? undo,
    }) async {
      final controller = CodeForgeController()..text = 'a:\n  b: tru\nc';
      await pumpEditor(tester, controller, undoController: undo);
      await focusEditor(tester);
      controller.selection = const TextSelection.collapsed(offset: 11);
      await tester.pump();
      final value = controller.currentTextEditingValue;
      final caret = value.selection.extentOffset;
      await sendDeltas(tester, [
        {
          ...textDelta(value.text, 'e', caret, caret),
          'composingBase': caret,
          'composingExtent': caret + 1,
        },
      ]);
      expect(controller.imeComposition?.displayText, 'e');
      expect(controller.text, 'a:\n  b: tru\nc');
      return controller;
    }

    testWidgets('ended by Enter indents the new line', (tester) async {
      final controller = await composeE(tester);

      await sendDeltas(tester, [textDelta('a:\n  b: true\nc', '\n', 12, 12)]);

      expect(controller.isComposingActive, isFalse);
      expect(controller.text, 'a:\n  b: true\n  \nc');
      expect(controller.selection, const TextSelection.collapsed(offset: 15));
      await settle(tester, 2);
    });

    testWidgets('ended by a bracket gets the bracket closed', (tester) async {
      final controller = await composeE(tester);

      await sendDeltas(tester, [textDelta('a:\n  b: true\nc', '(', 12, 12)]);

      expect(controller.text, 'a:\n  b: true()\nc');
      expect(controller.selection, const TextSelection.collapsed(offset: 13));
      await settle(tester, 2);
    });

    testWidgets('an undo takes back before the edit made ahead of it', (
      tester,
    ) async {
      final undo = UndoRedoController();
      addTearDown(undo.dispose);
      final controller = CodeForgeController()..text = 'a:\n  b: t\nc';
      await pumpEditor(tester, controller, undoController: undo);
      await focusEditor(tester);
      controller.selection = const TextSelection.collapsed(offset: 9);
      await typeText(tester, controller, 'ru');
      final value = controller.currentTextEditingValue;
      final caret = value.selection.extentOffset;
      await sendDeltas(tester, [
        {
          ...textDelta(value.text, 'e', caret, caret),
          'composingBase': caret,
          'composingExtent': caret + 1,
        },
      ]);
      expect(controller.imeComposition?.displayText, 'e');

      expect(undo.undo(), isTrue);
      expect(controller.isComposingActive, isFalse);
      expect(controller.text, 'a:\n  b: tru\nc');
      expect(undo.undo(), isTrue);
      expect(controller.text, 'a:\n  b: t\nc');

      undo
        ..redo()
        ..redo();
      expect(controller.text, 'a:\n  b: true\nc');
      await settle(tester, 2);
    });

    testWidgets('an undo takes back when it is all there is', (tester) async {
      final undo = UndoRedoController();
      addTearDown(undo.dispose);
      final controller = await composeE(tester, undo: undo);
      expect(undo.canUndo, isFalse);

      expect(undo.undo(), isTrue);

      expect(controller.isComposingActive, isFalse);
      expect(controller.text, 'a:\n  b: tru\nc');
      await settle(tester, 2);
    });

    testWidgets('the platform ends without a delta is committed', (
      tester,
    ) async {
      final controller = await composeE(tester);

      await sendDeltas(tester, []);

      expect(controller.isComposingActive, isFalse);
      expect(controller.text, 'a:\n  b: true\nc');
      expect(controller.selection, const TextSelection.collapsed(offset: 12));
      await settle(tester, 2);
    });

    testWidgets('is committed when the editor loses focus', (tester) async {
      final controller = await composeE(tester);

      controller.focusNode!.unfocus();
      await tester.pump();
      expect(controller.isComposingActive, isFalse);
      expect(controller.text, 'a:\n  b: true\nc');

      controller.focusNode!.requestFocus();
      await tester.pump();
      await typeText(tester, controller, '!');
      expect(controller.text, 'a:\n  b: true!\nc');
    });
  });

  testWidgets('a caret the input method moves across identical lines gets the '
      'window at its new place', (tester) async {
    final controller = CodeForgeController()
      ..text = List.filled(10, 'x').join('\n');
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    controller.selection = const TextSelection.collapsed(offset: 7);
    await tester.pump();
    final value = controller.currentTextEditingValue;
    final caret = value.selection.extentOffset;
    int statesSent() => tester.testTextInput.log
        .where((call) => call.method == 'TextInput.setEditingState')
        .length;
    final sentBefore = statesSent();
    await sendDeltas(tester, [
      {
        ...textDelta(value.text, '', -1, -1),
        'selectionBase': caret + 2,
        'selectionExtent': caret + 2,
      },
    ]);
    expect(controller.selection, const TextSelection.collapsed(offset: 9));
    expect(controller.currentTextEditingValue.text, value.text);
    expect(statesSent(), sentBefore + 1);

    final moved = controller.currentTextEditingValue;
    final movedCaret = moved.selection.extentOffset;
    await sendDeltas(tester, [
      textDelta(moved.text, '', movedCaret - 1, movedCaret),
    ]);
    expect(controller.text, 'x\nx\nx\nx\n\nx\nx\nx\nx\nx');
    await settle(tester, 2);
  });

  group('a window of the same text further along', () {
    late CodeForgeController controller;
    late TextEditingValue value;

    int statesSent(WidgetTester tester) => tester.testTextInput.log
        .where((call) => call.method == 'TextInput.setEditingState')
        .length;

    Future<void> pumpIdenticalLines(WidgetTester tester) async {
      controller = CodeForgeController()
        ..text = List.filled(10, 'x').join('\n');
      await pumpEditor(tester, controller);
      await focusEditor(tester);
      controller.selection = const TextSelection.collapsed(offset: 7);
      await tester.pump();
      value = controller.currentTextEditingValue;
    }

    testWidgets('maps an edit made in the one before it where that one put '
        'it', (tester) async {
      await pumpIdenticalLines(tester);
      final moved = value.selection.extentOffset + 2;
      await sendDeltas(tester, [
        {
          ...textDelta(value.text, '', -1, -1),
          'selectionBase': moved,
          'selectionExtent': moved,
        },
      ]);
      expect(controller.selection, const TextSelection.collapsed(offset: 9));

      await sendDeltas(tester, [textDelta(value.text, '', moved - 1, moved)]);
      expect(controller.text, 'x\nx\nx\nx\n\nx\nx\nx\nx\nx');
      await settle(tester, 2);
    });

    testWidgets('is sent for a caret a whole editing value moves', (
      tester,
    ) async {
      await pumpIdenticalLines(tester);
      final sentBefore = statesSent(tester);
      tester.testTextInput.updateEditingValue(
        value.copyWith(
          selection: TextSelection.collapsed(
            offset: value.selection.extentOffset + 2,
          ),
        ),
      );
      await tester.pump();

      expect(controller.selection, const TextSelection.collapsed(offset: 9));
      expect(statesSent(tester), sentBefore + 1);
      await settle(tester, 2);
    });
  });

  testWidgets('backspaces on a line longer than the IME window all land', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = 'x' * 6005;
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    controller.selection = const TextSelection.collapsed(offset: 6005);
    await tester.pump();

    var platform = controller.currentTextEditingValue.text;
    expect(platform.length, lessThan(6005));
    for (var i = 0; i < 5; i++) {
      final caret = platform.length;
      await sendDeltas(tester, [textDelta(platform, '', caret - 1, caret)]);
      platform = platform.substring(0, caret - 1);
    }
    expect(controller.length, 6000);
    await settle(tester, 2);
  });

  group('a selection the input method collapses and deletes', () {
    late CodeForgeController controller;
    late UndoRedoController undo;

    Future<void> deleteHello(WidgetTester tester) async {
      controller = CodeForgeController()..text = 'hello world';
      undo = UndoRedoController();
      addTearDown(undo.dispose);
      await pumpEditor(tester, controller, undoController: undo);
      await focusEditor(tester);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );
      await tester.pump();
      await sendDeltas(tester, [
        for (final extent in [0, 5])
          {
            ...textDelta('hello world', '', -1, -1),
            'selectionBase': 5,
            'selectionExtent': extent,
          },
        textDelta('hello world', '', 0, 5),
      ]);
      expect(controller.text, ' world');
    }

    void expectOneUndoRestoresIt() {
      expect(undo.undo(), isTrue);
      expect(controller.text, 'hello world');
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      expect(undo.canUndo, isFalse);
    }

    testWidgets('comes back selected on undo', (tester) async {
      await deleteHello(tester);
      expectOneUndoRestoresIt();
      await settle(tester, 2);
    });

    testWidgets('is typed over in one undo step', (tester) async {
      await deleteHello(tester);
      await sendDeltas(tester, [textDelta(' world', 'x', 0, 0)]);
      expect(controller.text, 'x world');
      expectOneUndoRestoresIt();
      await settle(tester, 2);
    });

    testWidgets('is composed over in one undo step', (tester) async {
      await deleteHello(tester);
      await sendDeltas(tester, [
        {
          ...textDelta(' world', 'k', 0, 0),
          'composingBase': 0,
          'composingExtent': 1,
        },
      ]);
      await sendDeltas(tester, [textDelta('k world', '可', 0, 1)]);
      expect(controller.text, '可 world');
      expectOneUndoRestoresIt();
      await settle(tester, 2);
    });
  });

  group('a word the input method marks as composing', () {
    Future<CodeForgeController> markWorld(
      WidgetTester tester,
      TextSelection selection,
    ) async {
      final controller = CodeForgeController()..text = 'hello world';
      await pumpEditor(tester, controller);
      await focusEditor(tester);
      controller.selection = selection;
      await tester.pump();
      final value = controller.currentTextEditingValue;
      await sendDeltas(tester, [
        {
          ...textDelta(value.text, '', -1, -1),
          'selectionBase': value.selection.baseOffset,
          'selectionExtent': value.selection.extentOffset,
          'composingBase': 6,
          'composingExtent': 11,
        },
      ]);
      return controller;
    }

    testWidgets('stays in the document and keeps the selection', (
      tester,
    ) async {
      final controller = await markWorld(
        tester,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      expect(controller.isComposingActive, isFalse);
      expect(controller.text, 'hello world');
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      await settle(tester, 2);
    });

    testWidgets('is composed once the input method rewrites it', (
      tester,
    ) async {
      final controller = await markWorld(
        tester,
        const TextSelection.collapsed(offset: 11),
      );
      await sendDeltas(tester, [
        {
          ...textDelta('hello world', 'worlds', 6, 11),
          'composingBase': 6,
          'composingExtent': 12,
        },
      ]);
      expect(controller.imeComposition?.displayText, 'worlds');

      await sendDeltas(tester, [
        {
          ...textDelta('hello worlds', '', -1, -1),
          'selectionBase': 12,
          'selectionExtent': 12,
        },
      ]);
      expect(controller.isComposingActive, isFalse);
      expect(controller.text, 'hello worlds');
      expect(controller.selection, const TextSelection.collapsed(offset: 12));
      await settle(tester, 2);
    });

    testWidgets('is kept as rewritten when the connection closes', (
      tester,
    ) async {
      final controller = await markWorld(
        tester,
        const TextSelection.collapsed(offset: 11),
      );
      await sendDeltas(tester, [
        {
          ...textDelta('hello world', 'worlds', 6, 11),
          'composingBase': 6,
          'composingExtent': 12,
        },
      ]);

      await sendToInputClient(tester, 'TextInputClient.onConnectionClosed');
      await settle(tester, 2);
      expect(controller.isComposingActive, isFalse);
      expect(controller.text, 'hello worlds');
    });
  });

  test('only a line feed breaks a line, as in Dart', () {
    for (final text in ['a\rb\n', 'a\u2028b\n', 'a\u0085b\n']) {
      final controller = CodeForgeController()..text = text;
      final lines = text.split('\n');
      expect(controller.lineCount, lines.length, reason: text);
      expect(controller.getLineStartOffset(1), lines[0].length + 1);
    }
  });

  test('CRLF text comes in as LF, so a backspace joins the lines', () {
    final controller = CodeForgeController()..text = 'a: 1\r\nb: 2\r\n';
    expect(controller.text, 'a: 1\nb: 2\n');

    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(1),
    );
    controller.backspace();

    expect(controller.text, 'a: 1b: 2\n');
  });

  test('CRLF handed to replaceRange comes in as LF', () {
    final controller = CodeForgeController()..text = 'a: 1\n';

    controller.replaceRange(5, 5, 'b: 2\r\nc: 3\r\n');

    expect(controller.text, 'a: 1\nb: 2\nc: 3\n');
    expect(controller.selection, const TextSelection.collapsed(offset: 15));
  });

  testWidgets('CRLF from the input method comes in as LF', (tester) async {
    final controller = CodeForgeController()..text = _document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    controller.selection = TextSelection.collapsed(offset: controller.length);
    await settle(tester, 2);

    final value = controller.currentTextEditingValue;
    final caret = value.selection.extentOffset;
    await sendDeltas(tester, [
      textDelta(value.text, '\r\n  - DIRECT', caret, caret),
    ]);
    await settle(tester, 2);

    expect(controller.text, '$_document\n  - DIRECT');
    expect(
      controller.selection,
      TextSelection.collapsed(offset: controller.length),
    );
  });

  testWidgets('text after CRLF in the same batch lands right after it', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = _document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    final anchor = controller.getLineStartOffset(1) + '  - name: '.length;
    controller.selection = TextSelection.collapsed(offset: anchor);
    await settle(tester, 2);

    final value = controller.currentTextEditingValue;
    final caret = value.selection.extentOffset;
    final afterCrlf = value.text.replaceRange(caret, caret, 'x\r\ny');
    await sendDeltas(tester, [
      textDelta(value.text, 'x\r\ny', caret, caret),
      textDelta(afterCrlf, 'z', caret + 4, caret + 4),
    ]);
    await settle(tester, 2);

    expect(controller.getLineText(1), '  - name: x');
    expect(controller.getLineText(2), 'yza');
    expect(controller.selection, TextSelection.collapsed(offset: anchor + 4));
  });

  testWidgets('a whole value with CRLF from the input method keeps no CR', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = _document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    final anchor = controller.getLineStartOffset(1) + '  - name: '.length;
    controller.selection = TextSelection.collapsed(offset: anchor);
    await settle(tester, 2);

    final value = controller.currentTextEditingValue;
    final caret = value.selection.extentOffset;
    final typed = TextEditingValue(
      text: value.text.replaceRange(caret, caret, 'x\r\ny'),
      selection: TextSelection.collapsed(offset: caret + 4),
    );
    tester.testTextInput.updateEditingValue(typed);
    await tester.pump();
    expect(controller.selection, TextSelection.collapsed(offset: anchor + 3));
    tester.testTextInput.updateEditingValue(
      typed.copyWith(selection: TextSelection.collapsed(offset: caret + 1)),
    );
    await settle(tester, 2);

    expect(controller.text, isNot(contains('\r')));
    expect(controller.getLineText(2), 'ya');
    expect(controller.selection, TextSelection.collapsed(offset: anchor + 1));
  });

  group('a composition the input method commits with CRLF', () {
    late CodeForgeController controller;
    late int anchor;
    late int caret;
    late String composing;

    Future<void> startComposing(WidgetTester tester) async {
      controller = CodeForgeController()..text = _document;
      await pumpEditor(tester, controller);
      await focusEditor(tester);
      anchor = controller.getLineStartOffset(1) + '  - name: '.length;
      controller.selection = TextSelection.collapsed(offset: anchor);
      await settle(tester, 2);
      final value = controller.currentTextEditingValue;
      caret = value.selection.extentOffset;
      composing = value.text.replaceRange(caret, caret, 'ni');
      await sendDeltas(tester, [
        {
          ...textDelta(value.text, 'ni', caret, caret),
          'composingBase': caret,
          'composingExtent': caret + 2,
        },
      ]);
      expect(controller.isComposingActive, isTrue);
    }

    testWidgets('comes in as LF with the caret after it', (tester) async {
      await startComposing(tester);

      await sendDeltas(tester, [
        textDelta(composing, 'x\r\ny', caret, caret + 2),
      ]);
      await settle(tester, 2);

      expect(controller.getLineText(1), '  - name: x');
      expect(controller.getLineText(2), 'ya');
      expect(controller.selection, TextSelection.collapsed(offset: anchor + 3));
    });

    testWidgets('while it goes on tells the input method the CR is gone', (
      tester,
    ) async {
      await startComposing(tester);

      final logged = tester.testTextInput.log.length;
      await sendDeltas(tester, [
        {
          ...textDelta(composing, 'x\r\nb', caret, caret + 2),
          'composingBase': caret + 3,
          'composingExtent': caret + 4,
        },
      ]);

      expect(controller.getLineText(1), '  - name: x');
      expect(controller.imeComposition?.anchor, anchor + 2);
      final sent = tester.testTextInput.log
          .skip(logged)
          .lastWhere((call) => call.method == 'TextInput.setEditingState');
      final state = sent.arguments as Map;
      expect(state['text'], isNot(contains('\r')));
      expect(
        [state['composingBase'], state['composingExtent']],
        [caret + 2, caret + 3],
      );

      await sendDeltas(tester, [
        textDelta(state['text'] as String, '不', caret + 2, caret + 3),
      ]);
      await settle(tester, 2);

      expect(controller.getLineText(2), '不a');
      expect(controller.selection, TextSelection.collapsed(offset: anchor + 3));
    });
  });

  test('a read-only document is neither indented nor outdented', () {
    final controller = CodeForgeController()
      ..text = '  a: 1'
      ..readOnly = true;
    addTearDown(controller.dispose);

    controller
      ..indent()
      ..unindent();

    expect(controller.text, '  a: 1');
  });

  test('outdenting lines keeps the selection end on its own line', () {
    final controller = CodeForgeController()..text = '\ta\n\tb\n\tc';
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 6);

    controller.unindent();

    expect(controller.text, 'a\nb\nc');
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 4),
    );
  });

  test('a line moves down past an empty last line', () {
    final controller = CodeForgeController()..text = 'a\nb\n';
    controller.selection = const TextSelection.collapsed(offset: 3);

    controller.moveLineDown();

    expect(controller.text, 'a\n\nb');
    expect(controller.selection, const TextSelection.collapsed(offset: 4));
  });

  test('edits not yet rendered merge into one covering line range', () {
    final controller = CodeForgeController()
      ..text = List.generate(12, (i) => 'line $i').join('\n');
    final before = controller.text.split('\n');
    controller.takeChange();

    void replaceLines(int from, int to, String text) => controller.replaceRange(
      controller.getLineStartOffset(from),
      controller.getLineStartOffset(to),
      text,
    );
    replaceLines(6, 6, 'a\nb\n');
    replaceLines(1, 2, '');
    replaceLines(9, 11, 'c\n');
    replaceLines(0, 0, 'd');

    final after = controller.text.split('\n');
    final edit = controller.takeChange().lines!;
    expect(edit, (line: 0, removed: 10, inserted: 10));
    expect([
      ...before.sublist(0, edit.line),
      ...after.sublist(edit.line, edit.line + edit.inserted + 1),
      ...before.sublist(edit.line + edit.removed + 1),
    ], after);
  });

  test('moving lines carries a selection that spans them', () {
    final controller = CodeForgeController()..text = 'a\nbb\nccc\ndd';
    controller.selection = const TextSelection(baseOffset: 3, extentOffset: 6);

    controller.moveLineUp();
    expect(controller.text, 'bb\nccc\na\ndd');
    expect(
      controller.selection,
      const TextSelection(baseOffset: 1, extentOffset: 4),
    );
    controller.moveLineUp();
    expect(controller.text, 'bb\nccc\na\ndd');

    controller
      ..moveLineDown()
      ..moveLineDown();
    expect(controller.text, 'a\ndd\nbb\nccc');
    expect(
      controller.selection,
      const TextSelection(baseOffset: 6, extentOffset: 9),
    );
    controller.moveLineDown();
    expect(controller.text, 'a\ndd\nbb\nccc');
  });

  test('duplicating copies the caret line or the selection after itself', () {
    final controller = CodeForgeController()..text = 'a: 1\nb: \u{1F600}';
    controller.selection = const TextSelection.collapsed(offset: 6);

    controller.duplicateLine();
    expect(controller.text, 'a: 1\nb: \u{1F600}\nb: \u{1F600}');
    expect(controller.selection, const TextSelection.collapsed(offset: 10));

    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    controller.duplicateLine();
    expect(controller.text, 'a: 1a: 1\nb: \u{1F600}\nb: \u{1F600}');
    expect(controller.selection, const TextSelection.collapsed(offset: 8));
  });

  test('moving and deleting by word run over blank lines', () {
    final controller = CodeForgeController()..text = 'ab  \n\n   cd ef';
    controller.selection = const TextSelection.collapsed(offset: 2);

    controller.moveWordRight();
    expect(controller.selection, const TextSelection.collapsed(offset: 9));
    controller.moveWordRight();
    expect(controller.selection, const TextSelection.collapsed(offset: 11));

    controller.selection = const TextSelection.collapsed(offset: 9);
    controller.moveWordLeft();
    expect(controller.selection, const TextSelection.collapsed(offset: 6));
    controller.moveWordLeft();
    expect(controller.selection, const TextSelection.collapsed(offset: 5));

    controller.selection = const TextSelection.collapsed(offset: 2);
    controller.deleteWordForward();
    expect(controller.text, 'ab ef');
    controller.selection = const TextSelection.collapsed(offset: 3);
    controller.deleteWordBackward();
    expect(controller.text, 'ef');

    controller.text = 'x  \n  ';
    controller.selection = const TextSelection.collapsed(offset: 1);
    controller.moveWordRight();
    expect(controller.selection, const TextSelection.collapsed(offset: 6));
    controller.selection = const TextSelection.collapsed(offset: 1);
    controller.deleteWordForward();
    expect(controller.text, 'x');
  });
}

void _indent() {
  test('unindenting removes a leading tab', () {
    final controller = CodeForgeController()
      ..text = '\ta: 1'
      ..selection = const TextSelection.collapsed(offset: 3);
    controller.unindent();

    expect(controller.text, 'a: 1');
    expect(controller.selection, const TextSelection.collapsed(offset: 2));
  });

  testWidgets('a new line under a tab indent is indented with spaces', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = 'a:\n\tb: 1';
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    controller
      ..useSpaceAsTab = true
      ..tabSize = 2
      ..selection = TextSelection.collapsed(offset: controller.length);
    await typeText(tester, controller, '\n');

    expect(controller.getLineText(2), '  ');
  });
}

void _comment() {
  CodeForgeController yaml(String text) => CodeForgeController()
    ..text = text
    ..lineCommentPrefix = '# ';

  CodeForgeController script(String text) => CodeForgeController()
    ..text = text
    ..lineCommentPrefix = '// '
    ..blockComments = true;

  test('a line comment goes after the indentation and keeps the caret', () {
    final controller = yaml('rules:\n  - MATCH,a')
      ..selection = TextSelection.collapsed(offset: 'rules:\n  - MA'.length);
    controller.toggleLineComment();

    expect(controller.text, 'rules:\n  # - MATCH,a');
    expect(
      controller.selection,
      TextSelection.collapsed(offset: 'rules:\n  # - MA'.length),
    );
  });

  test('the selected lines are commented together, skipping blank ones', () {
    final controller = script('a();\n\n  b();\nc();')
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: 'a();\n\n  b();\n'.length,
      );
    controller.toggleLineComment();

    expect(controller.text, '// a();\n\n  // b();\nc();');
    expect(
      controller.selection,
      TextSelection(
        baseOffset: 0,
        extentOffset: '// a();\n\n  // b();\n'.length,
      ),
    );
  });

  test('lines that are all commented are uncommented', () {
    final controller = script('// a();\n  //b();')
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: '// a();\n  //b();'.length,
      );
    controller.toggleLineComment();

    expect(controller.text, 'a();\n  b();');
    expect(
      controller.selection,
      TextSelection(baseOffset: 0, extentOffset: 'a();\n  b();'.length),
    );
  });

  test('a mixed selection is commented rather than uncommented', () {
    final controller = yaml('# a: 1\nb: 2')
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: '# a: 1\nb: 2'.length,
      );
    controller.toggleLineComment();

    expect(controller.text, '# # a: 1\n# b: 2');
  });

  test('a line comment toggle is one undo step', () {
    final undo = UndoRedoController();
    addTearDown(undo.dispose);
    final controller = script('a();\nb();')..setUndoController(undo);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.length,
    );
    controller.toggleLineComment();
    undo.undo();

    expect(controller.text, 'a();\nb();');
  });

  test('nothing happens without a comment prefix', () {
    final controller = CodeForgeController()
      ..text = 'a: 1'
      ..selection = const TextSelection.collapsed(offset: 0);
    controller.toggleLineComment();

    expect(controller.text, 'a: 1');
  });

  test('a selection is wrapped in a block comment and unwrapped again', () {
    final controller = script('const a = 1;')
      ..selection = const TextSelection(baseOffset: 6, extentOffset: 7);
    controller.toggleBlockComment();

    expect(controller.text, 'const /* a */ = 1;');
    expect(
      controller.selection,
      const TextSelection(baseOffset: 6, extentOffset: 13),
    );

    controller.toggleBlockComment();

    expect(controller.text, 'const a = 1;');
    expect(
      controller.selection,
      const TextSelection(baseOffset: 6, extentOffset: 7),
    );
  });

  test('a caret outside a comment opens an empty block comment', () {
    final controller = script('a();')
      ..selection = const TextSelection.collapsed(offset: 4);
    controller.toggleBlockComment();

    expect(controller.text, 'a();/*  */');
    expect(controller.selection, const TextSelection.collapsed(offset: 7));
  });

  test('a caret on a commented line unwraps it', () {
    final controller = script('  /* a(); */')
      ..selection = const TextSelection.collapsed(offset: 6);
    controller.toggleBlockComment();

    expect(controller.text, '  a();');
    expect(controller.selection, const TextSelection.collapsed(offset: 3));
  });

  test('block comments are off unless the language has them', () {
    final controller = yaml('a: 1')
      ..selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    controller.toggleBlockComment();

    expect(controller.text, 'a: 1');
  });
}

void _blockComment() {
  List<bool> starts(String text) {
    final controller = CodeForgeController()..text = text;
    final states = BlockCommentStates();
    return [
      for (var line = 0; line < controller.lineCount; line++)
        states.startsInside(controller, line),
    ];
  }

  test('the lines after an open block comment start inside it', () {
    expect(starts('a();\n/*\n * note\n */ b();\nc();'), [
      false,
      false,
      true,
      true,
      false,
    ]);
  });

  test('markers inside strings and line comments open nothing', () {
    expect(starts('const s = "/*";\n// /* not open\nx();'), [
      false,
      false,
      false,
    ]);
  });

  test('a comment closed on its own line leaves the next line outside', () {
    expect(starts('a(); /* b */\nc();'), [false, false]);
  });

  test('invalidating from an edited line recomputes the lines after it', () {
    final controller = CodeForgeController()..text = 'a();\nb();\nc();';
    final states = BlockCommentStates();
    expect(states.startsInside(controller, 2), isFalse);

    controller.replaceRange(0, 0, '/*');
    states.invalidateFrom(0);

    expect(states.startsInside(controller, 1), isTrue);
    expect(states.startsInside(controller, 2), isTrue);
  });
}

ReplaceOperation _replace(int offset) => ReplaceOperation(
  offset: offset,
  deletedText: 'a',
  insertedText: 'b',
  selectionBefore: TextSelection.collapsed(offset: offset),
  selectionAfter: TextSelection.collapsed(offset: offset + 1),
);

void _undoRedo() {
  test('operations carry their lengths in scalars through merge and undo', () {
    const caret = TextSelection.collapsed(offset: 0);
    final at = DateTime(2026);
    final typed = InsertOperation(
      offset: 0,
      text: 'a\u{1F600}',
      selectionBefore: caret,
      selectionAfter: caret,
      timestamp: at,
    );
    final next = InsertOperation(
      offset: 2,
      text: 'b',
      selectionBefore: caret,
      selectionAfter: caret,
      timestamp: at,
    );
    expect(typed.length, 2);
    expect(typed.canMergeWith(next), isTrue);

    final merged = typed.mergeWith(next) as InsertOperation;
    expect(merged.length, 3);
    expect((merged.inverse() as DeleteOperation).length, 3);

    final replaced =
        ReplaceOperation(
              offset: 0,
              deletedText: '\u{1F600}',
              insertedText: 'ab',
              selectionBefore: caret,
              selectionAfter: caret,
            ).inverse()
            as ReplaceOperation;
    expect((replaced.deletedLength, replaced.insertedLength), (2, 1));
  });

  test('a compound operation still groups once the history is full', () {
    final undo = UndoRedoController();
    addTearDown(undo.dispose);
    for (var i = 0; i < 2000; i++) {
      undo.recordEdit(_replace(i));
    }

    final group = undo.beginCompoundOperation();
    undo.recordEdit(_replace(0));
    undo.recordEdit(_replace(1));
    group.end();

    final stack = undo.undoStack;
    expect(
      stack.last,
      isA<CompoundOperation>().having(
        (operation) => operation.operations,
        'operations',
        hasLength(2),
      ),
    );
    expect(
      stack[stack.length - 2],
      isA<ReplaceOperation>().having(
        (operation) => operation.offset,
        'offset',
        1999,
      ),
    );
  });
}

Map<String, Object> _selectionDelta(String oldText, int base, int extent) => {
  'oldText': oldText,
  'deltaText': '',
  'deltaStart': -1,
  'deltaEnd': -1,
  'selectionBase': base,
  'selectionExtent': extent,
  'selectionAffinity': 'TextAffinity.downstream',
  'selectionIsDirectional': false,
  'composingBase': -1,
  'composingExtent': -1,
};

void _imeSelection() {
  final document = [for (var i = 0; i < 40; i++) 'line $i'].join('\n');

  testWidgets('the input method selecting all it holds selects the document', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(20),
    );
    await tester.pump();

    final window = controller.currentTextEditingValue.text;
    expect(window.length, lessThan(document.length));
    await sendDeltas(tester, [_selectionDelta(window, 0, window.length)]);

    expect(
      controller.selection,
      TextSelection(baseOffset: 0, extentOffset: controller.length),
    );
  });

  testWidgets('a late echo of an earlier caret leaves a newer selection', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    final start = controller.getLineStartOffset(10);
    controller.selection = TextSelection.collapsed(offset: start);
    await tester.pump();
    final earlier = controller.currentTextEditingValue;

    final word = TextSelection(baseOffset: start, extentOffset: start + 4);
    controller.selection = word;
    await tester.pump();
    await sendDeltas(tester, [
      _selectionDelta(
        earlier.text,
        earlier.selection.baseOffset,
        earlier.selection.extentOffset,
      ),
    ]);

    expect(controller.selection, word);
  });
}

Future<void> _chord(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool control = false,
  bool meta = false,
  bool alt = false,
  bool shift = false,
}) async {
  final modifiers = [
    if (control) LogicalKeyboardKey.controlLeft,
    if (meta) LogicalKeyboardKey.metaLeft,
    if (alt) LogicalKeyboardKey.altLeft,
    if (shift) LogicalKeyboardKey.shiftLeft,
  ];
  for (final modifier in modifiers) {
    await tester.sendKeyDownEvent(modifier);
  }
  await tester.sendKeyEvent(key);
  for (final modifier in modifiers.reversed) {
    await tester.sendKeyUpEvent(modifier);
  }
  await settle(tester, 2);
}

void _keyboard() {
  Future<(CodeForgeController, FindController, UndoRedoController)> pump(
    WidgetTester tester, {
    bool readOnly = false,
  }) async {
    final controller = CodeForgeController()..text = _document;
    final finder = FindController(controller);
    final undo = UndoRedoController();
    addTearDown(finder.dispose);
    addTearDown(undo.dispose);
    await pumpEditor(
      tester,
      controller,
      findController: finder,
      undoController: undo,
      readOnly: readOnly,
    );
    await focusEditor(tester);
    return (controller, finder, undo);
  }

  testWidgets('Ctrl+F and Ctrl+H open the finder', (tester) async {
    final (_, finder, _) = await pump(tester);

    await _chord(tester, LogicalKeyboardKey.keyF, control: true);
    expect(finder.isActive, isTrue);
    expect(finder.isReplaceMode, isFalse);

    await _chord(tester, LogicalKeyboardKey.keyH, control: true);
    expect(finder.isReplaceMode, isTrue);

    await _chord(tester, LogicalKeyboardKey.escape);
    expect(finder.isActive, isFalse);
  });

  testWidgets('read-only opens only the plain finder and blocks edits', (
    tester,
  ) async {
    final (controller, finder, _) = await pump(tester, readOnly: true);
    final clipboard = mockClipboard(tester);
    clipboard.text = 'x';

    await _chord(tester, LogicalKeyboardKey.keyH, control: true);
    expect(finder.isActive, isTrue);
    expect(finder.isReplaceMode, isFalse);

    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(1) + 4,
    );
    await _chord(tester, LogicalKeyboardKey.keyD, control: true);
    await _chord(tester, LogicalKeyboardKey.keyV, control: true);
    await _chord(tester, LogicalKeyboardKey.keyX, control: true);
    await _chord(tester, LogicalKeyboardKey.backspace, control: true);
    await _chord(tester, LogicalKeyboardKey.tab);
    expect(controller.text, _document);

    await _chord(tester, LogicalKeyboardKey.keyC, control: true);
    expect(clipboard.text, '  - name: a\n');
  });

  testWidgets('select all, copy, cut, paste and undo, redo', (tester) async {
    final (controller, _, undo) = await pump(tester);
    final clipboard = mockClipboard(tester);

    await _chord(tester, LogicalKeyboardKey.keyA, control: true);
    expect(
      controller.selection,
      TextSelection(baseOffset: 0, extentOffset: controller.length),
    );
    await _chord(tester, LogicalKeyboardKey.keyC, control: true);
    expect(clipboard.text, _document);

    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(2) + 2,
    );
    await _chord(tester, LogicalKeyboardKey.keyX, control: true);
    expect(clipboard.text, '    port: 80\n');
    expect(controller.lineCount, 4);

    controller.selection = const TextSelection.collapsed(offset: 3);
    await _chord(tester, LogicalKeyboardKey.keyV, control: true);
    expect(controller.getLineText(0), '    port: 80');
    expect(controller.getLineText(1), 'proxies:');

    await _chord(tester, LogicalKeyboardKey.keyZ, control: true);
    await _chord(tester, LogicalKeyboardKey.keyZ, control: true);
    expect(controller.text, _document);
    await _chord(tester, LogicalKeyboardKey.keyY, control: true);
    expect(controller.lineCount, 4);
    await _chord(tester, LogicalKeyboardKey.keyZ, control: true, shift: true);
    expect(controller.getLineText(0), '    port: 80');
    expect(undo.canRedo, isFalse);
  });

  testWidgets('Tab indents and Shift+Tab outdents the selected lines', (
    tester,
  ) async {
    final (controller, _, _) = await pump(tester);
    final tab = controller.tabSpace;

    controller.selection = TextSelection(
      baseOffset: 2,
      extentOffset: controller.getLineStartOffset(1) + 2,
    );
    await _chord(tester, LogicalKeyboardKey.tab);
    expect(controller.getLineText(0), '${tab}proxies:');
    expect(controller.getLineText(1), '$tab  - name: a');

    await _chord(tester, LogicalKeyboardKey.tab, shift: true);
    expect(controller.text, _document);
  });

  testWidgets('Ctrl+arrows move by word and Ctrl+Backspace/Delete delete one', (
    tester,
  ) async {
    final (controller, _, _) = await pump(tester);
    final line = controller.getLineStartOffset(1);

    controller.selection = TextSelection.collapsed(offset: line);
    await _chord(tester, LogicalKeyboardKey.arrowRight, control: true);
    expect(controller.selection.extentOffset, line + 2);
    await _chord(tester, LogicalKeyboardKey.arrowRight, control: true);
    expect(controller.selection.extentOffset, line + 3);
    await _chord(
      tester,
      LogicalKeyboardKey.arrowRight,
      control: true,
      shift: true,
    );
    expect(
      controller.selection,
      TextSelection(baseOffset: line + 3, extentOffset: line + 4),
    );
    await _chord(tester, LogicalKeyboardKey.arrowLeft, control: true);
    expect(controller.selection, TextSelection.collapsed(offset: line + 2));

    controller.selection = TextSelection.collapsed(
      offset: line + '  - name'.length,
    );
    await _chord(tester, LogicalKeyboardKey.backspace, control: true);
    expect(controller.getLineText(1), '  - : a');
    await _chord(tester, LogicalKeyboardKey.delete, control: true);
    expect(controller.getLineText(1), '  -  a');
  });

  testWidgets(
    'Apple platforms use Cmd and Option',
    (tester) async {
      final (controller, finder, _) = await pump(tester);

      await _chord(tester, LogicalKeyboardKey.keyF, meta: true, alt: true);
      expect(finder.isReplaceMode, isTrue);
      await _chord(tester, LogicalKeyboardKey.escape);

      controller.selection = TextSelection.collapsed(
        offset: controller.getLineStartOffset(1) + '  - name'.length,
      );
      await _chord(tester, LogicalKeyboardKey.backspace, alt: true);
      expect(controller.getLineText(1), '  - : a');
      await _chord(tester, LogicalKeyboardKey.keyZ, meta: true);
      expect(controller.text, _document);
      await _chord(tester, LogicalKeyboardKey.keyZ, meta: true, shift: true);
      expect(controller.getLineText(1), '  - : a');
      await _chord(tester, LogicalKeyboardKey.backspace, meta: true);
      expect(controller.getLineText(1), ': a');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}

Future<CodeForgeController> _pump(WidgetTester tester) async {
  final controller = CodeForgeController()..text = _document;
  await pumpEditor(tester, controller);
  await focusEditor(tester);
  return controller;
}

void _clipboard() {
  testWidgets('copy with nothing selected pastes the line above the caret', (
    tester,
  ) async {
    final clipboard = mockClipboard(tester);
    final controller = await _pump(tester);

    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(1) + 4,
    );
    await controller.copy();
    expect(clipboard.text, '  - name: a\n');

    final caret = controller.getLineStartOffset(3) + 2;
    controller.selection = TextSelection.collapsed(offset: caret);
    await controller.paste();
    await settle(tester);

    expect(controller.lineCount, 6);
    expect(controller.getLineText(3), '  - name: a');
    expect(controller.getLineText(4), 'rules:');
    expect(
      controller.selection,
      TextSelection.collapsed(offset: caret + '  - name: a\n'.length),
    );
  });

  testWidgets('pasted CRLF text comes in as LF', (tester) async {
    mockClipboard(tester).text = '- DIRECT\r\n- REJECT';
    final controller = await _pump(tester);

    controller.selection = TextSelection.collapsed(offset: controller.length);
    await controller.paste();
    await settle(tester);

    expect(controller.text, '$_document- DIRECT\n- REJECT');
  });

  testWidgets('cut with nothing selected removes the line', (tester) async {
    final clipboard = mockClipboard(tester);
    final controller = await _pump(tester);

    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(2) + 3,
    );
    await controller.cut();
    await settle(tester);
    expect(clipboard.text, '    port: 80\n');
    expect(controller.text, 'proxies:\n  - name: a\nrules:\n  - MATCH,a');
    expect(
      controller.selection,
      TextSelection.collapsed(offset: controller.getLineStartOffset(2)),
    );

    controller.selection = TextSelection.collapsed(offset: controller.length);
    await controller.cut();
    await settle(tester);
    expect(clipboard.text, '  - MATCH,a\n');
    expect(controller.text, 'proxies:\n  - name: a\nrules:');

    await controller.paste();
    await settle(tester);
    expect(controller.text, 'proxies:\n  - name: a\n  - MATCH,a\nrules:');
  });

  testWidgets('selections and outside clipboard text paste in place', (
    tester,
  ) async {
    final clipboard = mockClipboard(tester);
    final controller = await _pump(tester);
    final nameStart = controller.getLineStartOffset(1) + '  - name: '.length;

    await controller.copy();
    controller.selection = TextSelection(
      baseOffset: nameStart,
      extentOffset: nameStart + 1,
    );
    await controller.cut();
    await settle(tester);
    expect(clipboard.text, 'a');
    expect(controller.getLineText(1), '  - name: ');

    controller.selection = TextSelection.collapsed(offset: controller.length);
    await controller.paste();
    await settle(tester);
    expect(controller.getLineText(4), '  - MATCH,aa');

    controller.selection = const TextSelection.collapsed(offset: 0);
    await controller.copy();
    clipboard.text = 'b\n';
    controller.selection = TextSelection.collapsed(offset: nameStart);
    await controller.paste();
    await settle(tester);
    expect(controller.getLineText(0), 'proxies:');
    expect(controller.getLineText(1), '  - name: b');
    expect(controller.getLineText(2), '');
    expect(controller.getLineText(3), '    port: 80');
  });

  testWidgets('a large copy lands before the paste or copy after it', (
    tester,
  ) async {
    final clipboard = mockClipboard(tester);
    final document = List.generate(20000, (i) => 'line $i').join('\n');
    final controller = CodeForgeController()..text = document;
    await pumpEditor(tester, controller);
    await focusEditor(tester);

    await tester.runAsync(() async {
      controller.selectAll();
      unawaited(controller.copy());
      controller.selection = TextSelection.collapsed(offset: controller.length);
      await controller.paste();
    });
    await settle(tester);
    expect(controller.text, '$document$document');

    await tester.runAsync(() async {
      controller.selectAll();
      unawaited(controller.copy());
      controller.selection = const TextSelection.collapsed(offset: 0);
      unawaited(controller.copy());
      await controller.paste();
    });
    await settle(tester);
    expect(clipboard.text, 'line 0\n');
    expect(controller.getLineText(1), 'line 0');
  });

  testWidgets('a cut the clipboard refuses keeps the text and says so', (
    tester,
  ) async {
    final controller = await _pump(tester);
    var failures = 0;
    controller.onClipboardWriteFailed = () => failures++;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => throw PlatformException(code: 'error'),
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.getLineStartOffset(1),
    );
    await controller.cut();
    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(2),
    );
    await controller.cut();
    await settle(tester);

    expect(controller.text, _document);
    expect(failures, 2);
  });

  group('a cut still writing the clipboard leaves the text', () {
    late MockClipboard clipboard;
    late CodeForgeController controller;
    late Future<void> cut;

    Future<void> startCut(WidgetTester tester) async {
      clipboard = mockClipboard(tester);
      controller = await _pump(tester);
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.getLineStartOffset(1),
      );
      cut = controller.cut();
    }

    testWidgets('once the selection moves', (tester) async {
      await startCut(tester);
      controller.selection = TextSelection.collapsed(offset: controller.length);
      await cut;
      await settle(tester);

      expect(clipboard.text, 'proxies:\n');
      expect(controller.text, _document);
    });

    testWidgets('once the editor is read-only', (tester) async {
      await startCut(tester);
      controller.readOnly = true;
      await cut;
      await settle(tester);

      expect(controller.text, _document);
    });

    testWidgets('once the controller is disposed', (tester) async {
      await startCut(tester);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await cut;

      expect(clipboard.text, 'proxies:\n');
    });
  });

  testWidgets('a paste still reading the clipboard leaves a disposed '
      'controller alone', (tester) async {
    mockClipboard(tester).text = 'x';
    final controller = await _pump(tester);

    final paste = controller.paste();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await paste;
  });

  testWidgets('a paste the clipboard fails leaves the text', (tester) async {
    final controller = await _pump(tester);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => throw PlatformException(code: 'error'),
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await controller.paste();

    expect(controller.text, _document);
  });

  testWidgets('Android is not sent a clip past what one Binder call carries', (
    tester,
  ) async {
    const limit = 1 << 20;
    final clipboard = mockClipboard(tester);
    final controller = CodeForgeController()
      ..text = List.filled(1024, 'x' * 1024).join('\n');
    addTearDown(controller.dispose);
    final document = controller.text;
    var failures = 0;
    controller.onClipboardWriteFailed = () => failures++;

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      controller.selectAll();
      await controller.cut();
      expect(clipboard.text, isNull);
      expect(failures, 1);
      expect(controller.text, document);

      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: limit - 1,
      );
      await tester.runAsync(controller.copy);
      expect(clipboard.text, hasLength(limit - 1));
      expect(failures, 1);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

const _documentCompletion = 'proxies:\n  - name: alpha\n    type: vmess\n';

void _completion() {
  Future<(CodeForgeController, List<CodeForgeSuggestionDetails>)> pumpWords(
    WidgetTester tester, [
    String document = _documentCompletion,
  ]) async {
    final controller = CodeForgeController()..text = document;
    final popups = <CodeForgeSuggestionDetails>[];
    await pumpEditor(
      tester,
      controller,
      enableLocalSuggestions: true,
      suggestionPopupBuilder: (context, details) {
        popups.add(details);
        return Column(
          children: [
            for (final suggestion in details.suggestions)
              Text('suggest ${suggestion.label}'),
          ],
        );
      },
    );
    await focusEditor(tester);
    controller.selection = TextSelection.collapsed(offset: controller.length);
    await settle(tester, 2);
    return (controller, popups);
  }

  testWidgets('typing a known prefix opens the popup with document words', (
    tester,
  ) async {
    final (controller, popups) = await pumpWords(tester);

    await typeText(tester, controller, 'vm');
    await settle(tester, 8);

    expect(popups, isNotEmpty);
    final details = popups.last;
    expect(details.suggestions.map((s) => s.label), contains('vmess'));
    expect(find.text('suggest vmess'), findsOneWidget);
  });

  testWidgets('accepting a suggestion completes the word and closes it', (
    tester,
  ) async {
    final (controller, popups) = await pumpWords(tester);

    await typeText(tester, controller, 'al');
    await settle(tester, 8);
    final details = popups.last;
    final index = details.suggestions.indexWhere((s) => s.label == 'alpha');
    expect(index, isNonNegative);

    details.onAccept(index);
    await settle(tester, 4);

    expect(controller.text, '${_documentCompletion}alpha');
    expect(find.textContaining('suggest '), findsNothing);
  });

  testWidgets('arrow keys move the highlight that Enter accepts', (
    tester,
  ) async {
    const document = 'a: [alpha, alpine, also]\n';
    final (controller, popups) = await pumpWords(tester, document);

    await typeText(tester, controller, 'al');
    await settle(tester, 8);
    final labels = popups.last.suggestions.map((s) => s.label).toList();
    expect(labels, ['also', 'alpha', 'alpine']);
    expect(popups.last.selectedIndex, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(popups.last.selectedIndex, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(popups.last.selectedIndex, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester, 4);
    expect(controller.text, '${document}alpha');
    expect(find.textContaining('suggest '), findsNothing);
  });

  testWidgets('a newline from the IME accepts the highlighted suggestion', (
    tester,
  ) async {
    final (controller, _) = await pumpWords(tester);

    await typeText(tester, controller, 'al');
    await settle(tester, 8);
    await typeText(tester, controller, '\n');
    await settle(tester, 8);

    expect(controller.text, '${_documentCompletion}alpha');
  });

  testWidgets('a newline after a key opens no popup and breaks the line', (
    tester,
  ) async {
    final (controller, _) = await pumpWords(tester);

    await typeText(tester, controller, 'key:');
    await settle(tester, 8);
    expect(controller.suggestions, isNull);
    await typeText(tester, controller, '\n');
    await settle(tester, 8);

    expect(controller.text, startsWith('${_documentCompletion}key:\n'));
    expect(controller.lineCount, _documentCompletion.split('\n').length + 1);
  });

  testWidgets('a newline after a word with no matches breaks the line', (
    tester,
  ) async {
    final (controller, _) = await pumpWords(tester);

    await typeText(tester, controller, 'zzq');
    await settle(tester, 8);
    expect(controller.suggestions, isNull);
    await typeText(tester, controller, '\n');
    await settle(tester, 8);

    expect(controller.text, '${_documentCompletion}zzq\n');
  });

  testWidgets('the popup is given the caret line as the editor scrolls', (
    tester,
  ) async {
    final controller = CodeForgeController()
      ..text = [
        for (var i = 0; i < 40; i++) 'filler$i ${'z' * 60}',
        'type: vmess',
        'name: ',
        for (var i = 0; i < 40; i++) 'tail$i',
      ].join('\n');
    const popupKey = Key('popup');
    final popups = <CodeForgeSuggestionDetails>[];
    await pumpEditor(
      tester,
      controller,
      enableLocalSuggestions: true,
      suggestionPopupBuilder: (_, details) {
        popups.add(details);
        return const SizedBox(key: popupKey);
      },
    );
    await focusEditor(tester);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.indexOf('name: ') + 'name: '.length,
    );
    await settle(tester, 2);
    await typeText(tester, controller, 'vm');
    await settle(tester, 8);

    final before = popups.last.caretRect;
    expect(before.height, editorLineHeight);
    final scrollable = tester.state<TwoDimensionalScrollableState>(
      find.byType(TwoDimensionalScrollable),
    );

    scrollable.horizontalScrollable.position.jumpTo(10);
    await tester.pump();
    expect(popups.last.caretRect, before.shift(const Offset(-10, 0)));

    final vertical = scrollable.verticalScrollable.position;
    final start = vertical.pixels;
    vertical.jumpTo(start + 10);
    await tester.pump();
    expect(popups.last.caretRect, before.shift(const Offset(-10, -10)));

    vertical.jumpTo(start + 700);
    await tester.pump();
    expect(find.byKey(popupKey), findsNothing);

    vertical.jumpTo(start);
    await tester.pump();
    expect(find.byKey(popupKey), findsOneWidget);
    expect(popups.last.caretRect, before.shift(const Offset(-10, 0)));
  });

  testWidgets('replacing the text closes the popup', (tester) async {
    final (controller, _) = await pumpWords(tester);

    await typeText(tester, controller, 'al');
    await settle(tester, 8);
    expect(controller.suggestions, isNotNull);
    controller.text = 'other: 1';

    expect(controller.suggestions, isNull);
    await settle(tester, 8);
    expect(controller.suggestions, isNull);
  });

  testWidgets('an undo closes the popup for good', (tester) async {
    final (controller, _) = await pumpWords(tester);

    await typeText(tester, controller, 'al');
    await settle(tester, 8);
    expect(controller.suggestions, isNotNull);
    controller.undoController!.undo();

    expect(controller.suggestions, isNull);
    await settle(tester, 8);
    expect(controller.suggestions, isNull);
  });

  testWidgets('losing focus closes the popup for good', (tester) async {
    final (controller, _) = await pumpWords(tester);

    await typeText(tester, controller, 'al');
    controller.focusNode!.unfocus();
    await settle(tester, 8);
    expect(controller.suggestions, isNull);

    controller.focusNode!.requestFocus();
    await typeText(tester, controller, 'p');
    await settle(tester, 8);
    expect(controller.suggestions, isNotNull);
    controller.focusNode!.unfocus();
    await tester.pump();
    expect(controller.suggestions, isNull);
  });

  testWidgets('accepting a suggestion takes in the word still being '
      'composed', (tester) async {
    final (controller, popups) = await pumpWords(tester);

    await typeText(tester, controller, 'al');
    await settle(tester, 8);
    final value = controller.currentTextEditingValue;
    final caret = value.selection.extentOffset;
    await sendDeltas(tester, [
      {
        ...textDelta(value.text, 'p', caret, caret),
        'composingBase': caret,
        'composingExtent': caret + 1,
      },
    ]);
    expect(controller.isComposingActive, isTrue);

    final details = popups.last;
    details.onAccept(details.suggestions.indexWhere((s) => s.label == 'alpha'));
    await settle(tester, 4);

    expect(controller.isComposingActive, isFalse);
    expect(controller.text, '${_documentCompletion}alpha');
  });

  testWidgets('a completion source learns which lines changed since', (
    tester,
  ) async {
    final requests = <CodeForgeCompletionRequest>[];
    final controller = CodeForgeController()
      ..text = _documentCompletion
      ..completionSource = (request) {
        requests.add(request);
        return null;
      };
    await pumpEditor(tester, controller);
    await focusEditor(tester);
    const nameLine = '  - name: alpha';
    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(1) + nameLine.length,
    );
    await typeText(tester, controller, 'x');
    await settle(tester, 8);
    final first = requests.last;

    controller.replaceRange(0, 0, '# a\n# b\n');
    controller.selection = TextSelection.collapsed(
      offset: controller.getLineStartOffset(3) + '${nameLine}x'.length,
    );
    await typeText(tester, controller, 'y');
    await settle(tester, 8);
    final second = requests.last;

    expect(second.lines[3], '${nameLine}xy');
    expect(second.linesEditedSince(first.version), (
      line: 0,
      removed: 1,
      inserted: 3,
    ));
    expect(second.linesEditedSince(0), isNull);
  });
}

const _proxy = CodeForgeSnippet(
  '- name: \${1:trojan}\n'
  '  type: trojan\n'
  '  server: \${2:server}\n'
  '  port: \${3:443}\$0',
);

CodeForgeCompletion? _trojanSource(CodeForgeCompletionRequest request) {
  final typed = RegExp(r'[\w-]*$').stringMatch(request.textBeforeCaret)!;
  if (typed.isEmpty || !'x-trojan'.startsWith(typed)) return null;
  return CodeForgeCompletion(
    prefix: typed,
    suggestions: const [
      CodeForgeSuggestion(
        label: 'x-trojan',
        detail: 'proxies · trojan',
        snippet: _proxy,
      ),
    ],
  );
}

void _snippet() {
  Future<(CodeForgeController, UndoRedoController)> pump(
    WidgetTester tester, {
    String document = 'proxies:\n  ',
    List<CodeForgeSuggestionDetails>? popups,
  }) async {
    final controller = CodeForgeController()
      ..text = document
      ..completionSource = _trojanSource;
    final undo = UndoRedoController();
    addTearDown(undo.dispose);
    await pumpEditor(
      tester,
      controller,
      undoController: undo,
      suggestionPopupBuilder: (context, details) {
        popups?.add(details);
        return const SizedBox.shrink();
      },
    );
    await focusEditor(tester);
    controller.selection = TextSelection.collapsed(offset: controller.length);
    await settle(tester, 2);
    return (controller, undo);
  }

  String selected(CodeForgeController controller) => controller.text.substring(
    controller.selection.start,
    controller.selection.end,
  );

  Future<void> tab(WidgetTester tester, {bool shift = false}) async {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle(tester, 2);
  }

  testWidgets('a suggestion expands its snippet over the prefix it matched', (
    tester,
  ) async {
    final popups = <CodeForgeSuggestionDetails>[];
    final (controller, _) = await pump(tester, popups: popups);

    await typeText(tester, controller, 'x-tro');
    await settle(tester, 8);

    final entry = popups.last.suggestions.single;
    expect(entry.label, 'x-trojan');
    expect(entry.detail, 'proxies · trojan');

    popups.last.onAccept(0);
    await settle(tester, 4);

    expect(
      controller.text,
      'proxies:\n'
      '  - name: trojan\n'
      '    type: trojan\n'
      '    server: server\n'
      '    port: 443',
    );
    expect(selected(controller), 'trojan');
    expect(controller.suggestions, isNull);
  });

  testWidgets('Tab walks the stops and follows typing inside one', (
    tester,
  ) async {
    final (controller, _) = await pump(tester);
    controller.insertSnippet(_proxy);
    await settle(tester, 8);

    await typeText(tester, controller, 'jp');
    await tab(tester);
    expect(selected(controller), 'server');
    await typeText(tester, controller, 'a.example');
    await tab(tester);
    expect(selected(controller), '443');
    await tab(tester, shift: true);
    expect(selected(controller), 'a.example');
    await tab(tester);
    await tab(tester);
    await settle(tester, 8);

    expect(
      controller.text,
      endsWith(
        '- name: jp\n    type: trojan\n'
        '    server: a.example\n    port: 443',
      ),
    );
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.extentOffset, controller.length);
    expect(controller.isSnippetActive, isFalse);
  });

  testWidgets('an edit outside the current stop ends the snippet', (
    tester,
  ) async {
    final (controller, _) = await pump(tester);
    controller.insertSnippet(_proxy);
    await settle(tester, 8);

    controller.selection = const TextSelection.collapsed(offset: 0);
    await typeText(tester, controller, 'x');
    await settle(tester, 8);

    expect(controller.isSnippetActive, isFalse);
    expect(controller.nextSnippetStop(), isFalse);
  });

  testWidgets('one undo removes the whole snippet', (tester) async {
    final (controller, undo) = await pump(tester);
    controller.insertSnippet(_proxy);
    await settle(tester, 8);

    undo.undo();
    await settle(tester, 8);

    expect(controller.text, 'proxies:\n  ');
  });

  testWidgets('an undone snippet leaves Tab to indent', (tester) async {
    final (controller, undo) = await pump(tester);
    controller.insertSnippet(const CodeForgeSnippet('\${1:key}\$0'));
    await settle(tester, 8);
    expect(selected(controller), 'key');

    undo.undo();
    await settle(tester, 8);
    expect(controller.isSnippetActive, isFalse);
    await tab(tester);
    await settle(tester, 8);

    expect(controller.text, 'proxies:\n  ${controller.tabSpace}');
  });

  testWidgets('a snippet replaces the word still being composed', (
    tester,
  ) async {
    final (controller, _) = await pump(tester);
    final value = controller.currentTextEditingValue;
    final caret = value.selection.extentOffset;
    await sendDeltas(tester, [
      {
        ...textDelta(value.text, 'a', caret, caret),
        'composingBase': caret,
        'composingExtent': caret + 1,
      },
    ]);
    expect(controller.isComposingActive, isTrue);

    controller.insertSnippet(const CodeForgeSnippet('\${1:key}: \$0'));
    await settle(tester, 8);

    expect(controller.isComposingActive, isFalse);
    expect(controller.text, 'proxies:\n  key: ');
    expect(selected(controller), 'key');
  });

  testWidgets('bodies resolve escapes, bare stops and repeated numbers', (
    tester,
  ) async {
    final (controller, _) = await pump(tester, document: '');
    controller.insertSnippet(
      const CodeForgeSnippet(
        'fn \${1:name}(\$2) {\n\t\$0\n} \\\$1 \${1:again} \$x',
      ),
    );
    await settle(tester, 8);

    expect(
      controller.text,
      'fn name() {\n${controller.tabSpace}\n} \$1 again \$x',
    );
    expect(selected(controller), 'name');
    await tab(tester);
    expect(controller.selection.extentOffset, 'fn name('.length);
    await tab(tester);
    expect(
      controller.selection.extentOffset,
      'fn name() {\n'.length + controller.tabSpace.length,
    );
    expect(controller.isSnippetActive, isFalse);
    await settle(tester, 8);
  });
}

const _documentFind = '''
proxies:
  - name: Port-A
    port: 80
  - name: b
    port: 8080
    sport: 1
rules:
  - DST-PORT,80,DIRECT''';

void _find() {
  Future<(CodeForgeController, FindController)> pumpFind(
    WidgetTester tester, {
    UndoRedoController? undoController,
    String text = _documentFind,
  }) async {
    final controller = CodeForgeController()..text = text;
    final finder = FindController(controller);
    addTearDown(finder.dispose);
    await pumpEditor(
      tester,
      controller,
      findController: finder,
      undoController: undoController,
    );
    return (controller, finder);
  }

  List<String> highlighted(CodeForgeController controller) => [
    for (final highlight in controller.searchHighlights)
      controller.text.substring(highlight.start, highlight.end),
  ];

  testWidgets('find counts matches, highlights them and moves the caret', (
    tester,
  ) async {
    final (controller, finder) = await pumpFind(tester);

    finder.find('port');
    await settle(tester, 2);
    expect(finder.matchCount, 5);
    expect(highlighted(controller), ['Port', 'port', 'port', 'port', 'PORT']);
    expect(finder.currentMatchIndex, 0);
    expect(controller.selection.extentOffset, _documentFind.indexOf('Port'));
    expect(
      controller.searchHighlights.where((h) => h.isCurrentMatch),
      hasLength(1),
    );

    finder.next();
    expect(finder.currentMatchIndex, 1);
    expect(controller.selection.extentOffset, _documentFind.indexOf('port:'));
    finder.previous();
    finder.previous();
    expect(finder.currentMatchIndex, 4);
    expect(controller.selection.extentOffset, _documentFind.indexOf('PORT'));

    finder.find('');
    await settle(tester, 2);
    expect(finder.matchCount, 0);
    expect(controller.searchHighlights, isEmpty);
  });

  testWidgets('matches are counted in scalars and CJK words are whole words', (
    tester,
  ) async {
    final (controller, finder) = await pumpFind(
      tester,
      text: '😀 节点 a节点\n节点',
    );

    finder.find('节点');
    expect(finder.matchCount, 3);
    expect(controller.searchHighlights.first.start, 2);
    expect(controller.searchHighlights.last.start, 9);
    finder.matchWholeWord = true;
    expect(finder.matchCount, 2);
  });

  testWidgets('a regex may look around and an invalid or runaway one finds '
      'nothing', (tester) async {
    final (controller, finder) = await pumpFind(
      tester,
      text: 'port: 80\n${'a' * 40}b',
    );
    finder.isRegex = true;

    finder.find(r'(?<=port: )\d+');
    expect(highlighted(controller), ['80']);
    finder.find('(');
    expect(finder.matchCount, 0);
    final watch = Stopwatch()..start();
    finder.find(r'(a+)+\1$');
    expect(finder.matchCount, 0);
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  testWidgets('case, whole-word and regex options narrow the matches', (
    tester,
  ) async {
    final (controller, finder) = await pumpFind(tester);

    finder.find('port');
    finder.caseSensitive = true;
    expect(finder.matchCount, 3);
    finder.matchWholeWord = true;
    expect(finder.matchCount, 2);
    finder.caseSensitive = false;
    expect(highlighted(controller), ['Port', 'port', 'port', 'PORT']);

    finder.matchWholeWord = false;
    finder.isRegex = true;
    finder.find(r'\d+');
    expect(highlighted(controller), ['80', '8080', '1', '80']);
    finder.find('(');
    expect(finder.matchCount, 0);
  });

  testWidgets('finderBuilder shows only while the finder is active', (
    tester,
  ) async {
    final controller = CodeForgeController()..text = _documentFind;
    final findController = FindController(controller);
    addTearDown(findController.dispose);
    await pumpEditor(
      tester,
      controller,
      findController: findController,
      finderBuilder: (context, panel) => PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Text('matches: ${panel.matchCount}'),
      ),
    );
    expect(find.textContaining('matches:'), findsNothing);

    findController.isActive = true;
    findController.find('name');
    await tester.pump();
    expect(find.textContaining('matches: 2'), findsOneWidget);

    findController.isActive = false;
    await tester.pump();
    expect(find.textContaining('matches:'), findsNothing);
  });

  testWidgets('typing in the find field searches', (tester) async {
    final (_, finder) = await pumpFind(tester);
    finder.isActive = true;
    finder.findInputController.text = 'name';
    await settle(tester, 2);
    expect(finder.matchCount, 2);
  });

  testWidgets('matches follow edits to the document', (tester) async {
    final (controller, finder) = await pumpFind(tester);
    finder.isActive = true;
    finder.find('name');
    expect(finder.matchCount, 2);

    controller.replaceRange(controller.length, controller.length, '\n# name');
    await settle(tester, 2);
    expect(finder.matchCount, 3);
  });

  testWidgets('edits after closing the finder bring no highlights back', (
    tester,
  ) async {
    final (controller, finder) = await pumpFind(tester);
    finder.isActive = true;
    finder.find('name');
    finder.isActive = false;
    expect(controller.searchHighlights, isEmpty);

    controller.replaceRange(controller.length, controller.length, '\n# name');
    await settle(tester, 2);
    expect(controller.searchHighlights, isEmpty);

    finder.isActive = true;
    expect(finder.matchCount, 3);
  });

  testWidgets('replace swaps the current match and replaceAll the rest', (
    tester,
  ) async {
    final undo = UndoRedoController();
    addTearDown(undo.dispose);
    final (controller, finder) = await pumpFind(tester, undoController: undo);
    finder.isActive = true;
    finder.matchWholeWord = true;
    finder.find('80');
    expect(finder.matchCount, 2);

    finder.replaceInputController.text = '443';
    finder.replace();
    await settle(tester, 2);
    expect(controller.getLineText(2), '    port: 443');
    expect(finder.matchCount, 1);

    finder.replaceInputController.text = '53';
    finder.replaceAll();
    await settle(tester, 2);
    expect(controller.getLineText(7), '  - DST-PORT,53,DIRECT');
    expect(controller.getLineText(4), '    port: 8080');
    expect(finder.matchCount, 0);

    while (undo.canUndo) {
      undo.undo();
      await settle(tester, 2);
    }
    expect(controller.text, _documentFind);
  });

  testWidgets('regex replaceAll replaces the line matches find shows', (
    tester,
  ) async {
    final (controller, finder) = await pumpFind(tester);
    finder.isActive = true;
    finder.isRegex = true;
    finder.find(r'^    port');
    expect(finder.matchCount, 2);

    finder.replaceInputController.text = '    listen';
    finder.replaceAll();
    await settle(tester, 2);
    expect(controller.getLineText(2), '    listen: 80');
    expect(controller.getLineText(4), '    listen: 8080');
    expect(controller.getLineText(5), '    sport: 1');
  });

  testWidgets('replacing an empty regex match moves on to the next one', (
    tester,
  ) async {
    final (controller, finder) = await pumpFind(tester, text: 'a\nb\nc');
    finder.isActive = true;
    finder.isRegex = true;
    finder.find(r'$');
    expect(finder.matchCount, 3);

    finder.replaceInputController.text = ';';
    for (var i = 0; i < 3; i++) {
      finder.replace();
      await settle(tester, 2);
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.text, 'a;\nb;\nc;');
  });

  group('a word still being composed', () {
    Future<(CodeForgeController, FindController)> composeAtFirstMatch(
      WidgetTester tester,
    ) async {
      final (controller, finder) = await pumpFind(tester);
      await focusEditor(tester);
      finder.isActive = true;
      finder.matchWholeWord = true;
      finder.find('80');
      await tester.pump();
      final value = controller.currentTextEditingValue;
      final caret = value.selection.extentOffset;
      await sendDeltas(tester, [
        {
          ...textDelta(value.text, 's', caret, caret),
          'composingBase': caret,
          'composingExtent': caret + 1,
        },
      ]);
      expect(controller.isComposingActive, isTrue);
      finder.replaceInputController.text = '53';
      return (controller, finder);
    }

    testWidgets('is kept by replace', (tester) async {
      final (controller, finder) = await composeAtFirstMatch(tester);

      finder.replace();
      await settle(tester, 2);
      expect(controller.isComposingActive, isFalse);
      expect(controller.getLineText(2), '    port: s80');
      expect(controller.getLineText(7), '  - DST-PORT,53,DIRECT');
    });

    testWidgets('is kept by replaceAll', (tester) async {
      final (controller, finder) = await composeAtFirstMatch(tester);

      finder.replaceAll();
      await settle(tester, 2);
      expect(controller.isComposingActive, isFalse);
      expect(controller.getLineText(2), '    port: s80');
      expect(controller.getLineText(7), '  - DST-PORT,53,DIRECT');
    });
  });

  testWidgets('scrollToLine still works after the editor is rebuilt anew', (
    tester,
  ) async {
    final lines = [for (var i = 0; i < 200; i++) 'k$i: v'];
    final controller = CodeForgeController()..text = lines.join('\n');
    late ScrollController vertical;
    for (final key in const [ValueKey('light'), ValueKey('dark')]) {
      await pumpEditor(
        tester,
        controller,
        key: key,
        scrollbarBuilder: (context, details, child) {
          vertical = details.controller;
          return child;
        },
      );
    }
    vertical.jumpTo(0);
    await settle(tester, 2);

    controller.scrollToLine(100);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      vertical.offset + (600 - editorTopPadding) / 2,
      closeTo(editorLineHeight * 100.5, editorLineHeight),
    );
  });

  testWidgets('matches move with edits and edited lines are searched again', (
    tester,
  ) async {
    final (controller, finder) = await pumpFind(tester);
    finder.isActive = true;
    finder.find('port');
    expect(highlighted(controller), ['Port', 'port', 'port', 'port', 'PORT']);

    controller.replaceRange(0, 0, '# port\n');
    await settle(tester, 2);
    expect(highlighted(controller), [
      'port',
      'Port',
      'port',
      'port',
      'port',
      'PORT',
    ]);

    final sport = controller.text.indexOf('    sport');
    controller.replaceRange(sport, sport + '    sport: 1\n'.length, '');
    await settle(tester, 2);
    expect(highlighted(controller), ['port', 'Port', 'port', 'port', 'PORT']);
  });

  testWidgets('a regex match across lines is found once typing pauses', (
    tester,
  ) async {
    final (controller, finder) = await pumpFind(tester);
    finder.isActive = true;
    finder.isRegex = true;
    finder.find(r'b\n +port');
    expect(finder.matchCount, 1);

    final lineEnd = controller.getLineStartOffset(4) - 1;
    controller.replaceRange(lineEnd, lineEnd, ' x');
    await settle(tester, 2);
    expect(finder.matchCount, 0);

    controller.replaceRange(lineEnd, lineEnd + 2, '');
    await tester.pump(const Duration(milliseconds: 300));
    expect(finder.matchCount, 1);
  });
}
