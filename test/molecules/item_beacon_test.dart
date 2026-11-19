import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';

const _spokenInUse = 'Washer, in use by Carlos, 34 minutes';

Widget _beacon({
  ItemStatus status = ItemStatus.others,
  String id = 'washer',
  String name = 'Washer',
  AppIcons icon = AppIcons.washer,
  String? statusText,
  String? label,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  bool busy = false,
  String? busyLabel,
}) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: ItemBeacon(
    item: ItemView(id: id, name: name, icon: icon),
    status: status,
    statusLabel: statusText ?? (status == ItemStatus.free ? 'free' : '34 min'),
    semanticLabel:
        label ?? (status == ItemStatus.free ? 'Washer, free' : _spokenInUse),
    onTap: onTap ?? () {},
    onLongPress: onLongPress,
    busy: busy,
    busySemanticLabel: busyLabel,
  ),
);

/// The states in which somebody has the item.
const List<ItemStatus> _used = [ItemStatus.mine, ItemStatus.others];

Finder _key(String id) => find.byKey(Key('floorplan.item.$id'));
Finder get _button => find.byType(OutlinedButton);
Finder get _ring => find.byType(AppProgressRing);
Finder get _icon => find.byType(AppIcon).first;
Finder get _statusMarker => find.byType(AppIcon).last;

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

    for (final status in _used) {
      testWidgets(
        '${status.name}: the glyph sits in a busy ring with no known end',
        (tester) async {
          await tester.pumpWidget(host(_beacon(status: status)));

          final ring = tester.widget<AppProgressRing>(_ring);
          expect(ring.tone, AppRingTone.busy);
          expect(ring.value, isNull);
          expect(ring.semanticLabel, isNull);
          expect(tester.getSize(_ring), const Size.square(AppSizes.beacon));
          expect(
            tester.getCenter(_icon),
            offsetMoreOrLessEquals(tester.getCenter(_ring), epsilon: 0.01),
          );
        },
      );
    }

    testWidgets('free: no marker; mine a check; others a lock, same size', (
      tester,
    ) async {
      await tester.pumpWidget(host(_beacon(status: ItemStatus.free)));
      expect(find.byType(AppIcon), findsOneWidget);

      await tester.pumpWidget(host(_beacon(status: ItemStatus.mine)));
      expect(tester.widget<AppIcon>(_statusMarker).icon, AppIcons.check);
      expect(
        tester.getSize(_statusMarker),
        const Size.square(AppSizes.glyphMd),
      );
      final mineHeight = tester.getSize(_button).height;

      await tester.pumpWidget(host(_beacon()));
      expect(tester.widget<AppIcon>(_statusMarker).icon, AppIcons.occupied);
      expect(tester.getSize(_button).height, mineHeight);
    });

    testWidgets('the marker sits before the status text', (tester) async {
      await tester.pumpWidget(host(_beacon(status: ItemStatus.mine)));

      expect(
        tester.getRect(_statusMarker).right,
        lessThanOrEqualTo(tester.getRect(find.text('34 min')).left),
      );
    });

    testWidgets('free: the glyph sits on a sunken 34 tile, no ring', (
      tester,
    ) async {
      await tester.pumpWidget(host(_beacon(status: ItemStatus.free)));

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
              _beacon(id: 'oven', status: ItemStatus.free),
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

      for (final status in _used) {
        testWidgets('${status.name}: name is ink, status busy ($name)', (
          tester,
        ) async {
          await tester.pumpWidget(
            host(
              _beacon(status: status, statusText: 'Soon'),
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
          expect(tester.widget<AppIcon>(_statusMarker).color, colors.busy);
        });
      }

      testWidgets('free: name is ink, status muted, glyph ink ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            _beacon(status: ItemStatus.free, statusText: 'Free'),
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
      for (final status in ItemStatus.values) {
        await tester.pumpWidget(host(_beacon(status: status)));

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

  group('long press', () {
    testWidgets('calls onLongPress and not onTap', (tester) async {
      var taps = 0;
      var longs = 0;
      await tester.pumpWidget(
        host(_beacon(onTap: () => taps++, onLongPress: () => longs++)),
      );

      await tester.longPress(_button);
      await tester.pump();

      expect(longs, 1);
      expect(taps, 0);
    });

    testWidgets('a semantic long press calls onLongPress', (tester) async {
      final handle = tester.ensureSemantics();
      var longs = 0;
      await tester.pumpWidget(host(_beacon(onLongPress: () => longs++)));

      tester.semantics.longPress(find.semantics.byLabel(_spokenInUse));
      await tester.pump();

      expect(longs, 1);
      handle.dispose();
    });
  });

  group('busy', () {
    testWidgets('shows a primary ring around the glyph, free or used', (
      tester,
    ) async {
      for (final status in ItemStatus.values) {
        await tester.pumpWidget(host(_beacon(status: status, busy: true)));

        final ring = tester.widget<AppProgressRing>(_ring);
        expect(ring.tone, AppRingTone.primary, reason: status.name);
        expect(ring.value, isNull);
        expect(tester.getSize(_ring), const Size.square(AppSizes.beacon));
      }
    });

    testWidgets('keeps its size, whatever the status', (tester) async {
      for (final status in ItemStatus.values) {
        await tester.pumpWidget(host(_beacon(status: status)));
        final idle = tester.getSize(_button);
        final idleDrawn = _drawn(tester).size;

        await tester.pumpWidget(host(_beacon(status: status, busy: true)));

        expect(tester.getSize(_button), idle, reason: status.name);
        expect(_drawn(tester).size, idleDrawn, reason: status.name);
      }
    });

    testWidgets('ignores taps, long presses and the keyboard', (tester) async {
      var taps = 0;
      var longs = 0;
      await tester.pumpWidget(
        host(
          _beacon(busy: true, onTap: () => taps++, onLongPress: () => longs++),
        ),
      );

      await tester.tap(_button, warnIfMissed: false);
      await tester.longPress(_button, warnIfMissed: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(taps, 0);
      expect(longs, 0);
    });

    testWidgets('keeps the element tree and the focus when it starts', (
      tester,
    ) async {
      await tester.pumpWidget(host(_beacon()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focus = Focus.of(tester.element(find.byType(Semantics).last));
      expect(focus.hasFocus, isTrue);

      await tester.pumpWidget(host(_beacon(busy: true)));

      expect(
        Focus.of(tester.element(find.byType(Semantics).last)).hasFocus,
        isTrue,
      );
    });

    testWidgets('is still one button, with the busy label as live value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_beacon(busy: true, busyLabel: 'Updating')));

      expect(
        tester.getSemantics(_button),
        isSemantics(
          label: _spokenInUse,
          value: 'Updating',
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          isLiveRegion: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('says nothing extra when it is not busy', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_beacon(busyLabel: 'Updating')));

      expect(
        tester.getSemantics(_button),
        isSemantics(
          label: _spokenInUse,
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a semantic tap while busy does nothing', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(host(_beacon(busy: true, onTap: () => taps++)));

      tester.semantics.performAction(
        find.semantics.byLabel(_spokenInUse),
        SemanticsAction.tap,
        checkForAction: false,
      );
      await tester.pump();

      expect(taps, 0);
      handle.dispose();
    });

    testWidgets('the ring stands still when animations are off', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(_beacon(status: ItemStatus.free, busy: true)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.binding.transientCallbackCount, 0);
    });
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
      await tester.pumpWidget(host(_beacon(status: ItemStatus.free)));
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
    for (final status in ItemStatus.values) {
      testWidgets('is one focusable button named by the label, '
          '${status.name}', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(_beacon(status: status)));

        final label = status == ItemStatus.free ? 'Washer, free' : _spokenInUse;
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

    Widget longBeacon({ItemStatus status = ItemStatus.free}) => _beacon(
      status: status,
      name: longName,
      statusText: longStatus,
      label: 'Lavavajillas de la cocina grande, libre',
    );

    testWidgets('wraps and grows at 1.5 and 2.0, nothing clips or overflows', (
      tester,
    ) async {
      for (final kind in ItemStatus.values) {
        await tester.pumpWidget(host(longBeacon(status: kind), width: 220));
        final base = tester.getSize(find.text(longName));

        for (final scale in [1.5, 2.0]) {
          await tester.pumpWidget(
            host(longBeacon(status: kind), textScale: scale, width: 220),
          );
          final reason = '${kind.name} at ${scale}x';
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
