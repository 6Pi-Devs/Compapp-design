import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const display = 'packages/compapp_design/Bricolage Grotesque';
  const body = 'packages/compapp_design/Instrument Sans';
  const mapped = {'displayMedium', 'headlineSmall', 'titleLarge'};

  for (final (name, theme) in [
    ('light', CompappTheme.light),
    ('dark', CompappTheme.dark),
  ]) {
    group('resolved text theme ($name)', () {
      late TextTheme text;

      Future<void> pump(WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                text = Theme.of(context).textTheme;
                return const SizedBox();
              },
            ),
          ),
        );
      }

      Map<String, TextStyle?> slots() => {
        'displayLarge': text.displayLarge,
        'displayMedium': text.displayMedium,
        'displaySmall': text.displaySmall,
        'headlineLarge': text.headlineLarge,
        'headlineMedium': text.headlineMedium,
        'headlineSmall': text.headlineSmall,
        'titleLarge': text.titleLarge,
        'titleMedium': text.titleMedium,
        'titleSmall': text.titleSmall,
        'bodyLarge': text.bodyLarge,
        'bodyMedium': text.bodyMedium,
        'bodySmall': text.bodySmall,
        'labelLarge': text.labelLarge,
        'labelMedium': text.labelMedium,
        'labelSmall': text.labelSmall,
      };

      testWidgets('only the three mapped slots use Bricolage Grotesque', (
        tester,
      ) async {
        await pump(tester);

        for (final MapEntry(key: slot, value: style) in slots().entries) {
          expect(
            style?.fontFamily,
            mapped.contains(slot) ? display : body,
            reason: slot,
          );
        }
      });

      testWidgets('Bricolage slots carry opsz equal to their size', (
        tester,
      ) async {
        await pump(tester);

        for (final slot in mapped) {
          final style = slots()[slot]!;
          final variations = {
            for (final v in style.fontVariations ?? const <FontVariation>[])
              v.axis: v.value,
          };
          expect(variations, {
            'opsz': style.fontSize!.clamp(
              AppTypography.opticalSizeMin,
              AppTypography.opticalSizeMax,
            ),
          }, reason: slot);
          expect(style.fontWeight, FontWeight.w600, reason: slot);
        }
      });

      testWidgets('every other slot has no variations', (tester) async {
        await pump(tester);

        for (final MapEntry(key: slot, value: style) in slots().entries) {
          if (mapped.contains(slot)) continue;
          expect(style?.fontVariations ?? const [], isEmpty, reason: slot);
        }
      });

      testWidgets('mapped styles resolve the spec tracking', (tester) async {
        await pump(tester);

        expect(text.displayMedium?.letterSpacing, 0);
        expect(text.headlineSmall?.letterSpacing, 0);
        expect(text.titleLarge?.letterSpacing, 0);
        expect(text.bodyLarge?.letterSpacing, 0);
        expect(text.bodyMedium?.letterSpacing, 0);
        expect(text.labelLarge?.letterSpacing, 0.2);
        expect(text.bodySmall?.letterSpacing, 0);
      });
    });
  }
}
