import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/models/calendar_event_kind.dart';
import 'package:compapp_design/src/models/calendar_event_view.dart';
import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// A calendar event drawn as a ribbon over the days it covers: a glyph and the
/// event title on a colored bar.
///
/// The kind picks the glyph (a person for a visit, a bed for an overnight
/// stay, a moon for an absence, a calendar for the rest) and the color (sky,
/// apricot, a sunken tile with a hairline, sand). The glyph and the title tell
/// the kinds apart, never the color alone. The colored kinds use the pebble
/// colors with the dark ink of a pebble in both themes; an absence is quiet
/// and sunken, with the away gray on its glyph, and never a danger color.
///
/// A flat edge means the event goes on past that side of the days shown:
/// [continuesBefore] flattens the start edge and [continuesAfter] the end
/// edge, and both mirror in right-to-left. The flat edge is only a shape, so
/// say it in [semanticLabel] too.
///
/// [compact] draws the glyph alone, for a cell too narrow for a title (a day of
/// a week strip, about 44 wide). The glyph still tells the kind and
/// [semanticLabel] still says everything, so nothing is lost for assistive
/// technology. In the normal form the title is one line, cut with an ellipsis
/// when the ribbon is too narrow for it: it never wraps letter by letter.
///
/// The ribbon is not interactive. It is one node named by [semanticLabel]
/// ("Absence, Luis, until Fri 6 Nov"), which carries what the ribbon only
/// shows by its width and its edges, and replaces the visible title for
/// assistive technology. It fills the width it is given and is at least
/// `AppSizes.ribbon` tall. That height is a least height: it grows with the
/// text scale (the glyph does not scale), so a lane of a strip must be as tall
/// as its tallest ribbon, or use [compact]. A lane with a fixed height that is
/// too small would cut the title, and nothing in the ribbon can tell.
class EventRibbon extends StatelessWidget {
  const new({
    required this.event,
    required this.semanticLabel,
    this.continuesBefore = false,
    this.continuesAfter = false,
    this.compact = false,
    super.key,
  }) : assert(semanticLabel != '', 'The ribbon needs a spoken label');

  final CalendarEventView event;

  /// The spoken description, with the dates the ribbon only draws by width.
  final String semanticLabel;

  /// The event started before the first day shown: flat start edge.
  final bool continuesBefore;

  /// The event goes on after the last day shown: flat end edge.
  final bool continuesAfter;

  /// Only the glyph, without the title: for a cell too narrow for a title.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final (fill, ink, glyph, icon) = switch (event.kind) {
      CalendarEventKind.visit => (
        colors.pebbleSky,
        colors.onPebble,
        colors.onPebble,
        AppIcons.visit,
      ),
      CalendarEventKind.overnight => (
        colors.pebbleApricot,
        colors.onPebble,
        colors.onPebble,
        AppIcons.bed,
      ),
      CalendarEventKind.absence => (
        scheme.surfaceContainerHigh,
        scheme.onSurface,
        colors.presenceAway,
        AppIcons.away,
      ),
      CalendarEventKind.other => (
        colors.pebbleSand,
        colors.onPebble,
        colors.onPebble,
        AppIcons.calendar,
      ),
    };

    const round = Radius.circular(AppRadius.sm);
    final radius = BorderRadiusDirectional.horizontal(
      start: continuesBefore ? Radius.zero : round,
      end: continuesAfter ? Radius.zero : round,
    );

    return Semantics(
      key: Key('event.${event.id}'),
      container: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.ribbon),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: event.kind == CalendarEventKind.absence
                ? Border.all(color: scheme.outlineVariant)
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: compact
                ? Center(
                    heightFactor: 1,
                    child: AppIcon(icon, size: AppSizes.glyphMd, color: glyph),
                  )
                : Row(
                    children: [
                      AppIcon(icon, size: AppSizes.glyphMd, color: glyph),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
