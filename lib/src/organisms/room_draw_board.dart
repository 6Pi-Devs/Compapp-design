import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_badge.dart';
import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/foundation/equal_pair.dart';
import 'package:compapp_design/src/models/room_draw_room.dart';
import 'package:compapp_design/src/models/room_draw_status.dart';
import 'package:compapp_design/src/models/room_draw_view.dart';
import 'package:compapp_design/src/models/room_tile_state.dart';
import 'package:compapp_design/src/molecules/room_tile.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The result of a room draw as the admin and the members see it: a card with
/// the status of the draw and one [RoomTile] (in its draw form) for each
/// bedroom, and under it the two buttons of the admin, "Draw again" and "Apply
/// result", or the note that tells a member who decides.
///
/// It composes [RoomTile], `AppBadge` (the status), `AppButton` and `AppPebble`
/// (inside the tile). It takes plain data ([RoomDrawView]) and two callbacks:
/// [onDrawAgain] and [onApply]. The board draws no lot and has no clock: the
/// server draws at random and the app hands over the result already worded.
/// Only the admin draws and applies, so for a member the buttons are not drawn
/// and the note says why. A null callback means that action is not offered:
/// the button is not drawn, never drawn disabled, because a disabled button
/// would differ from an enabled one by color alone. An applied draw offers
/// only "Draw again", since there is nothing left to apply.
///
/// Both buttons stay enabled while the app answers. The app says what went
/// wrong in its own words: the daily limit of draws, a draw that is out
/// of date because someone joined or a bedroom changed, a request that did not
/// reach the server.
///
/// For assistive technology the status is a node, the bedrooms are a list with
/// one item for each, named by the app ("Bedroom 1: Carlos, from Bedroom 3"),
/// and the buttons are named by their visible labels. The pebbles and captions
/// add nothing of their own. Nothing is told by color alone: the status is a
/// word, a bedroom that stays free says so and has a dashed outline, and who
/// goes where is said in words.
///
/// The bedrooms sit in two columns of equal width, or in one when a word of a
/// bedroom would not fit its half, and a row is as tall as its tallest tile.
/// The two buttons share a row, or stack when a word does not fit. A small
/// render object with intrinsic and dry layout does it, not a `LayoutBuilder`.
/// Nothing is cut or clamped, large text grows the board, and it mirrors in
/// right-to-left. It is a column that takes its height from its content and
/// needs a bounded width: put it in the scrollable of the screen. It has no
/// motion.
///
/// Focus, for someone using a keyboard and once the new view is laid out: when
/// the button that holds focus is not offered any more (applying it makes the
/// draw applied, or the person stops being the admin) focus moves to the other
/// button, and when there is none, to the status, which shows the house focus
/// ring. A new draw keeps the focus of the button that held it.
class RoomDrawBoard extends StatefulWidget {
  const new({required this.view, this.onDrawAgain, this.onApply, super.key});

  final RoomDrawView view;

  /// Called by the "Draw again" button. Null: the button is not offered.
  final VoidCallback? onDrawAgain;

  /// Called by the "Apply result" button. Null: the button is not offered.
  final VoidCallback? onApply;

  @override
  State<RoomDrawBoard> createState() => _RoomDrawBoardState();
}

const double _gap = AppSpacing.sm + AppSpacing.xs;

bool _traditional() =>
    FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

bool _canDraw(RoomDrawBoard board) =>
    board.view.isAdmin && board.onDrawAgain != null;

bool _canApply(RoomDrawBoard board) =>
    board.view.isAdmin &&
    board.view.status == RoomDrawStatus.pending &&
    board.onApply != null;

class _RoomDrawBoardState extends State<RoomDrawBoard> {
  final _drawNode = FocusNode(debugLabel: 'roomDraw.drawAgain');
  final _applyNode = FocusNode(debugLabel: 'roomDraw.apply');
  final _statusNode = FocusNode(debugLabel: 'roomDraw.status');

