import 'dart:math' as math;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme, extras) in [
    ('light', CompappTheme.light, AppColors.light),
    ('dark', CompappTheme.dark, AppColors.dark),
  ]) {
    test('text colours reach 4.5:1 on their backgrounds ($name)', () {
      final s = theme.colorScheme;
      final pairs = <String, (Color, Color)>{
        'onPrimary/primary': (s.onPrimary, s.primary),
        'onSecondary/secondary': (s.onSecondary, s.secondary),
        'onTertiary/tertiary': (s.onTertiary, s.tertiary),
        'onError/error': (s.onError, s.error),
        'onPrimaryContainer/primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'onSecondaryContainer/secondaryContainer': (
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
        'onTertiaryContainer/tertiaryContainer': (
          s.onTertiaryContainer,
          s.tertiaryContainer,
        ),
        'onErrorContainer/errorContainer': (
          s.onErrorContainer,
          s.errorContainer,
        ),
        'onInverseSurface/inverseSurface': (
          s.onInverseSurface,
          s.inverseSurface,
        ),
        'inversePrimary/inverseSurface': (s.inversePrimary, s.inverseSurface),
        'primary/surface': (s.primary, s.surface),
        'primary/surfaceContainerLowest': (s.primary, s.surfaceContainerLowest),
        'busy/surface': (extras.busy, s.surface),
        'busy/surfaceContainerLowest': (extras.busy, s.surfaceContainerLowest),
        'onSurface/busySoft': (s.onSurface, extras.busySoft),
        'onSurface/presenceHome': (s.onSurface, extras.presenceHome),
        for (final surface in {
          'surface': s.surface,
          'surfaceContainerLowest': s.surfaceContainerLowest,
          'surfaceContainerLow': s.surfaceContainerLow,
          'surfaceContainer': s.surfaceContainer,
          'surfaceContainerHigh': s.surfaceContainerHigh,
          'surfaceContainerHighest': s.surfaceContainerHighest,
        }.entries) ...{
          'onSurface/${surface.key}': (s.onSurface, surface.value),
          'onSurfaceVariant/${surface.key}': (
            s.onSurfaceVariant,
            surface.value,
          ),
        },
      };

      final failing = [
        for (final MapEntry(key: pair, value: (fg, bg)) in pairs.entries)
          if (_contrast(fg, bg) < 4.5)
            '$pair: ${_contrast(fg, bg).toStringAsFixed(2)}',
      ];
      expect(failing, isEmpty, reason: 'below 4.5:1 in $name');
    });
  }
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
