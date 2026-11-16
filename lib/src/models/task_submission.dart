import 'package:compapp_design/src/models/task_target.dart';
import 'package:flutter/foundation.dart';

/// What a task composer logs: the [name] of the task, without the spaces
/// around it, and the [target] (room or item) it is tied to, or null.
///
/// It is the one argument of `TaskComposer.onSubmit`, so the form can gain a
/// field (a note) without changing the signature of the callback.
@immutable
class TaskSubmission {
  const new({required this.name, this.target})
    : assert(name != '', 'A submission needs a name');

  final String name;
  final TaskTarget? target;

  @override
  bool operator ==(Object other) =>
      other is TaskSubmission && other.name == name && other.target == target;

  @override
  int get hashCode => Object.hash(name, target);
}