  @override
  void didUpdateWidget(RoomDrawBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_traditional()) return;
    final FocusNode? target;
    if (_drawNode.hasFocus) {
      target = _canDraw(widget)
          ? _drawNode
          : _canApply(widget)
          ? _applyNode
          : _statusNode;
    } else if (_applyNode.hasFocus) {
      target = _canApply(widget)
          ? _applyNode
          : _canDraw(widget)
          ? _drawNode
          : _statusNode;
    } else {
      return;
    }
    // Asked for after the frame, once the new view is laid out. A rebuild
    // never cancels it and asking again is harmless.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (target!.parent != null && target.canRequestFocus) {
        target.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _drawNode.dispose();
    _applyNode.dispose();
    _statusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final rooms = view.bedrooms;
    assert(rooms.isNotEmpty, 'A draw has at least one bedroom');
    assert(
      rooms.length == {for (final r in rooms) r.room.id}.length,
      'The ids of the bedrooms are keys',
    );
    assert(() {
      final ids = [
        for (final r in rooms)
          for (final m in r.members) m.id,
      ];
      return ids.length == ids.toSet().length;
    }(), 'A member goes to one bedroom only');
    assert(
      rooms.every(
        (r) =>
            r.semanticLabel.contains(r.room.name) &&
            r.semanticLabel.contains(r.caption),
      ),
      'The spoken label of a bedroom holds its visible name and caption '
      '(label in name)',
    );
    assert(
      view.isAdmin || (view.readOnlyNote ?? '').isNotEmpty,
      'A member needs the note that says who decides',
    );

    final scheme = Theme.of(context).colorScheme;
    final canDraw = _canDraw(widget);
    final canApply = _canApply(widget);

    final draw = AppButton(
      key: const Key('roomDraw.drawAgain'),
      label: view.drawAgainLabel,
      variant: AppButtonVariant.secondary,
      focusNode: _drawNode,
      onPressed: widget.onDrawAgain,
    );
    final apply = AppButton(
      key: const Key('roomDraw.apply'),
      label: view.applyLabel,
      focusNode: _applyNode,
      onPressed: widget.onApply,
    );

    return Semantics(
      key: const Key('roomDraw.board'),
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _Status(
                      key: const Key('roomDraw.status'),
                      node: _statusNode,
                      label: view.statusLabel,
                      pending: view.status == RoomDrawStatus.pending,
                    ),
                  ),
                  Semantics(
                    key: Key('roomDraw.${view.drawId}'),
                    container: true,
                    explicitChildNodes: true,
                    role: SemanticsRole.list,
                    child: _TileGrid(
                      textDirection: Directionality.of(context),
                      children: [
                        for (final room in rooms)
                          Semantics(
                            key: Key('roomDraw.room.${room.room.id}'),
                            container: true,
                            explicitChildNodes: true,
                            role: SemanticsRole.listItem,
                            child: _tile(room),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!view.isAdmin && (view.readOnlyNote ?? '').isNotEmpty)
            Text(
              view.readOnlyNote!,
              key: const Key('roomDraw.note'),
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else if (canDraw && canApply)
            EqualPair(
              spacing: AppSpacing.sm,
              textDirection: Directionality.of(context),
              children: [draw, apply],
            )
          else if (canDraw)
            draw
          else if (canApply)
            apply,
        ],
      ),
    );
  }

  Widget _tile(RoomDrawRoom room) => RoomTile(
    room: room.room,
    state: room.members.isEmpty ? RoomTileState.free : RoomTileState.home,
    caption: room.caption,
    semanticLabel: room.semanticLabel,
    occupants: room.members,
    draw: true,
  );
}

/// The status of the draw as a badge with its word (a live region, so a change
/// is announced), and the fallback target of focus: it takes the house ring
/// (2 px of ink outside the shape) while it holds the primary focus and the
/// person is using a keyboard.
class _Status extends StatefulWidget {
  const new({
    required this.node,
    required this.label,
    required this.pending,
    super.key,
  });

  final FocusNode node;
  final String label;
  final bool pending;

  @override
  State<_Status> createState() => _StatusState();
}

class _StatusState extends State<_Status> {
  bool _ring = false;

  @override
  void initState() {
    super.initState();
    widget.node.addListener(_update);
    FocusManager.instance.addHighlightModeListener(_onMode);
  }

