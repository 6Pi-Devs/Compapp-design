import 'package:compapp_design/src/atoms/app_pebble.dart';
import 'package:compapp_design/src/atoms/app_status_dot.dart';
import 'package:compapp_design/src/models/member_status.dart';
import 'package:compapp_design/src/models/member_view.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// A member of the home on one line: their pebble, their name with an optional
/// [subtitle] under it, and an optional [trailing] text with a status dot.
///
/// The row is one thing to assistive technology: a single node that reads
/// `member.semanticLabel`, then the [subtitle], then the [trailing] text. The
/// label names the member, so the visible name is left out of semantics, and
/// the pebble and the dot are decorative here. The row is not interactive.
/// The dot follows the member's status (primary at home, a hollow ring away,
/// none while invited) and only appears beside a [trailing] text, which is
/// what names the status for everyone: the dot is never the only cue.
///
/// The row is at least `AppSizes.row` tall and grows with large text: the
/// name and the subtitle wrap, the trailing text wraps within a third of what
/// the row, and nothing is clamped. The trailing text takes only the width it
/// needs and hugs the end edge. It needs a bounded width, and has no divider
/// or padding at its sides: the list around it owns both. It reads in the text
/// direction, so in right-to-left the pebble sits at the right and the
/// trailing text at the left.
class MemberRow extends StatelessWidget {
  const new({required this.member, this.subtitle, this.trailing, super.key});

  final MemberView member;
  final String? subtitle;
  final String? trailing;

  /// The pebble and the texts may take two parts of the row and the trailing
  /// text one, so the trailing text wraps within a third of it.
  static const int _groupFlex = 2;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    final hasSubtitle = subtitle != null && subtitle.isNotEmpty;
    final hasTrailing = trailing != null && trailing.isNotEmpty;

    final pebble = AppPebble(
      initials: member.initials,
      joinOrder: member.joinOrder,
      semanticLabel: member.semanticLabel,
      status: switch (member.status) {
        MemberStatus.home => AppPebbleStatus.home,
        MemberStatus.away => AppPebbleStatus.away,
        MemberStatus.invited => AppPebbleStatus.invited,
      },
      isYou: member.isYou,
      isAdmin: member.isAdmin,
    );
    final dot = switch (member.status) {
      MemberStatus.home => AppDotStatus.home,
      MemberStatus.away => AppDotStatus.away,
      MemberStatus.invited => null,
    };

    return MergeSemantics(
      key: Key('member.${member.id}'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.row),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // The pebble and the texts are one group at the start, up to two
              // thirds of the row when there is a trailing text.
              Flexible(
                flex: hasTrailing ? _groupFlex : 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The label of the member is the spoken name of the row,
                    // so the pebble's own node is replaced by a plain one.
                    Semantics(
                      label: member.semanticLabel,
                      child: ExcludeSemantics(child: pebble),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ExcludeSemantics(
                            child: Text(
                              member.name,
                              style: AppTypography.labelLg.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (hasSubtitle)
                            Text(
                              subtitle,
                              style: AppTypography.caption.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // The trailing text hugs the end edge at its own width and wraps
              // only past a third of the row.
              if (hasTrailing)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (dot != null) ...[
                          AppStatusDot(status: dot),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: Text(
                            trailing,
                            style: AppTypography.caption.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
