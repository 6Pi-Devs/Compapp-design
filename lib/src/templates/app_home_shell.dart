import 'dart:math' as math;

import 'package:compapp_design/src/models/member_view.dart';
import 'package:compapp_design/src/models/nav_destination_view.dart';
import 'package:compapp_design/src/molecules/app_nav_bar.dart';
import 'package:compapp_design/src/molecules/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// The skeleton of the main screens of a home: the home [AppTopBar] on top, the
/// body of the selected tab and the [AppNavBar] at the bottom.
///
/// It takes plain data and one callback, [onTabSelected], called with the index
/// of the tapped destination, also when it is the selected one (the app may
/// scroll to the top). The app owns everything else: the tab state (the
/// selected index comes in, the shell never changes it), the routing and the
/// navigators (a `StatefulShellRoute` supplies the [body]), the words, the
/// badges (a count on a [NavDestinationView] is plain data the shell passes
/// through) and what the bar buttons do. The shell holds no state of its own
/// beyond the layout.
///
/// The shell is the outer `Scaffold` of the main screens. A page that is pushed
/// from a tab (a form, a detail) goes on the root navigator, above the shell,
/// and owns a `Scaffold` of its own; a tab body is not a page template and must
/// not hold a `Scaffold`: two of them would both take the insets, and a
/// `SnackBar` would go to the wrong one (see AGENTS.md).
///
/// **Insets.** The bar takes the top inset of the screen (the status bar) and
/// the nav bar paints under the bottom inset (the home indicator), so the shell
/// needs no `SafeArea`. The body is told so: both insets are taken out of the
/// `MediaQuery` it sees, so a `SafeArea` or a list padding inside a tab does
/// not count them twice. The sides of the screen (a landscape cutout) are not
/// handled by the shell.
///
/// **Keyboard.** The shell is a `Scaffold`, so the body is laid out above the
/// keyboard (`MediaQuery.viewInsets`) and a field in it is scrolled into view
/// by Flutter. The nav bar stays where it is, at the bottom of the screen, and
/// the keyboard covers it: it takes no room from the body, the room is not
/// counted twice, and while it is covered it is out of the focus order and of
/// the semantics, so Tab and a screen reader never land on a button that
/// cannot be seen. A `SnackBar` rides above the keyboard. The keyboard is on
/// screen while the person types, so the bar gives way too: when it alone
/// would take more than half of the room above the keyboard (200% text on a
/// short screen) it is taken out of the layout, out of the focus order and out
/// of the semantics until the keyboard goes, so the body keeps the room. With
/// no keyboard the bar always stays, however tall.
///
/// **Route name and tabs.** The title names the route that shows the shell
/// ([AppTopBar]'s `namesRoute`), so a screen reader announces it when the shell
/// opens. The shell announces nothing when the tab changes, as Material's
/// `NavigationBar` does not: the selected state of the destination is the cue.
/// The app puts the name of the tab, or of the home, in [title]; where the
/// platform treats a new route name as a new window title (Android), a changed
/// title is read by that mechanism and the shell adds nothing to it.
///
/// **Focus.** Tab goes through the bar, the body, then the nav bar, whatever
/// has scrolled out of sight: the order is set by the shell, and an order the
/// app sets inside the body (a group of its own) never moves anything in front
/// of the bar or behind the nav bar. The shell does not key the body: the app
/// decides whether a tab change gives a fresh body, by keying its own (a body
/// with a `GlobalKey`, such as go_router's `StatefulNavigationShell`, keeps
/// everything it has, scroll positions included, and a keyed body is a fresh
/// subtree). When the tab changes while focus is inside the body and the person
/// is using a keyboard (traditional navigation), focus moves after the frame to
/// the first stop of the body, then to the first stop of the nav bar, only to
/// nodes that are attached. The same hand-over runs when focus was in the body
/// and the node that held it is gone after a rebuild with the same tab, when
/// the bar leaves the layout while focus is in it, and when the keyboard covers
/// the nav bar while focus is in it; a rebuild that leaves focus where it was
/// moves nothing, and with touch nothing is moved. A tap on a destination
/// leaves focus on that button.
///
/// It fills the height it is given, so it needs a bounded height, as a route
/// has. It grows with large text instead of clipping and mirrors in
/// right-to-left. The labels and the badge counts of the nav bar stop growing
/// at 1.3, as [AppNavBar] defines, and its width limit is its own: it
/// supports 360; 320 is unsupported, as for [AppNavBar], though it was checked
/// with short labels. It has no motion of its own.
class AppHomeShell extends StatefulWidget {
  const new({
    required this.title,
    required this.activityLabel,
    required this.unreadCount,
    required this.onActivity,
    required this.me,
    required this.accountLabel,
    required this.onAccount,
    required this.destinations,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.navigationLabel,
    required this.body,
    this.subtitle,
    super.key,
  }) : assert(title != '', 'The title names the route'),
       assert(unreadCount >= 0, 'An unread count cannot be negative'),
       assert(activityLabel != '', 'The bell needs a spoken label'),
       assert(accountLabel != '', 'The account button needs a spoken label'),
       assert(navigationLabel != '', 'The landmark needs a spoken label'),
       assert(destinations.length > 0, 'The shell needs a destination'),
       assert(
         destinations.length <= AppNavBar.maxDestinations,
         'The shell holds at most ${AppNavBar.maxDestinations} destinations',
       ),
       assert(
         selectedIndex >= 0 && selectedIndex < destinations.length,
         'selectedIndex is outside the destinations',
       );

