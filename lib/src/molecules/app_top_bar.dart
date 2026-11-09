import 'package:compapp_design/src/atoms/app_badge.dart';
import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/atoms/app_pebble.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/models/member_view.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Which bar it is: the one of a home tab or the one of a pushed screen.
enum AppTopBarVariant { home, pushed }

/// The bar on top of a screen.
///
/// [AppTopBar.home] shows the title with an optional subtitle, the activity
/// bell with its unread count, and the account pebble. The pebble is drawn
/// from [me], the signed-in member (initials and join order: the account is
/// yours by definition, so the pebble has no "you" ring), and the button that
/// holds it is named by [accountLabel], the name of
/// the action ("Your account"), not by the member: `MemberView.semanticLabel`
/// describes a person and is not read here. [me] is required: the home bar
/// belongs to a signed-in member, and a screen with nobody signed in has no
/// home bar (the board has no variant without the account button).
///
/// [AppTopBar.pushed] shows a back button and an optional text action such
/// as "Mark all as read" on one row, and the title as a heading below it.
///
/// Every string is a prop, and so is every spoken label: [activityLabel]
/// carries the unread count in words ("Activity, 3 unread"), because the badge
/// on the bell is only a visual copy of it and is merged into the button.
/// Spoken labels are never empty.
///
/// The bar is its own semantics group, so it keeps its parts apart under a
/// grouping parent such as a `Card` or a list item. The title is a heading
/// node of its own, and the parts are read in order: the title, the subtitle,
/// the bell, the account (the title, the back button, the action, on the
/// pushed bar). The buttons are 44
/// drawn with a 48 hit area. The bar has no router and no timers: the app
/// passes the callbacks. A null [onAction] disables the action. It mirrors in
/// right-to-left text, back arrow included.
///
/// The bar takes the top inset of the screen (the status bar) into its own
/// padding, as Material's `AppBar` does, so it needs no `SafeArea` above it.
///
/// Text grows with the system text scale and never shrinks, so a long title
/// wraps onto more lines and the bar grows with it. Above a scale of 1.3 the
/// bell and the account of the home bar move to a row of their own under the
/// title, so the title keeps the whole width instead of breaking inside its
/// words. The count badge of the bell grows to the side of the glyph, never
/// over it, and the bell takes the room it needs.
class AppTopBar extends StatelessWidget {
  const new home({
    required this.title,
    required String this.activityLabel,
    required int this.unreadCount,
    required VoidCallback this.onActivity,
    required MemberView this.me,
    required String this.accountLabel,
    required VoidCallback this.onAccount,
    this.subtitle,
    super.key,
  }) : variant = AppTopBarVariant.home,
       backLabel = null,
       onBack = null,
       actionLabel = null,
       onAction = null,
       assert(unreadCount >= 0, 'An unread count cannot be negative'),
       assert(activityLabel != '', 'The bell needs a spoken label'),
       assert(accountLabel != '', 'The account button needs a spoken label');

