import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

/// Shorthands for the knobs the playgrounds repeat. They only work inside a
/// Widgetbook app, which owns the state that holds the knob values.
extension PlaygroundKnobs on BuildContext {
  /// A dropdown over every value of an enum, labeled with the value names.
  T enumKnob<T extends Enum>(
    String label,
    List<T> values, {
    T? initial,
    String? description,
  }) => knobs.object.dropdown<T>(
    label: label,
    options: values,
    initialOption: initial,
    description: description,
    labelBuilder: (value) => value.name,
  );

  /// A dropdown over every value of an enum plus null. It starts at null
  /// unless [initial] is given.
  T? enumKnobOrNull<T extends Enum>(
    String label,
    List<T> values, {
    T? initial,
    String? description,
  }) => knobs.objectOrNull.dropdown<T>(
    label: label,
    options: values,
    initialOption: initial,
    description: description,
    labelBuilder: (value) => value.name,
    defaultToNull: initial == null,
  );

  /// A text knob that starts with [initial], the locale sample of the prop.
  String textKnob(String label, String initial, {String? description}) => knobs
      .string(label: label, initialValue: initial, description: description);

  /// A text knob for a `String?` prop. It starts with [initial], or at null
  /// when [initial] is null.
  String? textKnobOrNull(
    String label,
    String? initial, {
    String? description,
  }) => knobs.stringOrNull(
    label: label,
    initialValue: initial,
    description: description,
    defaultToNull: initial == null,
  );
}
