import 'package:compapp_design/src/models/knock_cooldown.dart';
import 'package:flutter/foundation.dart';

/// The "who's home?" part of a presence panel: the label of the button and,
/// while the home was asked a short time ago, the [cooldown] it waits out.
///
/// [message] says who asked and when ("Carlos asked 4 min ago") and [hint]
/// the rule ("Once every 15 minutes per home"). Both are the app's words and
/// either may be left out. The design system keeps no clock: the app counts
/// the wait and passes the result in the [cooldown].
@immutable
class PresenceBroadcast {
  const new({required this.knockLabel, this.cooldown, this.message, this.hint})
    : assert(knockLabel != '', 'The button needs a label');

  final String knockLabel;
  final KnockCooldown? cooldown;
  final String? message;
  final String? hint;

  @override
  bool operator ==(Object other) =>
      other is PresenceBroadcast &&
      other.knockLabel == knockLabel &&
      other.cooldown == cooldown &&
      other.message == message &&
      other.hint == hint;

  @override
  int get hashCode => Object.hash(knockLabel, cooldown, message, hint);
}
