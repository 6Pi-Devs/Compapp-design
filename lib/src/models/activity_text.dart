import 'package:flutter/foundation.dart';

/// One run of the text of an activity entry: the [text] as written, with its
/// own spaces, and whether it is [strong] (semi-bold).
///
/// The app composes the line from runs and owns the word order of every
/// language: "**Carlos** finished your washer" is a strong run "Carlos " and a
/// plain one, "Room draw: you got **Bedroom 1**" is a plain run and a strong
/// one.
@immutable
class ActivityText {
  const new(this.text, {this.strong = false});

  final String text;
  final bool strong;

  @override
  bool operator ==(Object other) =>
      other is ActivityText && other.text == text && other.strong == strong;

  @override
  int get hashCode => Object.hash(text, strong);
}
