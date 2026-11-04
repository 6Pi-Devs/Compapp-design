import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design/src/tokens/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme, p, e) in [
    ('light', CompappTheme.light, AppPalette.light, AppColors.light),
    ('dark', CompappTheme.dark, AppPalette.dark, AppColors.dark),
  ]) {
    test('every ColorScheme slot equals its documented token ($name)', () {
      final s = theme.colorScheme;
      final expected = <String, (Color, Color)>{
        'surface': (s.surface, p.ground),
        'onSurface': (s.onSurface, p.ink),
        'onSurfaceVariant': (s.onSurfaceVariant, p.inkMuted),
        'outline': (s.outline, p.inkMuted),
        'outlineVariant': (s.outlineVariant, p.line),
        'surfaceContainerLowest': (s.surfaceContainerLowest, p.surface),
        'surfaceContainerLow': (s.surfaceContainerLow, p.surface),
        'surfaceContainer': (s.surfaceContainer, p.surface),
        'surfaceContainerHigh': (s.surfaceContainerHigh, p.surfaceSunken),
        'surfaceContainerHighest': (s.surfaceContainerHighest, p.surfaceSunken),
        'surfaceDim': (s.surfaceDim, p.surfaceSunken),
        'surfaceBright': (s.surfaceBright, p.surface),
        'primary': (s.primary, p.primary),
        'onPrimary': (s.onPrimary, p.onPrimary),
        'primaryContainer': (s.primaryContainer, p.primarySoft),
        'onPrimaryContainer': (s.onPrimaryContainer, p.ink),
        'secondary': (s.secondary, p.primary),
        'onSecondary': (s.onSecondary, p.onPrimary),
        'secondaryContainer': (s.secondaryContainer, p.primarySoft),
        'onSecondaryContainer': (s.onSecondaryContainer, p.ink),
        'tertiary': (s.tertiary, e.busy),
        'onTertiary': (s.onTertiary, p.onPrimary),
        'tertiaryContainer': (s.tertiaryContainer, e.busySoft),
        'onTertiaryContainer': (s.onTertiaryContainer, p.ink),
        'error': (s.error, p.danger),
        'onError': (s.onError, p.onPrimary),
        'errorContainer': (s.errorContainer, p.dangerSoft),
        'onErrorContainer': (s.onErrorContainer, p.ink),
        'inverseSurface': (s.inverseSurface, p.ink),
        'onInverseSurface': (s.onInverseSurface, p.ground),
        'inversePrimary': (s.inversePrimary, p.primarySoft),
        'surfaceTint': (s.surfaceTint, Colors.transparent),
      };

      final wrong = [
        for (final MapEntry(key: slot, value: (actual, token))
            in expected.entries)
          if (actual != token) slot,
      ];
      expect(wrong, isEmpty);
    });
  }
}
