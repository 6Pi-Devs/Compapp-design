import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// Component themes of the form controls, built from a [ColorScheme] and the
/// Compapp [TextTheme].
///
/// A raw Material `FilledButton`, `FilterChip`, `Switch` or `TextField` looks
/// right under `CompappTheme`, and the atoms inherit focus, ripple, keyboard
/// and semantics behavior from them.
///
/// The themes only set colors, shapes, sizes and text styles. They keep the
/// feedback and layout of the raw widgets (ripple, hover and focus overlays,
/// label padding), and atom-specific behavior lives in the atom's own style.
///
/// So a raw button gets Material's own pressed overlay on the token
/// background. `AppButton` draws pressed as a fill instead, in its own style.
/// Interactive component boundaries use `ColorScheme.outline`, which keeps 3:1
/// against the page; `outlineVariant` is for decorative hairlines.
abstract final class ControlThemes {
  /// Large filled button: primary fill, 52 tall.
  static FilledButtonThemeData filledButton(
    ColorScheme scheme,
    TextTheme text,
  ) {
    return FilledButtonThemeData(
      style: _base(scheme, text, height: AppSizes.controlLg).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? scheme.surfaceContainerHigh
              : scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurfaceVariant
              : scheme.onPrimary,
        ),
        side: _focusSide(scheme),
      ),
    );
  }

  /// Large outlined button: surface fill and an outline border, 52 tall.
  static OutlinedButtonThemeData outlinedButton(
    ColorScheme scheme,
    TextTheme text,
  ) {
    return OutlinedButtonThemeData(
      style: _base(scheme, text, height: AppSizes.controlLg).copyWith(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLowest),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurfaceVariant
              : scheme.onSurface,
        ),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return _focusBorder(scheme);
          }
          return BorderSide(
            color: states.contains(WidgetState.disabled)
                ? scheme.surfaceContainerHigh
                : scheme.outline,
          );
        }),
      ),
    );
  }

  /// Medium text button: no fill until pressed, 44 tall.
  static TextButtonThemeData textButton(ColorScheme scheme, TextTheme text) {
    return TextButtonThemeData(
      style:
          _base(
            scheme,
            text,
            height: AppSizes.controlMd,
            radius: AppRadius.sm,
          ).copyWith(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? scheme.onSurfaceVariant
                  : scheme.primary,
            ),
            side: _focusSide(scheme),
          ),
    );
  }

  /// Chip: surface fill, outline border, `radius.sm`, 44 tall. Selected is
  /// primary-soft with a primary border. `AppChip` lifts the height to 44.
  static ChipThemeData chip(ColorScheme scheme, TextTheme text) {
    final label = text.labelLarge!;
    return ChipThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
      ),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return scheme.surface;
        if (states.contains(WidgetState.selected)) {
          return scheme.primaryContainer;
        }
        return scheme.surfaceContainerLowest;
      }),
      side: WidgetStateBorderSide.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: scheme.surfaceContainerHigh);
        }
        if (states.contains(WidgetState.selected)) {
          return BorderSide(
            color: scheme.primary,
            width: AppSizes.borderEmphasis,
          );
        }
        return BorderSide(color: scheme.outline);
      }),
      labelStyle: label.copyWith(
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurfaceVariant
              : scheme.onSurface,
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface, size: AppSizes.glyphMd),
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
    );
  }

  /// Switch: the Material 3 52x32 track, primary when on, sunken with an
  /// outline border when off. The empty thumb icon keeps the off thumb at the
  /// size of the on thumb.
  static SwitchThemeData switchTheme(ColorScheme scheme) {
    bool isOn(Set<WidgetState> states) => states.contains(WidgetState.selected);
    bool isDisabled(Set<WidgetState> states) =>
        states.contains(WidgetState.disabled);

    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (isDisabled(states)) {
          return isOn(states) ? scheme.onSurfaceVariant : scheme.outlineVariant;
        }
        return isOn(states) ? scheme.onPrimary : scheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (isDisabled(states)) {
          return isOn(states) ? scheme.primaryContainer : scheme.surface;
        }
        return isOn(states) ? scheme.primary : scheme.surfaceContainerHigh;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (isOn(states) && !isDisabled(states)) return Colors.transparent;
        return isDisabled(states)
            ? scheme.surfaceContainerHigh
            : scheme.outline;
      }),
      trackOutlineWidth: const WidgetStatePropertyAll(AppSizes.hairline),
      thumbIcon: const WidgetStatePropertyAll(Icon(null)),
    );
  }

  /// Text field: surface fill (the ground when disabled), outline border, 52
  /// tall, `radius.sm`. Focus and error use a 2 px border.
  static InputDecorationThemeData inputDecoration(
    ColorScheme scheme,
    TextTheme text,
  ) {
    const radius = BorderRadius.all(Radius.circular(AppRadius.sm));
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );
    final body = text.bodyMedium!;
    final lineHeight = body.fontSize! * body.height!;

    return InputDecorationThemeData(
      filled: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? scheme.surface
            : scheme.surfaceContainerLowest,
      ),
      border: border(scheme.outline, AppSizes.hairline),
      enabledBorder: border(scheme.outline, AppSizes.hairline),
      focusedBorder: border(scheme.primary, AppSizes.borderEmphasis),
      errorBorder: border(scheme.error, AppSizes.borderEmphasis),
      focusedErrorBorder: border(scheme.error, AppSizes.borderEmphasis),
      disabledBorder: border(scheme.surfaceContainerHigh, AppSizes.hairline),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: (AppSizes.controlLg - lineHeight) / 2,
      ),
      hintStyle: body.copyWith(color: scheme.onSurfaceVariant),
      helperStyle: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
      errorStyle: text.bodySmall!.copyWith(color: scheme.error),
      helperMaxLines: 2,
      errorMaxLines: 2,
    );
  }

  /// Caret, selection and handles of text inputs.
  static TextSelectionThemeData textSelection(ColorScheme scheme) {
    return TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primaryContainer,
      selectionHandleColor: scheme.primary,
    );
  }

  static ButtonStyle _base(
    ColorScheme scheme,
    TextTheme text, {
    required double height,
    double radius = AppRadius.md,
  }) {
    return ButtonStyle(
      textStyle: const WidgetStatePropertyAll(AppTypography.labelLg),
      minimumSize: WidgetStatePropertyAll(Size(AppSizes.minDrawn, height)),
      // The height is a minimum: the vertical padding lets a button grow
      // with its label instead of the label touching the edges.
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      iconSize: const WidgetStatePropertyAll(AppSizes.glyphLg),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static WidgetStateProperty<BorderSide?> _focusSide(ColorScheme scheme) {
    return WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.focused) ? _focusBorder(scheme) : null,
    );
  }

  /// An ink ring drawn outside the shape, so it sits on the page and keeps its
  /// contrast against filled buttons.
  static BorderSide _focusBorder(ColorScheme scheme) => BorderSide(
    color: scheme.onSurface,
    width: AppSizes.borderEmphasis,
    strokeAlign: BorderSide.strokeAlignOutside,
  );
}
