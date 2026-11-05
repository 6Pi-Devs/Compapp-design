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

Bump the tag to upgrade. Releases are listed in [CHANGELOG.md](CHANGELOG.md).

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

## Catalog

The components are cataloged in Widgetbook, a separate Flutter app in `widgetbook/` that depends on this package by path.

```sh
cd widgetbook
flutter pub get
flutter run -d chrome
```

Use the addons to switch light and dark, English and Spanish, text scale and phone viewports. The same use cases drive the golden and accessibility tests:

| Task | Command (in `widgetbook/`) |
|------|----------------------------|
| Test | `flutter test` |

The committed goldens are Linux renders: Linux CI is the only reference platform. On other operating systems a local run compares with a tolerance and cannot write CI goldens. To add or update one, push, let CI fail, then run `rm -rf widgetbook/test/goldens/ci && gh run download <run-id> -n ci-goldens -D widgetbook/test/goldens/ci` (the artifact holds every golden and `gh` will not overwrite files), review the images with `git status` and `git diff --stat`, and commit them. Never commit a golden rendered outside Linux. See [AGENTS.md](AGENTS.md) for the details.

## Release

1. Bump `version` in `pubspec.yaml`.
2. Move the `CHANGELOG.md` Unreleased entries under the new version.
3. Run `flutter pub get` in `widgetbook/` and commit its `pubspec.lock`.
4. Tag the merge commit `vX.Y.Z` and push the tag.
5. Bump the `ref` in the app.

## Contributing

Read [AGENTS.md](AGENTS.md) first. It covers the atomic levels, import rules, token rules, the component manifest and the Definition of Done. It applies to humans and AI agents alike.
