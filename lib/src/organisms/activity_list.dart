import 'package:compapp_design/src/atoms/app_badge.dart';
import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/models/activity_entry.dart';
import 'package:compapp_design/src/models/activity_list_view.dart';
import 'package:compapp_design/src/molecules/activity_row.dart';
import 'package:compapp_design/src/molecules/app_empty_state.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// The activity feed: the entries that are new, then the earlier ones, each
/// group under its own heading, or an empty state when there is nothing.
///
/// It composes [ActivityRow]s in a card per group and takes plain data
/// ([ActivityListView]) and callbacks: [onOpen] gets the id of the tapped
/// entry and [onMarkAllRead] is called by the ghost action beside the first
/// heading, which only shows while something is unread. The app owns the
/// entries, their order, the dates and the paging.
///
/// The first heading shows [ActivityListView.unreadCount] in a badge. Both
/// headings are heading nodes for assistive technology, the first one saying
/// the count in words ([ActivityListView.unreadSemanticLabel]). Every group is
/// a container with its heading, then a list whose items are single button
/// nodes named by the entry's spoken label, with
/// [ActivityListView.unreadPrefix] before it for the unread ones, so nothing
/// is said twice. A group with no entries is left out, and when both are empty
/// the list is an [AppEmptyState] with no action.
///
/// When the action is activated while it has focus and the app takes it away
/// (nothing is unread any more), focus moves to the second heading, so the
/// person does not lose their place. The groups are keyed, so focus and the
/// node of a row survive the first group appearing or leaving.
///
/// There are two forms of the same list, with the same data, callbacks, looks
/// and semantics:
///
/// * `ActivityList(...)` is a box, a column that takes its height from every
///   row. It builds every row it gets, so use it for a short list, such as a
///   screen that shows the latest few entries, inside a `ListView`, a
///   `SingleChildScrollView` or a `SliverToBoxAdapter`.
/// * `ActivityList.sliver(...)` is a sliver for the feed that is kept 90 days.
///   Put it directly in a `CustomScrollView`: it builds only the rows that are
///   near the viewport.
///
/// Both need a bounded width, grow with large text instead of clipping, and
/// mirror in right-to-left. Neither has motion.
class ActivityList extends StatefulWidget {
  const new({
    required this.view,
    required this.onOpen,
    required this.onMarkAllRead,
    super.key,
  });

  /// The sliver form of the list, for a `CustomScrollView`. See [ActivityList].
  static Widget sliver({
    required ActivityListView view,
    required ValueChanged<String> onOpen,
    required VoidCallback onMarkAllRead,
    Key? key,
  }) => _SliverActivityList(
    key: key,
    view: view,
    onOpen: onOpen,
    onMarkAllRead: onMarkAllRead,
  );

  final ActivityListView view;
  final ValueChanged<String> onOpen;
  final VoidCallback onMarkAllRead;

  @override
  State<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList> with _FocusHandoff {
  @override
  VoidCallback get onMarkAllRead => widget.onMarkAllRead;

  @override
  void didUpdateWidget(ActivityList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A parent that rebuilds with the same view (a "marking" state, a
    // setState) says nothing about the answer the handoff is waiting for.
    if (widget.view == oldWidget.view) return;
    handoffUpdated(widget.view);
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    assert(_uniqueIds(view), 'The ids of the entries are the row keys');
    assert(
      view.unreadCount >= view.unread.length,
      'The unread count cannot be less than the unread entries listed',
    );

    if (view.isEmpty) return _empty(view);

    return Semantics(
      key: _listKey,
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: _groupGap,
        children: [
          if (view.unread.isNotEmpty)
            _Group(
              key: const ValueKey('unread'),
              data: _GroupData.unread(view),
              handoff: this,
              onOpen: widget.onOpen,
            ),
          if (view.earlier.isNotEmpty)
            _Group(
              key: const ValueKey('earlier'),
              data: _GroupData.earlier(view),
              handoff: this,
              onOpen: widget.onOpen,
            ),
        ],
      ),
    );
  }
}

class _SliverActivityList extends StatefulWidget {
  const new({
    required this.view,
    required this.onOpen,
    required this.onMarkAllRead,
    super.key,
  });

  final ActivityListView view;
  final ValueChanged<String> onOpen;
  final VoidCallback onMarkAllRead;

