import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/atoms/app_pebble.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/models/member_status.dart';
import 'package:compapp_design/src/models/member_view.dart';
import 'package:compapp_design/src/models/room_assign_option.dart';
import 'package:compapp_design/src/models/room_editor_archived_room.dart';
import 'package:compapp_design/src/models/room_editor_room.dart';
import 'package:compapp_design/src/models/room_editor_view.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// The rooms of the home as the admin edits them: the bedrooms, the common
/// areas and the archived rooms, each list under its heading, with the button
/// that adds a room.
///
/// It composes [AppButton] (add and assign), [AppPebble]s and icon buttons in
/// a card per list, and takes plain data ([RoomEditorView]) and five
/// callbacks: [onAdd], [onEdit], [onArchive] and [onRestore] (the room id) and
/// [onAssign] (the room id and the member id). It owns no data: a tap only
/// calls back, and the app answers with a new view. A bedroom that has members
/// to move in shows an assign button that opens, under its row, one button for
/// each of them (Escape closes it). The admin only sees this screen, so the
/// editor does not check the role.
///
/// Archive and restore are always enabled: the backend can refuse an archive
/// (a bedroom someone sleeps in), and the app tells the admin why with its own
/// message when it does. Restore is not blocked by the limit of rooms, because
/// restoring does not change how many there are.
///
/// Each row is a list item. For assistive technology its name and subtitle are
/// one node and each button is its own node named by the app ("Edit Bedroom
/// 1", "Archive Kitchen", "Restore Office"), so every action says which room it
/// acts on. The pebbles are decorative: the subtitle says who sleeps there.
///
/// It is a column that takes its height from its content: put it in the
/// scrollable of the screen. It needs a bounded width and grows with large
/// text, the buttons of a row wrapping under its texts when they do not fit
/// beside them. Nothing is cut or clamped. It mirrors in right-to-left. It
/// has no motion of its own.
///
/// Focus, for someone using a keyboard and once the new view is laid out: when
/// a view removes the room that holds focus, focus moves to the edit button of
/// the next room (the previous one, then the add button). For an archived room
/// that was restored it moves to the restore button of the next archived room
/// (the previous one, then the edit button of the restored room). When the
/// add button holds focus and the view disables it with a limit message, focus
/// moves to the edit button of the first room (the restore button of the first
/// archived room when every room is archived). When the assign list that holds
/// focus loses every option it moves to the edit button, and when it loses only
/// the option that holds it, to the assign button. It never falls to the route.
///
/// [initialAssignOpen] holds the ids of the bedrooms whose assign list is open
/// when the editor is first built, for an app that restores what was open (and
/// for the catalog). Only the rooms of that first view are opened: a room added
/// or restored later stays closed even if its id is in the set, and tapping the
/// assign button owns the list afterwards.
class RoomEditor extends StatefulWidget {
  const new({
    required this.view,
    required this.onAdd,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.onAssign,
    this.initialAssignOpen = const {},
    super.key,
  });

  final RoomEditorView view;
  final VoidCallback onAdd;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onArchive;
  final ValueChanged<String> onRestore;
  final void Function(String roomId, String accountId) onAssign;
  final Set<String> initialAssignOpen;

  @override
  State<RoomEditor> createState() => _RoomEditorState();
}

const double _gap = AppSpacing.sm + AppSpacing.xs;

bool _traditional() =>
    FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

bool _limited(RoomEditorView view) => (view.limitMessage ?? '').isNotEmpty;

/// Hands focus to what [target] answers once the frame is laid out, if it is
/// still attached and the widget that asked is still mounted. Asking again is
/// harmless, and a rebuild never cancels it.
void _focusAfterFrame(
  FocusNode? Function() target,
  bool Function() stillMounted,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!stillMounted()) return;
    final node = target();
    if (node != null && node.parent != null && node.canRequestFocus) {
      node.requestFocus();
    }
  });
}

class _RoomEditorState extends State<RoomEditor> {
  final _addNode = FocusNode(debugLabel: 'rooms.add');
  final _editNodes = <String, FocusNode>{};
  final _restoreNodes = <String, FocusNode>{};
  final _anchors = <String, FocusNode>{};

  /// The rooms whose list starts open: those of the first view that are in
  /// [RoomEditor.initialAssignOpen]. Emptied by the first update.
  late final Set<String> _seeded = widget.initialAssignOpen.intersection(
    _ids(widget.view).toSet(),
  );

  static List<String> _ids(RoomEditorView view) => [
    for (final room in [...view.bedrooms, ...view.commonAreas]) room.room.id,
  ];

  static List<String> _archivedIds(RoomEditorView view) => [
    for (final room in view.archived) room.room.id,
  ];