  /// The heading of the bar. It names the route, so it is never empty.
  final String title;

  /// Second line of the bar, such as who is home.
  final String? subtitle;

  /// Spoken name of the bell, with the unread count in words.
  final String activityLabel;

  /// Unread count on the bell. Zero draws no badge.
  final int unreadCount;
  final VoidCallback onActivity;

  /// The signed-in member the account pebble is drawn from.
  final MemberView me;

  /// Spoken name of the account button, the action it does ("Your account").
  final String accountLabel;
  final VoidCallback onAccount;

  /// The tabs, at most [AppNavBar.maxDestinations]. Their ids key the body.
  final List<NavDestinationView> destinations;

  /// Index of the selected tab.
  final int selectedIndex;

  /// Called with the index of the tapped destination, the selected one too.
  final ValueChanged<int> onTabSelected;

  /// Name of the navigation landmark, for example "Main".
  final String navigationLabel;

  /// The body of the selected tab. It sees no top or bottom inset, has a
  /// bounded height and holds no `Scaffold`.
  final Widget body;

  @override
  State<AppHomeShell> createState() => _AppHomeShellState();
}

class _AppHomeShellState extends State<AppHomeShell> {
  final OrderedTraversalPolicy _policy = OrderedTraversalPolicy();
  final FocusNode _bodyFocus = FocusNode(
    debugLabel: 'AppHomeShell.body',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final FocusNode _navFocus = FocusNode(
    debugLabel: 'AppHomeShell.nav',
    canRequestFocus: false,
    skipTraversal: true,
  );

  final FocusNode _barFocus = FocusNode(
    debugLabel: 'AppHomeShell.bar',
    canRequestFocus: false,
    skipTraversal: true,
  );

  /// Whether the layout has taken the bar out because it is too tall for the
  /// room the keyboard leaves. Reported by the layout after a frame.
  bool _barCollapsed = false;
  bool _keyboardUp = false;
  bool _checkScheduled = false;

  bool get _traditional =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final up = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (up && !_keyboardUp && _navFocus.hasFocus) {
      _scheduleCheck(force: false);
    }
    _keyboardUp = up;
  }

