import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled fonts under the family names the text styles resolve to.
///
/// Without them a test draws every glyph as a solid em square, which proves
/// nothing about how real text wraps or fits. Call it from `setUpAll` of the
/// group that measures text, and keep the groups that read the painted color
/// of a glyph before it: a loaded font has holes, a solid square has none.
Future<void> loadBundledFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader('packages/compapp_design/$family');
    for (final file in files) {
      final bytes = File('fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Bricolage Grotesque', ['BricolageGrotesque-Variable.ttf']);
  await load('Instrument Sans', [
    'InstrumentSans-Regular.ttf',
    'InstrumentSans-SemiBold.ttf',
  ]);
}
