import 'package:flutter/material.dart';

class AppDataTableColors {
  const AppDataTableColors({
    required this.headerBackground,
    required this.headerText,
    required this.evenRowBackground,
    required this.oddRowBackground,
    required this.selectedRowBackground,
  });

  final Color headerBackground;
  final Color headerText;
  final Color evenRowBackground;
  final Color oddRowBackground;
  final Color selectedRowBackground;

  factory AppDataTableColors.standard(ThemeData theme) {
    final base = theme.colorScheme.primary;
    return AppDataTableColors._fromBase(
      base: base,
      headerLightness: 0.92,
      oddLightness: 0.97,
      evenLightness: 0.985,
      saturationFactor: 0.28,
      theme: theme,
    );
  }

  factory AppDataTableColors.score(ThemeData theme, Color base) {
    return AppDataTableColors._fromBase(
      base: base,
      headerLightness: 0.86,
      oddLightness: 0.92,
      evenLightness: 0.95,
      saturationFactor: 0.45,
      theme: theme,
    );
  }

  factory AppDataTableColors._fromBase({
    required Color base,
    required double headerLightness,
    required double oddLightness,
    required double evenLightness,
    required double saturationFactor,
    required ThemeData theme,
  }) {
    final header = _toneColor(
      base,
      lightness: headerLightness,
      saturationFactor: saturationFactor,
    );
    final odd = _toneColor(
      base,
      lightness: oddLightness,
      saturationFactor: saturationFactor * 0.85,
    );
    final even = _toneColor(
      base,
      lightness: evenLightness,
      saturationFactor: saturationFactor * 0.7,
    );
    final selected = _toneColor(
      base,
      lightness: (headerLightness + oddLightness) / 2,
      saturationFactor: saturationFactor,
    );

    return AppDataTableColors(
      headerBackground: header,
      headerText: _onColor(header),
      evenRowBackground: even,
      oddRowBackground: odd,
      selectedRowBackground: selected.withAlpha(255),
    );
  }
}

MaterialStateProperty<Color?> buildHeaderColor(Color color) {
  return MaterialStateProperty.all(color);
}

MaterialStateProperty<Color?> buildStripedRowColor({
  required int index,
  required AppDataTableColors colors,
}) {
  return MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.selected)) {
      return colors.selectedRowBackground;
    }
    return index.isEven ? colors.evenRowBackground : colors.oddRowBackground;
  });
}

Color _toneColor(
  Color color, {
  required double lightness,
  required double saturationFactor,
}) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withSaturation((hsl.saturation * saturationFactor).clamp(0.0, 1.0))
      .withLightness(lightness.clamp(0.0, 1.0))
      .toColor();
}

Color _onColor(Color background) {
  final brightness = ThemeData.estimateBrightnessForColor(background);
  return brightness == Brightness.dark ? Colors.white : Colors.black87;
}
