import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'ci_golden_comparator.dart';

const _side = 100;
const _ciGolden = 'goldens/ci/Atoms/AppIcon/gallery-default.png';
const _platformGolden = 'goldens/windows/Atoms/AppIcon/gallery-default.png';

/// A white square with a black block of [blackPixels] x [rows] pixels.
Future<Uint8List> _png(int blackPixels, {int rows = 1}) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..drawRect(
      const ui.Rect.fromLTWH(0, 0, 100, 100),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    )
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, blackPixels.toDouble(), rows.toDouble()),
      ui.Paint()..color = const ui.Color(0xFF000000),
    );
  final image = await recorder.endRecording().toImage(_side, _side);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  late Directory dir;
  late List<String> logs;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ci_golden_comparator_test');
    logs = [];
  });
  tearDown(() => dir.deleteSync(recursive: true));

  CiGoldenComparator comparator({
    required bool isLinux,
    bool allowNonLinuxUpdates = false,
  }) => CiGoldenComparator(
    Uri.file('${dir.path}/a_test.dart'),
    isLinux: isLinux,
    allowNonLinuxUpdates: allowNonLinuxUpdates,
    log: logs.add,
  );

  Future<void> seed(Uint8List golden, String path) async {
    await comparator(isLinux: true).update(Uri.parse(path), golden);
  }

  group('on Linux', () {
    testWidgets('matches exactly', (tester) async {
      await tester.runAsync(() async {
        final golden = await _png(0);
        await seed(golden, _ciGolden);

        expect(
          await comparator(isLinux: true).compare(golden, Uri.parse(_ciGolden)),
          isTrue,
        );
      });
    });

    testWidgets('fails on a single different pixel', (tester) async {
      await tester.runAsync(() async {
        await seed(await _png(0), _ciGolden);

        await expectLater(
          comparator(isLinux: true)
              .compare(await _png(1), Uri.parse(_ciGolden)),
          throwsA(anything),
        );
        expect(logs, isEmpty);
      });
    });
  });

  group('off Linux', () {
    testWidgets('tolerates a small diff and says the strict check is on CI', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await seed(await _png(0), _ciGolden);

        final passed = await comparator(isLinux: false)
            .compare(await _png(20), Uri.parse(_ciGolden));

        expect(passed, isTrue);
        expect(logs, hasLength(1));
        expect(logs.single, contains('strict check runs on Linux CI'));
      });
    });

    testWidgets('fails a gross diff', (tester) async {
      await tester.runAsync(() async {
        await seed(await _png(0), _ciGolden);

        await expectLater(
          comparator(isLinux: false)
              .compare(await _png(_side, rows: 10), Uri.parse(_ciGolden)),
          throwsA(anything),
        );
      });
    });

    testWidgets('stays strict for platform goldens', (tester) async {
      await tester.runAsync(() async {
        await seed(await _png(0), _platformGolden);

        await expectLater(
          comparator(isLinux: false)
              .compare(await _png(1), Uri.parse(_platformGolden)),
          throwsA(anything),
        );
      });
    });

    testWidgets('refuses to write a CI golden', (tester) async {
      await tester.runAsync(() async {
        final png = await _png(0);
        await expectLater(() async {
          await comparator(isLinux: false).update(Uri.parse(_ciGolden), png);
        }, throwsStateError);
        expect(File('${dir.path}/$_ciGolden').existsSync(), isFalse);
      });
    });

    testWidgets('writes a CI golden when explicitly allowed', (tester) async {
      await tester.runAsync(() async {
        await comparator(
          isLinux: false,
          allowNonLinuxUpdates: true,
        ).update(Uri.parse(_ciGolden), await _png(0));

        expect(File('${dir.path}/$_ciGolden').existsSync(), isTrue);
      });
    });

    testWidgets('writes a platform golden freely', (tester) async {
      await tester.runAsync(() async {
        await comparator(isLinux: false)
            .update(Uri.parse(_platformGolden), await _png(0));

        expect(File('${dir.path}/$_platformGolden').existsSync(), isTrue);
      });
    });
  });

  group('failure files', () {
    final basedir = Uri.file('/repo/test/');
    final linux = CiGoldenComparator(
      Uri.file('/repo/test/a_test.dart'),
      isLinux: true,
    );

    String nameOf(String golden) => linux
        .getFailureFile('testImage', Uri.parse(golden), basedir)
        .uri
        .pathSegments
        .join('/');

    test('are named after the whole golden path', () {
      expect(
        nameOf('goldens/ci/Atoms/AppIcon/gallery-default.png'),
        endsWith(
          'test/failures/ci_Atoms_AppIcon_gallery-default_testImage.png',
        ),
      );
    });

    test('keep same-named use cases of two components apart', () {
      expect(
        nameOf('goldens/ci/Atoms/AppButton/primary-default.png'),
        isNot(nameOf('goldens/ci/Atoms/AppChip/primary-default.png')),
      );
    });
  });
}
