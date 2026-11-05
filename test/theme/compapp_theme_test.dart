import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design/src/tokens/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme, palette, extras, brightness) in [
    (
      'light',
      CompappTheme.light,
      AppPalette.light,
      AppColors.light,
      Brightness.light,
    ),
    (
      'dark',
      CompappTheme.dark,
      AppPalette.dark,
      AppColors.dark,
      Brightness.dark,
    ),
  ]) {
    group('CompappTheme.$name', () {
      final scheme = theme.colorScheme;

      test('is Material 3 with the right brightness', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);
        expect(scheme.brightness, brightness);
      });

      test('maps tokens to ColorScheme slots', () {
        expect(scheme.surface, palette.ground);
        expect(scheme.surfaceContainerLowest, palette.surface);
        expect(scheme.surfaceContainerHigh, palette.surfaceSunken);
        expect(scheme.onSurface, palette.ink);
        expect(scheme.onSurfaceVariant, palette.inkMuted);
        expect(scheme.outlineVariant, palette.line);
        expect(scheme.primary, palette.primary);
        expect(scheme.onPrimary, palette.onPrimary);
        expect(scheme.primaryContainer, palette.primarySoft);
        expect(scheme.error, palette.danger);
        expect(scheme.errorContainer, palette.dangerSoft);
      });

      test('uses standard density, not the compact one of desktop', () {
        expect(theme.visualDensity, VisualDensity.standard);
      });

      testWidgets('controls keep their token heights on a desktop platform', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.copyWith(platform: TargetPlatform.windows),
            home: Scaffold(
              body: Column(
                children: [
                  FilledButton(onPressed: () {}, child: const Text('Filled')),
                  TextButton(onPressed: () {}, child: const Text('Text')),
                  TextField(style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        );

        Size surface(Type type) => tester.getSize(
          find.descendant(
            of: find.byType(type),
            matching: find.byWidgetPredicate(
              (w) => w is Material && w.type == MaterialType.button,
            ),
          ),
        );
        expect(surface(FilledButton).height, 52);
        expect(surface(TextButton).height, 44);
        expect(tester.getSize(find.byType(TextField)).height, 52);
      });

      test('uses ground as the scaffold background', () {
        expect(theme.scaffoldBackgroundColor, palette.ground);
      });

      test('gives icons the ink color', () {
        expect(theme.iconTheme.color, palette.ink);
      });

      test('carries the AppColors extension', () {
        expect(theme.extension<AppColors>(), extras);
      });

      test('maps the type scale to the TextTheme slots', () {
        final text = theme.textTheme;

        expect(text.displayMedium?.fontSize, 40);
        expect(text.headlineSmall?.fontSize, 28);
        expect(text.titleLarge?.fontSize, 20);
        expect(text.bodyLarge?.fontSize, 17);
        expect(text.bodyMedium?.fontSize, 15);
        expect(text.labelLarge?.fontSize, 13);
        expect(text.bodySmall?.fontSize, 12);
      });

      test('uses the bundled font families', () {
        const display = 'packages/compapp_design/Bricolage Grotesque';
        const body = 'packages/compapp_design/Instrument Sans';
        final text = theme.textTheme;

        expect(text.displayMedium?.fontFamily, display);
        expect(text.headlineSmall?.fontFamily, display);
        expect(text.titleLarge?.fontFamily, display);
        expect(text.bodyLarge?.fontFamily, body);
        expect(text.bodyMedium?.fontFamily, body);
        expect(text.labelLarge?.fontFamily, body);
        expect(text.bodySmall?.fontFamily, body);
      });

      test('colours text with ink and keeps tabular figures', () {
        final body = theme.textTheme.bodyMedium;

        expect(body?.color, palette.ink);
        expect(
          body?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      });
    });
  }

  testWidgets('context.appColors reads the extension of the active theme', (
    tester,
  ) async {
    late AppColors seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: CompappTheme.light,
        darkTheme: CompappTheme.dark,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            seen = context.appColors;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(seen, AppColors.dark);
  });
}
