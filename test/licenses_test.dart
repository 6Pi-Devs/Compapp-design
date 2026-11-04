import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registerLicenses exposes the OFL text of both bundled fonts', () async {
    CompappDesign.registerLicenses();
    CompappDesign.registerLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final byPackage = {
      for (final entry in entries)
        for (final package in entry.packages) package: entry,
    };

    expect(
      byPackage.keys,
      containsAll(['Bricolage Grotesque', 'Instrument Sans']),
    );
    final text = byPackage['Instrument Sans']!.paragraphs
        .map((p) => p.text)
        .join();
    expect(text, contains('SIL OPEN FONT LICENSE'));
  });
}
