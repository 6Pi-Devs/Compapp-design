import 'package:flutter/foundation.dart';

/// A task the home already knows, offered while a name is typed.
///
/// Plain immutable data owned by this package. [id] is the stable task id that
/// widget keys are built from and that `onPick` gives back. [title] is the
/// text to show, already localized by the app. [subtitle] is the line under
/// it that says where the task comes from ("Same task as before · Carlos, 3
/// days ago"), or null for none.
@immutable
class TaskSuggestion {
  const new({required this.id, required this.title, this.subtitle})
    : assert(id != '', 'A suggestion needs an id'),
      assert(title != '', 'A suggestion needs a title');

  final String id;
  final String title;
  final String? subtitle;

  @override
  bool operator ==(Object other) =>
      other is TaskSuggestion &&
      other.id == id &&
      other.title == title &&
      other.subtitle == subtitle;

  @override
  int get hashCode => Object.hash(id, title, subtitle);
}
