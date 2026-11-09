import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';

const _spokenInUse = 'Washer, in use by Carlos, 34 minutes';

Widget _beacon({
  bool inUse = true,
  String id = 'washer',
  String name = 'Washer',
  AppIcons icon = AppIcons.washer,
  String? status,
  String? label,
  VoidCallback? onTap,
}) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: ItemBeacon(
    item: ItemView(id: id, name: name, icon: icon),
    inUse: inUse,
    statusLabel: status ?? (inUse ? '34 min' : 'free'),
    semanticLabel: label ?? (inUse ? _spokenInUse : 'Washer, free'),
    onTap: onTap ?? () {},
  ),
);

Finder _key(String id) => find.byKey(Key('floorplan.item.$id'));
Finder get _button => find.byType(OutlinedButton);
Finder get _ring => find.byType(AppProgressRing);
Finder get _icon => find.byType(AppIcon);

/// The drawn plate of the button, without the invisible hit padding.
Rect _drawn(WidgetTester tester) => tester.getRect(
  find.descendant(of: _button, matching: find.byType(Material)).first,
);

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('shows the glyph of the item, its name and its status', (
      tester,
    ) async {
      await tester.pumpWidget(host(_beacon(icon: AppIcons.oven)));

      expect(find.text('Washer'), findsOneWidget);
      expect(find.text('34 min'), findsOneWidget);
      expect(tester.widget<AppIcon>(_icon).icon, AppIcons.oven);
      expect(tester.getSize(_icon), const Size.square(AppSizes.glyphMd));
    });

    testWidgets('in use: the glyph sits in a busy ring with no known end', (
      tester,
    ) async {
      await tester.pumpWidget(host(_beacon()));

      final ring = tester.widget<AppProgressRing>(_ring);
      expect(ring.tone, AppRingTone.busy);
      expect(ring.value, isNull);
      expect(ring.semanticLabel, isNull);
      expect(tester.getSize(_ring), const Size.square(AppSizes.beacon));
      expect(
        tester.getCenter(_icon),
        offsetMoreOrLessEquals(tester.getCenter(_ring), epsilon: 0.01),
      );
    });

    testWidgets('free: the glyph sits on a sunken 34 tile, no ring', (
      tester,
    ) async {
      await tester.pumpWidget(host(_beacon(inUse: false)));

      expect(_ring, findsNothing);
      final tile = find.ancestor(
        of: _icon,
        matching: find.byType(DecoratedBox),
      );
      expect(tester.getSize(tile.first), const Size.square(AppSizes.beacon));
      final decoration =
          tester.widget<DecoratedBox>(tile.first).decoration as BoxDecoration;
      expect(
        decoration.color,
        CompappTheme.light.colorScheme.surfaceContainerHigh,
      );
    });

    testWidgets('the key is built from the item id', (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              _beacon(),
              _beacon(id: 'oven', inUse: false),
            ],
          ),
        ),
      );

      expect(_key('washer'), findsOneWidget);
      expect(_key('oven'), findsOneWidget);
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;

      testWidgets('in use: name is ink, status busy ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            _beacon(status: 'Soon'),
            theme: theme,
            background: scheme.surface,
          ),
        );

        expect(
          await paintedColorAtCenter(
            tester,
            hostBoundaryKey,
            find.text('Washer'),
          ),
          isSameColorAs(scheme.onSurface),
        );
        expect(
          await paintedColorAtCenter(
            tester,
            hostBoundaryKey,
            find.text('Soon'),
          ),
          isSameColorAs(colors.busy),
        );
        expect(tester.widget<AppIcon>(_icon).color, colors.busy);
      });

      testWidgets('free: name is ink, status muted, glyph ink ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            _beacon(inUse: false, status: 'Free'),
            theme: theme,
            background: scheme.surface,
          ),
        );

        expect(
          await paintedColorAtCenter(
            tester,
            hostBoundaryKey,
            find.text('Free'),
          ),
          isSameColorAs(scheme.onSurfaceVariant),
        );
        expect(tester.widget<AppIcon>(_icon).color, scheme.onSurface);
      });

      testWidgets('is a surface chip with an outline border ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(_beacon(), theme: theme, background: scheme.surface),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final drawn = _drawn(tester);
        final middle = drawn.center.dy - box.top;

        expect(
          await paintedColorAt(tester, hostBoundaryKey, Offset(0, middle)),
          isSameColorAs(scheme.outline),
          reason: 'the border is the outline color, 3:1 on the page',
        );
        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(drawn.left - box.left + 2, middle),
          ),
          isSameColorAs(scheme.surfaceContainerLowest),
        );
      });
    }

    testWidgets('is a 10 radius plate with room for the 34 glyph', (
      tester,
    ) async {
      await tester.pumpWidget(host(_beacon()));

      final button = tester.widget<OutlinedButton>(_button);
      final shape = button.style!.shape!.resolve({})! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.sm));
      expect(
        _drawn(tester).height,
        AppSizes.minDrawn,
        reason: '4 + 34 + 4 is below the 44 minimum, which wins',
      );
    });
  });

  group('touch target', () {
    testWidgets('is 44 drawn and 48 to hit, at every state', (tester) async {
      for (final inUse in [true, false]) {
        await tester.pumpWidget(host(_beacon(inUse: inUse)));

        expect(_drawn(tester).height, greaterThanOrEqualTo(AppSizes.minDrawn));
        expect(
          tester.getSize(_button).height,
          greaterThanOrEqualTo(AppSizes.minTarget),
        );
      }
    });

    testWidgets('a tap in the padding around the plate counts', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(_beacon(onTap: () => taps++)));
      final hit = tester.getRect(_button);
      final drawn = _drawn(tester);
      expect(hit.top, lessThan(drawn.top));

      await tester.tapAt(Offset(hit.center.dx, hit.top + 0.5));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('interaction', () {
    testWidgets('a tap calls onTap once', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(_beacon(onTap: () => taps++)));

      await tester.tap(_button);
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('it takes focus and Enter and Space activate it', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(host(_beacon(onTap: () => taps++)));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        Focus.of(tester.element(find.byType(Semantics).last)).hasFocus,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(taps, 2);
    });

    for (final (name, theme) in themes) {
      testWidgets('keyboard focus draws a 2 px ink ring outside ($name)', (
        tester,
      ) async {
        final scheme = theme.colorScheme;
        await tester.pumpWidget(
          host(
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: _beacon(),
            ),
            theme: theme,
            background: scheme.surface,
          ),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final drawn = _drawn(tester);
        final probe = Offset(
          drawn.left - box.left - 1,
          drawn.center.dy - box.top,
        );
        expect(
          await paintedColorAt(tester, hostBoundaryKey, probe),
          isSameColorAs(scheme.surface),
          reason: 'no ring before focus',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        // Material tweens the shape of a button: one frame starts the tween,
        // the next one lets the ring arrive.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          await paintedColorAt(tester, hostBoundaryKey, probe),
          isSameColorAs(scheme.onSurface),
        );
      });
    }
  });

  group('motion', () {
    testWidgets('the ring breathes only when animations are on', (
      tester,
    ) async {
      await tester.pumpWidget(host(_beacon()));
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.binding.transientCallbackCount,
        greaterThan(0),
        reason: 'the breathing ticks',
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(_beacon()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'the ring stands still, so the tree settles',
      );
    });

    testWidgets('a free beacon never animates', (tester) async {
      await tester.pumpWidget(host(_beacon(inUse: false)));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('right to left', () {
    testWidgets('the glyph is at the right and the texts before it', (
      tester,
    ) async {
      await tester.pumpWidget(host(_beacon(), direction: TextDirection.rtl));

      expect(
        tester.getCenter(_icon).dx,
        greaterThan(tester.getCenter(find.text('Washer')).dx),
      );
      expect(
        tester.getRect(_ring).right,
        lessThanOrEqualTo(tester.getRect(_button).right),
      );
    });

    testWidgets('the ring is a clock face and is not mirrored', (tester) async {
      await tester.pumpWidget(host(_beacon(), direction: TextDirection.rtl));

      expect(
        tester.renderObject<RenderBox>(_ring).size,
        const Size.square(AppSizes.beacon),
      );
      expect(
        find.descendant(of: _ring, matching: find.byType(Transform)),
        findsNothing,
      );
    });
  });

  group('semantics', () {
    for (final inUse in [true, false]) {
      testWidgets('is one focusable button named by the label, '
          '${inUse ? 'in use' : 'free'}', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(_beacon(inUse: inUse)));

        final label = inUse ? _spokenInUse : 'Washer, free';
        expect(
          tester.getSemantics(_button),
          isSemantics(
            label: label,
            isButton: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        expect(semanticsLabels(tester), [
          label,
        ], reason: 'the ring, the glyph and the texts add nothing');
        handle.dispose();
      });
    }

    testWidgets('needs a spoken label', (tester) async {
      expect(() => _beacon(label: ''), throwsAssertionError);
    });

    testWidgets('a semantic tap calls onTap', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(host(_beacon(onTap: () => taps++)));

      tester.semantics.tap(find.semantics.byLabel(_spokenInUse));
      await tester.pump();

      expect(taps, 1);
      handle.dispose();
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;
      final page = scheme.surface;
      final card = scheme.surfaceContainerLowest;

      test('text reaches 4.5:1 on the chip ($name)', () {
        expectContrast(
          {
            'name/card': (scheme.onSurface, card),
            'busy status/card': (colors.busy, card),
            'free status/card': (scheme.onSurfaceVariant, card),
          },
          minimum: 4.5,
          reason: name,
        );
      });

      test('glyphs, the ring and the border reach 3:1 ($name)', () {
        expectContrast(
          {
            'busy glyph/card': (colors.busy, card),
            'busy arc/track': (colors.busy, colors.busySoft),
            'busy arc/card': (colors.busy, card),
            'free glyph/tile': (scheme.onSurface, scheme.surfaceContainerHigh),
            'border/page': (scheme.outline, page),
            'border/card': (scheme.outline, card),
            'focus ring/page': (scheme.onSurface, page),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const longName = 'Lavavajillas de la cocina grande';
    const longStatus = 'libre desde hace dos horas';

    Widget longBeacon({bool inUse = false}) => _beacon(
      inUse: inUse,
      name: longName,
      status: longStatus,
      label: 'Lavavajillas de la cocina grande, libre',
    );

    testWidgets('wraps and grows at 1.5 and 2.0, nothing clips or overflows', (
      tester,
    ) async {
      for (final inUse in [true, false]) {
        await tester.pumpWidget(host(longBeacon(inUse: inUse), width: 220));
        final base = tester.getSize(find.text(longName));

        for (final scale in [1.5, 2.0]) {
          await tester.pumpWidget(
            host(longBeacon(inUse: inUse), textScale: scale, width: 220),
          );
          final reason = '${inUse ? 'in use' : 'free'} at ${scale}x';
          final hit = tester.getRect(_button);
          final drawn = _drawn(tester);
          final name = tester.getRect(find.text(longName));
          final status = tester.getRect(find.text(longStatus));

          expect(tester.takeException(), isNull, reason: reason);
          expect(hit.width, lessThanOrEqualTo(220.01), reason: reason);
          expect(
            drawn.height,
            greaterThanOrEqualTo(AppSizes.minDrawn),
            reason: reason,
          );
          expect(
            name.height,
            greaterThanOrEqualTo(base.height * scale - 1),
            reason: '$reason: the text is scaled, never clamped',
          );
          expect(
            name.height,
            greaterThanOrEqualTo(2 * 16 * scale - 1),
            reason: '$reason: the long name wrapped over two lines or more',
          );
          for (final (label, box) in [('name', name), ('status', status)]) {
            expect(
              box.left,
              greaterThanOrEqualTo(drawn.left),
              reason: '$reason: $label inside, left',
            );
            expect(
              box.right,
              lessThanOrEqualTo(drawn.right),
              reason: '$reason: $label inside, right',
            );
            expect(
              box.top,
              greaterThanOrEqualTo(drawn.top),
              reason: '$reason: $label inside, top',
            );
            expect(
              box.bottom,
              lessThanOrEqualTo(drawn.bottom),
              reason: '$reason: $label inside, bottom',
            );
          }
          expect(
            tester.getRect(_icon).right,
            lessThanOrEqualTo(name.left),
            reason: '$reason: the text never runs under the glyph',
          );
        }
      }
    });
  });
}
