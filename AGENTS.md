# AGENTS.md

Rules for anyone writing code in this repo, human or AI agent. Read this before changing anything. Humans onboarding should start with [README.md](README.md).

## Mission and golden rules

`compapp_design` is the design system of [Compapp](https://github.com/6Pi-Devs/Compapp-app): design tokens, a Material 3 theme and reusable widgets, organized by atomic design and cataloged in Widgetbook. The look is "Living Floorplan", defined in the [Claude Design canvas](https://claude.ai/artifact/XRN3NJsKyxv3FgVhGgFPpo). The app consumes this package as a git dependency pinned to a release tag. Work is tracked in [Compapp-app#24](https://github.com/6Pi-Devs/Compapp-app/issues/24).

1. **Compose down, never up.** `tokens, models <- atoms <- molecules <- organisms <- templates`. See [Import rules](#import-rules).
2. **Components are pure presentation.** Props are plain data and callbacks. No app or feature types, no repositories, cubits, use cases, `GetIt` or l10n delegates.
3. **Every visible string is a prop.** The app owns localization and passes strings in. Stories pass English and Spanish samples.
4. **Colors, sizes and motion come from tokens.** No `Color(0x...)` outside `lib/src/tokens/`, no magic numbers.
5. **Every interactive widget takes a required `semanticLabel`**, unless it renders a visible text label passed in as a prop (that label names it). Icon-only widgets always require it.
6. **The manifest is the contract.** A widget that is not in `components.json` does not exist. Add its entry in the same commit.
7. **Tokens have one source of truth**: `tokens/compapp.tokens.json`. The Dart tokens are hand-written and a parity test keeps them equal.
8. **Everything is in English**, including code, comments, docs, commits and PRs.
9. **Tests ship with the code** in the same commit.
10. **Never commit generated code** (`*.g.dart`, Widgetbook builds).

## Commands

| Task | Command |
|------|---------|
| Install | `flutter pub get` |
| Format | `dart format $(git ls-files '*.dart')` |
| Format check (as CI) | `dart format --output=none --set-exit-if-changed $(git ls-files '*.dart')` |
| Analyze (must be clean) | `flutter analyze --fatal-infos` |
| Test | `flutter test --coverage` |
| Fix constructor shorthand | `dart fix --apply` |

Widgetbook (`widgetbook/`) and golden tests arrive with the atoms slice and add their own commands here.

## Architecture

```
lib/
  compapp_design.dart     barrel: the only import an app needs
  src/
    tokens/               AppColors, AppSpacing, AppRadius, AppShadows, AppMotion, AppSizes, AppTypography (AppPalette is internal)
    theme/                CompappTheme.light / dark
    models/               view models and shared enums (MemberView, RoomView, AppIcons)
    atoms/                single-purpose controls (AppButton, AppPebble, AppChip)
    molecules/            atoms composed into a unit (MemberRow, RoomTile)
    organisms/            sections made of molecules (FloorplanMap, PresencePanel)
    templates/            page scaffolds with no data access
tokens/compapp.tokens.json   source of truth for every token (DTCG-style JSON)
components.json             machine-readable component manifest
widgetbook/                 catalog app (path dependency on this package)
fonts/                      bundled Bricolage Grotesque and Instrument Sans, with OFL licenses
```

### Import rules

| Level | May import | Must not import |
|-------|------------|-----------------|
| `tokens` | Flutter `painting` and `material` types | everything else in `src/` |
| `models` | Dart SDK, Flutter `painting` types, other `models` | `tokens` and everything above |
| `theme` | `tokens` | atoms and above |
| `atoms` | `tokens`, `models`, and `AppIcon` (the only atom an atom may use, so a button can show an icon) | every other atom, molecules and above |
| `molecules` | `tokens`, `models`, `atoms` | other molecules, organisms and above |
| `organisms` | `tokens`, `models`, `atoms`, `molecules` | other organisms, templates |
| `templates` | everything below | app or feature code |
| all levels | Flutter, Dart SDK, `package:compapp_design/...` | `flutter_bloc`, `get_it`, `dio`, `go_router`, l10n delegates, anything from Compapp-app |

`BuildContext` is read only for `Theme`, `MediaQuery` and `Directionality`. View models (`MemberView`, `RoomView`) and shared enums (`AppIcons`) live in `lib/src/models/`: plain immutable data owned by this package, importable from every level, exempt from the manifest. The app maps its business objects to them. Nothing in `models` imports upward.

Imports under `lib/` are `package:compapp_design/...`. Tests may import `test/helpers/` with a relative path.

### Naming

Classes are `PascalCase`, files `snake_case`. The file is the class name under its atomic level: `AppButton` lives in `lib/src/atoms/app_button.dart`. One public class per file. Exceptions: a sealed family or a small enum used only by one widget may share its widget's file.

### Constructors

The analyzer enforces the Dart 3.13 shorthand. Write `const new(this.x)` for the unnamed constructor and `factory fromJson(...)` or `new named(...)` for named ones. Run `dart fix --apply` if you wrote the long form.

## Components

### Rules

| Rule | Detail |
|------|--------|
| Props | Plain data and callbacks. Nullable callbacks mean disabled. |
| Strings | Labels, hints, errors and semantic labels arrive as `String` props. No literals in widgets. |
| Semantics | Interactive widgets take a required `semanticLabel`, unless they render a visible text label passed in as a prop (that label names them). Icon-only widgets always require it. Decorative widgets are excluded from semantics. |
| Keys | Stable `Key('<scope>.<thing>.<id>')` pattern, copied from the manifest, for example `Key('floorplan.room.<roomId>')`. The id comes from a prop, never from list position. |
| Motion | Respect `MediaQuery.disableAnimations`. Durations and curves come from `AppMotion`. |
| Calm | Danger colors only in destructive flows. Never show who is behind on a task. |
| Contrast and targets | Text contrast at least 4.5:1. Hit area at least `AppSizes.minTarget` (48), drawn size at least `AppSizes.minDrawn` (44). |

### Manifest

`components.json` holds one entry per widget. `test/manifest_test.dart` fails when an entry's `path` does not exist, when a Dart file under `lib/src/{atoms,molecules,organisms,templates}/` has no entry, or when `id`s or classes repeat.

```json
{
  "$schema-version": 1,
  "components": [
    {
      "id": "app-button",
      "level": "atom",
      "class": "AppButton",
      "path": "atoms/app_button.dart",
      "props": [{ "name": "label", "type": "String", "required": true }],
      "variants": ["primary", "secondary", "ghost", "danger"],
      "states": ["default", "pressed", "disabled", "loading"],
      "semantics": "Button named by label; icon-only requires semanticLabel",
      "key": "button.<action>",
      "stories": ["Atoms/AppButton/primary-default"]
    }
  ]
}
```

`path` is relative to `lib/src/`. `level` is `atom`, `molecule`, `organism` or `template`, and the path starts with its folder.

### Widgetbook and golden tests

- One use case per variant x state listed in the manifest, no more, no fewer.
- Use case names follow `<Level>/<Class>/<variant>-<state>` (`Atoms/AppButton/primary-disabled`). The manifest `stories`, the Widgetbook tree and the golden file names use the same string.
- Golden tests run per use case, light and dark, text scale 1.0 and 2.0, plus a semantics test with `meetsGuideline` for tap targets, labels and contrast.
- The golden tooling (plain `flutter_test` goldens versus a helper package, and how CI keeps them stable across platforms) is decided in the atoms slice. This section is updated then.
- Goldens in this root package must load the bundled fonts under the `packages/compapp_design/` prefix (for example `packages/compapp_design/Instrument Sans`), because the text styles carry `package: 'compapp_design'`. Fonts registered without the prefix are not used and the golden falls back to the test font.

### Add a component

1. Add its entry to `components.json` first (level, class, path, props, variants, states, semantics, key, stories).
2. Create `lib/src/<level>/<name>.dart` following the [Import rules](#import-rules). Export it from the barrel.
3. Add the Widgetbook use cases and golden tests for every variant x state.
4. Add a semantics test.
5. Run the [Definition of Done](#definition-of-done) checklist.

## Tokens

- `tokens/compapp.tokens.json` (DTCG-style JSON: string values, `px` line heights, un-namespaced `$extensions`) is the source of truth. Edit it first. It does not claim strict compliance with a specific DTCG spec revision.
- The Dart tokens in `lib/src/tokens/` are **hand-written**, not generated. The app consumes this package as a git dependency, and a git dependency never runs `build_runner`. Generated files would have to be committed, which is forbidden.
- Every token class exposes a `values` map keyed by JSON token name (`AppSpacing.values`, `AppPalette.values`, `AppColors.values`, `AppTypography.values`, and so on). `test/tokens/parity_test.dart` loads the JSON and compares it with those maps in both directions: a token on one side only, or with a different value, fails CI. Add every new token to its class and to `values`, and to the JSON, in the same commit. A constant that is not added to `values` is invisible to the test.
- `test/tokens/font_manifest_test.dart` checks that every family and weight `AppTypography` uses is declared in `pubspec.yaml`, so renaming a family there fails CI.
- Dark values live under `$extensions.mode.dark`, as on the canvas Contracts board.
- Bricolage styles (display, headline, title) set `fontVariations: [FontVariation.opticalSize(fontSize)]` and `fontWeight: w600`. `fontWeight` drives the variable font's `wght` axis, so never add `FontVariation.weight`: it would override `copyWith(fontWeight:)` and iOS Bold Text. Without `opsz` the font renders at its 96 default (display cut), so `opsz` equals the font size, clamped to the axis range 12 to 96, like `font-optical-sizing: auto` in browsers. The JSON records the rule under `font.$extensions.opticalSizing` and the parity test checks it.
- Never `copyWith(fontSize:)` on a Bricolage style: it keeps the old `opsz`. Add a size token to the JSON and `AppTypography` instead.
- Styles without tracking in the spec set `letterSpacing: 0`, so Material defaults do not leak in.
- Fonts are bundled (Bricolage Grotesque as a variable font with `opsz`, `wdth` and `wght` axes; Instrument Sans as static 400 and 600 TTFs) and declared in `pubspec.yaml`. Text styles carry `package: 'compapp_design'` so a consuming app resolves them. Numbers are always tabular, so every style carries `FontFeature.tabularFigures()`.
- The fonts are SIL OFL. The app calls `CompappDesign.registerLicenses()` once in `main` so the license page lists them.
- `AppPalette` (colors that have a Material slot) is internal and not exported. Widgets read those colors from `Theme.of(context).colorScheme`, the rest with `context.appColors`.

### Token to Flutter target

| Token | Flutter target |
|-------|----------------|
| `color.ground` | `ColorScheme.surface`, `scaffoldBackgroundColor` |
| `color.surface` | `ColorScheme.surfaceContainerLowest` (also `surfaceBright`) |
| `color.surface-sunken` | `ColorScheme.surfaceContainerHigh` (also `surfaceDim`, `surfaceContainerHighest`) |
| `color.ink` | `ColorScheme.onSurface` |
| `color.ink-muted` | `ColorScheme.onSurfaceVariant` (also `outline`) |
| `color.line` | `ColorScheme.outlineVariant` |
| `color.primary` | `ColorScheme.primary` |
| `color.on-primary` | `ColorScheme.onPrimary` |
| `color.primary-soft` | `ColorScheme.primaryContainer` |
| `color.danger` | `ColorScheme.error` |
| `color.danger-soft` | `ColorScheme.errorContainer` |
| `color.presence-home`, `presence-away`, `busy`, `busy-soft` | `AppColors.presenceHome`, `presenceAway`, `busy`, `busySoft` |
| `pebble.*` | `AppColors.pebbles` (sage, sky, apricot, rose, sand, tide), `AppColors.pebbleAt(joinOrder)` |
| `font.display`, `headline`, `title` | `TextTheme.displayMedium`, `headlineSmall`, `titleLarge` |
| `font.body-lg`, `body`, `label`, `caption` | `TextTheme.bodyLarge`, `bodyMedium`, `labelLarge`, `bodySmall` |
| `space.xs` to `xxl` | `AppSpacing.xs`, `sm`, `md`, `lg`, `xl`, `xxl` (4, 8, 16, 24, 32, 48) |
| `radius.xs` to `lg`, `radius.pebble` | `AppRadius.xs`, `sm`, `md`, `lg`, `AppRadius.pebble(size)` |
| `elevation.sheet` | `AppShadows.sheet` |
| `elevation.flat` | `AppSizes.hairline` (1px `colorScheme.outlineVariant` border) |
| `motion.presence`, `motion.in-use` | `AppMotion.presence`, `inUse` and their curves |
| `target.min` | `AppSizes.minTarget` (48 hit area), `AppSizes.minDrawn` (44 drawn) |

`ColorScheme` slots with no token are filled explicitly. Only `shadow`, `scrim` and the `*Fixed` slots keep Flutter's defaults:

| Slot | Value | Why |
|------|-------|-----|
| `secondary`, `onSecondary`, `secondaryContainer`, `onSecondaryContainer` | primary, on-primary, primary-soft, ink | The design has one accent |
| `tertiary`, `onTertiary`, `tertiaryContainer`, `onTertiaryContainer` | busy, on-primary, busy-soft, ink | Tertiary is the in-use accent |
| `onPrimaryContainer`, `onErrorContainer` | ink | Text on soft fills uses ink |
| `onError` | on-primary | Danger is light in dark mode, so it needs dark text, like primary |
| `surfaceContainerLow`, `surfaceContainer` | surface | Cards, sheets, nav bar and menus use surface |
| `inverseSurface`, `onInverseSurface` | ink, ground | Snackbars invert the page |
| `inversePrimary` | primary-soft | Passes 4.5:1 on the inverse surface in both themes |
| `surfaceTint` | transparent | No Material tint over surfaces |

The sheet shadow uses the light ink color at 18% in both themes, so it darkens the page in dark mode too.

## Releases

Releases are semver tags `vX.Y.Z`. The app pins a tag in its `pubspec.yaml`:

```yaml
compapp_design:
  git:
    url: https://github.com/6Pi-Devs/Compapp-design.git
    ref: vX.Y.Z
```

Rules: a renamed or removed public token, widget or prop is a major change (a minor while the version is `0.x`).

To release:

1. Bump `version` in `pubspec.yaml` to `X.Y.Z`.
2. Move the `CHANGELOG.md` Unreleased entries under a `[X.Y.Z]` heading with the date.
3. Merge, then tag the merge commit `vX.Y.Z` and push the tag.
4. Bump the `ref` in the app.

## Comments

Code explains itself through names. Keep comments rare.

- No commented-out code.
- No TODO without an issue reference (`// TODO(#123): ...`).
- Add a short `///` on a class only when its contract is not obvious from its name.

## Definition of Done

- [ ] Import rules respected, names follow [Naming](#naming)
- [ ] No `Color(0x...)` outside `lib/src/tokens/`, no magic numbers, no hardcoded strings
- [ ] `components.json` entry added or updated, manifest test green
- [ ] Use cases, goldens and semantics test for every variant x state
- [ ] Tokens changed in JSON and Dart together, parity test green
- [ ] Format check (as CI) clean and `flutter analyze --fatal-infos` reports 0 issues
- [ ] No generated files committed
- [ ] `CHANGELOG.md` updated
- [ ] Conventional Commit messages
