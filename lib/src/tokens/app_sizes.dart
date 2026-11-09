abstract final class AppSizes {
  /// Smallest hit area of an interactive element (`target.min`). Passes
  /// `androidTapTargetGuideline`.
  static const double minTarget = 48;

  /// Smallest drawn size of an interactive element (`target.min` drawn).
  static const double minDrawn = 44;

  /// Width of a flat border (`elevation.flat`).
  static const double hairline = 1;

  /// Height of a medium button and chip (`size.control-md`).
  static const double controlMd = 44;

  /// Height of a large button and of a text field (`size.control-lg`).
  static const double controlLg = 52;

  /// Icon or spinner beside a medium label (`size.glyph-md`).
  static const double glyphMd = 16;

  /// Icon or spinner beside a large label (`size.glyph-lg`).
  static const double glyphLg = 18;

  /// Icon of a top bar action, such as the bell or a sheet's close
  /// (`size.glyph-action`).
  static const double glyphAction = 20;

  /// Icon of a navigation destination and of the back arrow
  /// (`size.glyph-nav`).
  static const double glyphNav = 22;

  /// Selected, focused and error borders, spinner stroke
  /// (`size.border-emphasis`).
  static const double borderEmphasis = 2;

  /// Ring around a focused field (`size.focus-ring`).
  static const double focusRing = 4;

  /// Ring of a spinner beside a medium label (`size.spinner-md`).
  static const double spinnerMd = 12;

  /// Ring of a spinner beside a large label (`size.spinner-lg`).
  static const double spinnerLg = 13.5;

  /// Dash of a dashed border 1 px wide (`size.dash`). It scales with the
  /// border width.
  static const double dash = 4;

  /// Gap of a dashed border 1 px wide (`size.dash-gap`).
  static const double dashGap = 3;

  /// Width of one code input cell (`size.code-cell-width`).
  static const double codeCellWidth = 56;

  /// Height of one code input cell (`size.code-cell-height`).
  static const double codeCellHeight = 60;

  /// Side of the smallest pebble (`size.pebble-xs`).
  static const double pebbleXs = 28;

  /// Side of a small pebble (`size.pebble-sm`).
  static const double pebbleSm = 36;

  /// Side of a medium pebble (`size.pebble-md`).
  static const double pebbleMd = 44;

  /// Side of a large pebble (`size.pebble-lg`).
  static const double pebbleLg = 56;

  /// Side of the largest pebble (`size.pebble-xl`). Its initials use the
  /// Bricolage style (`font.pebble-xl`).
  static const double pebbleXl = 72;

  /// Side of the away and admin badges, drawn on a medium pebble and up
  /// (`size.pebble-badge`).
  static const double pebbleBadge = 20;

  /// Glyph inside [pebbleBadge] (`size.pebble-badge-glyph`).
  static const double pebbleBadgeGlyph = 11;

  /// How far a pebble badge hangs outside the pebble
  /// (`size.pebble-badge-offset`).
  static const double pebbleBadgeOffset = 4;

  /// Border of an invited pebble, drawn dashed (`size.border-dashed`).
  static const double borderDashed = 1.5;

  /// Status dot beside a label (`size.dot`).
  static const double dot = 8;

  /// Unread dot, a little larger than [dot] (`size.dot-unread`).
  static const double dotUnread = 10;

  /// Smallest side of a count badge (`size.badge-count`).
  static const double badgeCount = 18;

  /// Horizontal padding of a count badge (`size.badge-count-padding`).
  static const double badgeCountPadding = 5;

  /// Corner radius of a label badge (`size.badge-label-radius`).
  static const double badgeLabelRadius = 8;

  /// Side of a progress ring (`size.ring`). It grows to hold a large label.
  static const double ring = 56;

  /// Stroke of a progress ring, track and arc (`size.ring-stroke`).
  static const double ringStroke = 4;

  /// Height of the freshness bar (`size.freshness-bar`).
  static const double freshnessBar = 4;

  /// Least height of a list row (`size.row`). It grows with its text.
  static const double row = 64;

  /// Least height of a list row with a bar under its texts, such as a task
  /// row (`size.row-tall`). It grows with its text.
  static const double rowTall = 72;

  /// Side of the glyph tile or the breathing ring of an item beacon
  /// (`size.beacon`).
  static const double beacon = 34;

  /// Border of a room tile, solid or dashed (`size.border-room`).
  static const double borderRoom = 1.5;

  /// Least height of an event ribbon (`size.ribbon`). It grows with its text.
  static const double ribbon = 28;

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, double> values = {
    'target.min': minTarget,
    'target.min.drawn': minDrawn,
    'elevation.flat.width': hairline,
    'size.control-md': controlMd,
    'size.control-lg': controlLg,
    'size.glyph-md': glyphMd,
    'size.glyph-lg': glyphLg,
    'size.glyph-action': glyphAction,
    'size.glyph-nav': glyphNav,
    'size.border-emphasis': borderEmphasis,
    'size.focus-ring': focusRing,
    'size.spinner-md': spinnerMd,
    'size.spinner-lg': spinnerLg,
    'size.dash': dash,
    'size.dash-gap': dashGap,
    'size.code-cell-width': codeCellWidth,
    'size.code-cell-height': codeCellHeight,
    'size.pebble-xs': pebbleXs,
    'size.pebble-sm': pebbleSm,
    'size.pebble-md': pebbleMd,
    'size.pebble-lg': pebbleLg,
    'size.pebble-xl': pebbleXl,
    'size.pebble-badge': pebbleBadge,
    'size.pebble-badge-glyph': pebbleBadgeGlyph,
    'size.pebble-badge-offset': pebbleBadgeOffset,
    'size.border-dashed': borderDashed,
    'size.dot': dot,
    'size.dot-unread': dotUnread,
    'size.badge-count': badgeCount,
    'size.badge-count-padding': badgeCountPadding,
    'size.badge-label-radius': badgeLabelRadius,
    'size.ring': ring,
    'size.ring-stroke': ringStroke,
    'size.freshness-bar': freshnessBar,
    'size.row': row,
    'size.row-tall': rowTall,
    'size.beacon': beacon,
    'size.border-room': borderRoom,
    'size.ribbon': ribbon,
  };
}
