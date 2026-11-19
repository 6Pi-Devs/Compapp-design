/// Who has a shared thing right now, as a beacon draws it.
///
/// [free] is nobody. [mine] is the person looking at the screen and [others]
/// is someone else of the home. The three are drawn apart by more than color:
/// a free thing has no ring and a muted status, a used one has the busy ring,
/// and a small glyph before the status text says whose it is (a check for
/// [mine], a lock for [others]). The design system never says who by name:
/// the app words that in the status and spoken labels.
enum ItemStatus { free, mine, others }
