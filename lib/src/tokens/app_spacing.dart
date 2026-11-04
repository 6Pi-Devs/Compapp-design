abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, double> values = {
    'xs': xs,
    'sm': sm,
    'md': md,
    'lg': lg,
    'xl': xl,
    'xxl': xxl,
  };
}
