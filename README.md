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

## Develop

Requires Flutter 3.47.9 (see `pubspec.yaml`).

| Task | Command |
|------|---------|
| Install | `flutter pub get` |
| Format | `dart format $(git ls-files '*.dart')` |
| Analyze | `flutter analyze --fatal-infos` |
| Test | `flutter test` |

## Release

1. Bump `version` in `pubspec.yaml`.
2. Move the `CHANGELOG.md` Unreleased entries under the new version.
3. Tag the merge commit `vX.Y.Z` and push the tag.
4. Bump the `ref` in the app.

## Contributing

Read [AGENTS.md](AGENTS.md) first. It covers the atomic levels, import rules, token rules, the component manifest and the Definition of Done. It applies to humans and AI agents alike.
