/// Where a member is, as a member row or a room draws it.
///
/// [home] adds nothing to the member's pebble. [away] and [invited] change it:
/// a moon badge and a dashed outline, from the pebble's own rules.
enum MemberStatus { home, away, invited }
