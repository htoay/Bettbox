import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/pages/toolbox/mrs_lookup.dart';
import 'package:bett_box/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _result = MrsLookupResult(
  target: 'telegram.org',
  host: 'telegram.org',
  matches: [
    MrsMatch(
      kind: 'geosite',
      name: 'telegram',
      file: 'geo/geosite/telegram.mrs',
      count: 12,
    ),
  ],
);

Future<String?> _tapAndCopy(
  WidgetTester tester,
  bool copyRaw, {
  MrsRawSource source = MrsRawSource.bettRules,
}) async {
  String? copied;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  globalState.config = Config(
    themeProps: defaultThemeProps,
    appSetting: AppSettingProps(mrsCopyRawLink: copyRaw, mrsRawSource: source),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: SingleChildScrollView(child: buildMrsResultForTesting(_result)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(
    find.text('path-in-bundle: "geo/geosite/telegram.mrs"'),
    findsOneWidget,
  );
  await tester.tap(find.text('GEOSITE,telegram'));
  await tester.pump();
  return copied;
}

void main() {
  testWidgets('默认复制规则名', (tester) async {
    expect(await _tapAndCopy(tester, false), 'GEOSITE,telegram');
  });

  testWidgets('开启后复制 GitHub Raw 链接', (tester) async {
    expect(
      await _tapAndCopy(tester, true),
      'https://raw.githubusercontent.com/appshubcc/bett-rules/meta/geo/geosite/telegram.mrs',
    );
  });

  testWidgets('选择 meta-rules-dat 时复制对应链接', (tester) async {
    expect(
      await _tapAndCopy(tester, true, source: MrsRawSource.metaRulesDat),
      'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/telegram.mrs',
    );
  });
}