  const new pushed({
    required this.title,
    required String this.backLabel,
    required VoidCallback this.onBack,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : variant = AppTopBarVariant.pushed,
       subtitle = null,
       activityLabel = null,
       unreadCount = null,
       onActivity = null,
       me = null,
       accountLabel = null,
       onAccount = null,
       assert(backLabel != '', 'The back button needs a spoken label');

  final AppTopBarVariant variant;
  final String title;

  /// Second line of the home bar, such as who is home.
  final String? subtitle;

  /// Spoken name of the bell, with the unread count in words.
  final String? activityLabel;

  /// Unread count on the bell. Zero draws no badge.
  final int? unreadCount;
  final VoidCallback? onActivity;

  /// The signed-in member the account pebble is drawn from.
  final MemberView? me;

  /// Spoken name of the account button, the action it does ("Your account").
  final String? accountLabel;
  final VoidCallback? onAccount;

  /// Spoken name of the back button of the pushed bar.
  final String? backLabel;
  final VoidCallback? onBack;

  /// Text of the optional action of the pushed bar.
  final String? actionLabel;
  final VoidCallback? onAction;

  static const double _gap = AppSpacing.sm + AppSpacing.xs;

  /// Text scale above which the home bar puts its buttons under the title.
  static const double _stackActionsTextScale = 1.3;

  /// Where the badge starts, measured from the start of the 48 wide bell: the
  /// end edge of its glyph, so the badge sits beside the glyph and never
  /// covers it.
  static const double _badgeStart =
      (AppSizes.minTarget + AppSizes.glyphAction) / 2;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inset = MediaQuery.paddingOf(context).top;
    final heading = Semantics(
      container: true,
      header: true,
      sortKey: const OrdinalSortKey(0),
      child: Text(
        title,
        key: const Key('topBar.title'),
        style: AppTypography.title.copyWith(color: scheme.onSurface),
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: switch (variant) {
        AppTopBarVariant.home => _home(context, scheme, heading, inset),
        AppTopBarVariant.pushed => _pushed(scheme, heading, inset),
      },
    );
  }

  Widget _home(
    BuildContext context,
    ColorScheme scheme,
    Widget heading,
    double inset,
  ) {
    final subtitle = this.subtitle;
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackActionsTextScale;

    final titles = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading,
        if (subtitle != null && subtitle.isNotEmpty)
          Semantics(
            sortKey: const OrdinalSortKey(1),
            child: Text(
              subtitle,
              key: const Key('topBar.subtitle'),
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bell(),
        const SizedBox(width: _gap),
        _account(),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          _gap + inset,
          AppSpacing.md,
          _gap,
        ),
        child: stacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titles,
                  const SizedBox(height: _gap),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: actions,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titles),
                  const SizedBox(width: _gap),
                  actions,
                ],
              ),
      ),
    );
  }

  Widget _bell() {
    final unread = unreadCount!;
    return Stack(
      children: [
        OutlinedButton(
          key: const Key('topBar.activity'),
          onPressed: onActivity,
          style: _squareStyle(),
          child: Semantics(
            label: activityLabel,
            sortKey: const OrdinalSortKey(2),
            excludeSemantics: true,
            child: const AppIcon(AppIcons.bell, size: AppSizes.glyphAction),
          ),
        ),
        // The badge is laid out beside the glyph, so the bell grows with it
        // instead of the badge covering the glyph at large text.
        if (unread > 0)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: _badgeStart),
            child: IgnorePointer(
              child: ExcludeSemantics(child: AppBadge.count(unread)),
            ),
          ),
      ],
    );
  }

  Widget _account() {
    final me = this.me!;
    final label = accountLabel!;
    return TextButton(
      key: const Key('topBar.account'),
      onPressed: onAccount,
      style: _squareStyle(radius: AppSizes.pebbleMd * AppRadius.pebbleFraction),
      child: Semantics(
        label: label,
        sortKey: const OrdinalSortKey(3),
        excludeSemantics: true,
        child: AppPebble(
          initials: me.initials,
          joinOrder: me.joinOrder,
          semanticLabel: label,
        ),
      ),
    );
  }

  Widget _pushed(ColorScheme scheme, Widget heading, double inset) {
    final actionLabel = this.actionLabel;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm + inset,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                key: const Key('topBar.back'),
                onPressed: onBack,
                style: _squareStyle(foreground: scheme.onSurface),
                child: Semantics(
                  label: backLabel,
                  sortKey: const OrdinalSortKey(1),
                  excludeSemantics: true,
                  child: const AppIcon(AppIcons.back, size: AppSizes.glyphNav),
                ),
              ),
              if (actionLabel != null && actionLabel.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: TextButton(
                    key: const Key('topBar.action'),
                    onPressed: onAction,
                    style: const ButtonStyle(
                      textStyle: WidgetStatePropertyAll(AppTypography.label),
                    ),
                    child: Semantics(
                      sortKey: const OrdinalSortKey(1),
                      child: Text(actionLabel, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: heading,
          ),
        ],
      ),
    );
  }

  /// A 44 square button with no padding. Material pads the hit area to 48.
  static ButtonStyle _squareStyle({
    double radius = AppRadius.sm,
    Color? foreground,
  }) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.square(AppSizes.minDrawn)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      foregroundColor: foreground == null
          ? null
          : WidgetStatePropertyAll(foreground),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}
