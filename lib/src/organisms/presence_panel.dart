import 'package:compapp_design/src/models/member_status.dart';
import 'package:compapp_design/src/models/presence_entry.dart';
import 'package:compapp_design/src/models/presence_group.dart';
import 'package:compapp_design/src/models/presence_view.dart';
import 'package:compapp_design/src/molecules/knock_button.dart';
import 'package:compapp_design/src/molecules/member_row.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Who is home: the members at home, away and invited, each group under its
/// own heading, and the button that asks the home who is in.
///
/// It composes [MemberRow]s in a card per group and a [KnockButton] with the
/// words around it, and takes plain data ([PresenceView]) and one callback,
/// [onKnock], which a tap on the button calls while the home can be asked.
/// The app owns the members, the words and the clock: while the home was asked
/// a short time ago it passes a cooldown in the view and the button waits.
///
/// A group with no members says its empty label ("Nobody is home right now")
/// in place of rows, and a group with neither is left out. Away and invited
/// are told by their words, their dot or ring and the pebble, never by color
/// alone, and the panel never says who is behind on anything or who did not
/// answer: it says where people are.
///
/// For assistive technology every group is a container: a heading node, then a
/// list whose items hold one merged node per member (the member's spoken
/// label, then the subtitle and the trailing text). The asking part is a
/// container with the button's single node and, after it, one node for the
/// message and the hint. Nothing is said twice.
///
/// It is a column that takes its height from its content: put it in the
/// scrollable of the screen. It needs a bounded width and grows with large
/// text instead of clipping, the button wrapping under the words when they do
/// not fit beside it. It mirrors in right-to-left. It has no motion of its
/// own.
class PresencePanel extends StatelessWidget {
  const new({required this.view, required this.onKnock, super.key});

  final PresenceView view;
  final VoidCallback onKnock;

  static const double _gap = AppSpacing.sm + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    assert(_uniqueIds(view), 'The ids of the members are the row keys');
    assert(_statusesMatch(view), 'A member is in the group of their status');
    final broadcast = view.broadcast;
    final message = broadcast.message;
    final hint = broadcast.hint;
    final hasMessage = message != null && message.isNotEmpty;
    final hasHint = hint != null && hint.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    final sections = [
      ('home', view.home),
      ('away', view.away),
      if (view.invited != null) ('invited', view.invited!),
    ];

    return Semantics(
      key: const Key('presence.panel'),
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          for (final (id, group) in sections)
            if (group.isShown)
              _Section(key: ValueKey(id), sectionId: id, group: group),
          Semantics(
            key: const Key('presence.broadcast'),
            container: true,
            explicitChildNodes: true,
            child: _Card(
              child: Padding(
                padding: const EdgeInsets.all(_gap),
                // The words go beside the button when they fit and under it
                // when they do not, so a long word is never cut.
                child: Wrap(
                  spacing: _gap,
                  runSpacing: _gap,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    KnockButton(
                      label: broadcast.knockLabel,
                      onKnock: onKnock,
                      cooldown: broadcast.cooldown,
                    ),
                    if (hasMessage || hasHint)
                      MergeSemantics(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasMessage)
                              Text(
                                message,
                                key: const Key('presence.message'),
                                style: AppTypography.labelLg.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            if (hasHint)
                              Text(
                                hint,
                                key: const Key('presence.hint'),
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
            ),
          ),
        ],
      ),
    );
  }

  static bool _statusesMatch(PresenceView view) {
    bool all(PresenceGroup? group, MemberStatus status) =>
        group == null ||
        group.entries.every((entry) => entry.member.status == status);
    return all(view.home, MemberStatus.home) &&
        all(view.away, MemberStatus.away) &&
        all(view.invited, MemberStatus.invited);
  }

  static bool _uniqueIds(PresenceView view) {
    final ids = [
      for (final group in [view.home, view.away, ?view.invited])
        for (final entry in group.entries) entry.member.id,
    ];
    return ids.length == ids.toSet().length;
  }
}

/// A heading, then the card of members under it.
class _Section extends StatelessWidget {
  const new({required this.sectionId, required this.group, super.key});

  final String sectionId;
  final PresenceGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emptyLabel = group.emptyLabel;
    final entries = group.entries;

    return Semantics(
      key: Key('presence.section.$sectionId'),
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              group.title,
              style: AppTypography.label.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Card(
            key: Key('presence.card.$sectionId'),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PresencePanel._gap,
              ),
              child: entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: PresencePanel._gap,
                      ),
                      child: Text(
                        emptyLabel!,
                        key: Key('presence.empty.$sectionId'),
                        style: AppTypography.body.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Semantics(
                      container: true,
                      explicitChildNodes: true,
                      role: SemanticsRole.list,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < entries.length; i++) ...[
                            if (i > 0)
                              SizedBox(
                                height: AppSizes.hairline,
                                child: ColoredBox(color: scheme.outlineVariant),
                              ),
                            _Item(
                              key: Key('presence.item.${entries[i].member.id}'),
                              entry: entries[i],
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One member as a list item.
class _Item extends StatelessWidget {
  const new({required this.entry, super.key});

  final PresenceEntry entry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.listItem,
      child: MemberRow(
        member: entry.member,
        subtitle: entry.subtitle,
        trailing: entry.trailing,
      ),
    );
  }
}

/// The surface of a group: the card color with a hairline edge.
class _Card extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }
}
