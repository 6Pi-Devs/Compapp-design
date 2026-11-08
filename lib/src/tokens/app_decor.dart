/// Opacities of decoration that carries no meaning (`decor.*`).
abstract final class AppDecor {
  /// Glow ring of a room whose owner is home and edge of an occupied room, as
  /// a share of the presence-home or busy color (`decor.room-edge`).
  static const double roomEdge = 0.35;

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, double> values = {'room-edge': roomEdge};
}
