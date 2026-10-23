import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/pages/speed_test.dart';
import 'package:bett_box/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _groups = [
  Group(
    type: GroupType.Selector,
    name: 'Select',
    now: 'Auto',
    all: [
      Proxy(name: 'Auto', type: 'URLTest'),
      Proxy(name: 'HK 1', type: 'Shadowsocks'),
      Proxy(name: 'DIRECT', type: 'Direct'),
      Proxy(name: 'REJECT', type: 'Reject'),
    ],
  ),
  Group(
    type: GroupType.URLTest,
    name: 'Auto',
    now: 'JP 1',
    all: [
      Proxy(name: 'JP 1', type: 'Trojan'),
      Proxy(name: 'HK 1', type: 'Shadowsocks'),
    ],
  ),
  Group(
    type: GroupType.Selector,
    name: 'Other',
    now: 'US 1',
    all: [Proxy(name: 'US 1', type: 'Vmess')],
  ),
];

void main() {
  test('全部节点去重并排除 DIRECT、REJECT 与代理组', () {
    final nodes = collectBatchNodes(_groups, (
      scope: OutboundBatchScope.all,
      name: '',
    ));
    expect(nodes, unorderedEquals(['HK 1', 'JP 1', 'US 1']));
  });

  test('整组检测会展开嵌套代理组', () {
    final nodes = collectBatchNodes(_groups, (
      scope: OutboundBatchScope.group,
      name: 'Select',
    ));
    expect(nodes, unorderedEquals(['HK 1', 'JP 1']));
  });

  test('单个节点只检测该节点', () {
    final nodes = collectBatchNodes(_groups, (
      scope: OutboundBatchScope.node,
      name: 'US 1',
    ));
    expect(nodes, ['US 1']);
  });

  testWidgets('批量模式显示全部节点与整组检测入口并返回所选范围', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    globalState.appState = AppState(
      brightness: Brightness.light,
      version: 0,
      viewSize: const Size(600, 900),
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
      groups: _groups,
    );
    globalState.config = Config(
      themeProps: defaultThemeProps,
      currentProfileId: 'test',
      profiles: const [
        Profile(
          id: 'test',
          label: 'test',
          autoUpdateDuration: Duration(days: 1),
        ),
      ],
    );
    Object? picked;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                globalState.measure = Measure.of(context, 1);
                return ElevatedButton(
                  onPressed: () async {
                    picked = await showDialog<Object>(
                      context: context,
                      builder: (_) => buildSpeedTestOutboundPickerForTesting(
                        selected: '',
                        groups: _groups,
                        batch: true,
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(appLocalizations.mediaBatchAll), findsOneWidget);
    expect(find.text(appLocalizations.direct), findsNothing);
    expect(find.text(appLocalizations.mediaBatchGroup), findsNWidgets(3));

    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(find.text('DIRECT'), findsNothing);
    expect(find.text('REJECT'), findsNothing);

    await tester.tap(find.text(appLocalizations.mediaBatchGroup).last);
    await tester.pumpAndSettle();
    expect(picked, (scope: OutboundBatchScope.group, name: 'Other'));
  });
}