  @override
  void didUpdateWidget(_Status oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node != widget.node) {
      oldWidget.node.removeListener(_update);
      widget.node.addListener(_update);
      _update();
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onMode);
    widget.node.removeListener(_update);
    super.dispose();
  }

  void _onMode(FocusHighlightMode mode) => _update();

  void _update() {
    final ring = widget.node.hasPrimaryFocus && _traditional();
    if (ring != _ring) setState(() => _ring = ring);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.node,
      skipTraversal: true,
      includeSemantics: false,
      child: CustomPaint(
        foregroundPainter: _RingPainter(
          ring: _ring,
          ink: Theme.of(context).colorScheme.onSurface,
        ),
        // A live region, so a screen reader says the new word when the draw
        // goes from pending to applied.
        child: Semantics(
          liveRegion: true,
          container: true,
          child: AppBadge.label(
            widget.label,
            tone: widget.pending ? AppBadgeTone.busy : AppBadgeTone.soft,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const new({required this.ring, required this.ink});

  final bool ring;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (!ring) return;
    // A stroke is centered on its path: the badge inflated by half the width
    // puts all of the ring outside it.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(AppSizes.badgeLabelRadius),
      ).inflate(AppSizes.borderEmphasis / 2),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.borderEmphasis,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ring != ring || old.ink != ink;
}

/// Lays the tiles out in rows of at most two columns of equal width. In a
/// bounded width it takes two columns when each half holds the longest word of
/// every tile, and one otherwise. A row is as tall as its tallest
/// tile and at least `AppSizes.rowTall`, and the tiles of a row are as tall as
/// the row. A last tile that is alone keeps the width of a column.
class _TileGrid extends MultiChildRenderObjectWidget {
  const new({required this.textDirection, required super.children});

  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTileGrid(textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderTileGrid renderObject) {
    renderObject.textDirection = textDirection;
  }
}

class _GridParentData extends ContainerBoxParentData<RenderBox>;

typedef _Plan = ({Size size, int columns, double cell, List<double> heights});

class _RenderTileGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GridParentData> {
  new(this._textDirection);

  static const double _spacing = AppSpacing.sm;
  static const int _maxColumns = 2;

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GridParentData) {
      child.parentData = _GridParentData();
    }
  }

  double _need() {
    // The tiles are not controls, so there is no floor of 48: a column is as
    // narrow as its longest word.
    var need = 0.0;
    for (final child in getChildrenAsList()) {
      need = math.max(need, child.getMinIntrinsicWidth(double.infinity));
    }
    return need;
  }

  _Plan _plan(BoxConstraints constraints) {
    final children = getChildrenAsList();
    if (children.isEmpty) {
      return (
        size: constraints.smallest,
        columns: 1,
        cell: 0,
        heights: const [],
      );
    }
    final bounded = constraints.hasBoundedWidth;
    var columns = math.min(_maxColumns, children.length);
    if (bounded) {
      final fit = ((constraints.maxWidth + _spacing) / (_need() + _spacing))
          .floor();
      columns = math.max(1, math.min(columns, fit));
    }
    var cell = 0.0;
    if (bounded) {
      cell = (constraints.maxWidth - _spacing * (columns - 1)) / columns;
    } else {
      for (final child in children) {
        cell = math.max(cell, child.getMaxIntrinsicWidth(double.infinity));
      }
    }
    final heights = <double>[];
    for (var start = 0; start < children.length; start += columns) {
      var height = AppSizes.rowTall;
      for (final child in children.skip(start).take(columns)) {
        height = math.max(
          height,
          child.getDryLayout(BoxConstraints.tightFor(width: cell)).height,
        );
      }
      heights.add(height);
    }
    final width = bounded
        ? constraints.maxWidth
        : columns * cell + _spacing * (columns - 1);
    final height =
        heights.fold<double>(0, (sum, h) => sum + h) +
        _spacing * (heights.length - 1);
    return (
      size: constraints.constrain(Size(width, height)),
      columns: columns,
      cell: cell,
      heights: heights,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => _need();

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _plan(const BoxConstraints()).size.width;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _plan(BoxConstraints(maxWidth: width)).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _plan(constraints).size;

  @override
  void performLayout() {
    final plan = _plan(constraints);
    size = plan.size;
    final rtl = _textDirection == TextDirection.rtl;
    final children = getChildrenAsList();
    var top = 0.0;
    var index = 0;
    for (final height in plan.heights) {
      for (var column = 0; column < plan.columns; column++) {
        if (index >= children.length) break;
        final child = children[index++]
          ..layout(
            BoxConstraints.tightFor(width: plan.cell, height: height),
            parentUsesSize: true,
          );
        final x = column * (plan.cell + _spacing);
        (child.parentData! as _GridParentData).offset = Offset(
          rtl ? size.width - x - plan.cell : x,
          top,
        );
      }
      top += height + _spacing;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
