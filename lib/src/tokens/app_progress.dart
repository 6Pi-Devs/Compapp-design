/// Numbers of the progress atoms (`progress.*`).
abstract final class AppProgress {
  /// Arc of an in-use ring with no known end, as a fraction of the circle
  /// (`progress.ring-sweep`).
  static const double ringSweep = 0.3;

  /// Lowest opacity of the arc while it breathes (`progress.ring-breathe`).
  static const double ringBreatheOpacity = 0.4;

  /// Fill of the freshness bar of a task done today
  /// (`progress.freshness-fresh`).
  static const double freshnessFresh = 1;

  /// Fill of a task done one or two days ago (`progress.freshness-recent`).
  static const double freshnessRecent = 0.85;

  /// Fill of a task done three to six days ago (`progress.freshness-fading`).
  static const double freshnessFading = 0.6;

  /// Fill of a task done a week or more ago (`progress.freshness-stale`).
  static const double freshnessStale = 0.25;

  /// Oldest age, in calendar days, that still counts as fresh
  /// (`progress.freshness-fresh` `maxAgeDays`).
  static const int freshMaxAgeDays = 0;

  /// Oldest age that still counts as recent.
  static const int recentMaxAgeDays = 2;

  /// Oldest age that still counts as fading. Older is stale.
  static const int fadingMaxAgeDays = 6;

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, double> values = {
    'ring-sweep': ringSweep,
    'ring-breathe': ringBreatheOpacity,
    'freshness-fresh': freshnessFresh,
    'freshness-recent': freshnessRecent,
    'freshness-fading': freshnessFading,
    'freshness-stale': freshnessStale,
  };

  /// The `maxAgeDays` of each freshness token that has one, by JSON name.
  static const Map<String, int> freshnessMaxAgeDays = {
    'freshness-fresh': freshMaxAgeDays,
    'freshness-recent': recentMaxAgeDays,
    'freshness-fading': fadingMaxAgeDays,
  };
}
