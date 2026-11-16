import 'dart:math' as math;

import 'package:compapp_design/src/models/calendar_strip_day.dart';
import 'package:compapp_design/src/models/calendar_strip_event.dart';
import 'package:compapp_design/src/models/calendar_strip_view.dart';
import 'package:compapp_design/src/molecules/event_ribbon.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The week ahead on one card: seven day cells, a band of event ribbons under
/// them, and the events listed with their titles.
///
/// It composes [EventRibbon] and takes plain data ([CalendarStripView]) and
/// two callbacks: [onDayTap] with the date of the tapped day and [onEventTap]
/// with the id of the tapped event. Dates are `YYYY-MM-DD` strings in the
/// home's time zone and are only compared as strings: the app owns the calendar
/// and the clock, the strip does no date maths.
///
/// Each day is a button (its weekday over its number, today filled with the
/// primary color) whose spoken label is the app's label of the day followed by
/// the spoken label of every event that covers it, so a day reads its events.
/// Under the days, every event is drawn as a compact ribbon on each day it
/// covers (the glyph tells the kind, never the color alone), the pieces of one
/// event joining where it goes on and keeping a flat edge where it goes on past
/// the week. Events are placed in the first band row they do not overlap.
/// The ribbons only show where an event sits: they say nothing to assistive
/// technology. The events are named, and activated, in the list under the
/// band: one button per event with its glyph and its whole title, wrapped and
/// never cut, so nothing is lost at large text.
///
/// The seven days share the width equally and a day never gets less than
/// `AppSizes.minDrawn`. When the longest word of a day cell does not fit that
/// share (a weekday at 200% text), the days move to two rows, as the home bar
/// of `AppTopBar` does with its buttons, and the ribbons go with their days.
/// A small render object with intrinsic and dry layout does it, not a
/// `LayoutBuilder`, so the golden harness can measure the strip. The button of
/// a day is at least `AppSizes.minTarget` wide, which is wider than a column
/// in a narrow phone: it overlaps its neighbors by a few pixels and the node
/// is 48 wide, while a touch is handled by the column it falls in.
///
/// It is a plain column that takes its height from its content and needs a
/// bounded width. It grows with large text instead of clipping, never clamps
/// the text scale and mirrors in right-to-left (the first day at the right).
/// Its focus rings are drawn outside the shapes, so a parent that clips needs
/// `AppSizes.borderEmphasis` of room around it. It has no motion of its own.
class CalendarStrip extends StatelessWidget {
  const new({
    required this.view,
    required this.onDayTap,
    required this.onEventTap,
    super.key,
  });

  final CalendarStripView view;

  /// Called with the date of the tapped day.
  final ValueChanged<String> onDayTap;

  /// Called with the id of the tapped event.
  final ValueChanged<String> onEventTap;

  static const double _ribbonGap = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final days = view.days;
    assert(days.length == 7, 'A strip shows the seven days of the week');
    assert(_datesInOrder(days), 'The dates of the days are unique, in order');
    assert(_uniqueEventIds(view), 'The ids of the events are the row keys');
    assert(
      view.events.every((e) => e.startDate.compareTo(e.endDate) <= 0),
      'An event does not end before it starts',
    );
    assert(
      days.every(
        (day) =>
            day.semanticLabel.contains(day.weekday) &&
            day.semanticLabel.contains(day.dayNumber),
      ),
      'The spoken label of a day contains its visible texts (label in name)',
    );
    assert(
      view.events.every((e) => e.semanticLabel.contains(e.event.title)),
      'The spoken label of an event contains its visible title (label in name)',
    );
    final scheme = Theme.of(context).colorScheme;

    final placed = _place(view);
    final laneCount = placed.isEmpty
        ? 0
        : placed.map((p) => p.lane).reduce(math.max) + 1;

