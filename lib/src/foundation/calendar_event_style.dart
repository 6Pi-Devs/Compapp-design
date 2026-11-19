import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/models/calendar_event_kind.dart';
import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:flutter/material.dart';

/// How a kind of calendar event is drawn: the `fill` of its shape, the `ink`
/// of a text on it, the color of its `glyph`, the `icon` and whether the shape
/// has a hairline `border` (`colorScheme.outlineVariant`).
typedef CalendarEventStyle = ({
  Color fill,
  Color ink,
  Color glyph,
  AppIcons icon,
  bool border,
});

/// The style of [kind] in the theme of [context]: a person on sky for a visit,
/// a bed on apricot for an overnight stay, a moon in the away gray on a sunken
/// tile with a hairline for an absence (quiet, never a danger color), and a
/// calendar on sand for the rest. The colored kinds use the pebble colors with
/// the dark ink of a pebble in both themes. The glyph tells the kinds apart,
/// never the color alone.
CalendarEventStyle calendarEventStyle(
  BuildContext context,
  CalendarEventKind kind,
) {
  final scheme = Theme.of(context).colorScheme;
  final colors = context.appColors;
  return switch (kind) {
    CalendarEventKind.visit => (
      fill: colors.pebbleSky,
      ink: colors.onPebble,
      glyph: colors.onPebble,
      icon: AppIcons.visit,
      border: false,
    ),
    CalendarEventKind.overnight => (
      fill: colors.pebbleApricot,
      ink: colors.onPebble,
      glyph: colors.onPebble,
      icon: AppIcons.bed,
      border: false,
    ),
    CalendarEventKind.absence => (
      fill: scheme.surfaceContainerHigh,
      ink: scheme.onSurface,
      glyph: colors.presenceAway,
      icon: AppIcons.away,
      border: true,
    ),
    CalendarEventKind.other => (
      fill: colors.pebbleSand,
      ink: colors.onPebble,
      glyph: colors.onPebble,
      icon: AppIcons.calendar,
      border: false,
    ),
  };
}
