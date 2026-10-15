import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/theme.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/dashboard/widgets/media_unlock.dart';
import 'package:bett_box/views/dashboard/widgets/media_unlock_small.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUp(() {
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
    globalState.config = Config(themeProps: defaultThemeProps);
  });

  Widget buildApp(Brightness brightness, Widget child) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: brightness,
          ),
        ),
        home: Builder(
          builder: (context) {
            globalState.measure = Measure.of(context, 1);
            globalState.theme = CommonTheme.of(context, 1);
            return Scaffold(body: child);
          },
        ),
      ),
    );
  }

  Color? platformLabelColor(WidgetTester tester) {
    final name = defaultPinnedMediaPlatforms.first.defaultName;
    return tester.widget<Text>(find.text(name).first).style?.color;
  }

  for (final (label, child) in <(String, Widget)>[
    ('MediaUnlock', const MediaUnlock()),
    ('MediaUnlockSmall', const MediaUnlockSmall()),
  ]) {
    testWidgets('$label 在主题切换后立即使用新的配色', (tester) async {
      await tester.pumpWidget(buildApp(Brightness.light, child));
      await tester.pumpAndSettle();
      final lightColor = platformLabelColor(tester);

      await tester.pumpWidget(buildApp(Brightness.dark, child));
      await tester.pumpAndSettle();
      final context = tester.element(find.byWidget(child));
      final darkColor = platformLabelColor(tester);

      expect(darkColor, isNot(lightColor));
      expect(darkColor, Theme.of(context).colorScheme.onSurface);
    });
  }
}
