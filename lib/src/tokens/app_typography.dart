import 'package:flutter/material.dart';

/// Type scale. Numbers are always tabular, so every style carries
/// `FontFeature.tabularFigures()`. Styles without tracking in the spec set
/// `letterSpacing: 0` so Material defaults do not leak in.
///
/// Bricolage Grotesque is a variable font. `fontWeight` drives its `wght`
/// axis, so the styles set no `wght` variation (an explicit one would override
/// `copyWith(fontWeight:)` and iOS Bold Text). Every Bricolage style sets
/// `opsz` to its font size, clamped to the axis range, like
/// `font-optical-sizing: auto` in browsers. Never `copyWith(fontSize:)` on a
/// Bricolage style: it would keep the old `opsz`.
abstract final class AppTypography {
  static const String displayFamily = 'Bricolage Grotesque';
  static const String bodyFamily = 'Instrument Sans';
  static const String package = 'compapp_design';

  /// Range of the `opsz` axis of the bundled Bricolage Grotesque.
  static const double opticalSizeMin = 12;
  static const double opticalSizeMax = 96;

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontFamily: displayFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 40,
    fontVariations: [FontVariation.opticalSize(40)],
    height: 44 / 40,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: displayFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    fontVariations: [FontVariation.opticalSize(28)],
    height: 32 / 28,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  static const TextStyle title = TextStyle(
    fontFamily: displayFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    fontVariations: [FontVariation.opticalSize(20)],
    height: 26 / 20,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w400,
    fontSize: 17,
    height: 24 / 17,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 22 / 15,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  static const TextStyle label = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 16 / 13,
    letterSpacing: 0.2,
    fontFeatures: _tabular,
  );

  static const TextStyle labelLg = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 22 / 15,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  /// Initials of a pebble, at the board sizes. The line is as tall as the font
  /// size, except on pebbleMd: its 12 px line is the capital height, so the
  /// text line box (not every accent or descender) clears the 16 px badge
  /// squares of a 44 px pebble. The largest is Bricolage like a headline. Two
  /// capitals up to "MW" fit the nominal pebble inside the ring at these sizes,
  /// except on the smallest, which has [pebbleXsPair].
  static const TextStyle pebbleXs = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 1,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  /// Two initials on the smallest pebble: 10 px, so "MW" fits inside the ring
  /// of a 28 px pebble.
  static const TextStyle pebbleXsPair = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 10,
    height: 1,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  static const TextStyle pebbleSm = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  static const TextStyle pebbleMd = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 12 / 15,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  static const TextStyle pebbleLg = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  static const TextStyle pebbleXl = TextStyle(
    fontFamily: displayFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    fontVariations: [FontVariation.opticalSize(28)],
    height: 1,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  /// Number in a count badge. The 18 px line is the smallest side of the
  /// badge, so a scaled line keeps its breathing room.
  static const TextStyle badgeCount = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    height: 18 / 11,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  /// Label under a navigation icon. It has the values of [badgeLabel] and is
  /// kept apart because the two change for different reasons.
  static const TextStyle navLabel = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  /// Text of a label badge.
  static const TextStyle badgeLabel = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  /// Label in the middle of a progress ring. The line is as tall as the font
  /// size: the ring measures it and grows around it.
  static const TextStyle ringLabel = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );

  /// Every style by its JSON name, compared against the JSON by the parity
  /// test.
  static const Map<String, TextStyle> values = {
    'display': display,
    'headline': headline,
    'title': title,
    'body-lg': bodyLg,
    'body': body,
    'label': label,
    'label-lg': labelLg,
    'pebble-xs': pebbleXs,
    'pebble-xs-pair': pebbleXsPair,
    'pebble-sm': pebbleSm,
    'pebble-md': pebbleMd,
    'pebble-lg': pebbleLg,
    'pebble-xl': pebbleXl,
    'badge-count': badgeCount,
    'badge-label': badgeLabel,
    'nav-label': navLabel,
    'ring-label': ringLabel,
    'caption': caption,
  };

  /// display to `displayMedium`, headline to `headlineSmall`, title to
  /// `titleLarge`, body-lg to `bodyLarge`, body to `bodyMedium`, label to
  /// `labelLarge`, caption to `bodySmall`. label-lg has no Material slot: the
  /// button themes use it for their label.
  static const TextTheme textTheme = TextTheme(
    displayMedium: display,
    headlineSmall: headline,
    titleLarge: title,
    bodyLarge: bodyLg,
    bodyMedium: body,
    labelLarge: label,
    bodySmall: caption,
  );
}
