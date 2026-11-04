/// The stroke glyphs of `AppIcon`, drawn on a 24 px grid.
///
/// The name of each value is the glyph name on the canvas Atoms board.
enum AppIcons {
  floorplan(
    'M6.5 3.5H17.5A3 3 0 0 1 20.5 6.5V17.5A3 3 0 0 1 17.5 20.5H6.5 '
    'A3 3 0 0 1 3.5 17.5V6.5A3 3 0 0 1 6.5 3.5ZM3.5 12h8V3.5 '
    'M11.5 12v8.5M15 12h5.5',
  ),
  washer(
    'M7.5 3H16.5A3 3 0 0 1 19.5 6V18A3 3 0 0 1 16.5 21H7.5 '
    'A3 3 0 0 1 4.5 18V6A3 3 0 0 1 7.5 3ZM16.5 13 '
    'A4.5 4.5 0 1 1 7.5 13A4.5 4.5 0 1 1 16.5 13ZM8 6.5h2',
  ),
  dryer(
    'M7.5 3H16.5A3 3 0 0 1 19.5 6V18A3 3 0 0 1 16.5 21H7.5 '
    'A3 3 0 0 1 4.5 18V6A3 3 0 0 1 7.5 3ZM16.5 13 '
    'A4.5 4.5 0 0 1 16.063 14.935M14.515 16.732 '
    'A4.5 4.5 0 0 1 12.666 17.45M10.311 17.171 '
    'A4.5 4.5 0 0 1 8.682 16.04M7.597 13.93 '
    'A4.5 4.5 0 0 1 7.625 11.947M8.768 9.869 '
    'A4.5 4.5 0 0 1 10.428 8.783M12.79 8.57 '
    'A4.5 4.5 0 0 1 14.618 9.34M16.115 11.179A4.5 4.5 0 0 1 16.5 13 '
    'M8 6.5h2',
  ),
  oven(
    'M6 4H18A2.5 2.5 0 0 1 20.5 6.5V17.5A2.5 2.5 0 0 1 18 20H6 '
    'A2.5 2.5 0 0 1 3.5 17.5V6.5A2.5 2.5 0 0 1 6 4ZM3.5 9h17M7 6.5 '
    'h.01M10 6.5h.01M8 12H16A1 1 0 0 1 17 13V16A1 1 0 0 1 16 17H8 '
    'A1 1 0 0 1 7 16V13A1 1 0 0 1 8 12Z',
  ),
  dishwasher(
    'M7 3H17A2.5 2.5 0 0 1 19.5 5.5V18.5A2.5 2.5 0 0 1 17 21H7 '
    'A2.5 2.5 0 0 1 4.5 18.5V5.5A2.5 2.5 0 0 1 7 3ZM4.5 7.5h15 '
    'M8 5.2h3M8 12h8M8 15.5h8',
  ),
  tasks(
    'M10 6.5h10M10 12h10M10 17.5h10M3.5 6.5l1.3 1.3L7.2 5.4M3.5 12 '
    'l1.3 1.3 2.4-2.4M3.5 17.5l1.3 1.3 2.4-2.4',
  ),
  calendar(
    'M6.5 5H17.5A3 3 0 0 1 20.5 8V17.5A3 3 0 0 1 17.5 20.5H6.5 '
    'A3 3 0 0 1 3.5 17.5V8A3 3 0 0 1 6.5 5ZM3.5 10h17M8 3v4M16 3v4',
  ),
  bell('M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15zM10 20.5a2 2 0 0 0 4 0'),