    return Semantics(
      key: const Key('calendar.strip'),
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: _EqualColumns(
                textDirection: Directionality.of(context),
                children: [
                  for (var i = 0; i < days.length; i++)
                    _FocusLast(
                      key: ValueKey(days[i].date),
                      child: _DayColumn(
                        day: days[i],
                        isToday: days[i].date == view.today,
                        events: [
                          for (final p in placed)
                            if (p.covers(i)) p.event,
                        ],
                        lanes: [
                          for (var lane = 0; lane < laneCount; lane++)
                            _pieceAt(placed, lane, i, days),
                        ],
                        onTap: () => onDayTap(days[i].date),
                      ),
                    ),
                ],
              ),
            ),
            if (placed.isNotEmpty) ...[
              SizedBox(
                height: AppSizes.hairline,
                child: ColoredBox(color: scheme.outlineVariant),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Semantics(
                  key: const Key('calendar.events'),
                  container: true,
                  explicitChildNodes: true,
                  role: SemanticsRole.list,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < placed.length; i++) ...[
                        if (i > 0)
                          SizedBox(
                            height: AppSizes.hairline,
                            child: ColoredBox(color: scheme.outlineVariant),
                          ),
                        _EventRow(
                          key: ValueKey(placed[i].event.event.id),
                          event: placed[i].event,
                          onTap: () => onEventTap(placed[i].event.event.id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The events that touch the week, each with the first and last day it
  /// covers and the lane (row of the ribbon band) it sits in.
  static List<_Placed> _place(CalendarStripView view) {
    final days = view.days;
    final placed = <_Placed>[];
    final lanes = <List<_Placed>>[];
    for (final event in view.events) {
      var first = -1;
      var last = -1;
      for (var i = 0; i < days.length; i++) {
        final date = days[i].date;
        if (date.compareTo(event.startDate) >= 0 &&
            date.compareTo(event.endDate) <= 0) {
          if (first < 0) first = i;
          last = i;
        }
      }
      if (first < 0) continue;
      var lane = 0;
      while (lane < lanes.length &&
          lanes[lane].any((p) => p.first <= last && first <= p.last)) {
        lane++;
      }
      if (lane == lanes.length) lanes.add([]);
      final item = _Placed(event, first, last, lane);
      lanes[lane].add(item);
      placed.add(item);
    }
    return placed;
  }

  static Widget? _pieceAt(
    List<_Placed> placed,
    int lane,
    int index,
    List<CalendarStripDay> days,
  ) {
    for (final p in placed) {
      if (p.lane != lane || !p.covers(index)) continue;
      final before =
          index > p.first || p.event.startDate.compareTo(days.first.date) < 0;
      final after =
          index < p.last || p.event.endDate.compareTo(days.last.date) > 0;
      return _Piece(
        key: Key('calendar.ribbon.${p.event.event.id}.${days[index].date}'),
        event: p.event,
        continuesBefore: before,
        continuesAfter: after,
      );
    }
    return null;
  }

  static bool _datesInOrder(List<CalendarStripDay> days) {
    for (var i = 1; i < days.length; i++) {
      if (days[i - 1].date.compareTo(days[i].date) >= 0) return false;
    }
    return true;
  }

  static bool _uniqueEventIds(CalendarStripView view) {
    final ids = [for (final e in view.events) e.event.id];
    return ids.length == ids.toSet().length;
  }
}

class _Placed {
  const new(this.event, this.first, this.last, this.lane);

  final CalendarStripEvent event;
  final int first;
  final int last;
  final int lane;

  bool covers(int index) => index >= first && index <= last;
}

/// One day: the button, then one slot per lane of the ribbon band.
class _DayColumn extends StatelessWidget {
  const new({
    required this.day,
    required this.isToday,
    required this.events,
    required this.lanes,
    required this.onTap,
  });

  final CalendarStripDay day;
  final bool isToday;
  final List<CalendarStripEvent> events;
  final List<Widget?> lanes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spoken = [day.semanticLabel, for (final e in events) e.semanticLabel];

    final button = TextButton(
      key: Key('calendar.day.${day.date}'),
      onPressed: onTap,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, AppSizes.minTarget)),
        // The tap target is the 48 of the button itself: the padded one would
        // make a day need 48 of width in its column.
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.xs / 2,
            vertical: AppSpacing.xs,
          ),
        ),
        backgroundColor: WidgetStatePropertyAll(
          isToday ? scheme.primary : Colors.transparent,
        ),
        foregroundColor: WidgetStatePropertyAll(
          isToday ? scheme.onPrimary : scheme.onSurface,
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
        ),
      ),
      child: Semantics(
        label: spoken.join('\n'),
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day.weekday,
              style: AppTypography.caption.copyWith(
                color: isToday ? scheme.onPrimary : scheme.onSurfaceVariant,
                fontWeight: isToday ? FontWeight.w600 : null,
              ),
            ),
            Text(
              day.dayNumber,
              style: AppTypography.labelLg.copyWith(
                color: isToday ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: CalendarStrip._ribbonGap,
      children: [
        _Widen(minWidth: AppSizes.minTarget, child: button),
        for (final lane in lanes)
          SizedBox(height: AppSizes.ribbon, child: lane),
      ],
    );
  }
}

/// One piece of an event ribbon, on one day: the compact ribbon, inset where
/// the event starts or ends so two events side by side do not touch. It says
/// nothing to assistive technology: the day and the event row do.
class _Piece extends StatelessWidget {
  const new({
    required this.event,
    required this.continuesBefore,
    required this.continuesAfter,
    super.key,
  });