  FocusNode _node(Map<String, FocusNode> nodes, String id, String prefix) =>
      nodes.putIfAbsent(id, () => FocusNode(debugLabel: '$prefix.$id'));

  /// The id next to [ids] at [index] that [kept] still has: the one after it,
  /// else the one before it.
  static String? _neighbor(List<String> ids, int index, Set<String> kept) {
    final next = ids.skip(index + 1).where(kept.contains);
    final previous = ids.take(index).where(kept.contains);
    return next.isNotEmpty
        ? next.first
        : previous.isNotEmpty
        ? previous.last
        : null;
  }

  /// The id of the first room of [before] that [kept] lost and that holds
  /// focus, with its index.
  int? _lostWithFocus(List<String> before, Set<String> kept) {
    for (var i = 0; i < before.length; i++) {
      if (!kept.contains(before[i]) && _anchors[before[i]]?.hasFocus == true) {
        return i;
      }
    }
    return null;
  }

  void _handOver(RoomEditorView old, RoomEditorView now) {
    final before = _ids(old);
    final kept = _ids(now).toSet();
    final lost = _lostWithFocus(before, kept);
    if (lost != null) {
      final id = _neighbor(before, lost, kept);
      _focusAfterFrame(
        () => id == null ? _addNode : _editNodes[id],
        () => mounted,
      );
      return;
    }
    final archivedBefore = _archivedIds(old);
    final archivedKept = _archivedIds(now).toSet();
    final restored = _lostWithFocus(archivedBefore, archivedKept);
    if (restored != null) {
      final id = _neighbor(archivedBefore, restored, archivedKept);
      final room = archivedBefore[restored];
      _focusAfterFrame(
        () => id == null ? _editNodes[room] ?? _addNode : _restoreNodes[id],
        () => mounted,
      );
      return;
    }
    if (!_limited(old) && _limited(now) && _addNode.hasFocus) {
      final first = _ids(now).firstOrNull;
      final archived = _archivedIds(now).firstOrNull;
      _focusAfterFrame(
        () => first != null
            ? _editNodes[first]
            : archived == null
            ? null
            : _restoreNodes[archived],
        () => mounted,
      );
    }
  }

  @override
  void didUpdateWidget(RoomEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _seeded.clear();
    if (_traditional()) _handOver(oldWidget.view, widget.view);
    // The nodes of the rooms that left are disposed once nothing uses them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = {..._ids(widget.view), ..._archivedIds(widget.view)};
      for (final nodes in [_editNodes, _restoreNodes, _anchors]) {
        for (final id
            in nodes.keys.where((id) => !current.contains(id)).toList()) {
          nodes.remove(id)!.dispose();
        }
      }
    });
  }

  @override
  void dispose() {
    _addNode.dispose();
    for (final node in [
      ..._editNodes.values,
      ..._restoreNodes.values,
      ..._anchors.values,
    ]) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final active = [...view.bedrooms, ...view.commonAreas];
    final ids = [..._ids(view), ..._archivedIds(view)];
    assert(ids.length == ids.toSet().length, 'The ids of the rooms are keys');
    assert(
      view.archived.isEmpty || (view.archivedTitle ?? '').isNotEmpty,
      'Archived rooms need a heading',
    );
    assert(
      view.commonAreas.every(
        (room) => room.occupants.isEmpty && room.assignOptions.isEmpty,
      ),
      'A common area has no occupants and no assign options',
    );
    assert(
      active.every(
        (room) => room.assignOptions.every(
          (option) => !room.occupants.any((m) => m.id == option.member.id),
        ),
      ),
      'A member that is in a room is not offered that room',
    );
    assert(
      active.every((room) {
        final options = [for (final o in room.assignOptions) o.member.id];
        return options.length == options.toSet().length;
      }),
      'A member is offered a room once',
    );
    assert(
      active.every(
        (room) =>
            room.assignOptions.isEmpty ||
            (room.assignLabel ?? '').contains(view.assignLabel),
      ),
      'A room with options needs an assignLabel that holds the visible '
      'assignLabel of the view (label in name)',
    );
    assert(
      active.every(
        (room) => room.assignOptions.every(
          (option) => option.semanticLabel.contains(option.member.name),
        ),
      ),
      'The spoken label of an option holds the name of the member (label in '
      'name)',
    );
    final scheme = Theme.of(context).colorScheme;
    final limit = view.limitMessage;
    final hasLimit = _limited(view);

    Widget rows(List<RoomEditorRoom> rooms) => _Card(
      child: _List(
        children: [
          for (final room in rooms)
            _RoomRow(
              key: Key('rooms.${room.room.id}'),
              room: room,
              assignLabel: view.assignLabel,
              initiallyOpen: _seeded.contains(room.room.id),
              editNode: _node(_editNodes, room.room.id, 'rooms.edit'),
              anchor: _node(_anchors, room.room.id, 'rooms.row'),
              onEdit: () => widget.onEdit(room.room.id),
              onArchive: () => widget.onArchive(room.room.id),
              onAssign: (accountId) => widget.onAssign(room.room.id, accountId),
            ),
        ],
      ),
    );

    return Semantics(
      key: const Key('rooms.editor'),
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          _Section(
            key: const Key('rooms.section.bedrooms'),
            title: view.bedroomsTitle,
            action: AppButton(
              key: const Key('rooms.add'),
              label: view.addLabel,
              variant: AppButtonVariant.ghost,
              icon: AppIcons.add,
              onPressed: hasLimit ? null : widget.onAdd,
              focusNode: _addNode,
            ),
            note: hasLimit
                ? Text(
                    limit!,
                    key: const Key('rooms.limit'),
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : null,
            child: view.bedrooms.isEmpty ? null : rows(view.bedrooms),
          ),
          if (view.commonAreas.isNotEmpty)
            _Section(
              key: const Key('rooms.section.commonAreas'),
              title: view.commonAreasTitle,
              child: rows(view.commonAreas),
            ),
          if (view.archived.isNotEmpty)
            _Section(
              key: const Key('rooms.section.archived'),
              title: view.archivedTitle!,
              child: _Card(
                child: _List(
                  children: [
                    for (final room in view.archived)
                      _ArchivedRow(
                        key: Key('rooms.${room.room.id}'),
                        room: room,
                        anchor: _node(_anchors, room.room.id, 'rooms.row'),
                        restoreNode: _node(
                          _restoreNodes,
                          room.room.id,
                          'rooms.restore',
                        ),
                        onRestore: () => widget.onRestore(room.room.id),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A heading (with an optional action beside it and a note under it), then
/// the card of rows.
class _Section extends StatelessWidget {
  const new({
    required this.title,
    required this.child,
    this.action,
    this.note,
    super.key,
  });

  final String title;
  final Widget? child;
  final Widget? action;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          // The button sits beside the heading when it fits whole and under
          // it when it does not.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppTypography.labelLg.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          ?note,
          ?child,
        ],
      ),
    );
  }
}

/// The surface of a list: the card color with a hairline edge.
class _Card extends StatelessWidget {
  const new({required this.child});

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _gap),
        child: child,
      ),
    );
  }
}

