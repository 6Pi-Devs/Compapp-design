import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/atoms/app_status_dot.dart';
import 'package:compapp_design/src/models/activity_tone.dart';
import 'package:compapp_design/src/models/activity_view.dart';
import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// One entry of the activity feed on one line: a glyph tile, the entry's
/// text (runs, some of them strong) with its [ActivityView.meta] under it, and
/// a dot while it is [unread].
///
/// The row is one button named by [semanticLabel] ("Unread. Carlos finished
/// your washer"), on top of Material's `TextButton`, so it takes focus, shows
/// the ink focus ring and is activated by tap, Enter and Space. The label
/// replaces the visible texts for assistive technology: the app says in it
/// whether the entry is unread, because the dot is only a drawing, and it must
/// contain the visible text of the entry in the same words (WCAG 2.5.3, label
/// in name), so someone who speaks the words they read can activate the row.
/// The tile, the texts and the dot add nothing of their own, so nothing is
/// said twice.
///
/// Unread is told by the dot, a shape that is there or not, and by the spoken
/// label, never by color alone. The tile is calm on purpose: busy is amber,
/// and the row has no danger color and says nothing about who is behind.
///
/// The row is at least `AppSizes.row` tall and grows with large text: the
/// texts wrap, the tile and the dot keep their size, and nothing is clamped.
/// It needs a bounded width and mirrors in right-to-left, with the tile at the
/// start and the dot at the end. Its focus ring is drawn outside the shape, so
/// a parent that clips needs `AppSizes.borderEmphasis` of room around it.
class ActivityRow extends StatelessWidget {
  const new({
    required this.entry,
    required this.unread,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  }) : assert(semanticLabel != '', 'The row needs a spoken label');

  final ActivityView entry;
  final bool unread;
  final String semanticLabel;
  final VoidCallback onTap;

  static const double _gap = AppSpacing.sm + AppSpacing.xs;
  static const double _vertical = (AppSizes.row - AppSizes.activityTile) / 2;
  static const TextStyle _strong = TextStyle(fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    assert(entry.text.isNotEmpty, 'An entry needs a text');
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final meta = entry.meta;

    final (tile, glyph) = switch (entry.tone) {
      ActivityTone.neutral => (scheme.surfaceContainerHigh, scheme.onSurface),
      ActivityTone.busy => (colors.busySoft, colors.busy),
    };
    const body = AppTypography.body;
    // The dot sits on the middle of the first line, which grows with the text.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(body.fontSize!) * body.height!;
    final dotTop = (firstLine - AppSizes.dotUnread) / 2;

    return TextButton(
      key: Key('activity.${entry.id}'),
      onPressed: onTap,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size.fromHeight(AppSizes.row),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: _gap, vertical: _vertical),
        ),
        alignment: AlignmentDirectional.centerStart,
        foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
        ),
      ),
      child: Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: AppSizes.activityTile,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tile,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: AppIcon(
                    entry.icon,
                    size: AppSizes.glyphLg,
                    color: glyph,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        for (final run in entry.text)
                          TextSpan(
                            text: run.text,
                            style: run.strong ? _strong : null,
                          ),
                      ],
                    ),
                    style: body.copyWith(color: scheme.onSurface),
                  ),
                  if (meta != null && meta.isNotEmpty)
                    Text(
                      meta,
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: _gap),
              Padding(
                padding: EdgeInsets.only(top: dotTop < 0 ? 0 : dotTop),
                child: const AppStatusDot(status: AppDotStatus.unread),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
