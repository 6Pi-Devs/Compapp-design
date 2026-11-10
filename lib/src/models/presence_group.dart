import 'package:compapp_design/src/models/presence_entry.dart';
import 'package:flutter/foundation.dart';

/// A section of a presence panel: a [title] and the members under it.
///
/// A group with no [entries] says [emptyLabel] in place of its rows ("Nobody
/// is home right now"), and is left out of the panel when it has no label
/// either. The words are the app's and never blame anyone.
@immutable
class PresenceGroup {
  const new({required this.title, required this.entries, this.emptyLabel})
    : assert(title != '', 'A group needs a title');

  final String title;
  final List<PresenceEntry> entries;
  final String? emptyLabel;

  /// Whether the panel draws this group: it has members, or something to say
  /// in their place.
  bool get isShown =>
      entries.isNotEmpty || (emptyLabel != null && emptyLabel!.isNotEmpty);

  @override
  bool operator ==(Object other) =>
      other is PresenceGroup &&
      other.title == title &&
      listEquals(other.entries, entries) &&
      other.emptyLabel == emptyLabel;

  @override
  int get hashCode => Object.hash(title, Object.hashAll(entries), emptyLabel);
}