/// A list node with [children] separated by hairlines.
class _List extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.list,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              SizedBox(
                height: AppSizes.hairline,
                child: ColoredBox(color: line),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// The name and the line under it, one node.
class _Texts extends StatelessWidget {
  const new({
    required this.name,
    required this.subtitle,
    required this.nameStyle,
    required this.nameColor,
  });

  final String name;
  final String? subtitle;
  final TextStyle nameStyle;
  final Color nameColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: nameStyle.copyWith(color: nameColor)),
          if (subtitle != null && subtitle.isNotEmpty)
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// A 44 drawn, 48 hit area icon button named by [label].
class _IconButton extends StatelessWidget {
  const new({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.node,
  });

  /// The key of the button itself, which tests and the manifest name.
  final Key buttonKey;

  final FocusNode? node;
  final AppIcons icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      key: buttonKey,
      focusNode: node,
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size.square(AppSizes.minDrawn),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: AppIcon(icon, size: AppSizes.glyphAction),
      ),
    );
  }
}

/// An archived room: its texts, and the button that restores it.
class _ArchivedRow extends StatelessWidget {
  const new({
    required this.room,
    required this.anchor,
    required this.restoreNode,
    required this.onRestore,
    super.key,
  });

  final RoomEditorArchivedRoom room;
  final FocusNode anchor;
  final FocusNode restoreNode;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: anchor,
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.listItem,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Texts(
                  name: room.room.name,
                  subtitle: room.subtitle,
                  nameStyle: AppTypography.body,
                  nameColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                _IconButton(
                  buttonKey: Key('rooms.restore.${room.room.id}'),
                  node: restoreNode,
                  icon: AppIcons.history,
                  label: room.restoreLabel,
                  onPressed: onRestore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A room with its pebbles, texts and buttons, and the members it can take.
class _RoomRow extends StatefulWidget {
  const new({
    required this.room,
    required this.assignLabel,
    required this.initiallyOpen,
    required this.editNode,
    required this.anchor,
    required this.onEdit,
    required this.onArchive,
    required this.onAssign,
    super.key,
  });

  final RoomEditorRoom room;
  final String assignLabel;
  final bool initiallyOpen;
  final FocusNode editNode;
  final FocusNode anchor;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final ValueChanged<String> onAssign;

  @override
  State<_RoomRow> createState() => _RoomRowState();
}

class _RoomRowState extends State<_RoomRow> {
  final _assignNode = FocusNode(debugLabel: 'rooms.assign');
  final _optionNodes = <String, FocusNode>{};
  late bool _open = widget.initiallyOpen;

  FocusNode _optionNode(String id) =>
      _optionNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'rooms.option'));

  @override
  void didUpdateWidget(_RoomRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final room = widget.room;
    final options = {for (final o in room.assignOptions) o.member.id};
    final focusInOptions = [
      for (final id in _optionNodes.keys)
        if (!options.contains(id) && _optionNodes[id]!.hasFocus) id,
    ].isNotEmpty;
    final lostAssign =
        oldWidget.room.assignOptions.isNotEmpty && options.isEmpty;
    if (_traditional()) {
      if (lostAssign && (_assignNode.hasFocus || focusInOptions)) {
        _focusAfterFrame(() => widget.editNode, () => mounted);
      } else if (focusInOptions && options.isNotEmpty) {
        _focusAfterFrame(() => _assignNode, () => mounted);
      }
    }
    if (options.isEmpty) _open = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = {for (final o in widget.room.assignOptions) o.member.id};
      for (final id
          in _optionNodes.keys.where((id) => !current.contains(id)).toList()) {
        _optionNodes.remove(id)!.dispose();
      }
    });
  }

  @override
  void dispose() {
    _assignNode.dispose();
    for (final node in _optionNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _close() {
    setState(() => _open = false);
    _focusAfterFrame(() => _assignNode, () => mounted);
  }

  Widget _option(RoomAssignOption option) {
    final scheme = Theme.of(context).colorScheme;
    final member = option.member;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.listItem,
      child: TextButton(
        key: Key('rooms.option.${widget.room.room.id}.${member.id}'),
        focusNode: _optionNode(member.id),
        onPressed: () => widget.onAssign(member.id),
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppSizes.minTarget),
          ),
          alignment: AlignmentDirectional.centerStart,
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
        child: Semantics(
          label: option.semanticLabel,
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pebble(member, AppPebbleSize.s28),
              const SizedBox(width: _gap),
              Flexible(child: Text(member.name)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pebble(MemberView member, AppPebbleSize size) => AppPebble(
    key: Key('rooms.pebble.${widget.room.room.id}.${member.id}'),
    initials: member.initials,
    joinOrder: member.joinOrder,
    semanticLabel: member.semanticLabel,
    size: size,
    status: switch (member.status) {
      MemberStatus.home => AppPebbleStatus.home,
      MemberStatus.away => AppPebbleStatus.away,
      MemberStatus.invited => AppPebbleStatus.invited,
    },
    isYou: member.isYou,
    isAdmin: member.isAdmin,
  );

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final scheme = Theme.of(context).colorScheme;
    final options = room.assignOptions;
    final open = _open && options.isNotEmpty;

    final texts = _Texts(
      name: room.room.name,
      subtitle: room.subtitle,
      nameStyle: AppTypography.labelLg,
      nameColor: scheme.onSurface,
    );
    final lead = room.occupants.isEmpty
        ? texts
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 3 * (AppSizes.pebbleXs + AppSpacing.xs),
                  ),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final member in room.occupants)
                        _pebble(member, AppPebbleSize.s28),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: _gap),
              Flexible(child: texts),
            ],
          );

    return Focus(
      focusNode: widget.anchor,
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.listItem,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The buttons sit beside the texts when they fit and under them
              // when they do not, so no word is cut.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  lead,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconButton(
                        buttonKey: Key('rooms.edit.${room.room.id}'),
                        node: widget.editNode,
                        icon: AppIcons.edit,
                        label: room.editLabel,
                        onPressed: widget.onEdit,
                      ),
                      _IconButton(
                        buttonKey: Key('rooms.archive.${room.room.id}'),
                        icon: AppIcons.archive,
                        label: room.archiveLabel,
                        onPressed: widget.onArchive,
                      ),
                    ],
                  ),
                ],
              ),
              if (options.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppButton(
                    key: Key('rooms.assign.${room.room.id}'),
                    label: widget.assignLabel,
                    semanticLabel: room.assignLabel,
                    variant: AppButtonVariant.ghost,
                    icon: AppIcons.visit,
                    focusNode: _assignNode,
                    expanded: open,
                    onPressed: () => setState(() => _open = !open),
                  ),
                ),
              if (open)
                Actions(
                  actions: {
                    DismissIntent: CallbackAction<DismissIntent>(
                      onInvoke: (_) {
                        _close();
                        return null;
                      },
                    ),
                  },
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    role: SemanticsRole.list,
                    child: Column(
                      key: Key('rooms.options.${room.room.id}'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [for (final option in options) _option(option)],
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
