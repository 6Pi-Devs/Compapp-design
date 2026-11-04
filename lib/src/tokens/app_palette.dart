import 'package:flutter/painting.dart';

/// Colour tokens that map to a Material `ColorScheme` slot.
///
/// Internal: `CompappTheme` turns it into a `ColorScheme`. Widgets read these
/// colours through `Theme.of(context).colorScheme`.
class AppPalette {
  const new({
    required this.ground,
    required this.surface,
    required this.surfaceSunken,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.danger,
    required this.dangerSoft,
  });

  static const light = AppPalette(
    ground: Color(0xFFF2F5EF),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE8EEE6),
    ink: Color(0xFF1C2B22),
    inkMuted: Color(0xFF55635A),
    line: Color(0xFFCFD8CC),
    primary: Color(0xFF3D7A52),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFCFE6D3),
    danger: Color(0xFFB3261E),
    dangerSoft: Color(0xFFF6D5D2),
  );

  static const dark = AppPalette(
    ground: Color(0xFF111915),
    surface: Color(0xFF18221C),
    surfaceSunken: Color(0xFF0C120F),
    ink: Color(0xFFE3ECE5),
    inkMuted: Color(0xFF9DAEA3),
    line: Color(0xFF2C3A31),
    primary: Color(0xFF8CCB9C),
    onPrimary: Color(0xFF0E1A12),
    primarySoft: Color(0xFF24402D),
    danger: Color(0xFFF2B8B5),
    dangerSoft: Color(0xFF5C1F1B),
  );

  final Color ground;
  final Color surface;
  final Color surfaceSunken;
  final Color ink;
  final Color inkMuted;
  final Color line;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color danger;
  final Color dangerSoft;

  /// Every colour by its JSON name, compared against the JSON by the parity
  /// test.
  Map<String, Color> get values => {
    'ground': ground,
    'surface': surface,
    'surface-sunken': surfaceSunken,
    'ink': ink,
    'ink-muted': inkMuted,
    'line': line,
    'primary': primary,
    'on-primary': onPrimary,
    'primary-soft': primarySoft,
    'danger': danger,
    'danger-soft': dangerSoft,
  };
}