  @override
  State<_SliverActivityList> createState() => _SliverActivityListState();
}

class _SliverActivityListState extends State<_SliverActivityList>
    with _FocusHandoff {
  @override
  VoidCallback get onMarkAllRead => widget.onMarkAllRead;

  @override
  void didUpdateWidget(_SliverActivityList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A parent that rebuilds with the same view (a "marking" state, a
    // setState) says nothing about the answer the handoff is waiting for.
    if (widget.view == oldWidget.view) return;
    handoffUpdated(widget.view);
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    assert(_uniqueIds(view), 'The ids of the entries are the row keys');
    assert(
      view.unreadCount >= view.unread.length,
      'The unread count cannot be less than the unread entries listed',
    );

    if (view.isEmpty) return SliverToBoxAdapter(child: _empty(view));

    final groups = [
      if (view.unread.isNotEmpty) _GroupData.unread(view),
      if (view.earlier.isNotEmpty) _GroupData.earlier(view),
    ];
    return SliverSemantics(
      key: _listKey,
      container: true,
      explicitChildNodes: true,
      sliver: SliverMainAxisGroup(
        slivers: [
          for (var i = 0; i < groups.length; i++)
            SliverPadding(
              key: ValueKey(groups[i].id),
              padding: EdgeInsets.only(top: i == 0 ? 0 : _groupGap),
              sliver: _sliverGroup(context, groups[i]),
            ),
        ],
      ),
    );
  }

  Widget _sliverGroup(BuildContext context, _GroupData data) {
    final scheme = Theme.of(context).colorScheme;
    final entries = data.entries;
    final indexById = {
      for (var i = 0; i < entries.length; i++) entries[i].view.id: i,
    };
    return SliverSemantics(
      container: true,
      explicitChildNodes: true,
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: _groupGap),
              child: _header(context, data, this),
            ),
          ),
          DecoratedSliver(
            key: Key('activity.card.${data.id}'),
            decoration: _cardDecoration(scheme),
            sliver: SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              sliver: SliverSemantics(
                container: true,
                explicitChildNodes: true,
                role: SemanticsRole.list,
                sliver: SliverList.builder(
                  itemCount: entries.length,
                  // The indexes would wrap every row in a node of its own,
                  // between the list and its items.
                  addSemanticIndexes: false,
                  findChildIndexCallback: (key) {
                    const prefix = 'activity.item.';
                    if (key is! ValueKey<String> ||
                        !key.value.startsWith(prefix)) {
                      return null;
                    }
                    return indexById[key.value.substring(prefix.length)];
                  },
                  itemBuilder: (context, i) => Column(
                    key: Key('activity.item.${entries[i].view.id}'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (i > 0) _divider(scheme),
                      _item(data, entries[i], widget.onOpen),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _listKey = Key('activity.list');
const _markAllReadKey = Key('activity.markAllRead');

/// The gap between the two groups and between a heading and its card, the 8 of
/// the board.
const double _groupGap = AppSpacing.sm;

Widget _empty(ActivityListView view) => KeyedSubtree(
  key: _listKey,
  child: AppEmptyState(
    key: const Key('activity.empty'),
    title: view.emptyTitle,
    body: view.emptyBody,
  ),
);

bool _uniqueIds(ActivityListView view) {
  final ids = [
    for (final entry in [...view.unread, ...view.earlier]) entry.view.id,
  ];
  return ids.length == ids.toSet().length;
}

/// Keeps the place of a person who activated the action with the keyboard or a
/// screen reader: the action goes away when nothing is unread, and focus would
/// fall to the route, so it moves to the second heading.
///
/// The handoff is pending from the press of the action, when the focus is on
/// the action of THIS list, until the app's update arrives, which may be after
/// an `await`: the first update that leaves nothing unread completes it, one
/// that leaves something unread drops it, and so does the focus moving to
/// another control while the action is still there. It asks for focus only
/// when the heading is attached, so a request can never be remembered and
/// applied later, after the person has moved on.
mixin _FocusHandoff<T extends StatefulWidget> on State<T> {
  final FocusNode earlierFocus = FocusNode(
    debugLabel: 'activity.group.earlier',
    skipTraversal: true,
  );
  FocusNode? _pressedAction;

  VoidCallback get onMarkAllRead;

  void markAllRead() {
    final primary = FocusManager.instance.primaryFocus;
    final onAction =
        primary?.context?.findAncestorWidgetOfExactType<AppButton>()?.key ==
        _markAllReadKey;
    if (onAction && _isWithin(primary)) {
      if (_pressedAction == null) {
        FocusManager.instance.addListener(_focusChanged);
      }
      _pressedAction = primary;
    }
    onMarkAllRead();
  }

  /// Called when the app gives the list a new view.
  void handoffUpdated(ActivityListView view) {
    if (_pressedAction == null) return;
    if (view.unread.isNotEmpty) return _cancelHandoff();
    _cancelHandoff();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only an attached heading can take focus: a request on a detached node
      // would be remembered and applied when it attaches, much later. The
      // node keeps its context after it unmounts, so the parent tells.
      if (mounted && earlierFocus.parent != null) earlierFocus.requestFocus();
    });
  }

  void _focusChanged() {
    final action = _pressedAction;
    if (action == null) return;
    // While the action is attached, focus anywhere else is the person moving
    // on. Once it is gone, the fall of focus is what the handoff repairs.
    if (action.context != null &&
        FocusManager.instance.primaryFocus != action) {
      _cancelHandoff();
    }
  }

  void _cancelHandoff() {
    _pressedAction = null;
    FocusManager.instance.removeListener(_focusChanged);
  }

  /// Whether [node] is inside this list.
  bool _isWithin(FocusNode? node) {
    var within = false;
    node?.context?.visitAncestorElements((element) {
      within = element == context;
      return !within;
    });
    return within;
  }

  @override
  void dispose() {
    _cancelHandoff();
    earlierFocus.dispose();
    super.dispose();
  }
}

/// What a group draws, so the box and the sliver form share it.
class _GroupData {
  new unread(ActivityListView view)
    : id = 'unread',
      unread = true,
      title = view.unreadTitle,
      headingLabel = view.unreadSemanticLabel,
      count = view.unreadCount,
      markAllReadLabel = view.markAllReadLabel,
      spokenPrefix = view.unreadPrefix,
      entries = view.unread;

  new earlier(ActivityListView view)
    : id = 'earlier',
      unread = false,
      title = view.earlierTitle,
      headingLabel = view.earlierTitle,
      count = null,
      markAllReadLabel = null,
      spokenPrefix = null,
      entries = view.earlier;

  final String id;
  final String title;
  final String headingLabel;
  final int? count;
  final String? markAllReadLabel;
  final String? spokenPrefix;
  final List<ActivityEntry> entries;
  final bool unread;
}

/// The heading, with its count, and the action at the end of its line.
Widget _header(BuildContext context, _GroupData data, _FocusHandoff handoff) {
  final scheme = Theme.of(context).colorScheme;
  final count = data.count;
  final markAllReadLabel = data.markAllReadLabel;

  final heading = Semantics(
    key: Key('activity.group.${data.id}'),
    header: true,
    label: data.headingLabel,
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            data.title,
            style: AppTypography.label.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.sm),
          AppBadge.count(count),
        ],
      ],
    ),
  );

  // The action wraps under the heading when both do not fit, instead of
  // squeezing the heading into a word break.
  return Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    children: [
      if (data.unread)
        heading
      else
        Focus(
          focusNode: handoff.earlierFocus,
          child: _FocusRing(node: handoff.earlierFocus, child: heading),
        ),
      if (markAllReadLabel != null)
        AppButton(
          key: _markAllReadKey,
          label: markAllReadLabel,
          variant: AppButtonVariant.ghost,
          onPressed: handoff.markAllRead,
        ),
    ],
  );
}

