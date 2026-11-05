import 'package:flutter/widgets.dart';

extension LocalizedSample on BuildContext {
  /// The sample string for the current locale: [es] for Spanish, [en] for
  /// everything else. Use cases pass English and Spanish samples, because the
  /// design system never owns localization.
  String sample({required String en, required String es}) =>
      Localizations.localeOf(this).languageCode == 'es' ? es : en;
}
