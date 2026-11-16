/// Where the person using the app is: the two sides of the presence switch.
///
/// It is the state a person sets for themself, so it has no "invited": that
/// belongs to `MemberStatus`, which describes any member of the home.
enum Presence { home, away }
