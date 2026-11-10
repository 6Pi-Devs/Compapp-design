import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bar_host.dart';
import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';

void _noop() {}

const _me = MemberView(
  id: 'ana',
  name: 'Ana (you)',
  initials: 'A',
  joinOrder: 0,
  semanticLabel: 'Ana, you, at home',
  isYou: true,
);

AppTopBar _home({
  String title = 'Calle Luna 12',
  String? subtitle = '2 home · 1 away',
  int unread = 3,
  VoidCallback? onActivity = _noop,
  VoidCallback? onAccount = _noop,
}) => AppTopBar.home(
  title: title,
  subtitle: subtitle,
  activityLabel: 'Activity, $unread unread',
  unreadCount: unread,
  onActivity: onActivity ?? _noop,
  me: _me,
  accountLabel: 'Your account',
  onAccount: onAccount ?? _noop,
);

AppTopBar _pushed({
  String title = 'Activity',
  String? actionLabel = 'Mark all as read',
  VoidCallback? onAction = _noop,
  VoidCallback onBack = _noop,
}) => AppTopBar.pushed(
  title: title,
  backLabel: 'Back',
  onBack: onBack,
  actionLabel: actionLabel,
  onAction: onAction,
);

Finder _key(String part) => find.byKey(Key('topBar.$part'));

SemanticsNode _node(WidgetTester tester, String part) =>
    tester.getSemantics(_key(part));

