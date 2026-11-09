import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bar_host.dart';
import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';

AppEmptyState _state({
  String? actionLabel = 'Add a thing',
  VoidCallback? onAction = _noop,
  String title = 'No shared things yet',
  String body =
      'Add the washer, the oven or anything the house takes turns '
      'with.',
}) => AppEmptyState(
  title: title,
  body: body,
  actionLabel: actionLabel,
  onAction: onAction,
);

void _noop() {}

final Finder _title = find.byKey(const Key('emptyState.title'));
final Finder _body = find.byKey(const Key('emptyState.body'));
final Finder _action = find.byKey(const Key('emptyState.action'));
final Finder _motif = find.byKey(const Key('emptyState.motif'));

void main() {
  group('content', () {
    testWidgets('shows the motif, the title, the body and the action in '
        'order', (tester) async {
      await tester.pumpWidget(barHost(_state()));

      expect(find.text('No shared things yet'), findsOneWidget);
      expect(find.text('Add a thing'), findsOneWidget);
      final tops = [
        tester.getRect(_motif).top,
        tester.getRect(_title).top,
        tester.getRect(_body).top,
        tester.getRect(_action).top,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(tops.toSet(), hasLength(4));
    });

    testWidgets('the motif is 80 by 60', (tester) async {
      await tester.pumpWidget(barHost(_state()));

      expect(tester.getSize(_motif), const Size(80, 60));
    });

    testWidgets('the motif holds five rooms: three over a wide and a small '
        'one', (tester) async {
      await tester.pumpWidget(barHost(_state()));

      final rooms = find.descendant(
        of: _motif,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.foregroundPainter != null &&
              widget.child == null,
        ),
      );
      final rects = [
        for (var i = 0; i < rooms.evaluate().length; i++)
          tester.getRect(rooms.at(i)),
      ];

      expect(rects, hasLength(5));
      for (final rect in rects) {
        expect(rect.height, greaterThan(16), reason: 'a room is drawn');
        expect(rect.width, greaterThan(16), reason: 'a room is drawn');
      }
      expect(rects[0].top, rects[1].top);
      expect(rects[1].top, rects[2].top);
      expect(rects[3].top, rects[4].top);
      expect(rects[3].top, greaterThan(rects[0].bottom));
      expect(rects[3].width, greaterThan(rects[4].width));
      expect(rects[3].width, closeTo(rects[4].width * 2 + 4, 0.01));
    });

    testWidgets('everything is centered', (tester) async {
      await tester.pumpWidget(barHost(_state()));
      final center = tester.getCenter(find.byType(AppEmptyState)).dx;

      for (final finder in [_motif, _title, _action]) {
        expect(tester.getCenter(finder).dx, closeTo(center, 0.5));
      }
      expect(tester.widget<Text>(_title).textAlign, TextAlign.center);
      expect(tester.widget<Text>(_body).textAlign, TextAlign.center);
    });

    testWidgets('a null or empty actionLabel leaves the action out', (
      tester,
    ) async {
      for (final label in <String?>[null, '']) {
        await tester.pumpWidget(barHost(_state(actionLabel: label)));

        expect(_action, findsNothing, reason: '"$label"');
      }
    });

    testWidgets('the action calls onAction and a null one disables it', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(barHost(_state(onAction: () => taps++)));
      await tester.tap(_action);
      expect(taps, 1);

      await tester.pumpWidget(barHost(_state(onAction: null)));
      expect(tester.widget<AppButton>(_action).onPressed, isNull);
    });

    testWidgets('the action is the primary medium button', (tester) async {
      await tester.pumpWidget(barHost(_state()));

      final button = tester.widget<AppButton>(_action);
      expect(button.variant, AppButtonVariant.primary);
      expect(button.size, AppButtonSize.md);
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      testWidgets('text colors and the dashed motif ($name)', (tester) async {
        await tester.pumpWidget(barHost(_state(), theme: theme));
        await tester.pumpAndSettle();
        final scheme = theme.colorScheme;

        expect(tester.widget<Text>(_title).style!.color, scheme.onSurface);
        expect(
          tester.widget<Text>(_body).style!.color,
          scheme.onSurfaceVariant,
        );

        // The motif is outlined, not filled: its middle is the page, and the
        // outline is the decorative line color.
        final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
        final motif = tester.getRect(_motif).shift(-origin);
        final seen = <Color>{};
        for (var x = motif.left; x < motif.right; x += 0.5) {
          seen.add(
            await paintedColorAt(
              tester,
              barBoundaryKey,
              Offset(x, motif.top + 0.5),
            ),
          );
        }
        expect(
          seen.any((c) => isSameColorAs(scheme.outlineVariant).matches(c, {})),
          isTrue,
          reason: 'the outline is drawn in the line color',
        );
      });
    }

    testWidgets('the outline is dashed: it has gaps along its top edge', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_state()));
      final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
      final motif = tester.getRect(_motif).shift(-origin);

      var painted = 0;
      var empty = 0;
      for (var x = motif.left + 20; x < motif.right - 20; x++) {
        final color = await paintedColorAt(
          tester,
          barBoundaryKey,
          Offset(x, motif.top + 0.5),
        );
        if (color.a == 0) {
          empty++;
        } else {
          painted++;
        }
      }
      expect(painted, greaterThan(0));
      expect(empty, greaterThan(0));
    });
  });

  group('semantics', () {
    testWidgets('title and body are one node and the action another', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_state()));

      final labels = [for (final n in labeledNodes(tester)) n.label];
      const text =
          'No shared things yet\n'
          'Add the washer, the oven or anything the house takes turns with.';
      expect(labels, [text, 'Add a thing']);
      handle.dispose();
    });

    testWidgets('the text is plain text, not a heading or a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_state()));

      final text = tester.getSemantics(_title);
      expect(text.flagsCollection.isHeader, isFalse);
      expect(text.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('the action is a focusable button named by its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_state()));

      expect(
        tester.getSemantics(
          find.descendant(of: _action, matching: find.byType(FilledButton)),
        ),
        isSemantics(
          label: 'Add a thing',
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the motif is excluded and no action leaves one node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_state(actionLabel: null)));

      expect(labeledNodes(tester), hasLength(1));
      handle.dispose();
    });

    testWidgets('passes the Flutter tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_state()));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('targets', () {
    testWidgets('the action is 44 drawn with a 48 hit area', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_state()));

      final button = find.descendant(
        of: _action,
        matching: find.byType(FilledButton),
      );
      expect(
        tester.getSize(button).height,
        greaterThanOrEqualTo(AppSizes.minDrawn),
      );
      expect(
        tester.getSemantics(button).rect.height,
        greaterThanOrEqualTo(AppSizes.minTarget),
      );
      handle.dispose();
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      test('title and body 4.5:1 on the page ($name)', () {
        final scheme = theme.colorScheme;
        expectContrast(
          {
            'title/ground': (scheme.onSurface, scheme.surface),
            'body/ground': (scheme.onSurfaceVariant, scheme.surface),
            'action/primary': (scheme.onPrimary, scheme.primary),
          },
          minimum: 4.5,
          reason: name,
        );
      });
    }
  });

  group('right to left', () {
    testWidgets('stays centered and builds without errors', (tester) async {
      await tester.pumpWidget(barHost(_state()));
      final center = tester.getCenter(find.byType(AppEmptyState)).dx;

      await tester.pumpWidget(barHost(_state(), direction: TextDirection.rtl));

      expect(tester.getCenter(_title).dx, closeTo(center, 0.5));
      expect(tester.getCenter(_action).dx, closeTo(center, 0.5));
      expect(tester.takeException(), isNull);
    });
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const title = 'Todavía no hay cosas compartidas en la casa';
    const body =
        'Añade la lavadora, el horno o cualquier cosa que la casa se turne '
        'para usar entre todas las personas que viven aquí.';
    const action = 'Añadir una cosa compartida';

    // At 2.0x the state is taller than the 600 high test screen. It is meant
    // for a scrollable screen, so the tests give it one.
    Widget scrolling(Widget child) => SingleChildScrollView(child: child);

    testWidgets('wraps, grows and never clips or overflows', (tester) async {
      await tester.pumpWidget(
        barHost(
          scrolling(_state(title: title, body: body, actionLabel: action)),
        ),
      );
      final base = tester.getSize(find.byType(AppEmptyState)).height;

      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          barHost(
            scrolling(_state(title: title, body: body, actionLabel: action)),
            textScale: 2,
            direction: direction,
          ),
        );

        expect(tester.takeException(), isNull, reason: '$direction');
        final state = tester.getRect(find.byType(AppEmptyState));
        expect(state.height, greaterThan(base));
        for (final finder in [_title, _body, _action]) {
          final rect = tester.getRect(finder);
          expect(state.contains(rect.topLeft), isTrue);
          expect(state.contains(rect.bottomRight), isTrue);
        }
        for (final finder in [_title, _body]) {
          expect(
            tester.renderObject<RenderParagraph>(finder).didExceedMaxLines,
            isFalse,
          );
        }
        expect(
          tester.getRect(_title).bottom,
          lessThanOrEqualTo(tester.getRect(_body).top),
        );
        expect(
          tester.getRect(_body).bottom,
          lessThanOrEqualTo(tester.getRect(_action).top),
        );
      }
    });

    testWidgets('the text is never scaled down', (tester) async {
      await tester.pumpWidget(barHost(_state(title: 'Hola')));
      final base = tester.getSize(_title).height;

      await tester.pumpWidget(barHost(_state(title: 'Hola'), textScale: 2));

      expect(tester.getSize(_title).height, closeTo(base * 2, 1));
    });
  });
}
