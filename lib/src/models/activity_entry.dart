import 'package:compapp_design/src/models/activity_view.dart';
import 'package:flutter/foundation.dart';

/// One entry of an activity list: the [view] a row draws and the
/// [semanticLabel] it says.
///
/// Whether the entry is unread is not a field: it is the list the entry sits
/// in (`ActivityListView.unread` or `ActivityListView.earlier`), so an entry
/// can never be both. The label is the app's whole spoken description of the
/// entry, the visible text in the same words. It does not say whether the
/// entry is unread: the list puts `ActivityListView.unreadPrefix` before the
/// label of the entries in its unread list.
@immutable
class ActivityEntry {
  const new({required this.view, required this.semanticLabel})
    : assert(semanticLabel != '', 'An entry needs a spoken label');

  final ActivityView view;
  final String semanticLabel;

  @override
  bool operator ==(Object other) =>
      other is ActivityEntry &&
      other.view == view &&
      other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(view, semanticLabel);
}
