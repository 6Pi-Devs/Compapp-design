import 'dart:math' as math;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Set<WidgetState> _pressed = {WidgetState.pressed};
const Set<WidgetState> _disabled = {WidgetState.disabled};
const Set<WidgetState> _focused = {WidgetState.focused};
const Set<WidgetState> _selected = {WidgetState.selected};
const Set<WidgetState> _selectedDisabled = {
  WidgetState.selected,
  WidgetState.disabled,
};

void main() {
  for (final (name, theme) in [
    ('light', CompappTheme.light),
    ('dark', CompappTheme.dark),
  ]) {
    group('control themes ($name)', () {
      final scheme = theme.colorScheme;

      group('FilledButtonThemeData', () {
        final style = theme.filledButtonTheme.style!;

        test('is a primary fill with on-primary text, pressed or not', () {
          expect(style.backgroundColor!.resolve({}), scheme.primary);
          expect(
            style.backgroundColor!.resolve(_pressed),
            scheme.primary,
            reason: 'Material draws the pressed overlay on the token fill',
          );
          expect(style.foregroundColor!.resolve({}), scheme.onPrimary);
        });

        test('is sunken and muted when disabled', () {
          expect(
            style.backgroundColor!.resolve(_disabled),
            scheme.surfaceContainerHigh,
          );
          expect(
            style.foregroundColor!.resolve(_disabled),
            scheme.onSurfaceVariant,
          );
        });

        test('is 52 tall with token radius and no elevation', () {
          expect(style.minimumSize!.resolve({}), const Size(44, 52));
          expect(
            style.shape!.resolve({}),
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          );
          expect(style.elevation!.resolve({}), 0);
          expect(style.tapTargetSize, MaterialTapTargetSize.padded);
        });

        test('shows a 2 px ink ring outside the shape when focused', () {
          expect(style.side!.resolve({}), isNull);
          expect(style.side!.resolve(_focused), _focusRing(scheme));
        });

        test('keeps 4.5:1 in every state', () {
          for (final states in <Set<WidgetState>>[{}, _pressed, _disabled]) {
            _expectContrast(
              style.foregroundColor!.resolve(states)!,
              style.backgroundColor!.resolve(states)!,
              'filled $states',
            );
          }
        });
      });

      group('OutlinedButtonThemeData', () {
        final style = theme.outlinedButtonTheme.style!;

        test('is a surface fill with an outline border', () {
          expect(
            style.backgroundColor!.resolve({}),
            scheme.surfaceContainerLowest,
          );
          expect(
            style.backgroundColor!.resolve(_pressed),
            scheme.surfaceContainerLowest,
          );
          expect(style.side!.resolve({}), BorderSide(color: scheme.outline));
          expect(
            style.side!.resolve(_disabled),
            BorderSide(color: scheme.surfaceContainerHigh),
          );
          expect(style.side!.resolve(_focused), _focusRing(scheme));
          expect(style.minimumSize!.resolve({}), const Size(44, 52));
        });

        test('keeps 4.5:1 in every state', () {
          for (final states in <Set<WidgetState>>[{}, _pressed, _disabled]) {
            _expectContrast(
              style.foregroundColor!.resolve(states)!,
              style.backgroundColor!.resolve(states)!,
              'outlined $states',
            );
          }
        });
      });

      group('TextButtonThemeData', () {
        final style = theme.textButtonTheme.style!;

        test('is transparent with primary text, pressed or not', () {
          expect(style.backgroundColor!.resolve({}), Colors.transparent);
          expect(style.backgroundColor!.resolve(_pressed), Colors.transparent);
          expect(style.foregroundColor!.resolve({}), scheme.primary);
          expect(style.foregroundColor!.resolve(_pressed), scheme.primary);
          expect(
            style.foregroundColor!.resolve(_disabled),
            scheme.onSurfaceVariant,
          );
          expect(style.minimumSize!.resolve({}), const Size(44, 44));
          expect(
            style.shape!.resolve({}),
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          );
        });

        test('keeps 4.5:1 on the ground', () {
          _expectContrast(
            style.foregroundColor!.resolve({})!,
            scheme.surface,
            'text on ground',
          );
          _expectContrast(
            style.foregroundColor!.resolve(_disabled)!,
            scheme.surface,
            'text disabled',
          );
        });
      });

      group('ChipThemeData', () {
        final chip = theme.chipTheme;
        final side = chip.side! as WidgetStateBorderSide;

        test('fills and borders follow selected and disabled', () {
          expect(chip.color!.resolve({}), scheme.surfaceContainerLowest);
          expect(chip.color!.resolve(_selected), scheme.primaryContainer);
          expect(chip.color!.resolve(_disabled), scheme.surface);

          expect(side.resolve({}), BorderSide(color: scheme.outline));
          expect(
            side.resolve(_selected),
            BorderSide(color: scheme.primary, width: 2),
          );
          expect(
            side.resolve(_disabled),
            BorderSide(color: scheme.surfaceContainerHigh),
          );
        });

        test('disabled wins over selected', () {
          expect(chip.color!.resolve(_selectedDisabled), scheme.surface);
          expect(
            side.resolve(_selectedDisabled),
            BorderSide(color: scheme.surfaceContainerHigh),
          );
          expect(
            WidgetStateProperty.resolveAs<Color?>(
              chip.labelStyle!.color,
              _selectedDisabled,
            ),
            scheme.onSurfaceVariant,
          );
        });

        test('leaves the label padding and the checkmark to the widget', () {
          expect(chip.labelPadding, isNull);
          expect(chip.showCheckmark, isNull);
        });

        test('is not a pill', () {
          expect(
            chip.shape,
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            ),
          );
          expect(chip.elevation, 0);
        });

        test('keeps 4.5:1 for the label in every state', () {
          for (final states in <Set<WidgetState>>[{}, _selected, _disabled]) {
            _expectContrast(
              WidgetStateProperty.resolveAs<Color?>(
                chip.labelStyle!.color,
                states,
              )!,
              chip.color!.resolve(states)!,
              'chip $states',
            );
          }
        });
      });

      group('SwitchThemeData', () {
        final switches = theme.switchTheme;

        test('is primary when on and sunken with an outline when off', () {
          expect(switches.trackColor!.resolve(_selected), scheme.primary);
          expect(switches.thumbColor!.resolve(_selected), scheme.onPrimary);
          expect(
            switches.trackOutlineColor!.resolve(_selected),
            Colors.transparent,
          );
          expect(switches.trackColor!.resolve({}), scheme.surfaceContainerHigh);
          expect(switches.thumbColor!.resolve({}), scheme.onSurfaceVariant);
          expect(switches.trackOutlineColor!.resolve({}), scheme.outline);
          expect(switches.trackOutlineWidth!.resolve({}), 1);
        });

        test('keeps on and off apart when disabled', () {
          expect(
            switches.trackColor!.resolve(_selectedDisabled),
            scheme.primaryContainer,
          );
          expect(switches.trackColor!.resolve(_disabled), scheme.surface);
          expect(
            switches.thumbColor!.resolve(_selectedDisabled),
            scheme.onSurfaceVariant,
          );
          expect(
            switches.thumbColor!.resolve(_disabled),
            scheme.outlineVariant,
          );
        });

        test('gives the thumb 3:1 against the track when enabled', () {
          for (final states in <Set<WidgetState>>[{}, _selected]) {
            final ratio = _ratio(
              switches.thumbColor!.resolve(states)!,
              switches.trackColor!.resolve(states)!,
            );
            expect(ratio, greaterThanOrEqualTo(3), reason: '$states');
          }
        });
      });

      group('InputDecorationThemeData', () {
        final input = theme.inputDecorationTheme;

        test('fills with the surface and rounds with radius.sm', () {
          expect(input.filled, isTrue);
          final fill = input.fillColor! as WidgetStateColor;
          expect(fill.resolve({}), scheme.surfaceContainerLowest);
          expect(fill.resolve(_disabled), scheme.surface);
          final border = input.border! as OutlineInputBorder;
          expect(border.borderRadius, BorderRadius.circular(AppRadius.sm));
        });

        test('borders: outline, primary on focus, error on error', () {
          BorderSide side(InputBorder? border) =>
              (border! as OutlineInputBorder).borderSide;

          expect(side(input.enabledBorder).color, scheme.outline);
          expect(side(input.enabledBorder).width, 1);
          expect(
            side(input.focusedBorder),
            BorderSide(color: scheme.primary, width: 2),
          );
          expect(
            side(input.errorBorder),
            BorderSide(color: scheme.error, width: 2),
          );
          expect(side(input.focusedErrorBorder).color, scheme.error);
          expect(side(input.disabledBorder).color, scheme.surfaceContainerHigh);
        });

        test('makes a one-line field 52 tall', () {
          final padding = input.contentPadding! as EdgeInsets;
          final body = theme.textTheme.bodyMedium!;
          expect(
            padding.vertical + body.fontSize! * body.height!,
            AppSizes.controlLg,
          );
          expect(padding.horizontal, AppSpacing.md * 2);
        });

        test('keeps 4.5:1 for hint, helper and error text on the fill', () {
          _expectContrast(
            input.hintStyle!.color!,
            WidgetStateProperty.resolveAs<Color?>(
              input.fillColor,
              <WidgetState>{},
            )!,
            'hint',
          );
          _expectContrast(
            input.helperStyle!.color!,
            WidgetStateProperty.resolveAs<Color?>(
              input.fillColor,
              <WidgetState>{},
            )!,
            'helper',
          );
          _expectContrast(
            input.errorStyle!.color!,
            WidgetStateProperty.resolveAs<Color?>(
              input.fillColor,
              <WidgetState>{},
            )!,
            'error',
          );
          _expectContrast(
            scheme.onSurfaceVariant,
            scheme.surface,
            'disabled text on the disabled fill',
          );
        });
      });

      test('component boundaries keep 3:1 against the page and the cards', () {
        final outlined = theme.outlinedButtonTheme.style!.side!.resolve({})!;
        final chipSide = (theme.chipTheme.side! as WidgetStateBorderSide)
            .resolve({})!;
        final fieldSide =
            (theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
                .borderSide;
        final switchOutline = theme.switchTheme.trackOutlineColor!.resolve({})!;
        final boundaries = <String, Color>{
          'outlined button': outlined.color,
          'chip': chipSide.color,
          'text field': fieldSide.color,
          'switch off track': switchOutline,
          'code cell': scheme.outline,
        };

        for (final MapEntry(key: what, value: color) in boundaries.entries) {
          for (final (surface, surfaceName) in [
            (scheme.surface, 'ground'),
            (scheme.surfaceContainerLowest, 'card'),
          ]) {
            expect(
              _ratio(color, surface),
              greaterThanOrEqualTo(3),
              reason: '$what against the $surfaceName',
            );
          }
        }
      });

      testWidgets('raw buttons keep the Material press and hover feedback', (
        tester,
      ) async {
        final buttons = <(String, Widget Function(Widget), Type)>[
          (
            'FilledButton',
            (child) => FilledButton(onPressed: () {}, child: child),
            FilledButton,
          ),
          (
            'OutlinedButton',
            (child) => OutlinedButton(onPressed: () {}, child: child),
            OutlinedButton,
          ),
          (
            'TextButton',
            (child) => TextButton(onPressed: () {}, child: child),
            TextButton,
          ),
        ];

        for (final (name, build, type) in buttons) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(body: Center(child: build(const Text('x')))),
            ),
          );

          final ink = tester.widget<InkWell>(
            find.descendant(
              of: find.byType(type),
              matching: find.byType(InkWell),
            ),
          );
          for (final state in [WidgetState.pressed, WidgetState.hovered]) {
            expect(
              ink.overlayColor?.resolve({state})?.a,
              greaterThan(0),
              reason: '$name $state overlay',
            );
          }
          expect(
            ink.splashFactory,
            isNot(NoSplash.splashFactory),
            reason: '$name ripple',
          );
        }
      });

      testWidgets('raw buttons grow with a large label and keep the ring', (
        tester,
      ) async {
        for (final (build, type) in <(Widget Function(Widget), Type)>[
          (
            (child) => FilledButton(onPressed: () {}, child: child),
            FilledButton,
          ),
          ((child) => TextButton(onPressed: () {}, child: child), TextButton),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              builder: (context, app) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: app!,
              ),
              home: Scaffold(body: Center(child: build(const Text('x')))),
            ),
          );

          final surface = find.descendant(
            of: find.byType(type),
            matching: find.byWidgetPredicate(
              (w) => w is Material && w.type == MaterialType.button,
            ),
          );
          final label = tester.getSize(find.text('x')).height;
          expect(
            tester.getSize(surface).height,
            greaterThanOrEqualTo(label + AppSpacing.sm * 2),
            reason: '$type keeps room above and below the label',
          );
          expect(
            tester.widget<Material>(surface).clipBehavior,
            Clip.none,
            reason: '$type does not clip its focus ring',
          );
        }
      });

      test('TextSelectionThemeData uses primary and primary-soft', () {
        final selection = theme.textSelectionTheme;
        expect(selection.cursorColor, scheme.primary);
        expect(selection.selectionHandleColor, scheme.primary);
        expect(selection.selectionColor, scheme.primaryContainer);
        _expectContrast(
          scheme.onSurface,
          selection.selectionColor!,
          'text on selection',
        );
      });
    });
  }
}

BorderSide _focusRing(ColorScheme scheme) => BorderSide(
  color: scheme.onSurface,
  width: 2,
  strokeAlign: BorderSide.strokeAlignOutside,
);

void _expectContrast(Color foreground, Color background, String what) {
  expect(
    _ratio(foreground, background),
    greaterThanOrEqualTo(4.5),
    reason: '$what below 4.5:1',
  );
}

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
