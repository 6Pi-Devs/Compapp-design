/// What an item sheet asks the person to confirm.
enum ItemSheetMode {
  /// The item is free: start using it. Nobody is using it, so there is no
  /// usage.
  start,

  /// The item is being used and the person is finishing that use, their own or
  /// someone else's (anyone can finish a use).
  finish,

  /// Ask the person using the item to free it.
  nudge,

  /// Remind the person using the item that it is still in use, for example
  /// when the washer finished hours ago (the backend calls it a reminder).
  remind,

  /// A request to the person using the item was sent a short time ago, so the
  /// confirm button waits: it is shown but disabled, and the message says how
  /// long is left.
  cooldown,
}
