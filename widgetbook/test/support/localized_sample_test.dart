import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> _sampleFor(WidgetTester tester, Locale locale) async {
  late String sample;
  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: Builder(
        builder: (context) {
          sample = context.sample(en: 'Notifications', es: 'Notificaciones');
          return const SizedBox();
        },
      ),
    ),
  );
  return sample;
}

void main() {
  testWidgets('picks the Spanish sample for es', (tester) async {
    expect(await _sampleFor(tester, const Locale('es')), 'Notificaciones');
  });

  testWidgets('picks the English sample for en', (tester) async {
    expect(await _sampleFor(tester, const Locale('en')), 'Notifications');
  });

  testWidgets('falls back to English for other languages', (tester) async {
    expect(await _sampleFor(tester, const Locale('fr')), 'Notifications');
  });
}
