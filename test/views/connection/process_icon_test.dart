import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/connection/item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('首次加载的图标请求会完成并刷新当前行', (tester) async {
    const channel = MethodChannel('window_ext');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    globalState.appState = AppState(
      brightness: Brightness.light,
      version: 0,
      viewSize: Size.zero,
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
    globalState.config = Config(
      themeProps: defaultThemeProps,
      patchClashConfig: const ClashConfig(
        findProcessMode: FindProcessMode.always,
      ),
    );
    final info = TrackerInfo(
      id: 'request',
      start: DateTime(2026),
      metadata: const Metadata(
        process: 'app',
        processPath: '/tmp/bettbox-test/missing-app',
      ),
      chains: const ['DIRECT'],
      rule: '',
      rulePayload: '',
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: Builder(
            builder: (context) {
              globalState.measure = Measure.of(context, 1);
              return Scaffold(
                body: TrackerInfoItem(
                  trackerInfo: info,
                  detailTitle: 'detail',
                  index: 0,
                  count: 1,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.terminal), findsOneWidget);
  }, skip: !system.isDesktop);
}
