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

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, double> values = {
    'target.min': minTarget,
    'target.min.drawn': minDrawn,
    'elevation.flat.width': hairline,
    'size.control-md': controlMd,
    'size.control-lg': controlLg,
    'size.glyph-md': glyphMd,
    'size.glyph-lg': glyphLg,
    'size.border-emphasis': borderEmphasis,
    'size.focus-ring': focusRing,
    'size.spinner-md': spinnerMd,
    'size.spinner-lg': spinnerLg,
    'size.dash': dash,
    'size.dash-gap': dashGap,
    'size.code-cell-width': codeCellWidth,
    'size.code-cell-height': codeCellHeight,
  };
}
