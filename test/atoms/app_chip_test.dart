import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design/src/foundation/dashed_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {ThemeData? theme, double textScale = 1}) {
  return MaterialApp(
    theme: theme ?? CompappTheme.light,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

/// The chip as drawn, without the tap target padding.
Finder get _surface => find.descendant(
  of: find.byType(FilterChip),
  matching: find.byWidgetPredicate(
    (widget) => widget is Material && widget.shape != null,
  ),
);

Material _material(WidgetTester tester) => tester.widget<Material>(_surface);

Color? _fill(WidgetTester tester) {
  final ink = tester.widget<Ink>(
    find.descendant(of: find.byType(FilterChip), matching: find.byType(Ink)),
  );
  return (ink.decoration! as ShapeDecoration).color;
}

ShapeBorder _shape(WidgetTester tester) => _material(tester).shape!;

BorderSide _side(WidgetTester tester) =>
    (_shape(tester) as OutlinedBorder).side;

/// The color the label is really painted with, read from the rendered pixels.
/// flutter_test draws text with its FlutterTest font, whose glyphs are solid
/// squares,
/// so the pixel at the center of the label is the color of the text after
/// every opacity layer Material applies.
Future<Color> _paintedLabelColor(WidgetTester tester, String label) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  final center =
      tester.getCenter(find.text(label)) -
      tester.getTopLeft(find.byKey(_boundaryKey));
  final color = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    final x = center.dx.round();
    final y = center.dy.round();
    final offset = (y * image.width + x) * 4;
    return Color.fromARGB(
      data.getUint8(offset + 3),
      data.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
    );
  });
  return color!;
}

const _boundaryKey = Key('chip-boundary');

Widget _hostBoundary(Widget child, {ThemeData? theme}) => _host(
  RepaintBoundary(key: _boundaryKey, child: child),
  theme: theme,
);

/// Whether a pointer at the middle of the chip is dispatched to the render
/// object of the Material chip.
bool _hitsMaterialChip(WidgetTester tester) {
  final chip = tester.renderObject(find.byType(FilterChip));
  final result = HitTestResult();
  tester.binding.hitTestInView(
    result,
    tester.getCenter(find.byType(FilterChip)),
    tester.view.viewId,
  );
  return result.path.any((entry) {
    final target = entry.target;
    if (target is! RenderObject) return false;
    for (RenderObject? node = target; node != null; node = node.parent) {
      if (identical(node, chip)) return true;
    }
    return false;
  });
}

