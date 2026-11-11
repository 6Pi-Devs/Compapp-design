import 'package:flutter/foundation.dart';

/// What a task can be tied to: a [room] or an [item] (a shared thing).
enum TaskTargetKind { room, item }

/// The room or the item a task is linked to, by its [kind] and its [id].
///
/// A room and an item may share an id, so the kind is part of the identity.
/// It is what `TaskComposerView.linked` holds and what `onLink` gives back.
@immutable
class TaskTarget {
  const new(this.kind, this.id) : assert(id != '', 'A target needs an id');

  final TaskTargetKind kind;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is TaskTarget && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}