  final CalendarStripEvent event;
  final bool continuesBefore;
  final bool continuesAfter;

  @override
  Widget build(BuildContext context) {
    const inset = AppSpacing.xs / 2;
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: continuesBefore ? 0 : inset,
          end: continuesAfter ? 0 : inset,
        ),
        child: EventRibbon(
          event: event.event,
          semanticLabel: event.semanticLabel,
          continuesBefore: continuesBefore,
          continuesAfter: continuesAfter,
          compact: true,
        ),
      ),
    );
  }
}

/// An event in the list: its glyph and its whole title, as one button named by
/// the spoken label of the event.
class _EventRow extends StatelessWidget {
  const new({required this.event, required this.onTap, super.key});

  final CalendarStripEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.listItem,
      child: TextButton(
        key: Key('calendar.event.${event.event.id}'),
        onPressed: onTap,
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.fromHeight(AppSizes.row)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
          ),
          alignment: AlignmentDirectional.centerStart,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            ),
          ),
        ),
        child: Semantics(
          label: event.semanticLabel,
          excludeSemantics: true,
          child: Row(
            children: [
              SizedBox(
                width: AppSizes.minDrawn,
                child: EventRibbon(
                  event: event.event,
                  semanticLabel: event.semanticLabel,
                  compact: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  event.event.title,
                  style: AppTypography.body.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gives its child at least [minWidth] of width, even when its parent is
/// narrower: the child is centered and spills over the sides, so the node of a
/// button in a narrow column is still a full tap target. It takes the width
/// and the intrinsic widths of the column, not of the wider child.
class _Widen extends SingleChildRenderObjectWidget {
  const new({required this.minWidth, required super.child});

  final double minWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWiden(minWidth);

  @override
  void updateRenderObject(BuildContext context, _RenderWiden renderObject) {
    renderObject.minWidth = minWidth;
  }
}

class _RenderWiden extends RenderShiftedBox {
  new(this._minWidth) : super(null);

  double _minWidth;
  double get minWidth => _minWidth;
  set minWidth(double value) {
    if (value == _minWidth) return;
    _minWidth = value;
    markNeedsLayout();
  }

  BoxConstraints _childConstraints(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return constraints.loosen();
    final width = math.max(_minWidth, constraints.maxWidth);
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: constraints.maxHeight,
    );
  }

  Size _sizeFor(BoxConstraints constraints, Size child) =>
      constraints.constrain(
        Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : child.width,
          child.height,
        ),
      );

  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(math.max(_minWidth, width)) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(math.max(_minWidth, width)) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return _sizeFor(
      constraints,
      child.getDryLayout(_childConstraints(constraints)),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = _sizeFor(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Offset(
      (size.width - child.size.width) / 2,
      0,
    );
  }
}

/// Lays out its children as equal columns of the width it is given, in one row
/// when the longest word of every child fits its column (and a column is never
/// narrower than `AppSizes.minDrawn`), and in rows of the same number of
/// columns, the last one shorter, when it does not. The rows are as tall as
/// their tallest child, and the columns mirror in right-to-left.
class _EqualColumns extends MultiChildRenderObjectWidget {
  const new({required this.textDirection, required super.children});

  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEqualColumns(textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEqualColumns renderObject,
  ) {
    renderObject.textDirection = textDirection;
  }
}

class _ColumnsParentData extends ContainerBoxParentData<RenderBox> {
  /// Whether focus is inside this column: it paints after the others, so its
  /// focus ring is not hidden by the filled shape of a later neighbor.
  bool paintLast = false;
}

/// Marks its column as the one to paint last while focus is inside it.
class _FocusLast extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<_FocusLast> createState() => _FocusLastState();
}

class _FocusLastState extends State<_FocusLast> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return _PaintLast(
      paintLast: _focused,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: widget.child,
      ),
    );
  }
}

