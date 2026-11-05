# Compapp Design

Design system for the [Compapp](https://github.com/6Pi-Devs/Compapp-app) Flutter app: design tokens, a Material 3 theme and atomic widgets, cataloged in Widgetbook.

The visual direction ("Living Floorplan") lives in the [Claude Design canvas](https://claude.ai/artifact/XRN3NJsKyxv3FgVhGgFPpo). Work is tracked in [Compapp-app#24](https://github.com/6Pi-Devs/Compapp-app/issues/24).

## Use it from the app

The package is not published to pub.dev. The app depends on it through git, pinned to a release tag:

```yaml
dependencies:
  compapp_design:
    git:
      url: https://github.com/6Pi-Devs/Compapp-design.git
      ref: vX.Y.Z
```

Bump the tag to upgrade. Releases and their notes are listed on the [Releases page](https://github.com/6Pi-Devs/Compapp-design/releases).

```dart
import 'package:compapp_design/compapp_design.dart';

void main() {
  CompappDesign.registerLicenses(); // lists the bundled OFL fonts in the license page
  runApp(
    MaterialApp(
      theme: CompappTheme.light,
      darkTheme: CompappTheme.dark,
      home: const Placeholder(),
    ),
  );
}
```

Read colors from `Theme.of(context).colorScheme`, or `context.appColors` for presence, busy and pebble colors. Spacing, radius, motion and sizes come from `AppSpacing`, `AppRadius`, `AppMotion` and `AppSizes`.

## Develop

Requires Flutter 3.47.9 (see `pubspec.yaml`).

| Task | Command |
|------|---------|
| Install | `flutter pub get` |
| Format | `dart format $(git ls-files '*.dart')` |
| Analyze | `flutter analyze --fatal-infos` |
| Test | `flutter test` |

## Release

The git tag is the only version. A `feat` since the last tag bumps the minor version, anything else the patch (breaking changes: major from 1.0.0, minor before). See [AGENTS.md](AGENTS.md#releases).

1. Merge to `main`.
2. Run the Release workflow on `main`: `gh workflow run release.yml --ref main` (add `-f dry_run=true` to only print the version), or the Actions tab. CI must be green on that commit: a later push cancels pending runs, so re-run a cancelled one first.
3. It tags the commit and creates the GitHub Release with generated notes, built from PR titles, so give each PR a Conventional Commit title with the highest type among its commits.
4. In the app, bump the `ref` in `pubspec.yaml`, run `flutter pub get`, and commit `pubspec.yaml` and `pubspec.lock`.

Preview the next version locally with `git fetch --tags && dart tool/next_version.dart`.

## Contributing

Read [AGENTS.md](AGENTS.md) first. It covers the atomic levels, import rules, token rules, the component manifest and the Definition of Done. It applies to humans and AI agents alike.
