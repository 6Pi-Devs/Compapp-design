import 'dart:async';

import 'package:alchemist/alchemist.dart';

import 'helpers/ci_golden_comparator.dart';

/// Platform goldens are local-only (gitignored) and opt in with
/// `--dart-define=PLATFORM_GOLDENS=true`. Only the CI goldens are committed.
const _platformGoldens = bool.fromEnvironment('PLATFORM_GOLDENS');

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  CiGoldenComparator.install();
  await AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: _platformGoldens),
    ),
    run: testMain,
  );
}
