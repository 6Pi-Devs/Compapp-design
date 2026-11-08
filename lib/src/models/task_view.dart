import 'package:flutter/foundation.dart';

/// A recurring task of the home, as the design system draws it.
///
/// Plain immutable data owned by this package. [id] is the stable task id
/// that widget keys are built from. [title] is the text to show, already
/// localized by the app. [ageDays] is the number of calendar days since the
/// task was last done, counted by the app in the home's time zone: the design
/// system does no date maths.
@immutable
class TaskView {
  const new({required this.id, required this.title, required this.ageDays});

  final String id;
  final String title;
  final int ageDays;

  @override
  bool operator ==(Object other) =>
      other is TaskView &&
      other.id == id &&
      other.title == title &&
      other.ageDays == ageDays;

  @override
  int get hashCode => Object.hash(id, title, ageDays);
}