void main() {
  group('size', () {
    testWidgets('is 44 tall in every state and kind, with a 48 hit area', (
      tester,
    ) async {
      for (final kind in AppChipKind.values) {
        for (final (selected, onTap) in <(bool, VoidCallback?)>[
          (false, () {}),
          (true, () {}),
          (false, null),
        ]) {
          await tester.pumpWidget(
            _host(
              AppChip(
                label: 'Kitchen',
                kind: kind,
                selected: selected,
                onTap: onTap,
              ),
            ),
          );

          final reason = '$kind selected=$selected enabled=${onTap != null}';
          expect(
            tester.getSize(_surface).height,
            AppSizes.controlMd,
            reason: reason,
          );
          expect(
            tester.getSize(find.byType(AppChip)).height,
            AppSizes.minTarget,
            reason: reason,
          );
        }
      }
    });

    testWidgets('is not a pill: the radius is radius.sm', (tester) async {
      await tester.pumpWidget(_host(AppChip(label: 'Bath', onTap: () {})));

      expect(
        (_shape(tester) as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(AppRadius.sm),
      );
    });

    testWidgets('lays out at 2x text without overflow', (tester) async {
      await tester.pumpWidget(
        _host(
          AppChip(label: 'Dishwasher', selected: true, onTap: () {}),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('look', () {
    for (final (name, theme) in [
      ('light', CompappTheme.light),
      ('dark', CompappTheme.dark),
    ]) {
      final scheme = theme.colorScheme;

      testWidgets('default is a surface with an outline border ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            AppChip(label: 'Bathroom', onTap: () {}),
            theme: theme,
          ),
        );

        expect(_fill(tester), scheme.surfaceContainerLowest);
        expect(_side(tester).color, scheme.outline);
        expect(_side(tester).width, AppSizes.hairline);
      });

      testWidgets('selected is primary-soft with a primary border ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            AppChip(label: 'Kitchen', selected: true, onTap: () {}),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        expect(_fill(tester), scheme.primaryContainer);
        expect(_side(tester).color, scheme.primary);
        expect(_side(tester).width, AppSizes.borderEmphasis);
      });

      testWidgets('disabled is flat on the ground with muted text ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(const AppChip(label: 'Terrace', onTap: null), theme: theme),
        );

        expect(_fill(tester), scheme.surface);
        expect(_side(tester).color, scheme.surfaceContainerHigh);
        final text = tester.widget<RichText>(
          find.descendant(
            of: find.text('Terrace'),
            matching: find.byType(RichText),
          ),
        );
        expect(text.text.style?.color, scheme.onSurfaceVariant);
      });
    }

    for (final (name, theme) in [
      ('light', CompappTheme.light),
      ('dark', CompappTheme.dark),
    ]) {
      final scheme = theme.colorScheme;

      testWidgets('the disabled label is really painted muted ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _hostBoundary(
            const AppChip(label: 'Terrace', onTap: null),
            theme: theme,
          ),
        );

        expect(
          await _paintedLabelColor(tester, 'Terrace'),
          isSameColorAs(scheme.onSurfaceVariant),
        );
      });

      testWidgets('the enabled label is really painted in ink ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _hostBoundary(
            AppChip(label: 'Terrace', onTap: () {}),
            theme: theme,
          ),
        );

        expect(
          await _paintedLabelColor(tester, 'Terrace'),
          isSameColorAs(scheme.onSurface),
        );
      });

      testWidgets('disabled wins over selected ($name)', (tester) async {
        await tester.pumpWidget(
          _hostBoundary(
            const AppChip(label: 'Kitchen', selected: true, onTap: null),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        expect(_fill(tester), scheme.surface);
        expect(_side(tester).color, scheme.surfaceContainerHigh);
        expect(_side(tester).width, AppSizes.hairline);
        expect(
          await _paintedLabelColor(tester, 'Kitchen'),
          isSameColorAs(scheme.onSurfaceVariant),
        );
        expect(find.byType(AppIcon), findsOneWidget);
      });
    }

    testWidgets('a disabled selected chip is still 44 tall', (tester) async {
      await tester.pumpWidget(
        _host(const AppChip(label: 'Kitchen', selected: true, onTap: null)),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(_surface).height, AppSizes.controlMd);
    });

    testWidgets('pads the label 12 from the edge, 8 from the check', (
      tester,
    ) async {
      await tester.pumpWidget(_host(AppChip(label: 'Kitchen', onTap: () {})));
      final plain = tester.getRect(_surface);
      expect(
        tester.getTopLeft(find.text('Kitchen')).dx - plain.left,
        AppSpacing.sm + AppSpacing.xs + AppSizes.hairline,
      );

      await tester.pumpWidget(
        _host(AppChip(label: 'Kitchen', selected: true, onTap: () {})),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('Kitchen')).dx -
            tester.getTopRight(find.byType(AppIcon)).dx,
        AppSpacing.sm,
      );
    });

    testWidgets('a raw FilterChip keeps its own label padding and check', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FilterChip(
            label: const Text('Raw'),
            selected: true,
            onSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.showCheckmark, isNull);
      expect(chip.labelPadding, isNull);
    });

    testWidgets('selected shows a check, unselected does not', (tester) async {
      await tester.pumpWidget(_host(AppChip(label: 'Kitchen', onTap: () {})));
      expect(find.byType(AppIcon), findsNothing);

      await tester.pumpWidget(
        _host(AppChip(label: 'Kitchen', selected: true, onTap: () {})),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<AppIcon>(find.byType(AppIcon));
      expect(icon.icon, AppIcons.check);
      expect(
        tester.getSize(find.byType(AppIcon)),
        const Size.square(AppSizes.glyphMd),
      );
      expect(
        tester.getTopLeft(find.byType(AppIcon)).dx,
        lessThan(tester.getTopLeft(find.text('Kitchen')).dx),
      );
    });

    testWidgets('only the item kind has a dashed border', (tester) async {
      for (final kind in AppChipKind.values) {
        await tester.pumpWidget(
          _host(AppChip(label: 'Washer', kind: kind, onTap: () {})),
        );

        expect(
          _shape(tester) is DashedBorder,
          kind == AppChipKind.item,
          reason: '$kind',
        );
      }
    });

    testWidgets('the dashed border keeps the side color and width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppChip(
            label: 'Washer',
            kind: AppChipKind.item,
            selected: true,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_side(tester).color, CompappTheme.light.colorScheme.primary);
      expect(_side(tester).width, AppSizes.borderEmphasis);
    });
  });

  group('shape animation', () {
    /// The border the chip's Material is drawing this frame, which is not the
    /// `shape` it was given while the shape animates to a new one.
    ShapeBorder drawnShape(WidgetTester tester) {
      final clipper = tester
          .widget<PhysicalShape>(
            find.descendant(
              of: find.byType(FilterChip),
              matching: find.byType(PhysicalShape),
            ),
          )
          .clipper;
      return (clipper as ShapeBorderClipper).shape;
    }

    testWidgets('an item chip stays dashed while it is toggled', (
      tester,
    ) async {
      Widget chip({required bool selected}) => _host(
        AppChip(
          label: 'Washer',
          kind: AppChipKind.item,
          selected: selected,
          onTap: () {},
        ),
      );

      await tester.pumpWidget(chip(selected: false));
      await tester.pumpWidget(chip(selected: true));

      for (final milliseconds in [10, 40, 50, 100]) {
        await tester.pump(Duration(milliseconds: milliseconds));
        expect(
          drawnShape(tester),
          isA<DashedBorder>(),
          reason: 'after $milliseconds more ms',
        );
      }
      await tester.pumpAndSettle();
      expect(drawnShape(tester), isA<DashedBorder>());
    });
  });

  group('taps', () {
    testWidgets('calls onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(AppChip(label: 'Kitchen', onTap: () => taps++)),
      );

      await tester.tap(find.byType(AppChip));

      expect(taps, 1);
    });

    testWidgets(
      'a pointer at a disabled chip never reaches the Material chip',
      (tester) async {
        await tester.pumpWidget(
          _host(const AppChip(label: 'Terrace', onTap: null)),
        );

        expect(_hitsMaterialChip(tester), isFalse);
      },
    );

    testWidgets('a pointer at an enabled chip reaches the Material chip', (
      tester,
    ) async {
      await tester.pumpWidget(_host(AppChip(label: 'Terrace', onTap: () {})));

      expect(_hitsMaterialChip(tester), isTrue);
    });

    testWidgets('tapping a disabled chip draws no ink', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppChip(label: 'Terrace', onTap: null),
              AppChip(label: 'Kitchen', onTap: () => taps++),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Terrace'), warnIfMissed: false);
      await tester.tap(find.text('Kitchen'));

      expect(taps, 1, reason: 'the enabled neighbor still takes taps');
    });

    testWidgets('a disabled chip takes no keyboard focus', (tester) async {
      await tester.pumpWidget(
        _host(const AppChip(label: 'Terrace', onTap: null)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<AppChip>(),
        isNull,
      );
    });

    testWidgets('an enabled chip is focusable and Enter toggles it', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(AppChip(label: 'Kitchen', onTap: () => taps++)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(taps, 1);
    });
  });

  group('semantics', () {
    testWidgets('is a button named by its label with a selected state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(AppChip(label: 'Kitchen', selected: true, onTap: () {})),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(FilterChip)),
        isSemantics(
          label: 'Kitchen',
          isButton: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('is not selected by default and disabled without onTap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const AppChip(label: 'Terrace', onTap: null)),
      );

      expect(
        tester.getSemantics(find.byType(FilterChip)),
        isSemantics(
          label: 'Terrace',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('a chip is its own node inside a labeled group', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final onTap in <VoidCallback?>[null, () {}]) {
        await tester.pumpWidget(
          _host(
            Semantics(
              container: true,
              label: 'Group',
              child: AppChip(label: 'Attic', onTap: onTap),
            ),
          ),
        );

        expect(
          tester.getSemantics(find.byType(FilterChip)).label,
          'Attic',
          reason: 'enabled: ${onTap != null}',
        );
        expect(find.bySemanticsLabel('Group'), findsOneWidget);
      }
      handle.dispose();
    });

    testWidgets('the check icon adds no label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(AppChip(label: 'Kitchen', selected: true, onTap: () {})),
      );
      await tester.pumpAndSettle();

      expect(tester.getSemantics(find.byType(FilterChip)).label, 'Kitchen');
      handle.dispose();
    });
  });
}
