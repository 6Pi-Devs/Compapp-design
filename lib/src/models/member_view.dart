import 'package:compapp_design/src/models/member_status.dart';
import 'package:flutter/foundation.dart';

/// A member of the home, as the design system draws them.
///
/// Plain immutable data owned by this package: the app maps its own business
/// object onto it. [id] is the stable account id that widget keys are built
/// from, never a list position. [joinOrder] is the stable join sequence that
/// picks the pebble color (see `AppPebble`).
///
/// [name] is the text to show, already localized by the app ("Ana (you)").
/// [semanticLabel] is the whole spoken description ("Ana, you, admin, at
/// home"): it names the member, so a widget that reads it leaves the visible
/// name out of semantics to avoid saying it twice.
@immutable
class MemberView {
  const new({
    required this.id,
    required this.name,
    required this.initials,
    required this.joinOrder,
    required this.semanticLabel,
    this.status = MemberStatus.home,
    this.isYou = false,
    this.isAdmin = false,
  }) : assert(semanticLabel != '', 'A member needs a spoken label');

  final String id;
  final String name;
  final String initials;
  final int joinOrder;
  final String semanticLabel;
  final MemberStatus status;
  final bool isYou;
  final bool isAdmin;

  @override
  bool operator ==(Object other) =>
      other is MemberView &&
      other.id == id &&
      other.name == name &&
      other.initials == initials &&
      other.joinOrder == joinOrder &&
      other.semanticLabel == semanticLabel &&
      other.status == status &&
      other.isYou == isYou &&
      other.isAdmin == isAdmin;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    initials,
    joinOrder,
    semanticLabel,
    status,
    isYou,
    isAdmin,
  );
}
