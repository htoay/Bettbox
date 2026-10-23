import 'package:bett_box/common/color.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:material_ui/material_ui.dart';

List<Color> _roles(ColorScheme scheme) => [
  scheme.primary,
  scheme.onPrimary,
  scheme.primaryContainer,
  scheme.onPrimaryContainer,
  scheme.primaryFixed,
  scheme.primaryFixedDim,
  scheme.onPrimaryFixed,
  scheme.onPrimaryFixedVariant,
  scheme.secondary,
  scheme.onSecondary,
  scheme.secondaryContainer,
  scheme.onSecondaryContainer,
  scheme.secondaryFixed,
  scheme.secondaryFixedDim,
  scheme.onSecondaryFixed,
  scheme.onSecondaryFixedVariant,
  scheme.tertiary,
  scheme.onTertiary,
  scheme.tertiaryContainer,
  scheme.onTertiaryContainer,
  scheme.tertiaryFixed,
  scheme.tertiaryFixedDim,
  scheme.onTertiaryFixed,
  scheme.onTertiaryFixedVariant,
  scheme.error,
  scheme.onError,
  scheme.errorContainer,
  scheme.onErrorContainer,
  scheme.outline,
  scheme.outlineVariant,
  scheme.surface,
  scheme.surfaceDim,
  scheme.surfaceBright,
  scheme.surfaceContainerLowest,
  scheme.surfaceContainerLow,
  scheme.surfaceContainer,
  scheme.surfaceContainerHigh,
  scheme.surfaceContainerHighest,
  scheme.onSurface,
  scheme.onSurfaceVariant,
  scheme.inverseSurface,
  scheme.onInverseSurface,
  scheme.inversePrimary,
  scheme.shadow,
  scheme.scrim,
  scheme.surfaceTint,
];

List<int> _systemList(double hue, double chroma, Map<int, int> overrides) {
  final palette = TonalPalette.of(hue, chroma);
  return [
    for (final tone in TonalPalette.commonTones)
      overrides[tone] ?? palette.get(tone),
  ];
}

DynamicScheme _systemScheme(bool isDark) {
  final primary = TonalPalette.fromList(
    _systemList(250, 36, {40: 0xFF123456, 80: 0xFFA1B2C3}),
  );
  return DynamicScheme(
    sourceColorHct: primary.keyColor,
    variant: Variant.tonalSpot,
    isDark: isDark,
    primaryPalette: primary,
    secondaryPalette: TonalPalette.fromList(
      _systemList(250, 16, {90: 0xFFDDE3EA}),
    ),
    tertiaryPalette: TonalPalette.fromList(
      _systemList(310, 24, {40: 0xFF6A4F7A}),
    ),
    neutralPalette: TonalPalette.fromList(_systemList(250, 6, {})),
    neutralVariantPalette: TonalPalette.fromList(_systemList(250, 8, {})),
  );
}

void main() {
  test('DynamicScheme 转换与 ColorScheme.fromSeed 一致', () {
    for (final seed in const [Color(0xFF00897B), Color(0xFF93CAFF)]) {
      for (final brightness in Brightness.values) {
        final expected = ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
        );
        final actual = SchemeTonalSpot(
          sourceColorHct: Hct.fromInt(seed.toARGB32()),
          isDark: brightness == Brightness.dark,
          contrastLevel: 0,
        ).toColorScheme();
        expect(actual.brightness, brightness);
        expect(_roles(actual), _roles(expected));
      }
    }
  });

  test('跟随系统时保留系统色板的原始色值', () {
    final light = _systemScheme(false).toColorScheme();
    expect(light.brightness, Brightness.light);
    expect(light.primary, const Color(0xFF123456));
    expect(light.secondaryContainer, const Color(0xFFDDE3EA));
    expect(light.tertiary, const Color(0xFF6A4F7A));

    final dark = _systemScheme(true).toColorScheme();
    expect(dark.brightness, Brightness.dark);
    expect(dark.primary, const Color(0xFFA1B2C3));
  });
}
