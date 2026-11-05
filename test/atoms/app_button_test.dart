import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  Widget child, {
  ThemeData? theme,
  bool disableAnimations = false,
  double width = 360,
}) {
  return MaterialApp(
    theme: theme ?? CompappTheme.light,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: disableAnimations),
      child: app!,
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

/// The Material of the button itself, without its tap target padding.
Finder _surface(AppButtonVariant variant) {
  final type = switch (variant) {
    AppButtonVariant.primary || AppButtonVariant.danger => FilledButton,
    AppButtonVariant.secondary => OutlinedButton,
    AppButtonVariant.ghost => TextButton,
  };
  return find.descendant(
    of: find.byType(type),
    matching: find.byWidgetPredicate(
      (widget) => widget is Material && widget.type == MaterialType.button,
    ),
  );
}

Color? _fill(WidgetTester tester, AppButtonVariant variant) =>
    tester.widget<Material>(_surface(variant)).color;

Finder get _spinner => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_Spinner',
);

bool _focusInsideButton() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<AppButton>() !=
    null;

/// The ring (the arcs) a spinner paints, in the box it is given.
({Size box, double ring}) _spinnerGeometry(WidgetTester tester) {
  final paint = find
      .descendant(of: _spinner, matching: find.byType(CustomPaint))
      .first;
  double? ring;
  expect(
    tester.renderObject(paint),
    paints..something((method, arguments) {
      if (method == #drawArc) ring = (arguments[0] as Rect).width;
      return method == #drawArc;
    }),
  );
  return (box: tester.getSize(paint), ring: ring!);
}

void main() {
  group('variants', () {
    for (final (name, theme) in [
      ('light', CompappTheme.light),
      ('dark', CompappTheme.dark),
    ]) {
      final scheme = theme.colorScheme;

      testWidgets('primary is the primary fill ($name)', (tester) async {
        await tester.pumpWidget(
          _host(
            AppButton(label: 'Send', onPressed: () {}),
            theme: theme,
          ),
        );

        expect(_fill(tester, AppButtonVariant.primary), scheme.primary);
      });

      testWidgets(
        'secondary is a surface fill with an outline border ($name)',
        (tester) async {
          await tester.pumpWidget(
            _host(
              AppButton(
                label: 'Draw again',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              theme: theme,
            ),
          );

          expect(
            _fill(tester, AppButtonVariant.secondary),
            scheme.surfaceContainerLowest,
          );
          final shape =
              tester
                      .widget<Material>(_surface(AppButtonVariant.secondary))
                      .shape!
                  as RoundedRectangleBorder;
          expect(shape.side.color, scheme.outline);
        },
      );

      testWidgets('ghost has no fill ($name)', (tester) async {
        await tester.pumpWidget(
          _host(
            AppButton(
              label: 'Mark all as read',
              variant: AppButtonVariant.ghost,
              onPressed: () {},
            ),
            theme: theme,
          ),
        );

        expect(_fill(tester, AppButtonVariant.ghost), Colors.transparent);
      });

      testWidgets('danger is the error fill ($name)', (tester) async {
        await tester.pumpWidget(
          _host(
            AppButton(
              label: 'Delete',
              variant: AppButtonVariant.danger,
              onPressed: () {},
            ),
            theme: theme,
          ),
        );

        expect(_fill(tester, AppButtonVariant.danger), scheme.error);
      });

      testWidgets('danger is soft with error text when disabled ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            const AppButton(
              label: 'Delete',
              variant: AppButtonVariant.danger,
              onPressed: null,
            ),
            theme: theme,
          ),
        );

        expect(_fill(tester, AppButtonVariant.danger), scheme.errorContainer);
        final text = tester.widget<DefaultTextStyle>(
          find
              .descendant(
                of: _surface(AppButtonVariant.danger),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        );
        expect(text.style.color, scheme.error);
      });

      testWidgets('disabled wins over pressed ($name)', (tester) async {
        for (final variant in [
          AppButtonVariant.primary,
          AppButtonVariant.danger,
        ]) {
          final controller = WidgetStatesController({WidgetState.pressed});
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            _host(
              AppButton(
                label: 'Go',
                variant: variant,
                onPressed: null,
                statesController: controller,
              ),
              theme: theme,
            ),
          );

          expect(
            _fill(tester, variant),
            variant == AppButtonVariant.danger
                ? scheme.errorContainer
                : scheme.surfaceContainerHigh,
            reason: '$variant',
          );
        }
      });

      testWidgets('disabled primary is sunken with muted text ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(const AppButton(label: 'Send', onPressed: null), theme: theme),
        );

        expect(
          _fill(tester, AppButtonVariant.primary),
          scheme.surfaceContainerHigh,
        );
      });
    }
  });

  group('style', () {
    testWidgets('the label is the label-lg token, 15/22 at weight 600', (
      tester,
    ) async {
      await tester.pumpWidget(_host(AppButton(label: 'Go', onPressed: () {})));

      final style = tester
          .widget<RichText>(
            find.descendant(
              of: find.byType(AppButton),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!;
      expect(style.fontSize, AppTypography.labelLg.fontSize);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.height, AppTypography.labelLg.height);
    });

    testWidgets('draws no ripple or ink overlay, only the pressed fill', (
      tester,
    ) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          _host(AppButton(label: 'Go', variant: variant, onPressed: () {})),
        );
        final style = switch (variant) {
          AppButtonVariant.primary || AppButtonVariant.danger =>
            tester.widget<FilledButton>(find.byType(FilledButton)).style!,
          AppButtonVariant.secondary =>
            tester.widget<OutlinedButton>(find.byType(OutlinedButton)).style!,
          AppButtonVariant.ghost =>
            tester.widget<TextButton>(find.byType(TextButton)).style!,
        };

        expect(style.splashFactory, NoSplash.splashFactory, reason: '$variant');
        expect(
          style.overlayColor!.resolve({WidgetState.pressed}),
          Colors.transparent,
          reason: '$variant',
        );
      }
    });

    testWidgets('focus is an ink ring outside the shape', (tester) async {
      for (final variant in AppButtonVariant.values) {
        final controller = WidgetStatesController({WidgetState.focused});
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            AppButton(
              label: 'Go',
              variant: variant,
              onPressed: () {},
              statesController: controller,
            ),
          ),
        );

        final shape =
            tester.widget<Material>(_surface(variant)).shape!
                as RoundedRectangleBorder;
        expect(
          shape.side,
          BorderSide(
            color: CompappTheme.light.colorScheme.onSurface,
            width: AppSizes.borderEmphasis,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          reason: '$variant',
        );
        expect(
          tester.getSize(_surface(variant)).height,
          variant == AppButtonVariant.ghost
              ? AppSizes.controlMd
              : AppSizes.controlLg,
          reason: '$variant keeps its size when focused',
        );
      }
    });

    testWidgets('a focused primary button keeps 3:1 for its ring on the page', (
      tester,
    ) async {
      for (final theme in [CompappTheme.light, CompappTheme.dark]) {
        final scheme = theme.colorScheme;
        final lighter = scheme.onSurface.computeLuminance();
        final page = scheme.surface.computeLuminance();
        final ratio =
            (lighter > page ? lighter + 0.05 : page + 0.05) /
            (lighter > page ? page + 0.05 : lighter + 0.05);
        expect(ratio, greaterThanOrEqualTo(3));
      }
    });
  });

  group('pressed fills', () {
    testWidgets('disabled wins over pressed for every variant', (tester) async {
      final scheme = CompappTheme.light.colorScheme;
      final disabledText = {
        AppButtonVariant.primary: scheme.onSurfaceVariant,
        AppButtonVariant.secondary: scheme.onSurfaceVariant,
        AppButtonVariant.ghost: scheme.onSurfaceVariant,
        AppButtonVariant.danger: scheme.error,
      };
      final disabledFill = {
        AppButtonVariant.primary: scheme.surfaceContainerHigh,
        AppButtonVariant.secondary: scheme.surfaceContainerLowest,
        AppButtonVariant.ghost: Colors.transparent,
        AppButtonVariant.danger: scheme.errorContainer,
      };
      for (final variant in AppButtonVariant.values) {
        final controller = WidgetStatesController({WidgetState.pressed});
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            AppButton(
              label: 'Go',
              variant: variant,
              onPressed: null,
              statesController: controller,
            ),
          ),
        );

        expect(
          _fill(tester, variant),
          disabledFill[variant],
          reason: '$variant',
        );
        final text = tester.widget<RichText>(
          find.descendant(
            of: find.byType(AppButton),
            matching: find.byType(RichText),
          ),
        );
        expect(
          text.text.style?.color,
          disabledText[variant],
          reason: '$variant keeps the disabled text color',
        );
      }
    });

    testWidgets('a pressed ghost button turns its text to ink', (tester) async {
      final controller = WidgetStatesController({WidgetState.pressed});
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Go',
            variant: AppButtonVariant.ghost,
            onPressed: () {},
            statesController: controller,
          ),
        ),
      );

      final text = tester.widget<RichText>(
        find.descendant(
          of: find.byType(AppButton),
          matching: find.byType(RichText),
        ),
      );
      expect(text.text.style?.color, CompappTheme.light.colorScheme.onSurface);
    });
  });

  group('large label', () {
    testWidgets('every button grows with a 2x label and keeps its minimum', (
      tester,
    ) async {
      for (final (variant, size, minimum) in [
        (AppButtonVariant.primary, AppButtonSize.lg, AppSizes.controlLg),
        (AppButtonVariant.primary, AppButtonSize.md, AppSizes.controlMd),
        (AppButtonVariant.ghost, AppButtonSize.md, AppSizes.controlMd),
      ]) {
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: CompappTheme.light,
              builder: (context, app) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: app!,
              ),
              home: Scaffold(
                body: Center(
                  child: AppButton(
                    label: 'Go',
                    variant: variant,
                    size: size,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          );

          final height = tester.getSize(_surface(variant)).height;
          final label = tester.getSize(find.text('Go')).height;
          expect(
            height,
            greaterThanOrEqualTo(minimum),
            reason: '$variant $size at ${scale}x keeps its minimum',
          );
          expect(
            height,
            greaterThanOrEqualTo(label + AppSpacing.sm * 2),
            reason: '$variant $size at ${scale}x has room around the label',
          );
          if (scale == 1) expect(height, minimum);
        }
      }
    });

    testWidgets(
      'the focus ring is not clipped by the button or a tight parent',
      (tester) async {
        final controller = WidgetStatesController({WidgetState.focused});
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            SizedBox(
              height: AppSizes.controlLg,
              child: AppButton(
                label: 'Go',
                onPressed: () {},
                statesController: controller,
              ),
            ),
          ),
        );

        expect(
          tester
              .widget<Material>(_surface(AppButtonVariant.primary))
              .clipBehavior,
          Clip.none,
        );
        expect(
          find.ancestor(
            of: find.byType(FilledButton),
            matching: find.byType(ClipRect),
          ),
          findsNothing,
        );
      },
    );
  });

  group('size', () {
    testWidgets('is 52 tall large and 44 tall medium, with a 48 hit area', (
      tester,
    ) async {
      for (final (variant, size, drawn, hit) in [
        (AppButtonVariant.primary, null, 52.0, 52.0),
        (AppButtonVariant.primary, AppButtonSize.md, 44.0, 48.0),
        (AppButtonVariant.secondary, AppButtonSize.lg, 52.0, 52.0),
        (AppButtonVariant.ghost, null, 44.0, 48.0),
        (AppButtonVariant.ghost, AppButtonSize.lg, 52.0, 52.0),
        (AppButtonVariant.danger, AppButtonSize.md, 44.0, 48.0),
      ]) {
        await tester.pumpWidget(
          _host(
            AppButton(
              label: 'Go',
              variant: variant,
              size: size,
              onPressed: () {},
            ),
          ),
        );

        expect(
          tester.getSize(_surface(variant)).height,
          drawn,
          reason: '$variant $size drawn',
        );
        expect(
          tester.getSize(find.byType(AppButton)).height,
          hit,
          reason: '$variant $size hit area',
        );
      }
    });

    testWidgets('uses token radii: md for large, sm for medium', (
      tester,
    ) async {
      for (final (size, radius) in [
        (AppButtonSize.lg, AppRadius.md),
        (AppButtonSize.md, AppRadius.sm),
      ]) {
        await tester.pumpWidget(
          _host(AppButton(label: 'Go', size: size, onPressed: () {})),
        );

        final shape =
            tester.widget<Material>(_surface(AppButtonVariant.primary)).shape!
                as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(radius));
      }
    });

    testWidgets('keeps the size while loading', (tester) async {
      await tester.pumpWidget(
        _host(AppButton(label: 'Send', onPressed: () {})),
      );
      final idle = tester.getSize(find.byType(AppButton));

      await tester.pumpWidget(
        _host(
          AppButton(label: 'Send', onPressed: () {}, loading: true),
          disableAnimations: true,
        ),
      );

      expect(tester.getSize(find.byType(AppButton)), idle);
    });
  });

  group('taps', () {
    testWidgets('calls onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(AppButton(label: 'Send', onPressed: () => taps++)),
      );

      await tester.tap(find.byType(AppButton));

      expect(taps, 1);
    });

    testWidgets('a null onPressed disables the button', (tester) async {
      await tester.pumpWidget(
        _host(const AppButton(label: 'Send', onPressed: null)),
      );

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
        isFalse,
      );
    });

    testWidgets('Enter and Space press a focused button', (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        _host(AppButton(label: 'Send', onPressed: () => presses++)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusInsideButton(), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);

      expect(presses, 2);
    });

    testWidgets('loading keeps the label and the spinner', (tester) async {
      await tester.pumpWidget(
        _host(
          AppButton(label: 'Sending', onPressed: () {}, loading: true),
          disableAnimations: true,
        ),
      );

      expect(find.text('Sending'), findsOneWidget);
      expect(_spinner, findsOneWidget);
    });

    testWidgets('loading blocks a pointer tap', (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Sending',
            onPressed: () => presses++,
            loading: true,
          ),
          disableAnimations: true,
        ),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);

      expect(presses, 0);
    });

    testWidgets('loading blocks Enter and Space on the focused button', (
      tester,
    ) async {
      var presses = 0;
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Sending',
            onPressed: () => presses++,
            loading: true,
          ),
          disableAnimations: true,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusInsideButton(), isTrue, reason: 'it stays focusable');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);

      expect(presses, 0);
    });

    testWidgets('loading blocks the semantic tap action', (tester) async {
      final handle = tester.ensureSemantics();
      var presses = 0;
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Sending',
            onPressed: () => presses++,
            loading: true,
          ),
          disableAnimations: true,
        ),
      );

      tester.semantics.performAction(
        find.semantics.byLabel('Sending'),
        SemanticsAction.tap,
        checkForAction: false,
      );

      expect(presses, 0);
      handle.dispose();
    });

    testWidgets('a press on a loading button draws no pressed fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton(label: 'Sending', onPressed: () {}, loading: true),
          disableAnimations: true,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pump();

      expect(
        _fill(tester, AppButtonVariant.primary),
        CompappTheme.light.colorScheme.primary,
      );
      await gesture.up();
    });

    testWidgets('toggling loading keeps focus, the node and the button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Widget build({required bool loading}) => _host(
        AppButton(
          label: 'Send',
          loadingSemanticLabel: 'Loading',
          onPressed: () {},
          loading: loading,
        ),
        disableAnimations: true,
      );
      await tester.pumpWidget(build(loading: false));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final element = tester.element(find.byType(FilledButton));
      final nodeId = tester.getSemantics(find.byType(FilledButton)).id;
      expect(_focusInsideButton(), isTrue);

      await tester.pumpWidget(build(loading: true));
      expect(_focusInsideButton(), isTrue, reason: 'focus kept going on');
      expect(tester.element(find.byType(FilledButton)), same(element));
      expect(tester.getSemantics(find.byType(FilledButton)).id, nodeId);

      await tester.pumpWidget(build(loading: false));
      expect(_focusInsideButton(), isTrue, reason: 'focus kept going off');
      expect(tester.element(find.byType(FilledButton)), same(element));
      expect(tester.getSemantics(find.byType(FilledButton)).id, nodeId);
      handle.dispose();
    });

    testWidgets('loading keeps the default colors', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppButton(label: 'Send', onPressed: null, loading: true),
          disableAnimations: true,
        ),
      );

      expect(
        _fill(tester, AppButtonVariant.primary),
        CompappTheme.light.colorScheme.primary,
      );
    });
  });

  group('icon', () {
    testWidgets('shows the icon before the label at the glyph size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(AppButton(label: 'Add', icon: AppIcons.add, onPressed: () {})),
      );

      final icon = find.byType(AppIcon);
      expect(icon, findsOneWidget);
      expect(tester.getSize(icon), const Size.square(AppSizes.glyphLg));
      expect(
        tester.getTopLeft(icon).dx,
        lessThan(tester.getTopLeft(find.text('Add')).dx),
      );
    });

    testWidgets('uses the medium glyph size for a medium button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Add',
            icon: AppIcons.add,
            size: AppButtonSize.md,
            onPressed: () {},
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AppIcon)),
        const Size.square(AppSizes.glyphMd),
      );
    });

    testWidgets('the spinner replaces the icon while loading', (tester) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Add',
            icon: AppIcons.add,
            onPressed: () {},
            loading: true,
          ),
          disableAnimations: true,
        ),
      );

      expect(find.byType(AppIcon), findsNothing);
      expect(_spinner, findsOneWidget);
    });
  });

  group('pressed', () {
    testWidgets('a states controller renders the pressed fills', (
      tester,
    ) async {
      final ink = CompappTheme.light.colorScheme.onSurface;
      final scheme = CompappTheme.light.colorScheme;
      for (final (variant, expected) in [
        (
          AppButtonVariant.primary,
          Color.alphaBlend(
            ink.withValues(alpha: AppStateLayers.pressedPrimary),
            scheme.primary,
          ),
        ),
        (
          AppButtonVariant.secondary,
          Color.alphaBlend(
            ink.withValues(alpha: AppStateLayers.pressedSecondary),
            scheme.surfaceContainerLowest,
          ),
        ),
        (AppButtonVariant.ghost, scheme.primaryContainer),
        (
          AppButtonVariant.danger,
          Color.alphaBlend(
            ink.withValues(alpha: AppStateLayers.pressedDanger),
            scheme.error,
          ),
        ),
      ]) {
        final controller = WidgetStatesController({WidgetState.pressed});
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            AppButton(
              label: 'Go',
              variant: variant,
              onPressed: () {},
              statesController: controller,
            ),
          ),
        );

        expect(_fill(tester, variant), expected, reason: '$variant');
      }
    });

    testWidgets('a real press draws the same fill', (tester) async {
      await tester.pumpWidget(_host(AppButton(label: 'Go', onPressed: () {})));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pump();

      final scheme = CompappTheme.light.colorScheme;
      expect(
        _fill(tester, AppButtonVariant.primary),
        Color.alphaBlend(
          scheme.onSurface.withValues(alpha: AppStateLayers.pressedPrimary),
          scheme.primary,
        ),
      );

      await gesture.up();
    });
  });

  group('semantics', () {
    testWidgets('is a button named by its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(AppButton(label: 'Send request', onPressed: () {})),
      );

      expect(
        tester.getSemantics(find.byType(FilledButton)),
        isSemantics(
          label: 'Send request',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('is a disabled button when onPressed is null', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const AppButton(label: 'Send request', onPressed: null)),
      );

      expect(
        tester.getSemantics(find.byType(FilledButton)),
        isSemantics(
          label: 'Send request',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('semanticLabel replaces the label and keeps the tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Add',
            icon: AppIcons.add,
            semanticLabel: 'Add a chore',
            onPressed: () => taps++,
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(FilledButton));
      expect(
        node,
        isSemantics(
          label: 'Add a chore',
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(find.bySemanticsLabel('Add'), findsNothing);

      tester.semantics.tap(find.semantics.byLabel('Add a chore'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('loading keeps the label, adds the value in a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Sending',
            loadingSemanticLabel: 'Loading',
            onPressed: () {},
            loading: true,
          ),
          disableAnimations: true,
        ),
      );

      expect(
        tester.getSemantics(find.byType(FilledButton)),
        isSemantics(
          label: 'Sending',
          value: 'Loading',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          isLiveRegion: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the icon adds no label or node of its own', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(AppButton(label: 'Add', icon: AppIcons.add, onPressed: () {})),
      );

      final node = tester.getSemantics(find.byType(FilledButton));
      expect(node.label, 'Add');
      expect(node.hasChildren, isFalse);
      handle.dispose();
    });
  });

  group('spinner', () {
    testWidgets('draws a 13.5 ring in an 18 box beside a large label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton(label: 'Go', onPressed: () {}, loading: true),
          disableAnimations: true,
        ),
      );

      final geometry = _spinnerGeometry(tester);
      expect(geometry.box, const Size.square(AppSizes.glyphLg));
      expect(geometry.ring, AppSizes.spinnerLg);
    });

    testWidgets('draws a 12 ring in a 16 box beside a medium label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Go',
            size: AppButtonSize.md,
            onPressed: () {},
            loading: true,
          ),
          disableAnimations: true,
        ),
      );

      final geometry = _spinnerGeometry(tester);
      expect(geometry.box, const Size.square(AppSizes.glyphMd));
      expect(geometry.ring, AppSizes.spinnerMd);
    });
  });

  group('motion', () {
    testWidgets('the spinner turns by default', (tester) async {
      await tester.pumpWidget(
        _host(AppButton(label: 'Go', onPressed: () {}, loading: true)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('the spinner stands still when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton(label: 'Go', onPressed: () {}, loading: true),
          disableAnimations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('the spinner stops when animations get disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(AppButton(label: 'Go', onPressed: () {}, loading: true)),
      );
      await tester.pumpWidget(
        _host(
          AppButton(label: 'Go', onPressed: () {}, loading: true),
          disableAnimations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  testWidgets('wraps a long label instead of overflowing at 2x text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: AppButton(
              label: 'A rather long label for a narrow phone',
              icon: AppIcons.add,
              onPressed: () {},
            ),
          ),
        ),
        width: 200,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppButton)).width, 200);
  });
}