BoxDecoration _cardDecoration(ColorScheme scheme) => BoxDecoration(
  color: scheme.surfaceContainerLowest,
  border: Border.all(color: scheme.outlineVariant),
  borderRadius: BorderRadius.circular(AppRadius.md),
);

/// The hairline between two rows: the flat elevation, 1 px of `color.line`.
Widget _divider(ColorScheme scheme) => SizedBox(
  height: AppSizes.hairline,
  child: ColoredBox(color: scheme.outlineVariant),
);

Widget _item(
  _GroupData data,
  ActivityEntry entry,
  ValueChanged<String> onOpen, {
  Key? key,
}) {
  final prefix = data.spokenPrefix;
  return Semantics(
    key: key,
    container: true,
    explicitChildNodes: true,
    role: SemanticsRole.listItem,
    child: ActivityRow(
      entry: entry.view,
      unread: data.unread,
      semanticLabel: prefix == null
          ? entry.semanticLabel
          : '$prefix. ${entry.semanticLabel}',
      onTap: () => onOpen(entry.view.id),
    ),
  );
}

/// A heading, then the card of rows under it.
class _Group extends StatelessWidget {
  const new({
    required this.data,
    required this.handoff,
    required this.onOpen,
    super.key,
  });

  final _GroupData data;
  final _FocusHandoff handoff;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = data.entries;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: _groupGap,
        children: [
          _header(context, data, handoff),
          DecoratedBox(
            key: Key('activity.card.${data.id}'),
            decoration: _cardDecoration(scheme),
            // The room the focus ring of a row is drawn in: a row's ring sits
            // outside its shape, and the card does not clip.
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                role: SemanticsRole.list,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i > 0) _divider(scheme),
                      _item(
                        data,
                        entries[i],
                        onOpen,
                        key: Key('activity.item.${entries[i].view.id}'),
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

/// Draws a ring around [child] while [node] has focus, in the ink color and the
/// emphasis width of the other focus rings, and nothing otherwise: the layout
/// and the unfocused pixels are the child's own.
class _FocusRing extends StatelessWidget {
  const new({required this.node, required this.child});

  final FocusNode node;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return ListenableBuilder(
      listenable: node,
      child: child,
      builder: (context, child) => CustomPaint(
        foregroundPainter: _RingPainter(show: node.hasFocus, color: color),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const new({required this.show, required this.color});

  final bool show;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    const width = AppSizes.borderEmphasis;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).inflate(width / 2),
        const Radius.circular(AppRadius.xs),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.show != show || oldDelegate.color != color;
}
