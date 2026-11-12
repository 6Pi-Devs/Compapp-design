import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/foundation/header_body.dart';
import 'package:compapp_design/src/molecules/app_top_bar.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// The skeleton of a pushed screen that holds a form: the pushed [AppTopBar],
/// a column of fields the app fills in and the button that submits, which stays
/// at the bottom of the screen.
///
/// It takes plain data, the [fields] slot and two callbacks: [onBack], called
/// by the back button of the bar, and [onSubmit], called by the submit button
/// (null disables it, as for every button). The app owns the fields, their
/// controllers and errors, the validation, the words, and the route. While
/// [submitting] the button waits, as an [AppButton] does while it loads: the
/// app decides whether the fields stay editable.
///
/// The page is a `Scaffold`, so the keyboard takes room from it: the body is
/// laid out above the keyboard (`MediaQuery.viewInsets`), the submit button
/// rides on top of it and never sits under it, and the fields scroll. The bar
/// takes the top inset of the screen and the button the bottom inset (the home
/// indicator, `MediaQuery.padding`), so the page needs no `SafeArea`. The bar
/// stays pinned. When it alone would take more than half of the room that is
/// left above the button (the keyboard is up at 200% text on a short screen),
/// it scrolls away with the fields instead, so the fields keep the room.
/// The page fills the height it is given, so it needs a bounded height, as a
/// pushed route has.
///
/// The title names the route that shows the page, so assistive technology
/// announces it when the page opens. The fields are one form group; each
/// field says what it is. Tab goes through the back button, the fields in the
/// order they were given, then the submit button, whatever has scrolled out of
/// sight: the order is set by the page and not by where the fields are on the
/// screen. Focus is the app's, the page never takes it: put `autofocus` on the
/// field that should have it.
///
/// The fields are the first thing in the scrolling column, so they keep their
/// elements, their text and their focus when [submitting] or the submit
/// button changes. Give a field its own key where its position may change.
///
/// The order is the page's own and stays out of the fields: the fields are a
/// `FocusTraversalGroup` of their own, so a `FocusTraversalOrder` a field sets
/// inside it (or a group with its own policy) orders only the fields, and
/// never moves one of them in front of the back button or behind the submit
/// button.
///
/// When [onSubmit] becomes null while the submit button has focus, the page
/// moves focus off the disabled button instead of letting it fall back to the
/// last field, which would open the keyboard: with a keyboard (traditional
/// navigation) to the first stop of the page, the back button, and otherwise
/// to the route, with nothing focused. The submit button is the pinned
/// bottom bar of the `Scaffold`, so a `SnackBar` the app shows through the
/// `ScaffoldMessenger` sits above it and never covers it (an `AppSnackbar` the
/// app places itself needs a bottom margin that clears the button). The form
/// group holds the fields only: the button is pinned outside the scrolling
/// area, in its own subtree, and is read right after the last field.
///
/// A page is a route of its own (it is pushed above the home shell, not put
/// inside it), so it owns its `Scaffold`: a tab body inside a shell must not
/// use one. Inside a shell's `Scaffold` the `SnackBar` would go to the outer
/// `Scaffold` and cover the submit button, which is why a page template is
/// never nested in a shell (see AGENTS.md).
///
/// It grows with large text instead of clipping, nothing clamped, and mirrors
/// in right-to-left. It has no motion of its own.
class AppFormPage extends StatefulWidget {
  const new({
    required this.title,
    required this.backLabel,
    required this.onBack,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.submitting = false,
    this.submittingLabel,
    super.key,
  }) : assert(title != '', 'The title names the route'),
       assert(backLabel != '', 'The back button needs a spoken label'),
       assert(submitLabel != '', 'The submit button needs a label'),
       assert(submittingLabel != '', 'A spoken label is never empty');

  /// The heading of the page. It names the route, so it is never empty.
  final String title;

  /// Spoken name of the back button, for example "Back".
  final String backLabel;

  /// Called by the back button.
  final VoidCallback onBack;

  /// The form: one widget per field, stacked in the order given and as wide as
  /// the page allows.
  final List<Widget> fields;

  /// The visible label of the submit button.
  final String submitLabel;

  /// Called by the submit button. Null disables it.
  final VoidCallback? onSubmit;

  /// Whether the form is being sent: the button shows its spinner and ignores
  /// taps.
  final bool submitting;

  /// What assistive technology reads as the value of the button while
  /// [submitting], for example "Saving".
  final String? submittingLabel;

  static const double _gap = AppSpacing.md;

  @override
  State<AppFormPage> createState() => _AppFormPageState();
}

class _AppFormPageState extends State<AppFormPage> {
  final OrderedTraversalPolicy _policy = OrderedTraversalPolicy();
  final FocusNode _submit = FocusNode(debugLabel: 'AppFormPage.submit');

  @override
  void didUpdateWidget(AppFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onSubmit != null &&
        widget.onSubmit == null &&
        !widget.submitting &&
        _submit.hasFocus) {
      _leaveSubmit();
    }
  }

  /// A disabled button cannot hold focus, and focus would fall back to the
  /// last field and open the keyboard. Keyboard users get the first stop of
  /// the page, only if it is still attached; everyone else gets no focus.
  void _leaveSubmit() {
    final traditional =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final first = traditional
        ? _policy.findFirstFocus(_submit, ignoreCurrentFocus: true)
        : null;
    if (first != null && first != _submit && first.parent != null) {
      first.requestFocus();
    } else {
      _submit.unfocus();
    }
  }

  @override
  void dispose() {
    _submit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final padding = MediaQuery.paddingOf(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final widget = this.widget;
    assert(widget.fields.isNotEmpty, 'A form needs a field');

    return FocusTraversalGroup(
      policy: _policy,
      child: Scaffold(
        body: Scrollable(
          viewportBuilder: (context, position) => HeaderBody(
            offset: position,
            header: FocusTraversalOrder(
              order: const NumericFocusOrder(0),
              child: AppTopBar.pushed(
                title: widget.title,
                backLabel: widget.backLabel,
                onBack: widget.onBack,
                namesRoute: true,
              ),
            ),
            body: FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: FocusTraversalGroup(
                  child: Semantics(
                    role: SemanticsRole.form,
                    container: true,
                    explicitChildNodes: true,
                    child: Column(
                      key: const Key('formPage.fields'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppFormPage._gap,
                      children: widget.fields,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // The bottom bar of the Scaffold, so a SnackBar sits above it. The
        // Scaffold puts it at the bottom of the screen, under the keyboard, so
        // the room the keyboard takes is added under it: the bar is then
        // taller than the keyboard and the body ends above the button.
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm + AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md + padding.bottom,
                ),
                child: AppButton(
                  key: const Key('formPage.submit'),
                  focusNode: _submit,
                  label: widget.submitLabel,
                  onPressed: widget.onSubmit,
                  loading: widget.submitting,
                  loadingSemanticLabel: widget.submittingLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
