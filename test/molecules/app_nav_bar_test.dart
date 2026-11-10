import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bar_host.dart';
import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';
import '../helpers/painted_pixels.dart';
import '../helpers/word_breaks.dart';

const _destinations = [
  NavDestinationView(id: 'home', icon: AppIcons.floorplan, label: 'Home'),
  NavDestinationView(id: 'things', icon: AppIcons.washer, label: 'Things'),
  NavDestinationView(
    id: 'tasks',
    icon: AppIcons.tasks,
    label: 'Tasks',
    badgeCount: 2,
    semanticLabel: 'Tasks, 2 to do',
  ),
  NavDestinationView(
    id: 'calendar',
    icon: AppIcons.calendar,
    label: 'Calendar',
  ),
];

AppNavBar _bar({
  List<NavDestinationView> destinations = _destinations,
  int selected = 0,
  ValueChanged<int>? onSelected,
}) => AppNavBar(
  destinations: destinations,
  selectedIndex: selected,
  onSelected: onSelected ?? (_) {},
  semanticLabel: 'Main',
);

Finder _destination(String id) => find.byKey(Key('nav.$id'));

SemanticsNode _node(WidgetTester tester, String id) => tester.getSemantics(
  find.descendant(of: _destination(id), matching: find.byType(TextButton)),
);

/// The plate behind the icon of [id]: the `Container` that holds its icon.
Finder _plate(String id) => find.ancestor(
  of: find.descendant(of: _destination(id), matching: find.byType(AppIcon)),
  matching: find.byType(Container),
);

