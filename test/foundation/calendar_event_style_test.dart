import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design/src/foundation/calendar_event_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme) in [
    ('light', CompappTheme.light),
    ('dark', CompappTheme.dark),
  ]) {
    testWidgets('gives each kind its own glyph, and an absence a quiet '
        'bordered tile ($name)', (tester) async {
      final styles = <CalendarEventKind, CalendarEventStyle>{};
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              for (final kind in CalendarEventKind.values) {
                styles[kind] = calendarEventStyle(context, kind);
              }
              return const SizedBox();
            },
          ),
        ),
      );

      final colors = theme.extension<AppColors>()!;
      final icons = {for (final s in styles.values) s.icon};
      expect(icons, hasLength(CalendarEventKind.values.length));
      expect(styles[CalendarEventKind.visit]!.fill, colors.pebbleSky);
      expect(styles[CalendarEventKind.overnight]!.fill, colors.pebbleApricot);
      expect(styles[CalendarEventKind.other]!.fill, colors.pebbleSand);
      final absence = styles[CalendarEventKind.absence]!;
      expect(absence.fill, theme.colorScheme.surfaceContainerHigh);
      expect(absence.glyph, colors.presenceAway);
      expect(absence.border, isTrue);
      expect(
        [
          for (final kind in CalendarEventKind.values)
            if (styles[kind]!.border) kind,
        ],
        [CalendarEventKind.absence],
      );
    });
  }
}
