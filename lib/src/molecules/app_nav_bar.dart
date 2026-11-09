import 'package:compapp_design/src/atoms/app_badge.dart';
import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/models/nav_destination_view.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// The bar at the bottom of the main screens: one button per destination.
///
/// The bar knows nothing about routes. The app passes the [destinations], the
/// [selectedIndex] and [onSelected], which is called with the index of the
/// tapped destination, also when it is the selected one (the app may scroll to
/// the top). Every string is a prop.
///
/// The selected destination is drawn with a primary-soft plate behind its icon
/// and a 2 px primary border around the plate, ink text and an ink icon: the
/// border is a shape, so the selection never relies on color alone. The others
/// are muted.
///
/// A [NavDestinationView.badgeCount] above zero draws a count badge beside the
/// icon, never over it. The badge is only a visual copy: the destination reads
/// its `semanticLabel` ("Tasks, 2 to do") once, as one button.
///
/// For assistive technology the bar is a navigation landmark named by
/// [semanticLabel]. Each destination is a focusable button with a selected
/// state, in a mutually exclusive group, named by its label. Destinations are
/// 52 tall, share the width and are at least 48 wide. The order mirrors in
/// right-to-left text.
///
/// The bar holds at most [maxDestinations] destinations, like the board: with
/// more, a label like "Calendario" no longer fits a column of a 360 wide phone.
/// Keep labels to short single words. 360 is the narrowest width the bar
/// supports, the smallest target of the app: on a 320 wide screen "Calendario"
/// at 1.3 breaks inside the word and the largest badge leaves its column.
///
/// The bar paints its surface under the bottom inset of the screen (the home
/// indicator), as Material's `NavigationBar` does, so it needs no `SafeArea`
/// below it.
///
/// The one place where this design system caps the text scale: the labels and
/// the badge counts of this bar stop growing at [maxLabelTextScale] (1.3), as
/// the labels of Material's `NavigationBar` do (`_kMaxLabelTextScaleFactor`,
/// whose docs say a bottom bar loses its usability at larger sizes). Four
/// columns of a phone cannot hold a word at 2.0 without cutting it. The full
/// label stays in the semantics, and assistive technology is not capped.
class AppNavBar extends StatelessWidget {
  const new({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.semanticLabel,
    super.key,
  }) : assert(destinations.length > 0, 'The bar needs a destination'),
       assert(
         destinations.length <= maxDestinations,
         'The bar holds at most $maxDestinations destinations',
       ),
       assert(
         selectedIndex >= 0 && selectedIndex < destinations.length,
         'selectedIndex is outside the destinations',
       );

  /// The most destinations the bar holds.
  static const int maxDestinations = 4;

  /// The text scale where labels and badge counts stop growing.
  static const double maxLabelTextScale = 1.3;

  final List<NavDestinationView> destinations;

  /// Index of the selected destination.
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Name of the navigation landmark, for example "Main".
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inset = MediaQuery.paddingOf(context).bottom;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.navigation,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm + AppSpacing.xs + inset,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, destination) in destinations.indexed)
                  Expanded(
                    child: _Destination(
                      key: Key('nav.${destination.id}'),
                      destination: destination,
                      selected: index == selectedIndex,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const new({
    required this.destination,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final NavDestinationView destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    const plateRadius = BorderRadius.all(Radius.circular(AppRadius.sm));
    final badge = destination.badgeCount;
    final spoken = destination.semanticLabel;

    final plate = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.navPlatePadding,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : null,
        borderRadius: plateRadius,
      ),
      foregroundDecoration: selected
          ? BoxDecoration(
              borderRadius: plateRadius,
              border: Border.all(
                color: scheme.primary,
                width: AppSizes.borderEmphasis,
              ),
            )
          : null,
      child: AppIcon(destination.icon, size: AppSizes.glyphNav, color: ink),
    );

    final badged = Stack(
      clipBehavior: Clip.none,
      children: [
        plate,
        // Starts where the glyph ends and sits at the top of the plate: it
        // grows to the side, away from the glyph, and takes no room.
        if (badge > 0)
          PositionedDirectional(
            start: AppSizes.navPlatePadding + AppSizes.glyphNav,
            top: 0,
            width: 0,
            height: 0,
            child: OverflowBox(
              alignment: AlignmentDirectional.topStart,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: ExcludeSemantics(
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: AppNavBar.maxLabelTextScale,
                  child: AppBadge.count(badge),
                ),
              ),
            ),
          ),
      ],
    );

    return TextButton(
      onPressed: onTap,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(AppSizes.minTarget, AppSizes.controlLg),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: AppSpacing.xs),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: plateRadius),
        ),
        // Icons line up across destinations whose labels wrap differently.
        alignment: Alignment.topCenter,
      ),
      child: Semantics(
        label: spoken == null || spoken.isEmpty ? destination.label : spoken,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badged,
            const SizedBox(height: AppSpacing.xs),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: AppNavBar.maxLabelTextScale,
              child: Text(
                destination.label,
                textAlign: TextAlign.center,
                style: AppTypography.navLabel.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
