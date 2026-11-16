import 'package:compapp_design/src/models/activity_entry.dart';
import 'package:flutter/foundation.dart';

/// What an activity list draws, as plain data: the entries that are [unread]
/// ("New"), the ones that are [earlier] (already read) and the words around
/// them.
///
/// Every string is the app's, already localized. [unreadTitle] and
/// [earlierTitle] are the visible headings. [unreadCount] is the number the
/// badge of the first heading shows: the number of unread entries the app
/// has, which is more than the [unread] entries listed when it pages. It
/// defaults to their number and is never less (the list asserts it).
/// [unreadSemanticLabel] is what
/// the first heading says, with that same number in words ("New, 2 unread"):
/// the app must use [unreadCount] in it, so the badge and the heading cannot
/// disagree. [unreadPrefix] is the word the list puts before the spoken
/// label of every unread entry ("Unread"), so an earlier entry can never say
/// it. [markAllReadLabel] is the
/// visible label of the action that shows beside the first heading while
/// something is unread. [emptyTitle] and [emptyBody] are what the list says
/// when both lists are empty, which must never blame anyone.
///
/// The ids of the entries are the keys of the rows, so they must be unique
/// across both lists. The design system keeps no dates and no paging: the app
/// decides which entries are here and in which order.
@immutable
class ActivityListView {
  const new({
    required this.unread,
    required this.earlier,
    required this.unreadTitle,
    required this.unreadSemanticLabel,
    required this.unreadPrefix,
    required this.earlierTitle,
    required this.markAllReadLabel,
    required this.emptyTitle,
    required this.emptyBody,
    int? unreadCount,
  }) : _declaredUnreadCount = unreadCount,
       assert(unreadPrefix != '', 'The unread entries need a spoken prefix'),
       assert(unreadTitle != '', 'The first heading needs a title'),
       assert(unreadSemanticLabel != '', 'The first heading needs a label'),
       assert(earlierTitle != '', 'The second heading needs a title'),
       assert(markAllReadLabel != '', 'The action needs a label'),
       assert(emptyTitle != '', 'The empty state needs a title'),
       assert(emptyBody != '', 'The empty state needs a body');

  final List<ActivityEntry> unread;
  final List<ActivityEntry> earlier;
  final String unreadTitle;
  final String unreadSemanticLabel;
  final String unreadPrefix;
  final int? _declaredUnreadCount;

  /// The number the badge shows: what the app said, or the entries listed.
  int get unreadCount => _declaredUnreadCount ?? unread.length;
  final String earlierTitle;
  final String markAllReadLabel;
  final String emptyTitle;
  final String emptyBody;

  /// Whether there is nothing to list at all.
  bool get isEmpty => unread.isEmpty && earlier.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is ActivityListView &&
      listEquals(other.unread, unread) &&
      listEquals(other.earlier, earlier) &&
      other.unreadTitle == unreadTitle &&
      other.unreadSemanticLabel == unreadSemanticLabel &&
      other.unreadPrefix == unreadPrefix &&
      other.unreadCount == unreadCount &&
      other.earlierTitle == earlierTitle &&
      other.markAllReadLabel == markAllReadLabel &&
      other.emptyTitle == emptyTitle &&
      other.emptyBody == emptyBody;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(unread),
    Object.hashAll(earlier),
    unreadTitle,
    unreadSemanticLabel,
    unreadPrefix,
    unreadCount,
    earlierTitle,
    markAllReadLabel,
    emptyTitle,
    emptyBody,
  );
}
