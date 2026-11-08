/// What a calendar event is: a [visit] of a guest, an [overnight] stay, an
/// [absence] of a member (away from home) or [other].
///
/// The kind picks the glyph and the color of an event ribbon. The glyph is
/// what tells them apart, never the color alone.
enum CalendarEventKind { visit, overnight, absence, other }
