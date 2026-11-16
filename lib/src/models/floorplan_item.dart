import 'package:compapp_design/src/models/item_view.dart';
import 'package:flutter/foundation.dart';

/// A shared thing pinned to a room of the plan, as plain data: the [item], who
/// has it, and the two texts of its beacon.
///
/// [statusLabel] is the line under the name ("34 min", "free") and
/// [semanticLabel] the spoken name of the beacon ("Washer, in use by Carlos,
/// 34 minutes"), which must contain the visible name of the item in the same
/// words (WCAG 2.5.3, label in name). The app owns every word and every
/// duration.
@immutable
class FloorplanItem {
  const new({
    required this.item,
    required this.inUse,
    required this.statusLabel,
    required this.semanticLabel,
  }) : assert(statusLabel != '', 'A beacon says its status in words'),
       assert(semanticLabel != '', 'A beacon needs a spoken label');

  final ItemView item;
  final bool inUse;
  final String statusLabel;
  final String semanticLabel;

  @override
  bool operator ==(Object other) =>
      other is FloorplanItem &&
      other.item == item &&
      other.inUse == inUse &&
      other.statusLabel == statusLabel &&
      other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(item, inUse, statusLabel, semanticLabel);
}