  /// Presence "home" (a sun), not navigation.
  home(
    'M16 12A4 4 0 1 1 8 12A4 4 0 1 1 16 12ZM12 2.5v2M12 19.5v2 '
    'M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7 '
    'l1.4-1.4M17.3 6.7l1.4-1.4',
  ),
  away('M19.5 14.5A7.5 7.5 0 0 1 9.5 4.5a7.5 7.5 0 1 0 10 10z'),
  knock(
    'M5 20V5.5A1.5 1.5 0 0 1 6.5 4h7A1.5 1.5 0 0 1 15 5.5V20M3 20 '
    'h14M12 12.5h.01M18.5 9a4 4 0 0 1 0 6M20.8 7a7 7 0 0 1 0 10',
  ),
  draw(
    'M4 7h3.5c4 0 5 10 9 10H20M4 17h3.5c1.6 0 2.7-1.6 3.6-3.6 '
    'M13 10.6C13.9 8.6 15 7 16.5 7H20M17.5 4.5L20 7l-2.5 2.5 '
    'M17.5 14.5L20 17l-2.5 2.5',
  ),
  adminKey(
    'M12 15A4 4 0 1 1 4 15A4 4 0 1 1 12 15ZM11 12l8.5-8.5M16 7 '
    'l2.5 2.5M14 9l2 2',
  ),
  bed(
    'M3.5 18.5V6M3.5 14h17v4.5M20.5 14v-2.5a3 3 0 0 0-3-3H11V14 '
    'M9.3 11A1.8 1.8 0 1 1 5.7 11A1.8 1.8 0 1 1 9.3 11Z',
  ),
  visit(
    'M16 8.5A4 4 0 1 1 8 8.5A4 4 0 1 1 16 8.5ZM4.5 20 '
    'a7.5 7.5 0 0 1 15 0',
  ),
  occupied(
    'M7.5 10.5H16.5A2.5 2.5 0 0 1 19 13V18A2.5 2.5 0 0 1 16.5 20.5 '
    'H7.5A2.5 2.5 0 0 1 5 18V13A2.5 2.5 0 0 1 7.5 10.5ZM8 10.5V8 '
    'a4 4 0 0 1 8 0v2.5',
  ),
  clock(
    'M20.5 12A8.5 8.5 0 1 1 3.5 12A8.5 8.5 0 1 1 20.5 12ZM12 7.5V12 '
    'l3 2',
  ),
  history('M4 12a8 8 0 1 0 2.3-5.7L4 8.5M4 4v4.5h4.5M12 8v4l3 2'),
  archive(
    'M5 4.5H19A1.5 1.5 0 0 1 20.5 6V7.5A1.5 1.5 0 0 1 19 9H5 '
    'A1.5 1.5 0 0 1 3.5 7.5V6A1.5 1.5 0 0 1 5 4.5ZM5 9v9.5 '
    'A1.5 1.5 0 0 0 6.5 20h11a1.5 1.5 0 0 0 1.5-1.5V9M10 13h4',
  ),
  check('M5 12.5l4.5 4.5L19 7.5'),
  add('M12 5v14M5 12h14'),
  close('M6 6l12 12M18 6L6 18'),
  back('M14.5 6l-6 6 6 6', matchTextDirection: true),
  forward('M9.5 6l6 6-6 6', matchTextDirection: true),
  copy(
    'M11 8.5H17A2.5 2.5 0 0 1 19.5 11V17A2.5 2.5 0 0 1 17 19.5H11 '
    'A2.5 2.5 0 0 1 8.5 17V11A2.5 2.5 0 0 1 11 8.5ZM15.5 8.5V6 '
    'A1.5 1.5 0 0 0 14 4.5H6A1.5 1.5 0 0 0 4.5 6v8 '
    'A1.5 1.5 0 0 0 6 15.5h2.5',
  ),
  share(
    'M12 15V4M8 7.5L12 3.5l4 4M5 12v6.5A1.5 1.5 0 0 0 6.5 20h11 '
    'a1.5 1.5 0 0 0 1.5-1.5V12',
  ),
  edit('M4 20h4L19 9l-4-4L4 16zM13.5 6.5l4 4'),
  email(
    'M6 5.5H18A2.5 2.5 0 0 1 20.5 8V16A2.5 2.5 0 0 1 18 18.5H6 '
    'A2.5 2.5 0 0 1 3.5 16V8A2.5 2.5 0 0 1 6 5.5ZM4 7l8 6 8-6',
  ),
  signOut(
    'M14 4.5H6.5A1.5 1.5 0 0 0 5 6v12a1.5 1.5 0 0 0 1.5 1.5H14 '
    'M10 12h10M16.5 8.5L20 12l-3.5 3.5',
    matchTextDirection: true,
  ),
  show(
    'M2.5 12 '
    'S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z '
    'M15 12A3 3 0 1 1 9 12A3 3 0 1 1 15 12Z',
  );

  new(this.pathData, {this.matchTextDirection = false});

  /// Side of the square grid the glyphs are drawn on.
  static const double gridSize = 24;

  /// Stroke width on the [gridSize] grid. Caps and joins are round.
  static const double strokeWidth = 1.75;

  /// SVG path data on the [gridSize] grid, drawn as a stroke without fill.
  final String pathData;

  /// Whether the glyph points in the reading direction and is mirrored in
  /// right-to-left text.
  final bool matchTextDirection;
}
