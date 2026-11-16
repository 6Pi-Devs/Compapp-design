import 'package:compapp_design/src/models/item_sheet_mode.dart';
import 'package:compapp_design/src/models/item_usage.dart';
import 'package:compapp_design/src/models/item_view.dart';
import 'package:flutter/foundation.dart';

/// What an item sheet draws, as plain data: the [item], the [mode], who is
/// using it ([usage]) and the words.
///
/// The board lists ItemSheetView(item, usage, mode, nudgeAvailableAt). The
/// design system keeps no clock, so there is no instant: when a request has to
/// wait, the app says so in [message] ("You can ask Carlos again in 11
/// minutes") and the [mode] is [ItemSheetMode.cooldown]. [title] is the
/// question the sheet asks ("Ask Carlos to free the washer?"), [confirmLabel]
/// the visible and spoken name of the button ("Send request") and
/// [closeLabel] the spoken name of the close button. [message] is the line
/// under the usage, optional except while waiting.
///
/// The mode decides what must be there: a start has no [usage] (the item is
/// free), every other mode has one, and a wait has a [message]. Nobody is asked
/// to free or reminded of their own use, so a nudge, a remind or a wait never
/// has the person themselves as the usage (the backend refuses it with
/// HOME_CANNOT_NUDGE_SELF); only a finish can be one's own use. `ItemSheet`
/// asserts it, because a const constructor cannot read the member.
///
/// A new [item] id is a new sheet: its content is mounted again.
@immutable
class ItemSheetView {
  const new({
    required this.item,
    required this.mode,
    required this.title,
    required this.confirmLabel,
    required this.closeLabel,
    this.usage,
    this.message,
  }) : assert(title != '', 'A sheet asks a question'),
       assert(confirmLabel != '', 'The button needs a label'),
       assert(closeLabel != '', 'The close button needs a spoken label'),
       assert(
         (mode == ItemSheetMode.start) == (usage == null),
         'A start has no usage and every other mode has one',
       ),
       assert(
         mode != ItemSheetMode.cooldown || (message != null && message != ''),
         'A wait says how long is left',
       );

  final ItemView item;
  final ItemSheetMode mode;
  final ItemUsage? usage;
  final String title;
  final String? message;
  final String confirmLabel;
  final String closeLabel;

  @override
  bool operator ==(Object other) =>
      other is ItemSheetView &&
      other.item == item &&
      other.mode == mode &&
      other.usage == usage &&
      other.title == title &&
      other.message == message &&
      other.confirmLabel == confirmLabel &&
      other.closeLabel == closeLabel;

  @override
  int get hashCode =>
      Object.hash(item, mode, usage, title, message, confirmLabel, closeLabel);
}
