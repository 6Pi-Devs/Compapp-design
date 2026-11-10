import 'package:compapp_design/src/models/app_icons.dart';
import 'package:flutter/foundation.dart';

/// One destination of the navigation bar. Plain data owned by this package;
/// the app builds the list from its routes and strings.
@immutable
class NavDestinationView {
  const new({
    required this.id,
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    this.semanticLabel,
  }) : assert(label != '', 'A destination needs a visible label'),
       assert(semanticLabel != '', 'A spoken label is never empty'),
       assert(badgeCount >= 0, 'A count cannot be negative');

  /// Stable name of the destination (`home`, `tasks`). It becomes the key of
  /// its button, so it never depends on the position in the list.
  final String id;
  final AppIcons icon;

  /// The visible label under the icon.
  final String label;

  /// A count drawn beside the icon. Zero draws none.
  final int badgeCount;

  /// What assistive technology reads instead of [label], with the count in
  /// words ("Tasks, 2 to do"). It must contain the visible [label], so people
  /// who speak the label to a voice control can reach the button (WCAG 2.5.3).
  /// Required to say the count: without it the destination reads [label]
  /// alone.
  final String? semanticLabel;

  @override
  bool operator ==(Object other) =>
      other is NavDestinationView &&
      other.id == id &&
      other.icon == icon &&
      other.label == label &&
      other.badgeCount == badgeCount &&
      other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(id, icon, label, badgeCount, semanticLabel);
}
