import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';

const _entries = [
  CalendarLegendEntry(kind: CalendarEventKind.absence, label: 'Away'),
  CalendarLegendEntry(kind: CalendarEventKind.visit, label: 'Visit'),
  CalendarLegendEntry(
    kind: CalendarEventKind.overnight,
    label: 'Overnight guest',
  ),
  CalendarLegendEntry(kind: CalendarEventKind.other, label: 'Other'),
];

const Map<CalendarEventKind, AppIcons> _glyphs = {
  CalendarEventKind.visit: AppIcons.visit,
  CalendarEventKind.overnight: AppIcons.bed,
  CalendarEventKind.absence: AppIcons.away,
  CalendarEventKind.other: AppIcons.calendar,
};

Finder _entry(CalendarEventKind kind) =>
    find.byKey(Key('calendar.legend.${kind.name}'));

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  testWidgets('shows each entry with the glyph of its kind and its label', (
    tester,
  ) async {
    await tester.pumpWidget(host(const CalendarLegend(entries: _entries)));

    expect(find.byKey(const Key('calendar.legend')), findsOneWidget);
    for (final entry in _entries) {
      expect(
        find.descendant(
          of: _entry(entry.kind),
          matching: find.text(entry.label),
        ),
        findsOneWidget,
      );
      final icon = tester.widget<AppIcon>(
        find.descendant(of: _entry(entry.kind), matching: find.byType(AppIcon)),
      );
      expect(icon.icon, _glyphs[entry.kind], reason: entry.kind.name);
    }
  });

  for (final (name, theme) in themes) {
    testWidgets('the swatch takes the fill of the kind, as a ribbon does, and '
        'only an absence has a hairline ($name)', (tester) async {
      await tester.pumpWidget(
        host(const CalendarLegend(entries: _entries), theme: theme),
      );
      final colors = theme.extension<AppColors>()!;
      final fills = {
        CalendarEventKind.visit: colors.pebbleSky,
        CalendarEventKind.overnight: colors.pebbleApricot,
        CalendarEventKind.absence: theme.colorScheme.surfaceContainerHigh,
        CalendarEventKind.other: colors.pebbleSand,
      };
      for (final entry in _entries) {
        final box = tester.widget<Container>(
          find.descendant(
            of: _entry(entry.kind),
            matching: find.byType(Container),
          ),
        );
        final decoration = box.decoration! as BoxDecoration;
        expect(decoration.color, fills[entry.kind], reason: entry.kind.name);
        expect(
          decoration.border != null,
          entry.kind == CalendarEventKind.absence,
          reason: entry.kind.name,
        );
      }
    });

    testWidgets('labels reach 4.5:1 on the card ($name)', (tester) async {
      await tester.pumpWidget(
        host(const CalendarLegend(entries: _entries), theme: theme),
      );
      final text = tester.widget<Text>(find.text('Away'));
      expectContrast(
        {
          'label': (
            text.style!.color!,
            theme.colorScheme.surfaceContainerLowest,
          ),
          'label on page': (text.style!.color!, theme.colorScheme.surface),
        },
        minimum: 4.5,
        reason: name,
      );
    });
  }

  testWidgets('each entry is one text node named by its label; the swatch '
      'says nothing', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const CalendarLegend(entries: _entries)));

    expect(semanticsLabels(tester), [for (final e in _entries) e.label]);
    for (final node in semanticsNodes(tester)) {
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    }
    handle.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('wraps at 320 wide and text scale $scale without overflow', (
      tester,
    ) async {
      await loadBundledFonts();
      await tester.pumpWidget(
        host(const CalendarLegend(entries: _entries), textScale: scale),
      );
      expect(tester.takeException(), isNull);
      for (final entry in _entries) {
        expect(
          tester.getRect(_entry(entry.kind)).right,
          lessThanOrEqualTo(tester.getRect(find.byType(CalendarLegend)).right),
        );
      }
    });
  }

  testWidgets('mirrors in right-to-left: the first entry starts at the right', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const CalendarLegend(entries: _entries),
        direction: TextDirection.rtl,
      ),
    );
    final legend = tester.getRect(find.byType(CalendarLegend));
    final first = tester.getRect(_entry(CalendarEventKind.absence));
    expect(first.right, legend.right);
    final swatch = tester.getRect(
      find.descendant(
        of: _entry(CalendarEventKind.absence),
        matching: find.byType(Container),
      ),
    );
    expect(swatch.right, first.right);
  });
}
