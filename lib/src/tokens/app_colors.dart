import 'package:flutter/material.dart';

/// Colour tokens without a Material `ColorScheme` slot.
///
/// Read it with `context.appColors`.
class AppColors extends ThemeExtension<AppColors> {
  const new({
    required this.presenceHome,
    required this.presenceAway,
    required this.busy,
    required this.busySoft,
    required this.pebbles,
    required this.onPebble,
    required this.onPresenceAway,
  });

  static const light = AppColors(
    presenceHome: Color(0xFFA9D4B2),
    presenceAway: Color(0xFF5E6976),
    busy: Color(0xFF9A5A0E),
    busySoft: Color(0xFFF6D9A8),
    pebbles: _pebbles,
    onPebble: Color(0xFF1C2B22),
    onPresenceAway: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    presenceHome: Color(0xFF3E7350),
    presenceAway: Color(0xFF93A0AE),
    busy: Color(0xFFF0B866),
    busySoft: Color(0xFF4A3416),
    pebbles: _pebbles,
    onPebble: Color(0xFF1C2B22),
    onPresenceAway: Color(0xFF0E1A12),
  );

  /// sage, sky, apricot, rose, sand, tide. The same in both themes.
  static const List<Color> _pebbles = [
    Color(0xFFBFE0C6),
    Color(0xFFC4DAF0),
    Color(0xFFF6D3A8),
    Color(0xFFF2C6C2),
    Color(0xFFE6DDC4),
    Color(0xFFB9E2DD),
  ];

  /// Glow ring and wall of a room whose owner is home.
  final Color presenceHome;

  /// Away tray, away side of the presence switch, moon badge.
  final Color presenceAway;

  /// In-use text, ring and lock icon.
  final Color busy;

  /// Fill of an occupied room.
  final Color busySoft;

  /// Member colours in join order.
  final List<Color> pebbles;

  /// Initials on a pebble. The pebble colours are pastel in both themes, so
  /// the text is dark in both.
  final Color onPebble;

  /// Glyph of the away badge, drawn on [presenceAway].
  final Color onPresenceAway;

  /// JSON names of [pebbles], in the same order.
  static const List<String> pebbleNames = [
    'sage',
    'sky',
    'apricot',
    'rose',
    'sand',
    'tide',
  ];

  /// Every non-pebble colour by its JSON name, compared against the JSON by
  /// the parity test.
  Map<String, Color> get values => {
    'presence-home': presenceHome,
    'presence-away': presenceAway,
    'busy': busy,
    'busy-soft': busySoft,
    'on-pebble': onPebble,
    'on-presence-away': onPresenceAway,
  };

  /// The pebble colour of the member at [joinOrder], wrapping around.
  Color pebbleAt(int joinOrder) => pebbles[joinOrder % pebbles.length];

  @override
  AppColors copyWith({
    Color? presenceHome,
    Color? presenceAway,
    Color? busy,
    Color? busySoft,
    List<Color>? pebbles,
    Color? onPebble,
    Color? onPresenceAway,
  }) {
    return AppColors(
      presenceHome: presenceHome ?? this.presenceHome,
      presenceAway: presenceAway ?? this.presenceAway,
      busy: busy ?? this.busy,
      busySoft: busySoft ?? this.busySoft,
      pebbles: pebbles ?? this.pebbles,
      onPebble: onPebble ?? this.onPebble,
      onPresenceAway: onPresenceAway ?? this.onPresenceAway,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      presenceHome: Color.lerp(presenceHome, other.presenceHome, t)!,
      presenceAway: Color.lerp(presenceAway, other.presenceAway, t)!,
      busy: Color.lerp(busy, other.busy, t)!,
      busySoft: Color.lerp(busySoft, other.busySoft, t)!,
      pebbles: [
        for (var i = 0; i < pebbles.length; i++)
          Color.lerp(pebbles[i], other.pebbles[i], t)!,
      ],
      onPebble: Color.lerp(onPebble, other.onPebble, t)!,
      onPresenceAway: Color.lerp(onPresenceAway, other.onPresenceAway, t)!,
    );
  }
}
