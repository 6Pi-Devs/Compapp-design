import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';

const _ribbonWidth = 240.0;

EventRibbon _ribbon({
  CalendarEventKind kind = CalendarEventKind.visit,
  String id = 'visit',
  String title = 'Visit',
  String label = 'Visit, Marta, Saturday',
  bool before = false,
  bool after = false,
  bool compact = false,
}) => EventRibbon(
  event: CalendarEventView(id: id, kind: kind, title: title),
  semanticLabel: label,
  continuesBefore: before,
  continuesAfter: after,
  compact: compact,
);

Finder _key(String id) => find.byKey(Key('event.$id'));
Finder get _icon => find.byType(AppIcon);

Color _pebble(ThemeData theme, String name) {
  final colors = theme.extension<AppColors>()!;
  return colors.pebbles[AppColors.pebbleNames.indexOf(name)];
}

Color _fillOf(ThemeData theme, CalendarEventKind kind) => switch (kind) {
  CalendarEventKind.visit => _pebble(theme, 'sky'),
  CalendarEventKind.overnight => _pebble(theme, 'apricot'),
  CalendarEventKind.absence => theme.colorScheme.surfaceContainerHigh,
  CalendarEventKind.other => _pebble(theme, 'sand'),
};

const Map<CalendarEventKind, AppIcons> _glyphs = {
  CalendarEventKind.visit: AppIcons.visit,
  CalendarEventKind.overnight: AppIcons.bed,
  CalendarEventKind.absence: AppIcons.away,
  CalendarEventKind.other: AppIcons.calendar,
};

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('shows the title after the glyph of its kind', (tester) async {
      for (final kind in CalendarEventKind.values) {
        await tester.pumpWidget(
          host(
            _ribbon(kind: kind, id: kind.name),
            width: _ribbonWidth,
          ),
        );

        expect(find.text('Visit'), findsOneWidget);
        expect(
          tester.widget<AppIcon>(_icon).icon,
          _glyphs[kind],
          reason: '$kind',
        );
        expect(tester.getSize(_icon), const Size.square(AppSizes.glyphMd));
        expect(
          tester.getRect(_icon).right,
          lessThan(tester.getRect(find.text('Visit')).left + 0.01),
        );
      }
    });

    testWidgets('every kind has a glyph of its own', (tester) async {
      expect(
        _glyphs.values.toSet(),
        hasLength(CalendarEventKind.values.length),
      );
    });

    testWidgets('the key is built from the event id', (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              _ribbon(id: 'a'),
              _ribbon(id: 'b'),
            ],
          ),
          width: _ribbonWidth,
        ),
      );

      expect(_key('a'), findsOneWidget);
      expect(_key('b'), findsOneWidget);
    });

    testWidgets('is at least 28 tall and fills the width it is given', (
      tester,
    ) async {
      for (final width in [120.0, _ribbonWidth]) {
        await tester.pumpWidget(host(_ribbon(), width: width));

        expect(tester.getSize(_key('visit')), Size(width, AppSizes.ribbon));
      }
    });

    testWidgets('can be measured by intrinsic sizing, as the goldens do', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(IntrinsicHeight(child: _ribbon()), width: _ribbonWidth),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;

      for (final kind in CalendarEventKind.values) {
        testWidgets('${kind.name} paints its fill ($name)', (tester) async {
          await tester.pumpWidget(
            host(
              _ribbon(kind: kind, id: kind.name),
              theme: theme,
              width: _ribbonWidth,
              background: scheme.surface,
            ),
          );

          expect(
            await paintedColorAt(
              tester,
              hostBoundaryKey,
              const Offset(_ribbonWidth - 12, 14),
            ),
            isSameColorAs(_fillOf(theme, kind)),
          );
        });

        testWidgets('${kind.name} ink and glyph follow the kind ($name)', (
          tester,
        ) async {
          await tester.pumpWidget(
            host(
              _ribbon(kind: kind, id: kind.name, title: 'Soon'),
              theme: theme,
              width: _ribbonWidth,
              background: scheme.surface,
            ),
          );
          final absence = kind == CalendarEventKind.absence;

          expect(
            await paintedColorAtCenter(
              tester,
              hostBoundaryKey,
              find.text('Soon'),
            ),
            isSameColorAs(absence ? scheme.onSurface : colors.onPebble),
          );
          expect(
            tester.widget<AppIcon>(_icon).color,
            absence ? colors.presenceAway : colors.onPebble,
          );
        });
      }

      testWidgets('only an absence has a hairline edge ($name)', (
        tester,
      ) async {
        for (final kind in CalendarEventKind.values) {
          await tester.pumpWidget(
            host(
              _ribbon(kind: kind, id: kind.name),
              theme: theme,
              width: _ribbonWidth,
              background: scheme.surface,
            ),
          );
          final top = await paintedColorAt(
            tester,
            hostBoundaryKey,
            const Offset(_ribbonWidth / 2, 0),
          );

          expect(
            top,
            isSameColorAs(
              kind == CalendarEventKind.absence
                  ? scheme.outlineVariant
                  : _fillOf(theme, kind),
            ),
            reason: kind.name,
          );
        }
      });

      testWidgets('is calm: no kind uses a danger color ($name)', (
        tester,
      ) async {
        for (final kind in CalendarEventKind.values) {
          await tester.pumpWidget(
            host(
              _ribbon(kind: kind, id: kind.name),
              theme: theme,
              width: _ribbonWidth,
            ),
          );
          final fill = await paintedColorAt(
            tester,
            hostBoundaryKey,
            const Offset(_ribbonWidth - 12, 14),
          );

          expect(fill, isNot(isSameColorAs(scheme.error)));
          expect(fill, isNot(isSameColorAs(scheme.errorContainer)));
        }
      });
    }
  });

  group('edges', () {
    /// Whether the corner pixel at [x] (a corner of the first row) is painted.
    Future<bool> painted(WidgetTester tester, double x, double y) async =>
        (await paintedColorAt(tester, hostBoundaryKey, Offset(x, y))).a > 0.5;

    testWidgets('a flat edge means it continues on that side', (tester) async {
      for (final (before, after) in [
        (false, false),
        (true, false),
        (false, true),
        (true, true),
      ]) {
        await tester.pumpWidget(
          host(
            _ribbon(before: before, after: after),
            width: _ribbonWidth,
          ),
        );
        final reason = 'before $before, after $after';

        expect(
          await painted(tester, 0, 0),
          before,
          reason: 'start top, $reason',
        );
        expect(
          await painted(tester, 0, AppSizes.ribbon - 1),
          before,
          reason: 'start bottom, $reason',
        );
        expect(
          await painted(tester, _ribbonWidth - 1, 0),
          after,
          reason: 'end top, $reason',
        );
        expect(
          await painted(tester, _ribbonWidth - 1, AppSizes.ribbon - 1),
          after,
          reason: 'end bottom, $reason',
        );
      }
    });

    testWidgets('a rounded edge has the 10 radius', (tester) async {
      await tester.pumpWidget(host(_ribbon(), width: _ribbonWidth));

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: _key('visit'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(
        decoration.borderRadius,
        const BorderRadiusDirectional.horizontal(
          start: Radius.circular(AppRadius.sm),
          end: Radius.circular(AppRadius.sm),
        ),
      );
    });

    testWidgets('right to left mirrors the flat edge', (tester) async {
      await tester.pumpWidget(
        host(
          _ribbon(before: true),
          width: _ribbonWidth,
          direction: TextDirection.rtl,
        ),
      );

      expect(
        await painted(tester, _ribbonWidth - 1, 0),
        isTrue,
        reason: 'the start edge is the right one',
      );
      expect(
        await painted(tester, 0, 0),
        isFalse,
        reason: 'the end edge, rounded, is at the left',
      );
    });
  });

  group('compact', () {
    testWidgets('draws the glyph of the kind alone, centered, with no title', (
      tester,
    ) async {
      for (final kind in CalendarEventKind.values) {
        await tester.pumpWidget(
          host(_ribbon(kind: kind, id: kind.name, compact: true), width: 44),
        );
        final box = tester.getRect(_key(kind.name));

        expect(find.text('Visit'), findsNothing, reason: '$kind');
        expect(tester.widget<AppIcon>(_icon).icon, _glyphs[kind]);
        expect(tester.getCenter(_icon).dx, closeTo(box.center.dx, 0.01));
        expect(
          tester.getSize(_key(kind.name)),
          const Size(44, AppSizes.ribbon),
        );
      }
    });

    testWidgets('keeps its color, its edges and its ink in both themes', (
      tester,
    ) async {
      for (final (name, theme) in themes) {
        final scheme = theme.colorScheme;
        await tester.pumpWidget(
          host(
            _ribbon(compact: true, before: true),
            width: 44,
            theme: theme,
            background: scheme.surface,
          ),
        );

        expect(
          await paintedColorAt(tester, hostBoundaryKey, const Offset(40, 14)),
          isSameColorAs(_fillOf(theme, CalendarEventKind.visit)),
          reason: name,
        );
        expect(
          (await paintedColorAt(tester, hostBoundaryKey, Offset.zero)).a,
          greaterThan(0.5),
          reason: '$name: the flat start edge',
        );
        expect(
          tester.widget<AppIcon>(_icon).color,
          theme.extension<AppColors>()!.onPebble,
        );
      }
    });

    testWidgets('keeps the same height at text scale 2.0, the glyph is not '
        'scaled', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          host(_ribbon(compact: true), width: 44, textScale: scale),
        );

        expect(
          tester.getSize(_key('visit')),
          const Size(44, AppSizes.ribbon),
          reason: '${scale}x',
        );
        expect(tester.getSize(_icon), const Size.square(AppSizes.glyphMd));
      }
    });

    testWidgets('mirrors its flat edge in right-to-left', (tester) async {
      await tester.pumpWidget(
        host(
          _ribbon(compact: true, before: true),
          width: 44,
          direction: TextDirection.rtl,
        ),
      );

      expect(
        (await paintedColorAt(tester, hostBoundaryKey, const Offset(43, 0))).a,
        greaterThan(0.5),
      );
      expect(
        (await paintedColorAt(tester, hostBoundaryKey, Offset.zero)).a,
        lessThan(0.5),
      );
    });
  });

  group('right to left', () {
    testWidgets('the glyph is at the right and the title after it', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_ribbon(), width: _ribbonWidth, direction: TextDirection.rtl),
      );
      final box = tester.getRect(_key('visit'));

      expect(tester.getRect(_icon).right, box.right - AppSpacing.sm);
      expect(
        tester.getRect(find.text('Visit')).right,
        lessThanOrEqualTo(tester.getRect(_icon).left),
      );
    });

    testWidgets('keeps the glyph unmirrored: a person is a person', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_ribbon(), width: _ribbonWidth, direction: TextDirection.rtl),
      );

      expect(AppIcons.visit.matchTextDirection, isFalse);
      expect(
        find.descendant(of: _icon, matching: find.byType(Transform)),
        findsNothing,
      );
    });
  });

  group('semantics', () {
    testWidgets('stays its own node under a labeled container parent', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          Semantics(container: true, label: 'Week', child: _ribbon()),
          width: _ribbonWidth,
        ),
      );

      expect(semanticsLabels(tester), [
        'Week',
        'Visit, Marta, Saturday',
      ], reason: 'the ribbon label is not merged into the week label');
      final week = semanticsNodes(tester)
          .firstWhere((node) => node.label == 'Week');
      expect(tester.getSemantics(_key('visit')).parent, week);
      handle.dispose();
    });

    testWidgets('needs a spoken label', (tester) async {
      expect(() => _ribbon(label: ''), throwsAssertionError);
    });

    testWidgets('the compact form says the same as the full one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_ribbon(compact: true), width: 44));

      expect(semanticsLabels(tester), ['Visit, Marta, Saturday']);
      handle.dispose();
    });

    testWidgets('is one node named by the label, not interactive', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          _ribbon(
            kind: CalendarEventKind.absence,
            id: 'absence',
            title: 'Absence · Luis away',
            label: 'Absence, Luis, until Fri 6 Nov',
            before: true,
          ),
          width: _ribbonWidth,
        ),
      );

      expect(
        tester.getSemantics(_key('absence')),
        isSemantics(label: 'Absence, Luis, until Fri 6 Nov'),
      );
      expect(semanticsLabels(tester), [
        'Absence, Luis, until Fri 6 Nov',
      ], reason: 'the glyph and the visible title add nothing');
      handle.dispose();
    });

    testWidgets('the label replaces the visible title', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          _ribbon(title: 'Short', label: 'Visit, Marta, all day'),
          width: _ribbonWidth,
        ),
      );

      expect(semanticsLabels(tester), ['Visit, Marta, all day']);
      expect(find.bySemanticsLabel('Short'), findsNothing);
      handle.dispose();
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;

      test('titles reach 4.5:1 and glyphs 3:1 on their fill ($name)', () {
        final pastel = {
          'visit': _pebble(theme, 'sky'),
          'overnight': _pebble(theme, 'apricot'),
          'other': _pebble(theme, 'sand'),
        };
        expectContrast(
          {
            for (final fill in pastel.entries)
              '${fill.key} title': (colors.onPebble, fill.value),
            'absence title': (scheme.onSurface, scheme.surfaceContainerHigh),
          },
          minimum: 4.5,
          reason: name,
        );
        expectContrast(
          {
            for (final fill in pastel.entries)
              '${fill.key} glyph': (colors.onPebble, fill.value),
            'absence glyph': (colors.presenceAway, scheme.surfaceContainerHigh),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const longTitle = 'Ausencia · María de los Ángeles fuera de casa';

    Widget longRibbon({bool before = false, bool after = false}) => _ribbon(
      kind: CalendarEventKind.absence,
      id: 'absence',
      title: longTitle,
      label: 'Ausencia, María de los Ángeles, hasta el viernes',
      before: before,
      after: after,
    );

    testWidgets('keeps one line and grows at 1.5 and 2.0, nothing clips', (
      tester,
    ) async {
      await tester.pumpWidget(host(longRibbon(), width: 200));
      final base = tester.getSize(find.text(longTitle));

      for (final scale in [1.5, 2.0]) {
        await tester.pumpWidget(
          host(longRibbon(after: true), width: 200, textScale: scale),
        );
        final reason = 'at ${scale}x';
        final box = tester.getRect(_key('absence'));
        final title = tester.getRect(find.text(longTitle));
        final icon = tester.getRect(_icon);

        expect(tester.takeException(), isNull, reason: reason);
        expect(box.width, 200, reason: reason);
        expect(
          title.height,
          greaterThanOrEqualTo(base.height * scale - 1),
          reason: '$reason: the text is scaled, never clamped',
        );
        expect(
          title.height,
          lessThan(2 * 16 * scale),
          reason: '$reason: the title stays on one line',
        );
        expect(box.height, greaterThanOrEqualTo(title.height), reason: reason);
        expect(title.left, greaterThanOrEqualTo(icon.right), reason: reason);
        expect(title.right, lessThanOrEqualTo(box.right), reason: reason);
        expect(title.top, greaterThanOrEqualTo(box.top), reason: reason);
        expect(title.bottom, lessThanOrEqualTo(box.bottom), reason: reason);
        expect(
          icon.size,
          const Size.square(AppSizes.glyphMd),
          reason: '$reason: the glyph is not scaled',
        );
      }
    });

    testWidgets('right to left wraps the same way', (tester) async {
      await tester.pumpWidget(
        host(
          longRibbon(before: true),
          width: 200,
          textScale: 2,
          direction: TextDirection.rtl,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text(longTitle)).right,
        lessThanOrEqualTo(tester.getRect(_icon).left),
      );
    });
  });

  group('a narrow cell', () {
    setUpAll(loadBundledFonts);

    testWidgets('the full form keeps one line at 44 wide and never clips its '
        'title vertically, the compact form has none to clip', (tester) async {
      for (final compact in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(
            host(
              _ribbon(title: 'Visita', compact: compact),
              width: 44,
              textScale: scale,
            ),
          );
          final reason = '${compact ? 'compact' : 'full'} at ${scale}x';
          final box = tester.getRect(_key('visit'));

          expect(tester.takeException(), isNull, reason: reason);
          expect(box.width, 44, reason: reason);
          if (compact) {
            expect(find.text('Visita'), findsNothing, reason: reason);
            expect(box.height, AppSizes.ribbon, reason: reason);
          } else {
            final title = tester.getRect(find.text('Visita'));
            expect(
              title.height,
              lessThan(2 * 16 * scale),
              reason: '$reason: one line, not letter by letter',
            );
            expect(title.top, greaterThanOrEqualTo(box.top), reason: reason);
            expect(title.bottom, lessThanOrEqualTo(box.bottom), reason: reason);
            expect(
              tester.widget<Text>(find.text('Visita')).overflow,
              TextOverflow.ellipsis,
              reason: reason,
            );
          }
        }
      }
    });

    testWidgets('a lane as tall as the ribbon never clips at 2.0 when it grows '
        'with the text', (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              _ribbon(),
              _ribbon(id: 'second'),
            ],
          ),
          width: 200,
          textScale: 2,
        ),
      );
      final first = tester.getRect(_key('visit'));
      final second = tester.getRect(_key('second'));

      expect(first.height, greaterThan(AppSizes.ribbon));
      expect(second.top, greaterThanOrEqualTo(first.bottom));
      expect(tester.takeException(), isNull);
    });
  });
}
