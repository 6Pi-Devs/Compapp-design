import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/foundation/calendar_event_style.dart';
import 'package:compapp_design/src/models/calendar_legend_entry.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// What the marks of a calendar mean: for each entry, the swatch of its kind
/// (the glyph on the fill an `EventRibbon` of that kind draws) and its label.
///
/// The entries wrap onto more lines when they do not fit the width, and a
/// label wraps by its words, never cut. The swatch is decoration: each entry
/// is one text node named by its label, so assistive technology reads the
/// labels in order. It is not interactive. It mirrors in right-to-left and
/// grows with the text scale.
class CalendarLegend extends StatelessWidget {
  const new({required this.entries, super.key});

  final List<CalendarLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('calendar.legend'),
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in entries)
          _Entry(key: Key('calendar.legend.${entry.kind.name}'), entry: entry),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const new({required this.entry, super.key});

  final CalendarLegendEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = calendarEventStyle(context, entry.kind);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        ExcludeSemantics(
          child: Container(
            width: AppSizes.ribbon,
            height: AppSizes.ribbon,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: style.fill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: style.border
                  ? Border.all(color: scheme.outlineVariant)
                  : null,
            ),
            child: AppIcon(
              style.icon,
              size: AppSizes.glyphMd,
              color: style.glyph,
            ),
          ),
        ),
        Flexible(
          child: Text(
            entry.label,
            style: AppTypography.caption.copyWith(color: scheme.onSurface),
          ),
        ),
      ],
    );
  }
}
