/// How the glyph tile of an activity entry is colored.
///
/// [busy] is the in-use amber, for entries about a shared thing in use (a
/// finished washer). [neutral] is the sunken tile of every other entry. Neither
/// is a danger color, and the entry's text says what happened either way.
enum ActivityTone { neutral, busy }
