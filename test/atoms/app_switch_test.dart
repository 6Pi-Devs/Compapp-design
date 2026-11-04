import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {ThemeData? theme, double width = 360}) {
  return MaterialApp(
    theme: theme ?? CompappTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

Finder get _paint => find.descendant(
  of: find.byType(Switch),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        widget.painter.runtimeType.toString().contains('Switch'),
  ),
);

/// The rounded rectangles the switch draws, in order: track, outline, thumb.
List<(RRect, Paint)> _drawn(WidgetTester tester) {
  final drawn = <(RRect, Paint)>[];
  expect(
    tester.renderObject(_paint),
    paints..something((method, arguments) {
      if (method == #drawRRect) {
        drawn.add((arguments[0] as RRect, arguments[1] as Paint));
      }
      return method == #restore;
    }),
  );
  return drawn;
}

void main() {
  group('look', () {
    for (final (name, theme) in [
      ('light', CompappTheme.light),
      ('dark', CompappTheme.dark),
    ]) {
      final scheme = theme.colorScheme;

      testWidgets('on is a primary track with an on-primary thumb ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            AppSwitch(value: true, onChanged: (_) {}, label: 'All day'),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        final [track, outline, thumb] = _drawn(tester);
        expect(track.$2.color, isSameColorAs(scheme.primary));
        expect(outline.$2.color.a, 0);
        expect(thumb.$2.color, isSameColorAs(scheme.onPrimary));
      });

      testWidgets('off is a sunken track, an outline border and a muted thumb '
          '($name)', (tester) async {
        await tester.pumpWidget(
          _host(
            AppSwitch(value: false, onChanged: (_) {}, label: 'All day'),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        final [track, outline, thumb] = _drawn(tester);
        expect(track.$2.color, isSameColorAs(scheme.surfaceContainerHigh));
        expect(outline.$2.color, isSameColorAs(scheme.outline));
        expect(outline.$2.strokeWidth, AppSizes.hairline);
        expect(thumb.$2.color, isSameColorAs(scheme.onSurfaceVariant));
      });

      testWidgets('disabled keeps on and off apart by track and thumb '
          '($name)', (tester) async {
        await tester.pumpWidget(
          _host(
            const AppSwitch(value: true, onChanged: null, label: 'All day'),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();
        final [onTrack, _, onThumb] = _drawn(tester);

        await tester.pumpWidget(
          _host(
            const AppSwitch(value: false, onChanged: null, label: 'All day'),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();
        final [offTrack, _, offThumb] = _drawn(tester);

        expect(onTrack.$2.color, isSameColorAs(scheme.primaryContainer));
        expect(onThumb.$2.color, isSameColorAs(scheme.onSurfaceVariant));
        expect(offTrack.$2.color, isSameColorAs(scheme.surface));
        expect(offThumb.$2.color, isSameColorAs(scheme.outlineVariant));
      });
    }

    testWidgets('has the 52x32 Material track and a 24 thumb both ways', (
      tester,
    ) async {
      for (final value in [true, false]) {
        await tester.pumpWidget(
          _host(AppSwitch(value: value, onChanged: (_) {}, label: 'All day')),
        );
        await tester.pumpAndSettle();

        final [track, _, thumb] = _drawn(tester);
        expect(
          Size(track.$1.width, track.$1.height),
          const Size(52, 32),
          reason: 'value $value',
        );
        expect(
          Size(thumb.$1.width, thumb.$1.height),
          const Size.square(24),
          reason: 'value $value',
        );
      }
    });

    testWidgets('the off track outline keeps 3:1 against the page', (
      tester,
    ) async {
      for (final theme in [CompappTheme.light, CompappTheme.dark]) {
        await tester.pumpWidget(
          _host(
            AppSwitch(value: false, onChanged: (_) {}, label: 'All day'),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        final [_, outline, _] = _drawn(tester);
        final outlineLuminance = outline.$2.color.computeLuminance();
        final page = theme.colorScheme.surface.computeLuminance();
        final lighter = outlineLuminance > page ? outlineLuminance : page;
        final darker = outlineLuminance > page ? page : outlineLuminance;
        expect(
          (lighter + 0.05) / (darker + 0.05),
          greaterThanOrEqualTo(3),
          reason: '${theme.brightness}',
        );
      }
    });

    testWidgets('mutes the label when disabled', (tester) async {
      await tester.pumpWidget(
        _host(const AppSwitch(value: true, onChanged: null, label: 'All day')),
      );

      final text = tester.widget<Text>(find.text('All day'));
      expect(
        text.style?.color,
        CompappTheme.light.colorScheme.onSurfaceVariant,
      );
    });
  });

  group('size', () {
    testWidgets('is at least 48 tall and wraps a long label', (tester) async {
      await tester.pumpWidget(
        _host(
          AppSwitch(
            value: true,
            onChanged: (_) {},
            label: 'Remind me about my chores every single morning',
          ),
          width: 200,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(AppSwitch)).height,
        greaterThanOrEqualTo(AppSizes.minTarget),
      );
      expect(
        tester.getSize(find.byType(AppSwitch)).width,
        lessThanOrEqualTo(200),
      );
    });

    testWidgets('puts the label after the track', (tester) async {
      await tester.pumpWidget(
        _host(AppSwitch(value: true, onChanged: (_) {}, label: 'All day')),
      );

      expect(
        tester.getTopLeft(find.text('All day')).dx,
        greaterThan(tester.getTopRight(find.byType(Switch)).dx - 1),
      );
    });
  });

  group('taps', () {
    testWidgets('tapping the track toggles', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(AppSwitch(value: false, onChanged: calls.add, label: 'All day')),
      );

      await tester.tap(find.byType(Switch));

      expect(calls, [true]);
    });

    testWidgets('tapping the label toggles', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(AppSwitch(value: true, onChanged: calls.add, label: 'All day')),
      );

      await tester.tap(find.text('All day'));

      expect(calls, [false]);
    });

    testWidgets('does nothing when disabled', (tester) async {
      await tester.pumpWidget(
        _host(const AppSwitch(value: true, onChanged: null, label: 'All day')),
      );

      await tester.tap(find.text('All day'));
      await tester.tap(find.byType(Switch));

      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });
  });

  group('semantics', () {
    testWidgets('is one toggled node named by the label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(AppSwitch(value: true, onChanged: (_) {}, label: 'All day')),
      );

      final node = tester.getSemantics(find.byType(AppSwitch));
      expect(
        node,
        isSemantics(
          label: 'All day',
          hasToggledState: true,
          isToggled: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(node.hasChildren, isFalse);
      handle.dispose();
    });

    testWidgets('reports off and disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const AppSwitch(value: false, onChanged: null, label: 'All day')),
      );

      expect(
        tester.getSemantics(find.byType(AppSwitch)),
        isSemantics(
          label: 'All day',
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('a semantic tap toggles', (tester) async {
      final handle = tester.ensureSemantics();
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(AppSwitch(value: false, onChanged: calls.add, label: 'All day')),
      );

      tester.semantics.tap(find.semantics.byLabel('All day'));

      expect(calls, [true]);
      handle.dispose();
    });
  });
}
