import 'package:compapp_design/src/tokens/app_colors.dart';
import 'package:compapp_design/src/tokens/app_palette.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// Material 3 themes built from the design tokens.
///
/// Both themes use an explicit [ColorScheme] (no seed), the [AppColors]
/// extension and the Compapp type scale. Component themes arrive with the
/// atoms.
abstract final class CompappTheme {
  static final ThemeData light = _build(
    brightness: Brightness.light,
    palette: AppPalette.light,
    colors: AppColors.light,
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    palette: AppPalette.dark,
    colors: AppColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
    required AppColors colors,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      // Token-mapped slots.
      surface: palette.ground,
      surfaceContainerLowest: palette.surface,
      surfaceContainerHigh: palette.surfaceSunken,
      onSurface: palette.ink,
      onSurfaceVariant: palette.inkMuted,
      outlineVariant: palette.line,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primarySoft,
      error: palette.danger,
      errorContainer: palette.dangerSoft,
      // Filler slots, see the token table in AGENTS.md.
      onPrimaryContainer: palette.ink,
      secondary: palette.primary,
      onSecondary: palette.onPrimary,
      secondaryContainer: palette.primarySoft,
      onSecondaryContainer: palette.ink,
      tertiary: colors.busy,
      onTertiary: palette.onPrimary,
      tertiaryContainer: colors.busySoft,
      onTertiaryContainer: palette.ink,
      onError: palette.onPrimary,
      onErrorContainer: palette.ink,
      surfaceDim: palette.surfaceSunken,
      surfaceBright: palette.surface,
      surfaceContainerLow: palette.surface,
      surfaceContainer: palette.surface,
      surfaceContainerHighest: palette.surfaceSunken,
      outline: palette.inkMuted,
      inverseSurface: palette.ink,
      onInverseSurface: palette.ground,
      inversePrimary: palette.primarySoft,
      surfaceTint: Colors.transparent,
    );

    final textTheme = AppTypography.textTheme.apply(
      bodyColor: palette.ink,
      displayColor: palette.ink,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.bodyFamily,
      package: AppTypography.package,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.ground,
      textTheme: textTheme,
      extensions: [colors],
    );
  }
}
