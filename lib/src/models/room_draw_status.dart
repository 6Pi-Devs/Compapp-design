/// Where a room draw stands.
///
/// [pending] is the draw the admin can still apply. [applied] is the one whose
/// result is now in the home. A draw that was superseded or voided has no
/// board: the app draws the pending one, or none.
enum RoomDrawStatus { pending, applied }
