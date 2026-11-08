import 'package:compapp_design/src/models/app_icons.dart';
import 'package:flutter/foundation.dart';

/// A shared thing of the home (the washer, the oven), as the design system
/// draws it.
///
/// Plain immutable data owned by this package. [id] is the stable item id
/// that widget keys are built from. [name] is the text to show, already
/// localized by the app, and [icon] one of the appliance glyphs of
/// `AppIcons`.
@immutable
class ItemView {
  const new({required this.id, required this.name, required this.icon});

  final String id;
  final String name;
  final AppIcons icon;

  @override
  bool operator ==(Object other) =>
      other is ItemView &&
      other.id == id &&
      other.name == name &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(id, name, icon);
}
