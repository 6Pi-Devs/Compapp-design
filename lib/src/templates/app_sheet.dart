import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/foundation/header_body.dart';
import 'package:compapp_design/src/molecules/sheet_header.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_shadows.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The skeleton of a modal bottom sheet: a header with the title and the close
/// button, a body the app fills and the actions under it.
///
/// It is the layout `ItemSheet` proved, with the content left to the app: the
/// sheet surface (the sheet fill, top corners and shadow), a [SheetHeader], the
/// [body] slot and the [actions] slot, stacked and stretched to the width. It
/// takes plain data and one callback, [onClose], called by the close button and
/// by the Escape key. The app owns the words, what the body shows, the
/// buttons, and the route that shows the sheet.
///
/// The sheet is modal and meant for `showModalBottomSheet(isScrollControlled:
/// true, useSafeArea: true, backgroundColor: Colors.transparent, ...)`: the
/// sheet draws its own surface, `isScrollControlled` lets it use the height it
/// needs, and `useSafeArea` keeps the sheet under the status bar. Without it
/// the route removes the top inset, and once the keyboard is up at large text
/// the header slides under the status bar. The
/// header stays pinned and the body with the actions scrolls inside the sheet
/// when the height is bounded, so at large text on a short screen the last
/// action is reached by scrolling and nothing is clipped. When the header alone
/// would take more than half of a bounded height it stops being pinned and
/// scrolls together with the body. With no bound on the height (a golden, a
/// test) the sheet takes the height of its content.
///
/// The sheet adds the bottom inset of the screen (`MediaQuery.padding`, so an
/// ancestor `SafeArea` is not doubled) under the last child, and rides above
/// the keyboard: the height the keyboard takes (`MediaQuery.viewInsets`) is
/// left under the surface, so a field in the body is not covered and the
/// actions stay reachable.
///
/// For assistive technology the title is a heading that names the route (the
/// route that shows the sheet is the route scope, so the title is not said
/// twice), and focus starts on the title: once the sheet has been laid out the
/// title takes focus (and, with a keyboard, its ring), so the next Tab reaches
/// the close button and then the body. Focus is asked for once, when the sheet
/// opens, and only while the title is attached: a new title or a new body never
/// takes it back. Focus that is inside the body or the actions is the app's:
/// a button that disables itself while it has focus has to move focus first.
/// The sheet itself is one container, and its body and actions are the app's
/// widgets, so they say what they are.
///
/// [onClose] is called by the close button and by Escape while focus is inside
/// the sheet. The barrier, a drag down and the route's own dismiss action do
/// not reach it: the app must treat the pop result of the route as a close too.
///
/// The body is the first child of the scrolling column and the actions are the
/// last, so the body keeps its element, and its focus and text, when actions
/// come and go, and the actions keep theirs when the body changes. Give a
/// widget of a slot its own key where its position may change.
///
/// It needs a bounded width, grows with large text instead of clipping, nothing
/// clamped, and mirrors in right-to-left. It has no motion of its own.
class AppSheet extends StatefulWidget {
  const new({
    required this.title,
    required this.closeLabel,
    required this.onClose,
    required this.body,
    this.actions = const [],
    super.key,
  }) : assert(title != '', 'The title names the route'),
       assert(closeLabel != '', 'The close button needs a spoken label');

  /// The heading of the sheet. It names the route, so it is never empty.
  final String title;

  /// Spoken name of the close button, for example "Close".
  final String closeLabel;

  /// Called by the close button and by Escape.
  final VoidCallback onClose;

  /// What the sheet is about. It scrolls with the actions.
  final Widget body;

  /// The buttons under the body, one under the other and as wide as the sheet,
  /// in the order given (the one that confirms first). Only
  /// buttons: the sheet is not a place for other controls.
  final List<AppButton> actions;

  static const double _gap = AppSpacing.sm + AppSpacing.xs;

  @override
  State<AppSheet> createState() => _AppSheetState();
}

class _AppSheetState extends State<AppSheet> {
  final FocusNode _title = FocusNode(debugLabel: 'AppSheet.title');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A sheet that is gone by then has disposed the node.
      if (mounted && _title.parent != null) _title.requestFocus();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final padding = MediaQuery.paddingOf(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final actions = widget.actions;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
      },
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
              boxShadow: AppShadows.sheet,
            ),
            child: Scrollable(
              viewportBuilder: (context, position) => HeaderBody(
                offset: position,
                header: SheetHeader(
                  title: widget.title,
                  onClose: widget.onClose,
                  closeLabel: widget.closeLabel,
                  titleFocusNode: _title,
                  namesRoute: true,
                ),
                body: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.md + padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSheet._gap,
                    children: [
                      KeyedSubtree(
                        key: const Key('appSheet.body'),
                        child: widget.body,
                      ),
                      if (actions.isNotEmpty)
                        Column(
                          key: const Key('appSheet.actions'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          spacing: AppSpacing.sm,
                          children: actions,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
