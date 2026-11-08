import 'package:flutter/foundation.dart';

/// A room of the home, as the design system draws it.
///
/// Plain immutable data owned by this package. [id] is the stable room id
/// that widget keys are built from. [name] is the text to show, already
/// localized by the app ("Ana's room").
@immutable
class RoomView {
  const new({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is RoomView && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
