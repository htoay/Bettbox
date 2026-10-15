import 'package:bett_box/models/models.dart';
import 'package:bett_box/widgets/popup.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpMenu(WidgetTester tester, VoidCallback onPressed) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: CommonPopupBox(
            targetBuilder: (open) =>
                IconButton(onPressed: open, icon: const Icon(Icons.more_vert)),
            popup: CommonPopupMenu(
              items: [PopupMenuItemData(label: 'action', onPressed: onPressed)],
            ),
          ),
        ),
      ),
    ),
  );
}

double _menuOpacity(WidgetTester tester) {
  return tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.byType(CommonPopupMenu),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;
}

void main() {
  testWidgets('弹出动画等首帧构建完成后才开始，并完整播放', (tester) async {
    await _pumpMenu(tester, () {});

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    expect(_menuOpacity(tester), closeTo(0.1, 0.001));

    await tester.pump(const Duration(milliseconds: 200));
    expect(_menuOpacity(tester), closeTo(0.1, 0.001));

    await tester.pump(const Duration(milliseconds: 75));
    expect(_menuOpacity(tester), inExclusiveRange(0.1, 1.0));

    await tester.pump(const Duration(milliseconds: 75));
    expect(_menuOpacity(tester), closeTo(1.0, 0.001));
  });

  testWidgets('菜单项动作在关闭转场结束后才执行', (tester) async {
    var pressed = 0;
    await _pumpMenu(tester, () => pressed++);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('action'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(pressed, 0);
    expect(find.byType(CommonPopupMenu), findsOneWidget);

    await tester.pumpAndSettle();
    expect(pressed, 1);
    expect(find.byType(CommonPopupMenu), findsNothing);
  });
}