  @override
  void didUpdateWidget(AppHomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_bodyFocus.hasFocus) {
      _scheduleCheck(force: oldWidget.selectedIndex != widget.selectedIndex);
    }
  }

  /// Once the frame is built, hands focus over if it was lost, or always when
  /// [force] (the tab changed). Only a keyboard user is helped: with touch
  /// nothing moves, so a field never opens the keyboard by itself. It is
  /// scheduled once and a rebuild does not cancel it.
  void _scheduleCheck({required bool force}) {
    if (_checkScheduled || !_traditional) return;
    _checkScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (!mounted) return;
      final current = FocusManager.instance.primaryFocus;
      final inside =
          _bodyFocus.hasFocus || _navFocus.hasFocus || _barFocus.hasFocus;
      final lost =
          current == null ||
          !current.canRequestFocus ||
          current.parent == null ||
          !inside;
      if (force || lost) _handOver();
    });
  }

  /// A keyboard user gets the first stop of the body, or else of the nav bar.
  /// Only nodes that are still attached are used, and nothing is forced when
  /// there is none.
  void _handOver() {
    for (final scope in [_bodyFocus, _navFocus]) {
      for (final node in scope.traversalDescendants) {
        if (node.parent != null && node.context != null) {
          node.requestFocus();
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    _bodyFocus.dispose();
    _navFocus.dispose();
    _barFocus.dispose();
    super.dispose();
  }

  void _collapsedChanged(bool collapsed) {
    if (mounted && collapsed != _barCollapsed) {
      if (collapsed && _barFocus.hasFocus) _scheduleCheck(force: false);
      setState(() => _barCollapsed = collapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final widget = this.widget;

    return FocusTraversalGroup(
      policy: _policy,
      child: Scaffold(
        body: _ShellLayout(
          collapsible: keyboardUp,
          onCollapsedChanged: _collapsedChanged,
          header: FocusTraversalOrder(
            order: const NumericFocusOrder(0),
            child: ExcludeFocus(
              excluding: _barCollapsed,
              child: Focus(
                focusNode: _barFocus,
                child: AppTopBar.home(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  activityLabel: widget.activityLabel,
                  unreadCount: widget.unreadCount,
                  onActivity: widget.onActivity,
                  me: widget.me,
                  accountLabel: widget.accountLabel,
                  onAccount: widget.onAccount,
                  namesRoute: true,
                ),
              ),
            ),
          ),
          body: FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: Focus(
              focusNode: _bodyFocus,
              child: FocusTraversalGroup(
                child: Builder(
                  // Read below the Scaffold, which has already taken the
                  // keyboard out of what the body sees.
                  builder: (context) => MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    child: widget.body,
                  ),
                ),
              ),
            ),
          ),
        ),
        // The bottom bar of the Scaffold, so a SnackBar sits above it. It
        // stays at the bottom of the screen and the keyboard covers it.
        bottomNavigationBar: FocusTraversalOrder(
          order: const NumericFocusOrder(2),
          child: ExcludeSemantics(
            excluding: keyboardUp,
            child: ExcludeFocus(
              excluding: keyboardUp,
              child: Focus(
                focusNode: _navFocus,
                child: AppNavBar(
                  destinations: widget.destinations,
                  selectedIndex: widget.selectedIndex,
                  onSelected: widget.onTabSelected,
                  semanticLabel: widget.navigationLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ShellSlot { header, body }

/// A header over a body that fills a bounded height. The header takes its own
/// height and the body the rest, unless [collapsible] and the header alone is
/// taller than half of the height: then the header is out of the layout, the
/// paint, the hit test and the semantics, and the body takes it all. Without a
/// bound on the height it is a column. [onCollapsedChanged] is told after the
/// frame whenever the header goes out or comes back, so the widget tree can
/// take it out of the focus order too.
class _ShellLayout
    extends SlottedMultiChildRenderObjectWidget<_ShellSlot, RenderBox> {
  const new({
    required this.collapsible,
    required this.onCollapsedChanged,
    required this.header,
    required this.body,
  });

  final bool collapsible;
  final ValueChanged<bool> onCollapsedChanged;
  final Widget header;
  final Widget body;

  @override
  Iterable<_ShellSlot> get slots => _ShellSlot.values;

  @override
  Widget? childForSlot(_ShellSlot slot) => switch (slot) {
    _ShellSlot.header => header,
    _ShellSlot.body => body,
  };

  @override
  SlottedContainerRenderObjectMixin<_ShellSlot, RenderBox> createRenderObject(
    BuildContext context,
  ) => _RenderShellLayout(
    collapsible: collapsible,
    onCollapsedChanged: onCollapsedChanged,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderShellLayout renderObject,
  ) {
    renderObject
      ..collapsible = collapsible
      ..onCollapsedChanged = onCollapsedChanged;
  }
}

typedef _ShellSizes = ({Size header, Size body, bool collapsed});

class _RenderShellLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_ShellSlot, RenderBox> {
  new({required this._collapsible, required this.onCollapsedChanged});

  bool _collapsible;
  ValueChanged<bool> onCollapsedChanged;
  bool _collapsed = false;

  bool get collapsible => _collapsible;

  set collapsible(bool value) {
    if (value == _collapsible) return;
    _collapsible = value;
    markNeedsLayout();
  }

  RenderBox get _header => childForSlot(_ShellSlot.header)!;
  RenderBox get _body => childForSlot(_ShellSlot.body)!;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  _ShellSizes _layout(BoxConstraints constraints, ChildLayouter layout) {
    final width = constraints.maxWidth;
    final header = layout(
      _header,
      BoxConstraints(minWidth: width, maxWidth: width),
    );
    final bounded = constraints.hasBoundedHeight;
    final collapsed =
        _collapsible && bounded && header.height > constraints.maxHeight / 2;
    final room = bounded
        ? math.max<double>(
            0,
            constraints.maxHeight - (collapsed ? 0 : header.height),
          )
        : double.infinity;
    final body = layout(
      _body,
      BoxConstraints(
        minWidth: width,
        maxWidth: width,
        minHeight: bounded ? room : 0,
        maxHeight: room,
      ),
    );
    return (header: header, body: body, collapsed: collapsed);
  }

  Size _sizeOf(BoxConstraints constraints, _ShellSizes sizes) {
    final content =
        (sizes.collapsed ? 0 : sizes.header.height) + sizes.body.height;
    return constraints.constrain(Size(constraints.maxWidth, content));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _sizeOf(
    constraints,
    _layout(constraints, ChildLayoutHelper.dryLayoutChild),
  );

  @override
  void performLayout() {
    final sizes = _layout(constraints, ChildLayoutHelper.layoutChild);
    (_header.parentData! as BoxParentData).offset = Offset.zero;
    (_body.parentData! as BoxParentData).offset = Offset(
      0,
      sizes.collapsed ? 0 : sizes.header.height,
    );
    size = _sizeOf(constraints, sizes);
    if (sizes.collapsed != _collapsed) {
      _collapsed = sizes.collapsed;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (attached) onCollapsedChanged(_collapsed);
      });
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _header.getMinIntrinsicWidth(height),
    _body.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    _header.getMaxIntrinsicWidth(height),
    _body.getMaxIntrinsicWidth(height),
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      _header.getMinIntrinsicHeight(width) + _body.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _header.getMaxIntrinsicHeight(width) + _body.getMaxIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) {
    context.paintChild(
      _body,
      offset + (_body.parentData! as BoxParentData).offset,
    );
    if (!_collapsed) context.paintChild(_header, offset);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (!_collapsed) visitor(_header);
    visitor(_body);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [_body, if (!_collapsed) _header]) {
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
