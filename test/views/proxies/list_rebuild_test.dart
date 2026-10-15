import 'package:bett_box/common/common.dart';
import 'package:bett_box/controller.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/proxies/card.dart';
import 'package:bett_box/views/proxies/list.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final sticky in [true, false]) {
    testWidgets('展开收起只重建发生变化的组 sticky=$sticky', (tester) async {
      globalState.appState = AppState(
        brightness: Brightness.light,
        version: 0,
        viewSize: const Size(400, 800),
        requests: FixedList(maxLength),
        logs: FixedList(maxLogLength),
        traffics: FixedList(30),
        totalTraffic: Traffic(),
        systemUiOverlayStyle: const SystemUiOverlayStyle(),
        groups: [
          for (var g = 0; g < 12; g++)
            Group(
              type: GroupType.Selector,
              name: 'group$g',
              now: 'node$g-0',
              all: [
                for (var i = 0; i < 4; i++)
                  Proxy(name: 'node$g-$i', type: 'Shadowsocks'),
              ],
            ),
        ],
      );
      globalState.config = Config(
        themeProps: defaultThemeProps,
        currentProfileId: 'p',
        profiles: const [
          Profile(
            id: 'p',
            label: 'p',
            autoUpdateDuration: Duration(days: 1),
            unfoldSet: {'group0'},
          ),
        ],
        proxiesStyle: defaultProxiesStyle.copyWith(
          type: ProxiesType.list,
          autoStickyHeader: sticky,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [AppLocalizations.delegate],
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  globalState.appController = AppController(context, ref);
                  globalState.measure = Measure.of(context, 1);
                  return const ProxiesListView();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('node1-0'), findsOneWidget);
      final cardsBefore = tester.widgetList(find.byType(ProxyCard)).toSet();
      expect(cardsBefore, hasLength(4));

      final builds = <String, int>{};
      debugOnRebuildDirtyWidget = (element, _) {
        final type = '${element.widget.runtimeType}';
        builds[type] = (builds[type] ?? 0) + 1;
      };
      addTearDown(() => debugOnRebuildDirtyWidget = null);

      await tester.tap(find.byType(CommonExpandIcon).at(1));
      await tester.pump();
      debugOnRebuildDirtyWidget = null;

      expect(builds['_GroupHeader'], 1);
      expect(find.text('node1-0'), findsNWidgets(2));
      final cardsAfter = tester.widgetList(find.byType(ProxyCard)).toSet();
      expect(cardsAfter, hasLength(8));
      expect(cardsAfter.containsAll(cardsBefore), isTrue);
      expect(builds['ProxyCard'], 4);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
