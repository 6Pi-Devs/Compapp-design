import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _ciGoldenPrefix = 'goldens/ci/';

/// Share of pixels that may differ from a CI golden on an operating system
/// other than Linux. Linux CI is the only reference platform and rasterizes
/// curves slightly differently from Windows and macOS, so this absorbs
/// anti-aliasing there and still catches a gross break.
const nonLinuxGoldenTolerance = 0.01;

/// The comparator of every golden test.
///
/// - CI goldens are Linux-only references. On Linux the match is exact. On any
///   other OS it allows [nonLinuxGoldenTolerance] and says so, and writing a CI
///   golden throws unless `--dart-define=ALLOW_NON_LINUX_GOLDENS=true` is set,
///   so nobody commits a render that fails on CI.
/// - Failure images are named after the whole golden path
///   (`failures/ci_Atoms_AppIcon_gallery-default_testImage.png`), not only its
///   last segment, so two components with a same-named use case never
///   overwrite each other's diff.
class CiGoldenComparator extends LocalFileComparator {
  new(
    super.testFile, {
    bool? isLinux,
    this.allowNonLinuxUpdates = const bool.fromEnvironment(
      'ALLOW_NON_LINUX_GOLDENS',
    ),
    void Function(String message)? log,
  }) : isLinux = isLinux ?? Platform.isLinux,
       log = log ?? debugPrint;

  /// Replaces the comparator of the running test file with this one.
  static void install() {
    final current = goldenFileComparator;
    if (current is! LocalFileComparator) return;
    goldenFileComparator = CiGoldenComparator(
      current.basedir.resolve('test.dart'),
    );
  }

  final bool isLinux;
  final bool allowNonLinuxUpdates;
  final void Function(String message) log;

  bool _isCiGolden(Uri golden) => golden.path.startsWith(_ciGoldenPrefix);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    if (isLinux || !_isCiGolden(golden)) {
      return await super.compare(imageBytes, golden);
    }

    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) {
      result.dispose();
      return true;
    }
    if (result.diffPercent <= nonLinuxGoldenTolerance) {
      log(
        'Golden "$golden" differs by '
        '${(result.diffPercent * 100).toStringAsFixed(2)}%, within the '
        '${(nonLinuxGoldenTolerance * 100).toStringAsFixed(0)}% allowed off '
        'Linux. The strict check runs on Linux CI.',
      );
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    if (!isLinux && !allowNonLinuxUpdates && _isCiGolden(golden)) {
      throw StateError(
        'Refusing to write "$golden": CI goldens are Linux renders and a '
        'golden rendered on this OS fails Linux CI. Push, let CI fail, and '
        'download its `ci-goldens` artifact instead (see AGENTS.md). Pass '
        '--dart-define=ALLOW_NON_LINUX_GOLDENS=true only to experiment '
        'locally.',
      );
    }
    await super.update(golden, imageBytes);
  }

  @override
  File getFailureFile(String failure, Uri golden, Uri basedir) {
    final segments = golden.pathSegments.where((s) => s != 'goldens').toList();
    final last = segments.removeLast();
    final stem = last.substring(0, last.lastIndexOf('.'));
    final flat = [...segments, stem].join('_');
    return File('${basedir.toFilePath()}failures/${flat}_$failure.png');
  }
}
