import 'package:bett_box/common/navigator.dart';
import 'package:bett_box/widgets/builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget field() => Scaffold(
    body: IdleFocusBuilder(
      builder: (_, focusNode) => TextField(focusNode: focusNode),
    ),
  );

  bool focused(WidgetTester tester) => tester
      .widget<TextField>(find.byType(TextField, skipOffstage: false))
      .focusNode!
      .hasFocus;

  testWidgets('页面转场期间不聚焦，结束后立即聚焦', (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [routeIdleObserver],
        home: const Scaffold(body: Text('home')),
      ),
    );
    key.currentState!.push(MaterialPageRoute<void>(builder: (_) => field()));
    await tester.pump();
    expect(routeIdleObserver.busy.value, isTrue);
    var frames = 0;
    while (routeIdleObserver.busy.value) {
      expect(focused(tester), isFalse);
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
    }
    expect(frames, greaterThan(3));
    await tester.pumpAndSettle();
    expect(routeIdleObserver.busy.value, isFalse);
    expect(focused(tester), isTrue);
  });

  testWidgets('弹窗转场期间不聚焦，结束后聚焦', (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [routeIdleObserver],
        home: const Scaffold(body: Text('home')),
      ),
    );
    showGeneralDialog<void>(
      context: key.currentContext!,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) =>
          Center(child: SizedBox(width: 200, height: 100, child: field())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(focused(tester), isFalse);
    await tester.pumpAndSettle();
    expect(focused(tester), isTrue);
  });

  testWidgets('没有转场时下一帧即聚焦，输入框已卸载则跳过', (tester) async {
    await tester.pumpWidget(MaterialApp(home: field()));
    await tester.pump();
    await tester.pump();
    expect(focused(tester), isTrue);

    final node = FocusNode();
    addTearDown(node.dispose);
    final pending = node.requestFocusWhenIdle();
    await tester.pump();
    await tester.pump();
    await pending;
    expect(node.hasFocus, isFalse);
  });
}
