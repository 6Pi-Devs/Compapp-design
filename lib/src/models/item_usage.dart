import 'package:compapp_design/src/models/member_view.dart';
import 'package:flutter/foundation.dart';

/// Who is using an item and since when, as an item sheet draws it.
///
/// Plain immutable data owned by this package: the design system keeps no
/// clock, so the app works out the time and hands over [subtitle], already
/// worded and localized ("Started 34 min ago"). [member] is the person using
/// the item, drawn as a `MemberRow`.
@immutable
class ItemUsage {
  const new({required this.member, required this.subtitle})
    : assert(subtitle != '', 'A usage says since when');

  final MemberView member;
  final String subtitle;

  @override
  bool operator ==(Object other) =>
      other is ItemUsage &&
      other.member == member &&
      other.subtitle == subtitle;

  @override
  int get hashCode => Object.hash(member, subtitle);
}
