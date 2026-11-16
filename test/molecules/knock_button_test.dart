import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';
import '../helpers/painted_pixels.dart';
import '../helpers/word_breaks.dart';

const _spoken = "Asked who's home. You can ask again in 11 minutes";

KnockCooldown _cooldown({
  double remaining = 0.73,
  String label = 'Asked',
  String left = '11 min',
  String spoken = _spoken,
}) => KnockCooldown(
  remaining: remaining,
  label: label,
  remainingLabel: left,
  semanticLabel: spoken,
);

KnockButton _button({
  String label = "Who's home?",
  VoidCallback? onKnock,
  KnockCooldown? cooldown,
}) => KnockButton(label: label, onKnock: onKnock ?? () {}, cooldown: cooldown);

Finder get _knock => find.byKey(const Key('presence.knock'));
Finder get _ring => find.byType(AppProgressRing);
Finder get _glyph => find.byType(AppIcon);

/// The drawn plate, without the invisible hit padding.
Rect _drawn(WidgetTester tester) => tester.getRect(
  find.descendant(of: _knock, matching: find.byType(Material)).first,
);

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('ready shows the door glyph over the label and no ring', (
      tester,
    ) async {
      await tester.pumpWidget(host(_button()));

      expect(find.text("Who's home?"), findsOneWidget);
      expect(tester.widget<AppIcon>(_glyph).icon, AppIcons.knock);
      expect(tester.widget<AppIcon>(_glyph).size, AppSizes.glyphLg);
      expect(_ring, findsNothing);
      expect(
        tester.getRect(_glyph).bottom,
        lessThanOrEqualTo(tester.getRect(find.text("Who's home?")).top),
      );
    });

    testWidgets('cooldown shows the ring, the label and the time left, and '
        'no glyph', (tester) async {
      await tester.pumpWidget(host(_button(cooldown: _cooldown())));

      expect(find.text('Asked'), findsOneWidget);
      expect(find.text('11 min'), findsOneWidget);
      expect(find.text("Who's home?"), findsNothing);
      expect(_glyph, findsNothing);
      final ring = tester.widget<AppProgressRing>(_ring);
      expect(ring.value, 0.73);
      expect(ring.size, AppSizes.knockRing);
      expect(ring.semanticLabel, isNull);
      expect(ring.tone, AppRingTone.primary);
      expect(
        tester.getRect(find.text('Asked')).top,
        greaterThanOrEqualTo(tester.getRect(_ring).bottom),
      );
    });

    testWidgets('is at least 96 wide and 64 tall in both states, drawn and '
        'hit', (tester) async {
      for (final cooldown in [null, _cooldown(left: 'Soon')]) {
        await tester.pumpWidget(
          host(
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _button(label: 'Go', cooldown: cooldown),
            ),
          ),
        );

        expect(_drawn(tester).size, const Size(96, 64), reason: '$cooldown');
        expect(
          tester.getSize(_knock).height,
          greaterThanOrEqualTo(AppSizes.minTarget),
        );
      }
    });

    testWidgets('both states have the same height, so the layout does not '
        'jump', (tester) async {
      await tester.pumpWidget(host(_button()));
      final ready = _drawn(tester).height;
      await tester.pumpWidget(host(_button(cooldown: _cooldown())));

      expect(_drawn(tester).height, ready);
    });

    testWidgets('can be measured by intrinsic sizing, as the goldens do', (
      tester,
    ) async {
      for (final cooldown in [null, _cooldown()]) {
        await tester.pumpWidget(
          host(IntrinsicHeight(child: _button(cooldown: cooldown))),
        );

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('needs a label', (tester) async {
      expect(() => _button(label: ''), throwsAssertionError);
    });

    group('KnockCooldown', () {
      test('keeps the share the ring draws between 0 and 1', () {
        expect(_cooldown(remaining: 0.4).ringValue, 0.4);
        expect(_cooldown(remaining: 0).ringValue, 0);
        expect(_cooldown(remaining: 1).ringValue, 1);
        expect(_cooldown(remaining: 7).ringValue, 1);
        expect(_cooldown(remaining: -2).ringValue, 0);
        expect(_cooldown(remaining: double.infinity).ringValue, 1);
        expect(_cooldown(remaining: double.negativeInfinity).ringValue, 0);
      });

      test('rejects a share that is not a number, so it equals itself', () {
        expect(() => _cooldown(remaining: double.nan), throwsAssertionError);
        final cooldown = _cooldown(remaining: double.infinity);
        expect(cooldown, cooldown);
        expect(cooldown, _cooldown(remaining: double.infinity));
      });

      test('needs every text', () {
        expect(() => _cooldown(label: ''), throwsAssertionError);
        expect(() => _cooldown(left: ''), throwsAssertionError);
        expect(() => _cooldown(spoken: ''), throwsAssertionError);
      });

      test('compares by value', () {
        expect(_cooldown(), _cooldown());
        expect(_cooldown().hashCode, _cooldown().hashCode);
        expect(_cooldown(), isNot(_cooldown(remaining: 0.5)));
        expect(_cooldown(), isNot(_cooldown(left: '10 min')));
      });

      testWidgets('a share that is not a number does not break the ring', (
        tester,
      ) async {
        for (final remaining in <double>[double.infinity, -3, 12]) {
          await tester.pumpWidget(
            host(_button(cooldown: _cooldown(remaining: remaining))),
          );

          expect(tester.takeException(), isNull, reason: '$remaining');
          expect(
            tester.widget<AppProgressRing>(_ring).value,
            inInclusiveRange(0, 1),
          );
        }
      });
    });
  });

  group('interaction', () {
    testWidgets('a tap while ready calls onKnock once', (tester) async {
      var knocks = 0;
      await tester.pumpWidget(host(_button(onKnock: () => knocks++)));

      await tester.tap(_knock);
      await tester.pump();
      await tester.tap(find.text("Who's home?"));
      await tester.pump();

      expect(knocks, 2);
    });

    testWidgets('a tap during the cooldown does nothing', (tester) async {
      var knocks = 0;
      await tester.pumpWidget(
        host(_button(onKnock: () => knocks++, cooldown: _cooldown())),
      );

      await tester.tap(_knock, warnIfMissed: false);
      await tester.tap(find.text('Asked'), warnIfMissed: false);
      await tester.pump();

      expect(knocks, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(knocks, 0, reason: 'nor does Enter or Space on the focused plate');
    });

    testWidgets('takes focus while ready, and Enter and Space activate it', (
      tester,
    ) async {
      var knocks = 0;
      await tester.pumpWidget(host(_button(onKnock: () => knocks++)));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(knocks, 2);
    });

    testWidgets('has one tab stop in both states', (tester) async {
      int stops() => FocusManager.instance.rootScope.traversalDescendants
          .where(
            (node) =>
                node is! FocusScopeNode &&
                node.canRequestFocus &&
                !node.skipTraversal,
          )
          .length;

      await tester.pumpWidget(host(_button()));
      expect(stops(), 1);

      await tester.pumpWidget(host(_button(cooldown: _cooldown())));
      expect(stops(), 1, reason: 'the plate stays focusable but inert');
    });

    testWidgets('keyboard focus stays on the button when the wait starts, and '
        'the next Tab goes to the next control', (tester) async {
      Widget page({KnockCooldown? cooldown}) => host(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _button(cooldown: cooldown),
            TextButton(
              key: const Key('next'),
              onPressed: () {},
              child: const Text('Next'),
            ),
          ],
        ),
      );
      await tester.pumpWidget(page());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      bool inside(Finder finder) {
        final context = FocusManager.instance.primaryFocus?.context;
        return context != null &&
            find
                .ancestor(
                  of: find.byElementPredicate((element) => element == context),
                  matching: finder,
                )
                .evaluate()
                .isNotEmpty;
      }

      expect(inside(_knock), isTrue, reason: 'focus starts on the button');

      await tester.pumpWidget(page(cooldown: _cooldown()));
      await tester.pump();

      expect(
        inside(_knock),
        isTrue,
        reason: 'the wait started and focus did not move',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        inside(find.byKey(const Key('next'))),
        isTrue,
        reason: 'the next Tab goes to the next control',
      );
    });

    testWidgets('the wait draws the focus ring too', (tester) async {
      final scheme = CompappTheme.light.colorScheme;
      await tester.pumpWidget(
        host(
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _button(cooldown: _cooldown()),
            ),
          ),
          background: scheme.surface,
        ),
      );
      final box = tester.getRect(find.byKey(hostBoundaryKey));
      final plate = _drawn(tester);
      final probe = Offset(plate.center.dx - box.left, plate.top - box.top - 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        await paintedColorAt(tester, hostBoundaryKey, probe),
        isSameColorAs(scheme.onSurface),
      );
    });

    group('a press', () {
      Future<Color> pressed(
        WidgetTester tester, {
        required KnockCooldown? cooldown,
        required ColorScheme scheme,
      }) async {
        await tester.pumpWidget(
          host(
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _button(label: 'Go', cooldown: cooldown),
            ),
            background: scheme.surface,
          ),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final plate = _drawn(tester);
        final probe = Offset(
          plate.left + 4 - box.left,
          plate.center.dy - box.top,
        );
        final gesture = await tester.startGesture(plate.center);
        // The ink fades in over a few frames: pump twice, well past the first.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 300));
        final color = await paintedColorAt(tester, hostBoundaryKey, probe);
        await gesture.up();
        await tester.pumpAndSettle();
        return color;
      }

      testWidgets('on the wait shows no pressed fill', (tester) async {
        final scheme = CompappTheme.light.colorScheme;

        expect(
          await pressed(
            tester,
            cooldown: _cooldown(left: 'Soon'),
            scheme: scheme,
          ),
          isSameColorAs(scheme.surfaceContainerHigh),
        );
      });

      testWidgets('on a ready button does change the pixels, so the check '
          'above can fail', (tester) async {
        final scheme = CompappTheme.light.colorScheme;

        expect(
          await pressed(tester, cooldown: null, scheme: scheme),
          isNot(isSameColorAs(scheme.surfaceContainerLowest)),
        );
      });

      testWidgets('on the wait keeps the basic mouse cursor', (tester) async {
        await tester.pumpWidget(host(_button(cooldown: _cooldown())));

        final style = tester.widget<OutlinedButton>(_knock).style!;
        expect(style.mouseCursor!.resolve({}), SystemMouseCursors.basic);
      });
    });

    testWidgets('the semantics node is the same one before and after the wait '
        'starts, and it stays focused', (tester) async {
      final handle = tester.ensureSemantics();
      Widget page({KnockCooldown? cooldown}) => host(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_button(cooldown: cooldown)],
        ),
      );
      SemanticsNode node() => tester.getSemantics(find.byType(KnockButton));

      await tester.pumpWidget(page());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final before = node();
      expect(
        before,
        isSemantics(
          label: "Who's home?",
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          isFocused: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      final id = before.id;

      await tester.pumpWidget(page(cooldown: _cooldown()));
      await tester.pump();

      // Read the node again: the one in hand is the one from before.
      final after = node();
      expect(after.id, id, reason: 'the same node, not a new one');
      expect(
        after,
        isSemantics(
          label: _spoken,
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
          isFocusable: true,
          isFocused: true,
          hasFocusAction: true,
        ),
      );
      expect(
        after.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'the wait has no tap action',
      );

      await tester.pumpWidget(page());
      await tester.pump();
      expect(node().id, id, reason: 'and back again');
      expect(node().getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('a semantic focus action focuses the button, in the wait '
        'too', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_button(cooldown: _cooldown())));

      tester.semantics.performAction(
        find.semantics.byLabel(_spoken),
        SemanticsAction.focus,
      );
      await tester.pump();

      expect(
        tester.getSemantics(find.byType(KnockButton)),
        isSemantics(isFocused: true),
      );
      handle.dispose();
    });

    testWidgets('a semantic tap calls onKnock while ready', (tester) async {
      final handle = tester.ensureSemantics();
      var knocks = 0;
      await tester.pumpWidget(host(_button(onKnock: () => knocks++)));

      tester.semantics.tap(find.semantics.byLabel("Who's home?"));
      await tester.pump();

      expect(knocks, 1);
      handle.dispose();
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      testWidgets('ready has the surface fill, an outline border, an ink '
          'label and an ink glyph ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _button(label: 'Knock'),
            ),
            theme: theme,
            background: scheme.surface,
          ),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final plate = _drawn(tester);

        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(plate.left + 4 - box.left, plate.center.dy - box.top),
          ),
          isSameColorAs(scheme.surfaceContainerLowest),
        );
        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(plate.center.dx - box.left, plate.top - box.top),
          ),
          isSameColorAs(scheme.outline),
          reason: 'the border is the outline color',
        );
        expect(
          await paintedColorAtCenter(
            tester,
            hostBoundaryKey,
            find.text('Knock'),
          ),
          isSameColorAs(scheme.onSurface),
        );
        expect(
          countPixels(
            await paintedPixels(
              tester,
              hostBoundaryKey,
              region: tester.getRect(_glyph).shift(-box.topLeft),
            ),
            scheme.onSurface,
          ),
          greaterThan(0),
          reason: 'the thin strokes of the glyph are drawn in ink',
        );
      });

      testWidgets('cooldown has the sunken fill, a hairline border and '
          'muted texts ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _button(cooldown: _cooldown(left: 'Soon')),
            ),
            theme: theme,
            background: scheme.surface,
          ),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final plate = _drawn(tester);

        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(plate.left + 4 - box.left, plate.center.dy - box.top),
          ),
          isSameColorAs(scheme.surfaceContainerHigh),
        );
        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(plate.center.dx - box.left, plate.top - box.top),
          ),
          isSameColorAs(scheme.outlineVariant),
        );
        for (final text in ['Asked', 'Soon']) {
          expect(
            await paintedColorAtCenter(
              tester,
              hostBoundaryKey,
              find.text(text),
            ),
            isSameColorAs(scheme.onSurfaceVariant),
            reason: text,
          );
        }
      });

      testWidgets('the ring draws the share left, clockwise from the top '
          '($name)', (tester) async {
        Future<List<Color>> around(double remaining) async {
          await tester.pumpWidget(
            host(
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _button(cooldown: _cooldown(remaining: remaining)),
              ),
              theme: theme,
              background: scheme.surface,
            ),
          );
          final box = tester.getRect(find.byKey(hostBoundaryKey));
          final ring = tester.getRect(_ring).shift(-box.topLeft);
          Future<Color> at(Offset point) =>
              paintedColorAt(tester, hostBoundaryKey, point);
          const edge = AppSizes.ringStroke / 2;
          return [
            await at(ring.topCenter + const Offset(2, edge)),
            await at(ring.centerRight - const Offset(edge, 0)),
            await at(ring.bottomCenter - const Offset(2, edge)),
            await at(ring.centerLeft + const Offset(edge, 0)),
          ];
        }

        final full = await around(1);
        expect(
          full.every(
            (pixel) => isSameColorAs(scheme.primary).matches(pixel, {}),
          ),
          isTrue,
          reason: 'a full share is a full circle',
        );

        final quarter = await around(0.25);
        expect(
          isSameColorAs(scheme.primary).matches(quarter[0], {}),
          isTrue,
          reason: 'the top, where it starts',
        );
        expect(
          isSameColorAs(scheme.primary).matches(quarter[1], {}),
          isTrue,
          reason: 'the right, a quarter on',
        );
        expect(isSameColorAs(scheme.primary).matches(quarter[2], {}), isFalse);
        expect(isSameColorAs(scheme.primary).matches(quarter[3], {}), isFalse);

        final empty = await around(0);
        expect(
          empty.any(
            (pixel) => isSameColorAs(scheme.primary).matches(pixel, {}),
          ),
          isFalse,
          reason: 'nothing left, nothing drawn',
        );
      });

      testWidgets('is calm in both states: no danger color is drawn ($name)', (
        tester,
      ) async {
        for (final cooldown in [null, _cooldown(), _cooldown(remaining: 1)]) {
          await tester.pumpWidget(
            host(
              _button(cooldown: cooldown),
              theme: theme,
              background: scheme.surface,
            ),
          );
          final pixels = await paintedPixels(tester, hostBoundaryKey);

          expect(countPixels(pixels, scheme.error), 0);
          expect(countPixels(pixels, scheme.errorContainer), 0);
        }
      });

      testWidgets('keyboard focus draws a 2 px ink ring outside ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _button(),
              ),
            ),
            theme: theme,
            background: scheme.surface,
          ),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final plate = _drawn(tester);
        final probe = Offset(
          plate.center.dx - box.left,
          plate.top - box.top - 1,
        );
        expect(
          await paintedColorAt(tester, hostBoundaryKey, probe),
          isSameColorAs(scheme.surface),
          reason: 'no ring before focus',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          await paintedColorAt(tester, hostBoundaryKey, probe),
          isSameColorAs(scheme.onSurface),
        );
      });
    }
  });

  group('right to left', () {
    testWidgets('reads the same: the content is centered and the ring is a '
        'clock face', (tester) async {
      final scheme = CompappTheme.light.colorScheme;
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          host(
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _button(cooldown: _cooldown(remaining: 0.25)),
            ),
            direction: direction,
            background: scheme.surface,
          ),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final ring = tester.getRect(_ring).shift(-box.topLeft);
        const edge = AppSizes.ringStroke / 2;

        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            ring.centerRight - const Offset(edge, 0),
          ),
          isSameColorAs(scheme.primary),
          reason: '$direction: a quarter on is still the right',
        );
        expect(
          tester.getRect(_ring).center.dx,
          closeTo(_drawn(tester).center.dx, 0.5),
        );
        expect(
          tester.getRect(find.text('Asked')).center.dx,
          closeTo(_drawn(tester).center.dx, 0.5),
        );
      }
    });

    testWidgets('the button sits at the start edge', (tester) async {
      await tester.pumpWidget(
        host(
          Align(alignment: AlignmentDirectional.centerStart, child: _button()),
          direction: TextDirection.rtl,
        ),
      );

      expect(
        tester.getRect(_knock).right,
        tester.getRect(find.byKey(hostBoundaryKey)).right,
      );
    });
  });

  group('semantics', () {
    testWidgets('ready is one button named by its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_button()));

      expect(
        tester.getSemantics(_knock),
        isSemantics(
          label: "Who's home?",
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(semanticsLabels(tester), ["Who's home?"]);
      handle.dispose();
    });

    testWidgets('cooldown is one disabled button named by the sentence, '
        'and the ring and texts add nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_button(cooldown: _cooldown())));

      expect(
        tester.getSemantics(_knock),
        isSemantics(
          label: _spoken,
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
        ),
      );
      expect(
        tester
            .getSemantics(_knock)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      expect(semanticsLabels(tester), [_spoken]);
      handle.dispose();
    });

    for (final (name, wrap) in <(String, Widget Function(Widget))>[
      (
        'a labeled container',
        (child) => Semantics(container: true, label: 'Panel', child: child),
      ),
      (
        'a list view',
        (child) => SizedBox(height: 200, child: ListView(children: [child])),
      ),
      ('a card', (child) => Card(child: child)),
    ]) {
      for (final cooldown in [null, _cooldown()]) {
        final state = cooldown == null ? 'ready' : 'cooldown';
        testWidgets('$state stays its own node under $name', (tester) async {
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(host(wrap(_button(cooldown: cooldown))));

          final expected = cooldown?.semanticLabel ?? "Who's home?";
          expect(
            tester.getSemantics(_knock).getSemanticsData().label,
            expected,
          );
          expect(semanticsLabels(tester).where((label) => label == expected), [
            expected,
          ], reason: 'said once, not merged into the parent');
          handle.dispose();
        });
      }
    }
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final backgrounds = {
        'page': scheme.surface,
        'card': scheme.surfaceContainerLowest,
      };

      test('texts reach 4.5:1 in both states ($name)', () {
        expectContrast(
          {
            'ready label': (scheme.onSurface, scheme.surfaceContainerLowest),
            'cooldown label': (
              scheme.onSurfaceVariant,
              scheme.surfaceContainerHigh,
            ),
          },
          minimum: 4.5,
          reason: name,
        );
      });

      test('the glyph, the ring, the border and the focus ring reach 3:1 '
          '($name)', () {
        expectContrast(
          {
            'glyph/ready fill': (
              scheme.onSurface,
              scheme.surfaceContainerLowest,
            ),
            'ring arc/cooldown fill': (
              scheme.primary,
              scheme.surfaceContainerHigh,
            ),
            for (final background in backgrounds.entries) ...{
              'ready border/${background.key}': (
                scheme.outline,
                background.value,
              ),
              'focus ring/${background.key}': (
                scheme.onSurface,
                background.value,
              ),
            },
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const label = '¿Quién está en casa ahora mismo?';
    const asked = 'Preguntado';
    const left = '11 minutos';

    testWidgets('grows at 1.3, 1.5 and 2.0 and never cuts a word', (
      tester,
    ) async {
      for (final cooldown in [
        null,
        _cooldown(label: asked, left: left, spoken: 'Preguntado, 11 minutos'),
      ]) {
        await tester.pumpWidget(
          host(_button(label: label, cooldown: cooldown)),
        );
        final base = tester.getSize(_drawnFinder).height;

        for (final scale in [1.3, 1.5, 2.0]) {
          await tester.pumpWidget(
            host(
              _button(label: label, cooldown: cooldown),
              textScale: scale,
            ),
          );
          final reason =
              '${cooldown == null ? 'ready' : 'cooldown'} at '
              '${scale}x';
          final plate = _drawn(tester);

          expect(tester.takeException(), isNull, reason: reason);
          expect(plate.height, greaterThanOrEqualTo(base), reason: reason);
          expect(plate.width, lessThanOrEqualTo(hostWidth), reason: reason);
          for (final text in cooldown == null ? [label] : [asked, left]) {
            final box = tester.getRect(find.text(text));
            expect(box.left, greaterThanOrEqualTo(plate.left), reason: reason);
            expect(box.right, lessThanOrEqualTo(plate.right), reason: reason);
            expect(box.top, greaterThanOrEqualTo(plate.top), reason: reason);
            expect(box.bottom, lessThanOrEqualTo(plate.bottom), reason: reason);
            expectNoMidWordBreaks(
              tester,
              find.text(text),
              bold: text == asked,
              reason: reason,
            );
          }
          expect(
            cooldown == null ? tester.getSize(_glyph) : tester.getSize(_ring),
            cooldown == null
                ? const Size.square(AppSizes.glyphLg)
                : const Size.square(AppSizes.knockRing),
            reason: '$reason: the glyph and the ring keep their size',
          );
        }
      }
    });

    testWidgets('the label is scaled, never clamped, and wraps by word', (
      tester,
    ) async {
      await tester.pumpWidget(host(_button(label: label)));
      final base = tester.getSize(find.text(label)).height;

      await tester.pumpWidget(host(_button(label: label), textScale: 2));

      expect(
        tester.getSize(find.text(label)).height,
        greaterThanOrEqualTo(base * 2 - 1),
      );
      expect(
        tester.getSize(find.text(label)).height,
        greaterThanOrEqualTo(2 * 16 * 2 - 1),
        reason: 'wrapped over at least two lines',
      );
    });

    testWidgets('right to left grows the same way at 2.0', (tester) async {
      await tester.pumpWidget(
        host(
          _button(
            label: label,
            cooldown: _cooldown(label: asked, left: left),
          ),
          textScale: 2,
          direction: TextDirection.rtl,
        ),
      );

      expect(tester.takeException(), isNull);
      expectNoMidWordBreaks(tester, find.text(asked), bold: true);
      expectNoMidWordBreaks(tester, find.text(left));
    });
  });
}

Finder get _drawnFinder =>
    find.descendant(of: _knock, matching: find.byType(Material)).first;