void main() {
  group('destinations', () {
    testWidgets('shows an icon and a label for each, keyed by its id', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar()));

      for (final destination in _destinations) {
        expect(_destination(destination.id), findsOneWidget);
        expect(
          find.descendant(
            of: _destination(destination.id),
            matching: find.text(destination.label),
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<AppIcon>(
                find.descendant(
                  of: _destination(destination.id),
                  matching: find.byType(AppIcon),
                ),
              )
              .icon,
          destination.icon,
        );
      }
    });

    testWidgets('keys follow the id, not the position', (tester) async {
      await tester.pumpWidget(
        barHost(_bar(destinations: _destinations.reversed.toList())),
      );

      expect(_destination('home'), findsOneWidget);
      expect(
        tester.getCenter(_destination('home')).dx,
        greaterThan(tester.getCenter(_destination('calendar')).dx),
      );
    });

    testWidgets('they share the width equally', (tester) async {
      await tester.pumpWidget(barHost(_bar()));

      final widths = {
        for (final d in _destinations) tester.getSize(_destination(d.id)).width,
      };
      expect(widths, hasLength(1));
    });

    testWidgets('a tap calls onSelected with the index, selected or not', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(barHost(_bar(selected: 1, onSelected: taps.add)));

      await tester.tap(_destination('calendar'));
      await tester.tap(_destination('things'));
      await tester.tap(_destination('home'));

      expect(taps, [3, 1, 0]);
    });

    testWidgets('the bar rejects no destinations and a stray index', (
      tester,
    ) async {
      expect(() => _bar(destinations: const []), throwsAssertionError);
      expect(() => _bar(selected: 4), throwsAssertionError);
      expect(() => _bar(selected: -1), throwsAssertionError);
    });
  });

  group('selected look', () {
    for (final (name, theme) in themes) {
      testWidgets('the plate is primary-soft with a primary border ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(barHost(_bar(selected: 1), theme: theme));
        await tester.pumpAndSettle();
        final scheme = theme.colorScheme;
        final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
        final plate = tester.getRect(_plate('things')).shift(-origin);

        // Inside the border, away from the glyph: the fill.
        expect(
          await paintedColorAt(
            tester,
            barBoundaryKey,
            Offset(plate.left + 4, plate.center.dy),
          ),
          isSameColorAs(scheme.primaryContainer),
          reason: 'fill',
        );
        // On the border.
        expect(
          await paintedColorAt(
            tester,
            barBoundaryKey,
            Offset(plate.left + 0.5, plate.center.dy),
          ),
          isSameColorAs(scheme.primary),
          reason: 'border',
        );
      });

      testWidgets('an unselected plate has neither fill nor border ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(barHost(_bar(selected: 1), theme: theme));
        await tester.pumpAndSettle();
        final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
        final plate = tester.getRect(_plate('home')).shift(-origin);

        for (final dx in [0.5, 4.0]) {
          expect(
            await paintedColorAt(
              tester,
              barBoundaryKey,
              Offset(plate.left + dx, plate.center.dy),
            ),
            isSameColorAs(theme.colorScheme.surfaceContainerLowest),
            reason: 'dx $dx',
          );
        }
      });

      testWidgets('selected ink and muted ink ($name)', (tester) async {
        await tester.pumpWidget(barHost(_bar(selected: 1), theme: theme));
        await tester.pumpAndSettle();
        final scheme = theme.colorScheme;

        Color labelColor(String id, String label) => tester
            .widget<Text>(
              find.descendant(of: _destination(id), matching: find.text(label)),
            )
            .style!
            .color!;
        Color glyphColor(String id) => tester
            .widget<AppIcon>(
              find.descendant(
                of: _destination(id),
                matching: find.byType(AppIcon),
              ),
            )
            .color!;

        expect(labelColor('things', 'Things'), scheme.onSurface);
        expect(glyphColor('things'), scheme.onSurface);
        expect(labelColor('home', 'Home'), scheme.onSurfaceVariant);
        expect(glyphColor('home'), scheme.onSurfaceVariant);
      });
    }

    testWidgets('the selected destination differs by shape, not only color', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar(selected: 1)));

      final selected = tester.widget<Container>(_plate('things').first);
      final other = tester.widget<Container>(_plate('home').first);

      expect(selected.foregroundDecoration, isNotNull);
      expect(other.foregroundDecoration, isNull);
      final border =
          (selected.foregroundDecoration! as BoxDecoration).border! as Border;
      expect(border.top.width, AppSizes.borderEmphasis);
    });

    testWidgets('the layout does not move when the selection does', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar()));
      final before = tester.getRect(_destination('things'));
      final beforeIcon = tester.getRect(
        find.descendant(
          of: _destination('things'),
          matching: find.byType(AppIcon),
        ),
      );

      await tester.pumpWidget(barHost(_bar(selected: 1)));

      expect(tester.getRect(_destination('things')), before);
      expect(
        tester.getRect(
          find.descendant(
            of: _destination('things'),
            matching: find.byType(AppIcon),
          ),
        ),
        beforeIcon,
      );
    });
  });

  group('badge', () {
    testWidgets('draws the count of the destination that has one', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar()));

      final badge = find.descendant(
        of: _destination('tasks'),
        matching: find.byType(AppBadge),
      );
      expect(tester.widget<AppBadge>(badge).count, 2);
      expect(find.byType(AppBadge), findsOneWidget);
    });

    testWidgets('past 99 it shows 99+ and zero draws nothing', (tester) async {
      await tester.pumpWidget(
        barHost(
          _bar(
            destinations: [
              _destinations[0],
              const NavDestinationView(
                id: 'tasks',
                icon: AppIcons.tasks,
                label: 'Tasks',
                badgeCount: 120,
              ),
            ],
          ),
        ),
      );
      expect(find.text('99+'), findsOneWidget);

      await tester.pumpWidget(
        barHost(
          _bar(
            destinations: [
              for (final d in _destinations)
                NavDestinationView(id: d.id, icon: d.icon, label: d.label),
            ],
          ),
        ),
      );
      expect(find.byType(AppBadge), findsNothing);
    });

    testWidgets('sits at the top end of the plate, clear of the icon', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(barHost(_bar(), direction: direction));
        final badge = tester.getRect(find.byType(AppBadge));
        final icon = tester.getRect(
          find.descendant(
            of: _destination('tasks'),
            matching: find.byType(AppIcon),
          ),
        );

        expect(badge.overlaps(icon), isFalse, reason: '$direction');
        if (direction == TextDirection.ltr) {
          expect(badge.center.dx, greaterThan(icon.center.dx));
        } else {
          expect(badge.center.dx, lessThan(icon.center.dx));
        }
      }
    });
  });

  group('semantics', () {
    testWidgets('the bar is a navigation landmark with a name', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_bar()));

      final landmark = labeledNodes(tester).singleWhere(
        (node) => node.getSemanticsData().role == SemanticsRole.navigation,
      );
      expect(landmark.label, 'Main');
      handle.dispose();
    });

    testWidgets(
      'each destination is a focusable button with a selected state',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(barHost(_bar(selected: 1)));

        for (final (index, d) in _destinations.indexed) {
          expect(
            _node(tester, d.id),
            isSemantics(
              label: d.semanticLabel ?? d.label,
              isButton: true,
              isFocusable: true,
              hasEnabledState: true,
              isEnabled: true,
              hasSelectedState: true,
              isSelected: index == 1,
              isInMutuallyExclusiveGroup: true,
              hasTapAction: true,
              hasFocusAction: true,
            ),
            reason: d.id,
          );
        }
        handle.dispose();
      },
    );

    testWidgets('a badge count is merged into its destination and read once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_bar()));

      final labels = [for (final n in labeledNodes(tester)) n.label];
      expect(labels, contains('Tasks, 2 to do'));
      expect(labels.where((label) => label.contains('2')), [
        'Tasks, 2 to do',
      ], reason: 'no separate node for the badge text');
      expect(
        labels.where((label) => label == 'Tasks'),
        isEmpty,
        reason: 'the visible label is not a second node either',
      );
      handle.dispose();
    });

    testWidgets('without a semanticLabel a destination reads its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_bar()));

      expect(_node(tester, 'home').label, 'Home');
      handle.dispose();
    });

    testWidgets('passes the Flutter tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_bar()));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('the destinations can take keyboard focus in order', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar()));

      final order = <String>[];
      for (var i = 0; i < _destinations.length; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final primary = FocusManager.instance.primaryFocus!.context!;
        for (final d in _destinations) {
          final focused = find.descendant(
            of: _destination(d.id),
            matching: find.byElementPredicate((e) => identical(e, primary)),
          );
          if (focused.evaluate().isNotEmpty) order.add(d.id);
        }
      }

      expect(order, [for (final d in _destinations) d.id]);
    });
  });

  group('targets', () {
    testWidgets('every destination is at least 48 wide and 52 tall', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar()));

      for (final d in _destinations) {
        final size = tester.getSize(_destination(d.id));
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.controlLg));
      }
    });

    testWidgets('the bar holds four destinations and no more', (tester) async {
      expect(AppNavBar.maxDestinations, 4);
      expect(
        () => _bar(
          destinations: [
            ..._destinations,
            const NavDestinationView(
              id: 'history',
              icon: AppIcons.history,
              label: 'History',
            ),
          ],
        ),
        throwsAssertionError,
      );
      await tester.pumpWidget(barHost(_bar()));
      expect(tester.takeException(), isNull);
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      test('text 4.5:1 and graphics 3:1 on every surface ($name)', () {
        final scheme = theme.colorScheme;
        final surface = scheme.surfaceContainerLowest;
        expectContrast(
          {
            'selected label/surface': (scheme.onSurface, surface),
            'muted label/surface': (scheme.onSurfaceVariant, surface),
            'selected glyph/plate': (scheme.onSurface, scheme.primaryContainer),
            'muted glyph/surface': (scheme.onSurfaceVariant, surface),
          },
          minimum: 4.5,
          reason: name,
        );
        expectContrast(
          {
            'plate border/surface': (scheme.primary, surface),
            'plate border/plate': (scheme.primary, scheme.primaryContainer),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('right to left', () {
    testWidgets('the order mirrors and the selected plate follows', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar(selected: 3)));
      final ltr = <double>[
        for (final d in _destinations) tester.getCenter(_destination(d.id)).dx,
      ];
      expect(ltr, orderedEquals(ltr.toList()..sort()));
      expect(tester.getCenter(_plate('calendar').first).dx, greaterThan(180));

      await tester.pumpWidget(
        barHost(_bar(selected: 3), direction: TextDirection.rtl),
      );
      final rtl = <double>[
        for (final d in _destinations) tester.getCenter(_destination(d.id)).dx,
      ];

      expect(rtl, orderedEquals(rtl.toList()..sort((a, b) => b.compareTo(a))));
      expect(tester.getCenter(_plate('calendar').first).dx, lessThan(180));
    });
  });

  group('inset and asserts', () {
    testWidgets('the surface runs under the bottom inset', (tester) async {
      await tester.pumpWidget(barHost(_bar()));
      final plain = tester.getSize(find.byType(AppNavBar)).height;

      await tester.pumpWidget(
        barHost(_bar(), padding: const EdgeInsets.only(bottom: 34)),
      );
      await tester.pumpAndSettle();

      final bar = inBarHost(tester, find.byType(AppNavBar));
      expect(bar.height, plain + 34);
      final pixels = await paintedPixels(
        tester,
        barBoundaryKey,
        region: Rect.fromLTWH(bar.center.dx, bar.bottom - 4, 1, 3),
      );
      expect(
        countPixels(
          pixels,
          CompappTheme.light.colorScheme.surfaceContainerLowest,
        ),
        pixels.length,
        reason: 'the bar fill is painted down to the inset',
      );
    });

    testWidgets('a label is never empty and a count never negative', (
      tester,
    ) async {
      expect(
        () => NavDestinationView(id: 'a', icon: AppIcons.add, label: ''),
        throwsAssertionError,
      );
      expect(
        () => NavDestinationView(
          id: 'a',
          icon: AppIcons.add,
          label: 'A',
          semanticLabel: '',
        ),
        throwsAssertionError,
      );
      expect(
        () => NavDestinationView(
          id: 'a',
          icon: AppIcons.add,
          label: 'A',
          badgeCount: -1,
        ),
        throwsAssertionError,
      );
    });

    test('a destination compares by value', () {
      const a = NavDestinationView(id: 'a', icon: AppIcons.add, label: 'A');
      const b = NavDestinationView(id: 'a', icon: AppIcons.add, label: 'A');
      const c = NavDestinationView(id: 'a', icon: AppIcons.add, label: 'B');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const long = [
      NavDestinationView(id: 'home', icon: AppIcons.floorplan, label: 'Casa'),
      NavDestinationView(id: 'things', icon: AppIcons.washer, label: 'Cosas'),
      NavDestinationView(
        id: 'tasks',
        icon: AppIcons.tasks,
        label: 'Tareas de hoy',
        badgeCount: 120,
        semanticLabel: 'Tareas de hoy, 120 por hacer',
      ),
      NavDestinationView(
        id: 'calendar',
        icon: AppIcons.calendar,
        label: 'Calendario común',
      ),
    ];

    testWidgets('labels wrap inside their destination and nothing overflows', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar(destinations: long)));
      final base = tester.getSize(find.byType(AppNavBar)).height;

      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          barHost(
            _bar(destinations: long, selected: 3),
            textScale: 2,
            direction: direction,
          ),
        );

        expect(tester.takeException(), isNull, reason: '$direction');
        expect(
          tester.getSize(find.byType(AppNavBar)).height,
          greaterThan(base),
          reason: 'the bar grows',
        );
        for (final d in long) {
          final cell = tester.getRect(_destination(d.id));
          final text = tester.getRect(
            find.descendant(
              of: _destination(d.id),
              matching: find.text(d.label),
            ),
          );
          expect(text.left, greaterThanOrEqualTo(cell.left), reason: d.id);
          expect(text.right, lessThanOrEqualTo(cell.right), reason: d.id);
          expect(text.bottom, lessThanOrEqualTo(cell.bottom), reason: d.id);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: _destination(d.id),
              matching: find.text(d.label),
            ),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: d.id);
        }
      }
    });

    testWidgets('labels grow up to 1.3x and stop there, the semantics stay', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Future<double> labelHeight(double scale) async {
        await tester.pumpWidget(
          barHost(_bar(destinations: long), textScale: scale),
        );
        return tester
            .getSize(
              find.descendant(
                of: _destination('home'),
                matching: find.text('Casa'),
              ),
            )
            .height;
      }

      final base = await labelHeight(1);
      final capped = await labelHeight(AppNavBar.maxLabelTextScale);
      final doubled = await labelHeight(2);

      expect(AppNavBar.maxLabelTextScale, 1.3);
      expect(capped, closeTo(base * 1.3, 1));
      expect(doubled, capped, reason: 'the one documented cap');
      expect(_node(tester, 'tasks').label, 'Tareas de hoy, 120 por hacer');
      handle.dispose();
    });

    testWidgets('no label breaks inside a word at 1.0x, 1.3x or 2.0x', (
      tester,
    ) async {
      const english = [
        NavDestinationView(id: 'home', icon: AppIcons.floorplan, label: 'Home'),
        NavDestinationView(
          id: 'things',
          icon: AppIcons.washer,
          label: 'Things',
        ),
        NavDestinationView(id: 'tasks', icon: AppIcons.tasks, label: 'Tasks'),
        NavDestinationView(
          id: 'calendar',
          icon: AppIcons.calendar,
          label: 'Calendar',
        ),
      ];
      const spanish = [
        NavDestinationView(id: 'home', icon: AppIcons.floorplan, label: 'Casa'),
        NavDestinationView(id: 'things', icon: AppIcons.washer, label: 'Cosas'),
        NavDestinationView(id: 'tasks', icon: AppIcons.tasks, label: 'Tareas'),
        NavDestinationView(
          id: 'calendar',
          icon: AppIcons.calendar,
          label: 'Calendario',
        ),
      ];

      for (final destinations in [english, spanish, long]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          for (final direction in TextDirection.values) {
            await tester.pumpWidget(
              barHost(
                _bar(destinations: destinations),
                textScale: scale,
                direction: direction,
              ),
            );

            for (final d in destinations) {
              expectNoMidWordBreaks(
                tester,
                find.descendant(
                  of: _destination(d.id),
                  matching: find.text(d.label),
                ),
                reason: '$scale $direction',
              );
            }
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('a 99+ badge stays clear of the glyph and inside the bar', (
      tester,
    ) async {
      final heavy = [
        for (final d in long)
          NavDestinationView(
            id: d.id,
            icon: d.icon,
            label: d.label,
            badgeCount: 150,
            semanticLabel: '${d.label}, 150',
          ),
      ];

      for (final scale in [1.0, 2.0]) {
        for (final direction in TextDirection.values) {
          await tester.pumpWidget(
            barHost(
              _bar(destinations: heavy),
              textScale: scale,
              direction: direction,
            ),
          );

          final bar = tester.getRect(find.byType(AppNavBar));
          final badges = find.byType(AppBadge);
          expect(badges, findsNWidgets(4));
          for (var i = 0; i < 4; i++) {
            final badge = tester.getRect(badges.at(i));
            final d = heavy[direction == TextDirection.ltr ? i : 3 - i];
            final glyph = tester.getRect(
              find.descendant(
                of: _destination(d.id),
                matching: find.byType(AppIcon),
              ),
            );
            final reason = '$scale $direction ${d.id}';
            expect(badge.overlaps(glyph), isFalse, reason: reason);
            expect(
              badge.top,
              closeTo(tester.getRect(_plate(d.id).first).top, 0.5),
              reason: '$reason: at the top of the plate',
            );
            expect(bar.contains(badge.topLeft), isTrue, reason: reason);
            expect(bar.contains(badge.bottomRight), isTrue, reason: reason);
          }
        }
      }
    });

    testWidgets('icons stay on one line across destinations that wrap', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar(destinations: long), textScale: 2));

      final tops = {
        for (final d in long)
          tester
              .getTopLeft(
                find.descendant(
                  of: _destination(d.id),
                  matching: find.byType(AppIcon),
                ),
              )
              .dy,
      };
      expect(tops, hasLength(1));
    });

    testWidgets('every destination keeps a 48 wide, 52 tall target', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar(destinations: long), textScale: 2));

      for (final d in long) {
        final size = tester.getSize(_destination(d.id));
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.controlLg));
      }
    });
  });
}