class _PaintLast extends ParentDataWidget<_ColumnsParentData> {
  const new({required this.paintLast, required super.child});

  final bool paintLast;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _ColumnsParentData;
    if (data.paintLast == paintLast) return;
    data.paintLast = paintLast;
    renderObject.parent?.markNeedsPaint();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _EqualColumns;
}

typedef _ColumnsPlan = ({
  Size size,
  int perRow,
  double columnWidth,
  List<double> rowHeights,
});

class _RenderEqualColumns extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ColumnsParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ColumnsParentData> {
  new(this._textDirection);

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ColumnsParentData) {
      child.parentData = _ColumnsParentData();
    }
  }

  List<RenderBox> get _children => getChildrenAsList();

  double _need() {
    var need = AppSizes.minDrawn;
    for (final child in _children) {
      need = math.max(need, child.getMinIntrinsicWidth(double.infinity));
    }
    return need;
  }

  _ColumnsPlan _plan(BoxConstraints constraints) {
    final children = _children;
    final count = children.length;
    if (count == 0) {
      return (
        size: constraints.smallest,
        perRow: 0,
        columnWidth: 0,
        rowHeights: const [],
      );
    }
    final int perRow;
    final double columnWidth;
    if (constraints.hasBoundedWidth) {
      final fit = math.max(1, (constraints.maxWidth / _need()).floor());
      final rows = (count / math.min(fit, count)).ceil();
      perRow = (count / rows).ceil();
      columnWidth = constraints.maxWidth / perRow;
    } else {
      perRow = count;
      columnWidth = [
        for (final child in children)
          child.getMaxIntrinsicWidth(double.infinity),
      ].reduce(math.max);
    }
    final tight = BoxConstraints.tightFor(width: columnWidth);
    final rowHeights = <double>[];
    for (var start = 0; start < count; start += perRow) {
      var height = 0.0;
      for (final child in children.skip(start).take(perRow)) {
        height = math.max(height, child.getDryLayout(tight).height);
      }
      rowHeights.add(height);
    }
    final size = constraints.constrain(
      Size(
        constraints.hasBoundedWidth
            ? constraints.maxWidth
            : perRow * columnWidth,
        rowHeights.fold<double>(0, (sum, h) => sum + h),
      ),
    );
    return (
      size: size,
      perRow: perRow,
      columnWidth: columnWidth,
      rowHeights: rowHeights,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => _need();

  @override
  double computeMaxIntrinsicWidth(double height) {
    final children = _children;
    if (children.isEmpty) return 0;
    return children.length *
        [for (final child in children) child.getMaxIntrinsicWidth(height)]
            .reduce(math.max);
  }

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
    var top = 0.0;
    var index = 0;
    for (final rowHeight in plan.rowHeights) {
      for (var column = 0; column < plan.perRow; column++) {
        if (index >= childCount) break;
        final child = _children[index++]
          ..layout(
            BoxConstraints.tightFor(width: plan.columnWidth, height: rowHeight),
            parentUsesSize: true,
          );
        final x = rtl
            ? size.width - (column + 1) * plan.columnWidth
            : column * plan.columnWidth;
        (child.parentData! as _ColumnsParentData).offset = Offset(x, top);
      }
      top += rowHeight;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // In order, and the column with focus after the others.
    for (final last in [false, true]) {
      for (final child in _children) {
        final data = child.parentData! as _ColumnsParentData;
        if (data.paintLast == last) {
          context.paintChild(child, data.offset + offset);
        }
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
