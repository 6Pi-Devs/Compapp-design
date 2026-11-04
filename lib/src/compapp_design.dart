import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Package-level setup the consuming app calls once.
abstract final class CompappDesign {
  static const _package = 'packages/compapp_design';
  static const _licenses = {
    'Bricolage Grotesque': '$_package/fonts/OFL-BricolageGrotesque.txt',
    'Instrument Sans': '$_package/fonts/OFL-InstrumentSans.txt',
  };

  static bool _registered = false;

  /// Adds the SIL Open Font License of the bundled fonts to Flutter's
  /// `LicenseRegistry`, so `showLicensePage` lists them. Call it once in
  /// `main`, before `runApp`. Repeated calls are ignored.
  static void registerLicenses() {
    if (_registered) return;
    _registered = true;
    LicenseRegistry.addLicense(() async* {
      for (final MapEntry(key: font, value: asset) in _licenses.entries) {
        final text = await rootBundle.loadString(asset);
        yield LicenseEntryWithLineBreaks([font], text);
      }
    });
  }
}
