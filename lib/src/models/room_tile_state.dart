/// What a room tile reports.
///
/// [home] is a bedroom whose owner is in, [away] one whose owner is out,
/// [occupied] a common room somebody is using, and [free] a room nobody is
/// using.
enum RoomTileState { home, away, occupied, free }
