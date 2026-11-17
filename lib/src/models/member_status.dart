/// Where a member is, as a member row or a room draws it.
///
/// [home] adds nothing to the member's pebble. [away] and [invited] change it:
/// a moon badge and a dashed outline, from the pebble's own rules. [unknown]
/// is a member who has never said whether they are home: the pebble is drawn
/// as for [home], and a member row shows no status dot, as for [invited].
enum MemberStatus { home, away, invited, unknown }
