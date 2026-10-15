import 'package:bett_box/models/common.dart';
import 'package:bett_box/widgets/code_editor.dart';
import 'package:bett_box/widgets/popup.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<double>> pumpMenu(WidgetTester tester, double zoom) async {
    final changes = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: CommonPopupMenu(
            items: [PopupMenuItemData(label: 'Wrap', onPressed: () {})],
            footer: EditorZoomMenuItem(
              zoom: zoom,
              minZoom: 0.7,
              maxZoom: 1.5,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  bool enabled(WidgetTester tester, IconData icon) =>
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, icon))
          .onPressed !=
      null;

  testWidgets('the zoom row sits below the items and steps by ten percent', (
    tester,
  ) async {
    final changes = await pumpMenu(tester, 1);

    expect(
      tester.getTopLeft(find.text('100%')).dy,
      greaterThan(tester.getBottomLeft(find.text('Wrap')).dy),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove));
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(changes.map((zoom) => (zoom * 100).round()), [110, 100, 90]);
    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('a pinched size steps to the next whole level', (tester) async {
    final changes = await pumpMenu(tester, 1.09375);

    expect(find.text('109%'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('120%'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(changes.map((zoom) => (zoom * 100).round()), [120, 110, 100]);
  });

  testWidgets('the zoom buttons stop at the limits', (tester) async {
    final changes = await pumpMenu(tester, 1.4);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(changes, [1.5]);
    expect(enabled(tester, Icons.add), isFalse);
    expect(enabled(tester, Icons.remove), isTrue);

    await tester.pumpWidget(const SizedBox());
    await pumpMenu(tester, 0.7);

    expect(enabled(tester, Icons.remove), isFalse);
  });
}