void main() {
  group('home', () {
    testWidgets('shows the title, the subtitle, the bell and the account', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_home()));

      expect(find.text('Calle Luna 12'), findsOneWidget);
      expect(find.text('2 home · 1 away'), findsOneWidget);
      expect(_key('activity'), findsOneWidget);
      expect(_key('account'), findsOneWidget);
      expect(find.byType(AppPebble), findsOneWidget);
      expect(_key('back'), findsNothing);
      expect(_key('action'), findsNothing);
    });

    testWidgets('a null or empty subtitle leaves the line out', (tester) async {
      for (final subtitle in <String?>[null, '']) {
        await tester.pumpWidget(barHost(_home(subtitle: subtitle)));

        expect(_key('subtitle'), findsNothing, reason: '"$subtitle"');
      }
    });

    testWidgets('the bell badge shows the count and is gone at zero', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_home()));
      expect(tester.widget<AppBadge>(find.byType(AppBadge)).count, 3);

      await tester.pumpWidget(barHost(_home(unread: 120)));
      expect(find.text('99+'), findsOneWidget);

      await tester.pumpWidget(barHost(_home(unread: 0)));
      expect(find.byType(AppBadge), findsNothing);
    });

    testWidgets(
      'the home bar ends in a hairline of the decorative line color',
      (tester) async {
        for (final (name, theme) in themes) {
          await tester.pumpWidget(barHost(_home(), theme: theme));
          await tester.pumpAndSettle();
          final bar = tester.getRect(find.byType(AppTopBar));

          final line = await paintedColorAt(
            tester,
            barBoundaryKey,
            Offset(bar.width / 2, bar.height - 1),
          );
          expect(
            line,
            isSameColorAs(theme.colorScheme.outlineVariant),
            reason: name,
          );
        }
      },
    );

    testWidgets('rejects a negative unread count in debug', (tester) async {
      expect(() => _home(unread: -1), throwsAssertionError);
    });

    testWidgets('the bell and the account call their callbacks', (
      tester,
    ) async {
      var bell = 0;
      var account = 0;
      await tester.pumpWidget(
        barHost(_home(onActivity: () => bell++, onAccount: () => account++)),
      );

      await tester.tap(_key('activity'));
      await tester.tap(_key('account'));

      expect((bell, account), (1, 1));
    });

    testWidgets('the bell draws its icon and a boundary in the theme colors', (
      tester,
    ) async {
      for (final (name, theme) in themes) {
        await tester.pumpWidget(barHost(_home(), theme: theme));
        await tester.pumpAndSettle();
        final scheme = theme.colorScheme;
        final bell = tester.getRect(_key('activity'));
        final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
        final inner = bell.shift(-origin);

        // Inside the 44 square, away from the glyph: the surface fill.
        final fill = await paintedColorAt(
          tester,
          barBoundaryKey,
          Offset(inner.left + 8, inner.bottom - 8),
        );
        expect(
          fill,
          isSameColorAs(scheme.surfaceContainerLowest),
          reason: name,
        );
      }
    });
  });

  group('pushed', () {
    testWidgets('shows the back button, the title and the action', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_pushed()));

      expect(_key('back'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Mark all as read'), findsOneWidget);
      expect(_key('activity'), findsNothing);
      expect(_key('account'), findsNothing);
    });

    testWidgets('hugs its content instead of filling the height', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_pushed()));
      expect(tester.getSize(find.byType(AppTopBar)).height, lessThan(200));

      await tester.pumpWidget(barHost(_home()));
      expect(tester.getSize(find.byType(AppTopBar)).height, lessThan(200));
    });

    testWidgets('a null or empty actionLabel leaves the action out', (
      tester,
    ) async {
      for (final label in <String?>[null, '']) {
        await tester.pumpWidget(barHost(_pushed(actionLabel: label)));

        expect(_key('action'), findsNothing, reason: '"$label"');
      }
    });

    testWidgets('a null onAction disables the action', (tester) async {
      await tester.pumpWidget(barHost(_pushed(onAction: null)));

      expect(tester.widget<TextButton>(_key('action')).onPressed, isNull);
      expect(
        _node(tester, 'action'),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
    });

    testWidgets('the back button draws the back glyph and the bell its own', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_pushed()));
      expect(
        tester
            .widget<AppIcon>(
              find.descendant(of: _key('back'), matching: find.byType(AppIcon)),
            )
            .icon,
        AppIcons.back,
      );

      await tester.pumpWidget(barHost(_home()));
      expect(
        tester
            .widget<AppIcon>(
              find.descendant(
                of: _key('activity'),
                matching: find.byType(AppIcon),
              ),
            )
            .icon,
        AppIcons.bell,
      );
    });

    testWidgets('back and action call their callbacks', (tester) async {
      var back = 0;
      var action = 0;
      await tester.pumpWidget(
        barHost(_pushed(onBack: () => back++, onAction: () => action++)),
      );

      await tester.tap(_key('back'));
      await tester.tap(_key('action'));

      expect((back, action), (1, 1));
    });
  });

  group('semantics', () {
    testWidgets('the title is a heading and the subtitle is plain text', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_home()));

      expect(
        tester.getSemantics(find.text('Calle Luna 12')),
        isSemantics(label: 'Calle Luna 12', isHeader: true),
      );
      final subtitle = tester.getSemantics(find.text('2 home · 1 away'));
      expect(subtitle.label, '2 home · 1 away');
      expect(subtitle.flagsCollection.isHeader, isFalse);
      handle.dispose();
    });

    testWidgets('the pushed title is a heading too', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_pushed()));

      expect(
        tester.getSemantics(find.text('Activity')),
        isSemantics(label: 'Activity', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('the bell is one focusable button that reads the count once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_home()));

      final node = _node(tester, 'activity');
      expect(
        node,
        isSemantics(
          label: 'Activity, 3 unread',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      final spoken = labeledNodes(tester).map((n) => n.label).toList();
      expect(spoken.where((label) => label.contains('3')), [
        'Activity, 3 unread',
      ], reason: 'the badge text is not a second node');
      expect(spoken, isNot(contains('3')));
      handle.dispose();
    });

    testWidgets('the account is one focusable button named by its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_home()));

      expect(
        _node(tester, 'account'),
        isSemantics(
          label: 'Your account',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(
        labeledNodes(tester).where((n) => n.label == 'Your account'),
        hasLength(1),
        reason: 'the pebble image is merged into the button, not a sibling',
      );
      handle.dispose();
    });

    testWidgets('the button reads the action, not the member', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_home()));

      final spoken = [for (final n in labeledNodes(tester)) n.label];
      expect(spoken, contains('Your account'));
      expect(spoken, isNot(contains(_me.semanticLabel)));
      expect(spoken, isNot(contains(_me.name)));
      handle.dispose();
    });

    testWidgets('back and action are focusable buttons named by their text', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_pushed()));

      expect(
        _node(tester, 'back'),
        isSemantics(
          label: 'Back',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(
        _node(tester, 'action'),
        isSemantics(
          label: 'Mark all as read',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a bar passes the Flutter tap target guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final bar in [_home(), _pushed()]) {
        await tester.pumpWidget(barHost(bar));

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }
      handle.dispose();
    });
  });

  group('targets', () {
    testWidgets('every button has a 48 hit area around 44 drawn', (
      tester,
    ) async {
      for (final (bar, parts) in [
        (_home(), ['activity', 'account']),
        (_pushed(), ['back', 'action']),
      ]) {
        await tester.pumpWidget(barHost(bar));

        for (final part in parts) {
          // The button is padded to 48 for the hit area; the Material inside
          // it is the drawn shape.
          final drawn = tester.getSize(
            find
                .descendant(of: _key(part), matching: find.byType(Material))
                .first,
          );
          expect(
            drawn.width,
            greaterThanOrEqualTo(AppSizes.minDrawn),
            reason: part,
          );
          expect(
            drawn.height,
            greaterThanOrEqualTo(AppSizes.minDrawn),
            reason: part,
          );
          final semantics = _node(tester, part).rect;
          expect(
            semantics.width,
            greaterThanOrEqualTo(AppSizes.minTarget),
            reason: '$part hit width',
          );
          expect(
            semantics.height,
            greaterThanOrEqualTo(AppSizes.minTarget),
            reason: '$part hit height',
          );
        }
      }
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      test('text reaches 4.5:1 and boundaries 3:1 ($name)', () {
        final scheme = theme.colorScheme;
        expectContrast(
          {
            'title/ground': (scheme.onSurface, scheme.surface),
            'subtitle/ground': (scheme.onSurfaceVariant, scheme.surface),
            'bell glyph/surface': (
              scheme.onSurface,
              scheme.surfaceContainerLowest,
            ),
            'back glyph/ground': (scheme.onSurface, scheme.surface),
            'action/ground': (scheme.primary, scheme.surface),
          },
          minimum: 4.5,
          reason: name,
        );
        expectContrast(
          {
            'bell boundary/ground': (scheme.outline, scheme.surface),
            'focus ring/ground': (scheme.onSurface, scheme.surface),
          },
          minimum: 3,
          reason: name,
        );
      });

      testWidgets('the painted title and subtitle keep it ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(barHost(_home(), theme: theme));
        final scheme = theme.colorScheme;

        final title = tester.widget<Text>(find.text('Calle Luna 12'));
        final subtitle = tester.widget<Text>(find.text('2 home · 1 away'));
        expect(title.style!.color, scheme.onSurface);
        expect(subtitle.style!.color, scheme.onSurfaceVariant);
      });
    }
  });

  group('right to left', () {
    testWidgets(
      'the home bar mirrors: title at the right, account at the left',
      (tester) async {
        await tester.pumpWidget(barHost(_home()));
        final ltrTitle = tester.getCenter(find.text('Calle Luna 12')).dx;
        final ltrAccount = tester.getCenter(_key('account')).dx;
        final ltrBell = tester.getCenter(_key('activity')).dx;

        await tester.pumpWidget(barHost(_home(), direction: TextDirection.rtl));

        expect(
          tester.getTopRight(find.text('Calle Luna 12')).dx,
          greaterThan(180),
        );
        expect(ltrTitle, lessThan(180));
        expect(tester.getCenter(_key('account')).dx, lessThan(180));
        expect(ltrAccount, greaterThan(180));
        expect(
          tester.getCenter(_key('activity')).dx,
          lessThan(tester.getCenter(find.text('Calle Luna 12')).dx),
        );
        expect(ltrBell, lessThan(ltrAccount));
        expect(
          tester.getCenter(_key('activity')).dx,
          greaterThan(tester.getCenter(_key('account')).dx),
          reason: 'the bell stays next to the title, the account at the end',
        );
      },
    );

    testWidgets(
      'the pushed bar mirrors: back at the right, action at the left',
      (tester) async {
        await tester.pumpWidget(barHost(_pushed()));
        expect(tester.getCenter(_key('back')).dx, lessThan(180));
        expect(tester.getCenter(_key('action')).dx, greaterThan(180));

        await tester.pumpWidget(
          barHost(_pushed(), direction: TextDirection.rtl),
        );

        expect(tester.getCenter(_key('back')).dx, greaterThan(180));
        expect(tester.getCenter(_key('action')).dx, lessThan(180));
      },
    );

    testWidgets('the back arrow points the other way', (tester) async {
      await tester.pumpWidget(barHost(_pushed()));
      expect(
        find.descendant(of: _key('back'), matching: find.byType(Transform)),
        findsNothing,
      );

      await tester.pumpWidget(barHost(_pushed(), direction: TextDirection.rtl));

      final flipped = find.descendant(
        of: _key('back'),
        matching: find.byWidgetPredicate(
          (widget) => widget is Transform && widget.transform.storage[0] == -1,
        ),
      );
      expect(flipped, findsOneWidget);
    });

    testWidgets(
      'the badge hangs at the top end of the bell in both directions',
      (tester) async {
        await tester.pumpWidget(barHost(_home()));
        final ltrBell = tester.getRect(_key('activity'));
        expect(
          tester.getCenter(find.byType(AppBadge)).dx,
          greaterThan(ltrBell.center.dx),
        );

        await tester.pumpWidget(barHost(_home(), direction: TextDirection.rtl));
        final rtlBell = tester.getRect(_key('activity'));

        expect(
          tester.getCenter(find.byType(AppBadge)).dx,
          lessThan(rtlBell.center.dx),
        );
      },
    );
  });

  group('semantics under a grouping parent', () {
    // A `Card`, a list item and a `Semantics(container: true)` all group what
    // is inside them. The bar must keep its heading and its buttons apart.
    final parents = <String, Widget Function(Widget)>{
      'a Card': (bar) => Card(child: bar),
      'a ListView item': (bar) =>
          SizedBox(height: 400, child: ListView(children: [bar])),
      'a Semantics container': (bar) => Semantics(container: true, child: bar),
      'a Column': (bar) => Column(children: [bar]),
    };

    for (final MapEntry(key: name, value: wrap) in parents.entries) {
      testWidgets('the home title stays a heading of its own in $name', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(barHost(wrap(_home())));

        final heading = tester.getSemantics(find.text('Calle Luna 12'));
        expect(heading.label, 'Calle Luna 12', reason: 'not merged with more');
        expect(heading.flagsCollection.isHeader, isTrue);
        expect(heading.childrenCount, 0);
        expect(
          tester.getSemantics(find.text('2 home · 1 away')).label,
          '2 home · 1 away',
        );
        expect(_node(tester, 'activity').label, 'Activity, 3 unread');
        expect(_node(tester, 'activity').flagsCollection.isHeader, isFalse);
        handle.dispose();
      });

      testWidgets('the pushed title is a heading and the buttons are not its '
          'children in $name', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(barHost(wrap(_pushed())));

        final heading = tester.getSemantics(find.text('Activity'));
        expect(heading.label, 'Activity');
        expect(heading.flagsCollection.isHeader, isTrue);
        expect(heading.childrenCount, 0);
        for (final part in ['back', 'action']) {
          final node = _node(tester, part);
          expect(node.flagsCollection.isButton, isTrue, reason: part);
          expect(node.flagsCollection.isHeader, isFalse, reason: part);
          var ancestor = node.parent;
          while (ancestor != null) {
            expect(ancestor.flagsCollection.isHeader, isFalse, reason: part);
            ancestor = ancestor.parent;
          }
        }
        handle.dispose();
      });
    }

    testWidgets('the pushed bar reads the heading before the buttons', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_pushed()));

      final group = tester.getSemantics(find.text('Activity')).parent!;
      final order = [
        for (final node in group.debugListChildrenInOrder(
          DebugSemanticsDumpOrder.traversalOrder,
        ))
          node.label,
      ];

      expect(order, ['Activity', 'Back', 'Mark all as read']);
      handle.dispose();
    });
  });

  group('painted glyphs and borders', () {
    for (final (name, theme) in themes) {
      testWidgets('the back glyph is ink, not the primary green ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(barHost(_pushed(), theme: theme));
        await tester.pumpAndSettle();
        final icon = find.descendant(
          of: _key('back'),
          matching: find.byType(AppIcon),
        );

        final pixels = await paintedRegion(tester, inBarHost(tester, icon));

        expect(
          countColor(pixels, theme.colorScheme.onSurface),
          greaterThan(3),
          reason: name,
        );
        expect(countColor(pixels, theme.colorScheme.primary), 0, reason: name);
      });

      testWidgets(
        'the bell glyph is ink and its border is the outline ($name)',
        (tester) async {
          await tester.pumpWidget(barHost(_home(unread: 0), theme: theme));
          await tester.pumpAndSettle();
          final scheme = theme.colorScheme;
          final icon = find.descendant(
            of: _key('activity'),
            matching: find.byType(AppIcon),
          );
          final drawn = inBarHost(
            tester,
            find
                .descendant(
                  of: _key('activity'),
                  matching: find.byType(Material),
                )
                .first,
          );

          final glyph = await paintedRegion(tester, inBarHost(tester, icon));
          final border = await paintedRegion(
            tester,
            Rect.fromLTWH(drawn.left, drawn.center.dy, 1, 1),
          );

          expect(
            countColor(glyph, scheme.onSurface),
            greaterThan(3),
            reason: name,
          );
          expect(countColor(glyph, scheme.primary), 0, reason: name);
          expect(countColor(border, scheme.outline), 1, reason: '$name border');
        },
      );
    }

    testWidgets('the pushed action label is font.label: 13 and 600', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_pushed()));

      final style = tester
          .renderObject<RenderParagraph>(find.text('Mark all as read'))
          .text
          .style!;
      expect(style.fontSize, AppTypography.label.fontSize);
      expect(style.fontSize, 13);
      expect(style.fontWeight, FontWeight.w600);
    });
  });

  group('inset and asserts', () {
    testWidgets('both bars start below the status bar inset', (tester) async {
      for (final bar in [_home(), _pushed()]) {
        await tester.pumpWidget(barHost(bar));
        final plain = tester.getSize(find.byType(AppTopBar)).height;
        final plainTitle = tester.getTopLeft(_key('title')).dy;

        await tester.pumpWidget(
          barHost(bar, padding: const EdgeInsets.only(top: 40)),
        );

        expect(tester.getSize(find.byType(AppTopBar)).height, plain + 40);
        expect(tester.getTopLeft(_key('title')).dy, plainTitle + 40);
      }
    });

    testWidgets('the account pebble is drawn from the member', (tester) async {
      const other = MemberView(
        id: 'bo',
        name: 'Bo',
        initials: 'BO',
        joinOrder: 3,
        semanticLabel: 'Bo',
      );
      AppTopBar bar(MemberView me) => AppTopBar.home(
        title: 'T',
        activityLabel: 'Activity',
        unreadCount: 0,
        onActivity: _noop,
        me: me,
        accountLabel: 'Your account',
        onAccount: _noop,
      );

      await tester.pumpWidget(barHost(bar(_me)));
      var pebble = tester.widget<AppPebble>(find.byType(AppPebble));
      expect(
        (pebble.initials, pebble.joinOrder, pebble.isYou),
        ('A', 0, false),
      );

      await tester.pumpWidget(barHost(bar(other)));
      pebble = tester.widget<AppPebble>(find.byType(AppPebble));
      expect(
        (pebble.initials, pebble.joinOrder, pebble.isYou),
        ('BO', 3, false),
      );
      expect(pebble.semanticLabel, 'Your account');
    });

    testWidgets('a spoken label is never empty', (tester) async {
      expect(
        () => AppTopBar.home(
          title: 'T',
          activityLabel: 'Activity',
          unreadCount: 0,
          onActivity: _noop,
          me: _me,
          accountLabel: '',
          onAccount: _noop,
        ),
        throwsAssertionError,
      );
      expect(
        () => AppTopBar.home(
          title: 'T',
          activityLabel: '',
          unreadCount: 0,
          onActivity: _noop,
          me: _me,
          accountLabel: 'Your account',
          onAccount: _noop,
        ),
        throwsAssertionError,
      );
      expect(
        () => AppTopBar.pushed(title: 'T', backLabel: '', onBack: _noop),
        throwsAssertionError,
      );
    });
  });

  group('last fixes', () {
    setUpAll(loadBundledFonts);

    testWidgets(
      'hugs its content in a bounded parent at 1.0x, 1.31x and 2.0x',
      (tester) async {
        final parents = <String, Widget Function(Widget)>{
          'Align': (bar) => Align(alignment: Alignment.topLeft, child: bar),
          'Stack': (bar) => Stack(children: [bar]),
          'Column': (bar) => Column(children: [bar]),
          'SafeArea + Align': (bar) => SafeArea(
            child: Align(alignment: Alignment.topLeft, child: bar),
          ),
        };
        for (final MapEntry(key: name, value: wrap) in parents.entries) {
          for (final scale in [1.0, 1.31, 2.0]) {
            for (final bar in [_home(), _pushed()]) {
              await tester.pumpWidget(barHost(wrap(bar), textScale: scale));

              final height = tester.getSize(find.byType(AppTopBar)).height;
              expect(
                height,
                lessThan(500),
                reason: '$name ${bar.variant.name} at ${scale}x',
              );
              expect(tester.takeException(), isNull);
            }
          }
        }
      },
    );

    testWidgets('the home bar reads title, subtitle, bell, account in order', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final subtitle in ['2 home', 'Todos fuera', 'Solo tú']) {
        for (final direction in TextDirection.values) {
          await tester.pumpWidget(
            barHost(
              Card(child: _home(subtitle: subtitle)),
              direction: direction,
            ),
          );

          final group = tester.getSemantics(_key('title')).parent!;
          final order = [
            for (final node in group.debugListChildrenInOrder(
              DebugSemanticsDumpOrder.traversalOrder,
            ))
              node.label,
          ];

          expect(order, [
            'Calle Luna 12',
            subtitle,
            'Activity, 3 unread',
            'Your account',
          ], reason: '$subtitle $direction');
        }
      }
      handle.dispose();
    });

    testWidgets('a loose text beside the bar in a Card does not swallow the '
        'subtitle', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        barHost(Card(child: Column(children: [_home(), const Text('Loose')]))),
      );

      expect(
        tester.getSemantics(find.text('2 home · 1 away')).label,
        '2 home · 1 away',
      );
      expect(tester.getSemantics(find.text('Loose')).label, 'Loose');
      handle.dispose();
    });

    for (final (name, theme) in themes) {
      testWidgets('the account pebble paints no "you" ring ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(barHost(_home(), theme: theme));
        await tester.pumpAndSettle();
        final colors = theme.extension<AppColors>()!;
        final pebble = inBarHost(tester, find.byType(AppPebble));

        // The ring of an `isYou` pebble sits inset from the edge: the pixel
        // there is the pebble color, not the dark ring.
        final band = await paintedRegion(
          tester,
          Rect.fromLTWH(pebble.left + 2, pebble.center.dy, 2, 1),
        );

        expect(tester.widget<AppPebble>(find.byType(AppPebble)).isYou, isFalse);
        expect(countColor(band, colors.onPebble), 0, reason: name);
        expect(countColor(band, colors.pebbleAt(0)), band.length, reason: name);
      });
    }
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const longTitle =
        'El piso compartido de la calle Doctor Fleming, número doce';
    const longSubtitle = '2 personas en casa y 1 persona fuera hasta mañana';

    testWidgets('the home bar grows and nothing overflows or clips', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_home()));
      final base = tester.getSize(find.byType(AppTopBar));

      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          barHost(
            _home(title: longTitle, subtitle: longSubtitle, unread: 120),
            textScale: 2,
            direction: direction,
          ),
        );

        expect(tester.takeException(), isNull, reason: '$direction');
        final bar = tester.getRect(find.byType(AppTopBar));
        expect(bar.height, greaterThan(base.height));
        expect(bar.width, 360);
        for (final text in [longTitle, longSubtitle]) {
          final rect = tester.getRect(find.text(text));
          expect(bar.contains(rect.topLeft), isTrue, reason: text);
          expect(bar.contains(rect.bottomRight), isTrue, reason: text);
        }
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(longTitle),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          tester.getRect(find.text(longTitle)).right,
          lessThanOrEqualTo(tester.getRect(_key('activity')).left + 360),
        );
      }
    });

    testWidgets(
      'no word of the title or subtitle breaks at 1.0x, 1.3x or 2.0x',
      (tester) async {
        for (final scale in [1.0, 1.3, 2.0]) {
          for (final direction in TextDirection.values) {
            await tester.pumpWidget(
              barHost(
                _home(title: longTitle, subtitle: longSubtitle, unread: 150),
                textScale: scale,
                direction: direction,
              ),
            );

            expectNoMidWordBreaks(
              tester,
              find.text(longTitle),
              reason: '$scale $direction',
            );
            expectNoMidWordBreaks(
              tester,
              find.text(longSubtitle),
              reason: '$scale $direction',
            );
            expect(tester.takeException(), isNull);
          }
        }
      },
    );

    testWidgets('the buttons share the row up to 1.3x and drop below above', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_home(), textScale: 1.3));
      expect(
        tester.getRect(_key('activity')).top,
        lessThan(tester.getRect(_key('title')).bottom),
        reason: 'beside the title at 1.3x',
      );

      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          barHost(_home(), textScale: 1.5, direction: direction),
        );

        expect(
          tester.getRect(_key('activity')).top,
          greaterThanOrEqualTo(
            tester.getRect(find.text('2 home · 1 away')).bottom,
          ),
          reason: 'below the title at 1.5x, $direction',
        );
        final bar = tester.getRect(find.byType(AppTopBar));
        expect(
          bar.contains(tester.getRect(_key('account')).bottomRight),
          isTrue,
        );
      }
    });

    testWidgets('a 99+ badge stays clear of the bell glyph at 2.0x', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          barHost(_home(unread: 150), textScale: 2, direction: direction),
        );

        final badge = tester.getRect(find.byType(AppBadge));
        final glyph = tester.getRect(
          find.descendant(of: _key('activity'), matching: find.byType(AppIcon)),
        );
        expect(badge.overlaps(glyph), isFalse, reason: '$direction');
        expect(
          tester.getRect(find.byType(AppTopBar)).contains(badge.topLeft),
          isTrue,
        );
        expect(
          tester.getRect(find.byType(AppTopBar)).contains(badge.bottomRight),
          isTrue,
          reason: 'the bell grew to hold it',
        );
        expect(
          tester
              .getRect(_key('activity'))
              .overlaps(tester.getRect(_key('account'))),
          isFalse,
        );
      }
    });

    testWidgets('the title never scales down', (tester) async {
      await tester.pumpWidget(barHost(_pushed()));
      final base = tester.getSize(find.text('Activity')).height;

      await tester.pumpWidget(barHost(_pushed(), textScale: 2));

      expect(
        tester.getSize(find.text('Activity')).height,
        closeTo(base * 2, 1),
      );
    });

    testWidgets('the pushed bar wraps a long title and a long action', (
      tester,
    ) async {
      await tester.pumpWidget(
        barHost(
          _pushed(
            title: 'Todo lo que ha pasado en el piso durante esta semana',
            actionLabel: 'Marcar todo como leído',
          ),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
      final bar = tester.getRect(find.byType(AppTopBar));
      for (final part in ['back', 'action']) {
        final rect = tester.getRect(_key(part));
        expect(bar.contains(rect.topLeft), isTrue, reason: part);
        expect(bar.contains(rect.bottomRight), isTrue, reason: part);
      }
      expect(
        tester.getRect(_key('back')).overlaps(tester.getRect(_key('action'))),
        isFalse,
      );
    });
  });
}
