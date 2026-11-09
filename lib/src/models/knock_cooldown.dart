import 'package:flutter/foundation.dart';

/// The wait before a home can be asked "who's home?" again, as the design
/// system draws it.
///
/// Plain immutable data owned by this package: the app does the clock and the
/// time zone maths and hands over the result, because the design system has no
/// timers and no dates. [remaining] is the share of the wait that is left, from
/// 0 to 1 (values outside it are clamped). It is a number: NaN is rejected,
/// so a cooldown always equals itself.
/// [label] says what happened ("Asked"), [remainingLabel] how long is left
/// ("11 min") and [semanticLabel] says both in one sentence ("Asked who's
/// home. You can ask again in 11 minutes").
@immutable
class KnockCooldown {
  const new({
    required this.remaining,
    required this.label,
    required this.remainingLabel,
    required this.semanticLabel,
  }) : assert(remaining == remaining, 'The share left is a number'),
       assert(label != '', 'A cooldown needs a label'),
       assert(remainingLabel != '', 'A cooldown needs the time left'),
       assert(semanticLabel != '', 'A cooldown needs a spoken label');

  final double remaining;
  final String label;
  final String remainingLabel;
  final String semanticLabel;

  /// [remaining] as the ring draws it, from 0 to 1. A NaN that got through a
  /// release build, where asserts are off, is drawn as 0.
  double get ringValue => remaining.isNaN ? 0 : remaining.clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is KnockCooldown &&
      other.remaining == remaining &&
      other.label == label &&
      other.remainingLabel == remainingLabel &&
      other.semanticLabel == semanticLabel;

  @override
  int get hashCode =>
      Object.hash(remaining, label, remainingLabel, semanticLabel);
}
