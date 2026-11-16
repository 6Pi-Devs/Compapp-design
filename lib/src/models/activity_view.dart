import 'package:compapp_design/src/models/activity_text.dart';
import 'package:compapp_design/src/models/activity_tone.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:flutter/foundation.dart';

/// One entry of the activity feed, as the design system draws it.
///
/// Plain immutable data owned by this package. [id] is the stable entry id
/// that widget keys are built from. [icon] is the glyph of the entry's type and
/// [tone] the color of its tile. [text] is the line as runs, some of them
/// strong, already localized and in the word order of the language, and [meta]
/// the muted line under it ("Washer · 2 h ago"). The app owns every string and
/// every date: the design system does no date maths. A line has at least one
/// run.
@immutable
class ActivityView {
  const new({
    required this.id,
    required this.icon,
    required this.text,
    this.tone = ActivityTone.neutral,
    this.meta,
  });

  final String id;
  final AppIcons icon;
  final ActivityTone tone;
  final List<ActivityText> text;
  final String? meta;

  @override
  bool operator ==(Object other) =>
      other is ActivityView &&
      other.id == id &&
      other.icon == icon &&
      other.tone == tone &&
      listEquals(other.text, text) &&
      other.meta == meta;

  @override
  int get hashCode => Object.hash(id, icon, tone, Object.hashAll(text), meta);
}
