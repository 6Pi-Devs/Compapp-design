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

The Widgetbook catalog is its own Flutter package in `widgetbook/`. Run these from that folder:

| Task | Command |
|------|---------|
| Install | `flutter pub get` |
| Run the catalog | `flutter run -d chrome` |
| Build check (CI does this, no deploy) | `flutter build web` |
| Build as published (served under `/Compapp-design/`) | `flutter build web --release --base-href /Compapp-design/` (in Git Bash on Windows prefix it with `MSYS_NO_PATHCONV=1`) |
| Analyze (must be clean) | `flutter analyze --fatal-infos` |
| Test (use case contract, goldens, semantics) | `flutter test` |
| Add or update a golden | Push and let CI render it, see [Golden tooling](#golden-tooling). `--update-goldens` refuses to write CI goldens off Linux |
| Add local platform goldens (never committed) | `flutter test --dart-define=PLATFORM_GOLDENS=true --update-goldens` (the CI variant refuses to write and reports it, which is expected) |

The root `flutter analyze` and `flutter test` skip `widgetbook/`, so run both packages before you push. `widgetbook/pubspec.lock` is committed: whenever the root dependencies change, run `flutter pub get` in `widgetbook/` and commit its lock, or `--enforce-lockfile` fails in CI.

## Architecture

```
lib/
  compapp_design.dart     barrel: the only import an app needs
  src/
    tokens/               AppColors, AppSpacing, AppRadius, AppShadows, AppMotion, AppSizes, AppStateLayers, AppProgress, AppDecor, AppTypography (AppPalette is internal)
    theme/                CompappTheme.light / dark
    models/               view models and shared enums (MemberView, RoomView, AppIcons)
    atoms/                single-purpose controls (AppButton, AppPebble, AppChip)
    molecules/            atoms composed into a unit (MemberRow, RoomTile)
    organisms/            sections made of molecules (FloorplanMap, PresencePanel)
    templates/            page scaffolds with no data access
tokens/compapp.tokens.json   source of truth for every token (DTCG-style JSON)
components.json             machine-readable component manifest
widgetbook/                 catalog app (path dependency on this package)
tool/                       repo tooling such as next_version.dart, not part of the package API
fonts/                      bundled Bricolage Grotesque and Instrument Sans, with OFL licenses
```

### Import rules

| Level | May import | Must not import |
|-------|------------|-----------------|
| `tokens` | Flutter `painting` and `material` types | everything else in `src/` |
| `models` | Dart SDK, Flutter `painting` and `foundation` types (`@immutable`), other `models` | `tokens` and everything above |
| `theme` | `tokens` | atoms and above |
| `atoms` | `tokens`, `models`, and `AppIcon` (the only atom an atom may use, so a button can show an icon) | every other atom, molecules and above |
| `molecules` | `tokens`, `models`, `atoms` | other molecules, organisms and above |
| `organisms` | `tokens`, `models`, `atoms`, `molecules` | other organisms, templates |
| `templates` | everything below | app or feature code |
| all levels | Flutter, Dart SDK, `path_parsing`, `package:compapp_design/...` | `flutter_bloc`, `get_it`, `dio`, `go_router`, l10n delegates, anything from Compapp-app |

`BuildContext` is read only for `Theme`, `IconTheme`, `MediaQuery` and `Directionality`. View models (`MemberView`, `RoomView`) and shared enums (`AppIcons`) live in `lib/src/models/`: plain immutable data owned by this package, importable from every level, exempt from the manifest. The app maps its business objects to them. Nothing in `models` imports upward.

Imports under `lib/` are `package:compapp_design/...`. Tests may import `test/helpers/` and `tool/` with a relative path (`tool/` sits outside `lib/`, so it has no package URI).

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
| Contrast and targets | Text contrast at least 4.5:1. The boundary of an interactive component (field border, switch off track outline, chip and outlined button border, empty code cell) is `colorScheme.outline` (ink-muted) so it keeps 3:1 against the page (WCAG 1.4.11); `outlineVariant` (line) is for decorative hairlines only. Hit area at least `AppSizes.minTarget` (48), drawn size at least `AppSizes.minDrawn` (44). |

### Manifest

`components.json` holds one entry per widget. `test/manifest_test.dart` fails when an entry's `path` does not exist, when a Dart file under `lib/src/{atoms,molecules,organisms,templates}/` has no entry, when `id`s or classes repeat, or when a `playground` is missing, is not `<Level>/<Class>/playground`, repeats or is also a story. The schema version is 2: version 2 added the required `playground` field.

```json
{
  "$schema-version": 2,
  "components": [
    {
      "id": "app-button",
      "level": "atom",
      "class": "AppButton",
      "playground": "Atoms/AppButton/playground",
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

- One fixed use case per variant x state listed in the manifest, no more, no fewer, plus exactly one `playground` per component (see [Playgrounds](#playgrounds)).
- Use case names follow `<Level>/<Class>/<variant>-<state>` (`Atoms/AppButton/primary-disabled`). The manifest `stories`, the Widgetbook tree and the golden file names use the same string.
- A fixed use case is a plain builder with fixed props, no knobs. The same builder feeds the Widgetbook tree and the tests, so the catalog and the goldens cannot drift. Knobs live only in the `playground`.
- The tree is written by hand in `widgetbook/lib/src/catalog/` (`catalog.dart` composes `atoms.dart` and `molecules.dart`, one file of use cases per component under `atoms/` and `molecules/`). There is no `widgetbook_generator` and no `build_runner`: generated files are never committed, and an explicit tree is easier for agents to read.
- Strings in use cases come in English and Spanish: `context.sample(en: ..., es: ...)` picks one by the locale the Widgetbook localization addon sets. Goldens render `en` only.
- Generic tests in `widgetbook/test/` loop over the catalog, so a new atom or molecule is covered without touching them:
  - `catalog_contract_test.dart`: the fixed use case paths equal the union of every manifest `stories` entry, in both directions, follow the naming pattern, and each manifest entry has exactly one story per variant x state. The playgrounds in the tree equal the manifest `playground` paths, one per component.
  - `catalog_goldens_test.dart`: one golden per fixed use case, named after its path, holding four scenarios (light and dark, text scale 1.0 and 2.0).
  - `catalog_semantics_test.dart`: every fixed use case, light and dark, meets `androidTapTargetGuideline`, `iOSTapTargetGuideline` and `labeledTapTargetGuideline`. It also runs `textContrastGuideline`, which finds a text by its semantics label and so is blind to a merged or replaced label: do not rely on it for contrast.
  - `catalog_text_contrast_test.dart`: owns the contrast of every rendered text. It walks the `RenderParagraph`s of every fixed use case, light and dark, reads the text color (`color` or `foreground`, times the opacity of its ancestors) and the nearest opaque fill among the render ancestors (the painted pixels around it when the nearest painting ancestor is a custom painter), and holds each text to 4.5:1. A text it cannot read is reported, not skipped, and a fully transparent one is not painted, so it is not read. `widgetbook/test/helpers/rendered_text_contrast_test.dart` holds the cases it must pass and fail.
  - `catalog_molecules_layout_test.dart`: every fixed molecule use case is laid out the way the goldens do (intrinsic sizing, real fonts), draws at a visible size in all four scenarios and overflows nowhere. A molecule that expands (a row) gets a fixed width in its use case, and must not use `LayoutBuilder` (the golden harness measures intrinsic sizes).
- States a static builder cannot reach by gesture are rendered deterministically without a test-only prop on the component, so every golden scenario shows them. Buttons take Material's `statesController` holding `WidgetState.pressed` or `WidgetState.focused` (`StatesControllerHost`). Fields and the code input take a `FocusNode` that reports focus (`FocusedNodeHost`), because only one widget can really hold the primary focus and the four scenarios of a golden render side by side. Spinners freeze under `FrozenMotion` (`MediaQuery.disableAnimations`), so `pumpAndSettle` can finish. The helpers live in `widgetbook/lib/src/support/story_support.dart`.
- alchemist draws the text of an editable field as blocks, so a golden never proves its text color: component widget tests read the painted pixel instead.
- Widgetbook shows light and dark (`CompappTheme`), `en` and `es`, text scale and phone viewports through addons.

#### Playgrounds

Every component has one extra use case named `playground` (`Atoms/AppButton/playground`), built with Widgetbook knobs for every public prop, so the catalog can be explored by hand. It is the only use case with knobs and it is never a golden.

| Prop | Knob |
|------|------|
| Enum | `context.enumKnob` (dropdown), `enumKnobOrNull` for a nullable one |
| `bool` | `context.knobs.boolean` |
| Number | a slider limited to the valid range (story-only bounds are named constants), for example ring value 0 to 1 with an "in use" toggle, `ageDays` 0 to 30, `joinOrder`, code length |
| `String` | `context.textKnob` with the `context.sample` English or Spanish text as default, `textKnobOrNull` for `String?` |
| Nullable callback | an "enabled" boolean: null means disabled |
| `AppIcons` | `enumKnob` over `AppIcons.values` |
| Controller, `FocusNode`, `WidgetStatesController`, callbacks | plumbing: the story owns them. A knob forces the look instead ("focused look", "forced state") |

Rules:

- A knob is the initial value. Stateful atoms stay interactive: typing, toggling and selecting drive local state, held by `SeededState` (switch value, chip selected) or `TextControllerHost` (text). Widgetbook keys a use case by the URL, so any knob change rebuilds the preview from the knob values: whatever the user typed or toggled starts over, and a field with `autofocus` takes focus again (the autofocus knobs say to turn it off before editing other knobs). Never wire a knob straight to a value the user can also change.
- A playground reads knobs, so it only builds inside a Widgetbook app. Goldens, the semantics test, the freshness bar layout test and the contract use `collectFixedUseCases`, which leaves playgrounds out, and `playground_paths_test.dart` fails if one of those files goes back to `collectUseCases`.
- `catalog_playgrounds_test.dart` opens every playground in a real Widgetbook app (`CatalogApp(initialRoute: ...)` with `path`, `preview` and `knobs` query parameters), checks that the component builds with its default knobs, and that the full catalog builds with a knobs panel that has knobs (not "No Knobs available"). A table lists every knob of every playground with a value other than its default and a check on the rendered component: the test fails when a knob is missing from the table, registered but unlisted, or not connected to the component (the check also has to fail on the default state). Values are set through the URL and through `WidgetbookState.updateQueryField`. A new knob needs a row in that table.
- Show a rule, do not hide a knob: the pebble badges draw from s44 up, so the badge knobs stay and have no effect below it.

#### Golden tooling

Goldens use [`alchemist`](https://pub.dev/packages/alchemist), configured in `widgetbook/test/flutter_test_config.dart`. Only its **CI goldens** are committed, under `widgetbook/test/goldens/ci/`. They draw text as solid blocks (sized by the real font metrics) and skip shadows.

**Linux, meaning CI, is the only reference platform for CI goldens.** Windows and macOS rasterize curves slightly differently, so a golden rendered there fails on Linux CI. `CiGoldenComparator` (`widgetbook/test/helpers/`) enforces it:

- On Linux the match is exact.
- On any other OS a local run uses a tolerant comparison (`nonLinuxGoldenTolerance`, 1% of the pixels) and prints a line saying the strict check runs on Linux CI. It catches gross breaks, not anti-aliasing.
- On any other OS, writing a CI golden throws, so `--update-goldens` cannot produce a golden that fails CI. `--dart-define=ALLOW_NON_LINUX_GOLDENS=true` lifts the guard for local experiments: never commit what it writes.

To add or update a golden (a new atom, or an intentional visual change):

1. Commit the code and push. CI fails the golden check.
2. The failed run renders the proposed goldens on Linux and uploads them as the `ci-goldens` artifact. The artifact holds every CI golden and `gh run download` refuses to overwrite files, so replace the folder: `rm -rf widgetbook/test/goldens/ci && gh run download <run-id> -n ci-goldens -D widgetbook/test/goldens/ci`. Then review with `git status` and `git diff --stat`: only the goldens you meant to change should differ.
3. Review every image, commit them with the code that changed them, and push.

**Never commit a golden rendered outside Linux.**

- Platform goldens (real glyphs and shadows, for looking at a component) are off by default, gitignored, and opt in with `--dart-define=PLATFORM_GOLDENS=true`. Alchemist registers every font in the font manifest itself, including the `packages/compapp_design/` families the text styles resolve to (they carry `package: 'compapp_design'`), so no font loading code is needed. A platform golden run with `--update-goldens` would also rewrite the CI goldens on that machine, so the comparator refuses unless `ALLOW_NON_LINUX_GOLDENS` is set. Never set it for that run.
- If CI reports a mismatch you cannot reproduce, download the `golden-failures` artifact of the run: it holds the master, test, isolated and masked diff images, named after the whole golden path (`ci_Atoms_AppIcon_gallery-default_testImage.png`), so same-named use cases never overwrite each other.
- Never raise a diff threshold to silence a mismatch. Find out why the pixels differ.

### Add a component

1. Add its entry to `components.json` first (level, class, playground, path, props, variants, states, semantics, key, stories). `playground` is `<Level>/<Class>/playground`.
2. Create `lib/src/<level>/<name>.dart` following the [Import rules](#import-rules). Export it from the barrel.
3. Add `widgetbook/lib/src/catalog/<level>s/<name>_use_cases.dart` (`atoms/` or `molecules/`) with one use case per variant x state, and register it in `atoms.dart` or `molecules.dart`. The goldens and the semantics test pick it up on their own.
4. In the same file add the `playground` use case with a knob for every prop (see [Playgrounds](#playgrounds)). The playground smoke test picks it up on its own.
5. Push, let CI render the Linux golden, download the `ci-goldens` artifact, review the new PNGs and commit them (see [Golden tooling](#golden-tooling)).
6. Run the [Definition of Done](#definition-of-done) checklist.

## Tokens

- `tokens/compapp.tokens.json` (DTCG-style JSON: string values, `px` line heights, un-namespaced `$extensions`) is the source of truth. Edit it first. It does not claim strict compliance with a specific DTCG spec revision.
- The Dart tokens in `lib/src/tokens/` are **hand-written**, not generated. The app consumes this package as a git dependency, and a git dependency never runs `build_runner`. Generated files would have to be committed, which is forbidden.
- Every token class exposes a `values` map keyed by JSON token name (`AppSpacing.values`, `AppPalette.values`, `AppColors.values`, `AppTypography.values`, and so on). `test/tokens/parity_test.dart` loads the JSON and compares it with those maps in both directions: a token on one side only, or with a different value, fails CI. Add every new token to its class and to `values`, and to the JSON, in the same commit. A constant that is not added to `values` is invisible to the test.
- `test/tokens/font_manifest_test.dart` checks that every family and weight `AppTypography` uses is declared in `pubspec.yaml`, so renaming a family there fails CI.
- Dark values live under `$extensions.mode.dark`, as on the canvas Contracts board.
- Bricolage styles (display, headline, title, pebble-xl) set `fontVariations: [FontVariation.opticalSize(fontSize)]` and `fontWeight: w600`. `fontWeight` drives the variable font's `wght` axis, so never add `FontVariation.weight`: it would override `copyWith(fontWeight:)` and iOS Bold Text. Without `opsz` the font renders at its 96 default (display cut), so `opsz` equals the font size, clamped to the axis range 12 to 96, like `font-optical-sizing: auto` in browsers. The JSON records the rule under `font.$extensions.opticalSizing` and the parity test checks it.
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
| `color.ink` | `ColorScheme.onSurface`, `ThemeData.iconTheme` color |
| `color.ink-muted` | `ColorScheme.onSurfaceVariant` (also `outline`) |
| `color.line` | `ColorScheme.outlineVariant` |
| `color.primary` | `ColorScheme.primary` |
| `color.on-primary` | `ColorScheme.onPrimary` |
| `color.primary-soft` | `ColorScheme.primaryContainer` |
| `color.danger` | `ColorScheme.error` |
| `color.danger-soft` | `ColorScheme.errorContainer` |
| `color.presence-home`, `presence-away`, `busy`, `busy-soft` | `AppColors.presenceHome`, `presenceAway`, `busy`, `busySoft` |
| `pebble.*` | `AppColors.pebbles` (sage, sky, apricot, rose, sand, tide), `AppColors.pebbleAt(joinOrder)` |
| `color.on-presence-away` | `AppColors.onPresenceAway`: glyph of the away badge on `presence-away` |
| `color.on-pebble` | `AppColors.onPebble`: initials and ring on a pebble. Dark in both themes, because the pebble colors are pastel in both |
| `font.display`, `headline`, `title` | `TextTheme.displayMedium`, `headlineSmall`, `titleLarge` |
| `font.body-lg`, `body`, `label`, `caption` | `TextTheme.bodyLarge`, `bodyMedium`, `labelLarge`, `bodySmall` |
| `font.label-lg` | `AppTypography.labelLg` (15/22, 600). No `TextTheme` slot: the button themes use it for their label |
| `space.xs` to `xxl` | `AppSpacing.xs`, `sm`, `md`, `lg`, `xl`, `xxl` (4, 8, 16, 24, 32, 48) |
| `radius.xs` to `lg`, `radius.pebble` | `AppRadius.xs`, `sm`, `md`, `lg`, `AppRadius.pebble(size)` |
| `elevation.sheet` | `AppShadows.sheet` |
| `elevation.flat` | `AppSizes.hairline` (1px `colorScheme.outlineVariant` border) |
| `motion.presence`, `motion.in-use` | `AppMotion.presence`, `inUse` and their curves |
| `motion.spin` | `AppMotion.spin`, `spinCurve` (one turn of a loading spinner) |
| `target.min` | `AppSizes.minTarget` (48 hit area), `AppSizes.minDrawn` (44 drawn) |
| `size.control-md`, `control-lg` | `AppSizes.controlMd` (44), `controlLg` (52): heights of buttons, chips and fields |
| `size.glyph-md`, `glyph-lg` | `AppSizes.glyphMd` (16), `glyphLg` (18): icon or spinner beside a label |
| `size.spinner-md`, `spinner-lg` | `AppSizes.spinnerMd` (12), `spinnerLg` (13.5): the ring of a spinner, drawn in a glyph box |
| `size.dash`, `dash-gap` | `AppSizes.dash` (4), `dashGap` (3): dash pattern of a 1 px dashed border, scaled by the border width |
| `size.pebble-xs` to `pebble-xl` | `AppSizes.pebbleXs` to `pebbleXl` (28, 36, 44, 56, 72): sides of `AppPebble` |
| `font.pebble-xs` to `pebble-xl`, `pebble-xs-pair` | `AppTypography.pebbleXs` to `pebbleXl` (600, 12, 14, 15, 20 Instrument Sans and 28 Bricolage; `pebbleXsPair` is 10 px, for two initials on the smallest pebble; line height equal to size, except 12 for the 15 px one so it clears the badges of a 44 px pebble): initials of `AppPebble` |
| `size.pebble-badge`, `pebble-badge-glyph`, `pebble-badge-offset` | `AppSizes.pebbleBadge*`: away and admin badges (20 box, 11 glyph), drawn from s44 up, and how far they hang outside |
| `size.border-dashed` | `AppSizes.borderDashed` (1.5): dashed outline of an invited pebble |
| `size.dot`, `dot-unread` | `AppSizes.dot` (8), `dotUnread` (10): `AppStatusDot` |
| `size.badge-count`, `badge-count-padding`, `badge-label-radius` | `AppSizes.badgeCount` (18, smallest side), `badgeCountPadding` (5), `badgeLabelRadius` (8): `AppBadge` |
| `font.badge-count`, `badge-label` | `AppTypography.badgeCount` (11, 600, 18 line), `badgeLabel` (12, 600, 16 line): text of `AppBadge` |
| `font.ring-label` | `AppTypography.ringLabel` (600, 15, line height equal to size): label in the middle of `AppProgressRing` |
| `size.ring`, `ring-stroke` | `AppSizes.ring` (56, grows with a large label), `ringStroke` (4): `AppProgressRing` |
| `progress.ring-sweep`, `ring-breathe` | `AppProgress.ringSweep` (0.3 of the circle, the arc of an in-use ring), `ringBreatheOpacity` (0.4, lowest opacity while it breathes) |
| `progress.freshness-*` | `AppProgress.freshnessFresh`, `Recent`, `Fading`, `Stale` (1, 0.85, 0.6, 0.25): how much of the freshness bar is filled. `maxAgeDays` (0, 2, 6) is the oldest age in calendar days of each tier |
| `size.freshness-bar` | `AppSizes.freshnessBar` (4): height of `AppFreshnessBar` |
| `size.row`, `row-tall` | `AppSizes.row` (64), `rowTall` (72), both grow with their text: least height of a list row, `MemberRow`, and of one with a bar under its texts, `TaskRow` |
| `size.beacon` | `AppSizes.beacon` (34): glyph tile or breathing ring of `ItemBeacon` |
| `size.border-room` | `AppSizes.borderRoom` (1.5): border of a `RoomTile`, solid or dashed |
| `size.ribbon` | `AppSizes.ribbon` (28, grows with its text): least height of an `EventRibbon` |
| `size.border-emphasis`, `focus-ring` | `AppSizes.borderEmphasis` (2, selected, focus and error borders), `focusRing` (4, primary-soft ring around a focused field) |
| `size.code-cell-width`, `code-cell-height` | `AppSizes.codeCellWidth` (56), `codeCellHeight` (60) |
| `state-layer.*` | `AppStateLayers`: ink opacity over a fill when pressed (primary 12%, surface 8%, danger 16%) and the spinner track (35%) |
| `decor.room-edge` | `AppDecor.roomEdge` (35%): glow ring of a home `RoomTile` and edge of an occupied one, a share of the presence-home or busy color. Decoration only, it carries no meaning |

### Component themes

`CompappTheme` styles the Material controls through component themes (`lib/src/theme/control_themes.dart`): `FilledButtonThemeData`, `OutlinedButtonThemeData`, `TextButtonThemeData`, `ChipThemeData`, `SwitchThemeData`, `InputDecorationThemeData` and `TextSelectionThemeData`. A raw Material widget looks right in the app, and atoms wrap those widgets with the Compapp API instead of redrawing them.

A component theme sets colors, shapes, sizes and text styles only. It must not remove feedback or change the layout of raw Material widgets (no transparent overlays, no `NoSplash`, no label padding or checkmark changes): atom-specific behavior goes in the atom's own widget-level style. A raw button gets Material's own pressed overlay on the token background. `AppButton` draws pressed as a fill (the ink layer blended over the base color) in its own style, so a `WidgetStatesController` holding `WidgetState.pressed` renders it without a gesture, which is how stories and goldens show it. Button heights are minimums, with vertical padding, so a button grows with a large label. Keyboard focus on buttons is a 2 px ink ring drawn outside the shape: Material buttons do not clip it, but a parent that clips (`ClipRect`, a scroll view without padding) will, so leave `AppSizes.borderEmphasis` of room around a button inside one.

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

## Catalog publishing

`.github/workflows/widgetbook-pages.yml` publishes the catalog to `https://6pi-devs.github.io/Compapp-design/` with GitHub Pages. It runs on pushes to `main` that touch `lib/`, `widgetbook/`, `fonts/`, the pubspec files or the workflow itself, and on demand (`gh workflow run widgetbook-pages.yml --ref main`).

- It fails closed: it only builds on `main`, and it waits for a successful `ci.yml` push run on the same commit before it deploys. A missing, cancelled or red run stops it.
- `widgetbook/web/index.html` must keep `<base href="$FLUTTER_BASE_HREF">`: the workflow sets the sub-path with `--base-href`.
- One-time repo setting: Settings, Pages, Build and deployment, Source: "GitHub Actions". Check it with `gh api repos/6Pi-Devs/Compapp-design/pages` (404 means Pages is not enabled yet).
- Deploys do not create tags or releases: the catalog always shows `main`.

## Releases

Releases are semver git tags `vX.Y.Z`, each with a GitHub Release. The tag is the only version: `pubspec.yaml` has no `version`, and there is no changelog. The app pins a tag in its `pubspec.yaml`:

```yaml
compapp_design:
  git:
    url: https://github.com/6Pi-Devs/Compapp-design.git
    ref: vX.Y.Z
```

The next version is computed from the non-merge commits (subjects and footers) since the highest `vX.Y.Z` tag merged into `main`, starting from `0.0.0` when there is no tag. Prerelease and malformed tags (`v0.2.0-rc1`, `v1.2`) are ignored. Only well-formed Conventional Commits count: `type(scope): description` with the colon directly after the type or scope and one space after it. `feat:x`, `feat : x` and `feat!(x):` count as plain patch commits.

| Commits since the last tag | Bump |
|----------------------------|------|
| Breaking change: a renamed or removed public token, widget or prop. Mark it with `!` in the subject (`feat(button)!: rename prop`). A `BREAKING CHANGE:` footer counts too, as long as only footer lines (`Key: value`, such as `Signed-off-by:`) follow it | major from `1.0.0`, minor while the version is `0.x` |
| Any `feat` | minor |
| Anything else (`fix`, `refactor`, `perf`, `docs`, `test`, `ci`, `chore`, `build`, `style`) | patch |

`tool/next_version.dart` implements the rule and `test/tool/next_version_test.dart` covers it. Preview the next version locally with `git fetch --tags && dart tool/next_version.dart`. It exits non-zero when there is nothing to release or when the computed tag already exists.

PRs are merged with merge commits, so two things use different sources:

- The version bump reads the commits inside the PR (merge commits are skipped).
- The GitHub release notes list the merged PR titles since the previous tag.

Give the PR a Conventional Commit title that carries the highest type among its commits (`feat` if any commit is a `feat`, and `!` if any is breaking), so the notes and the version agree.

To release, from `main`:

1. Wait for the CI run on the commit you are releasing to succeed. A later push cancels pending push runs, so if that run was cancelled, re-run it first. The workflow refuses to release a commit whose `ci.yml` push run is missing, running or not green, dry runs included.
2. Optionally preview the version: `gh workflow run release.yml --ref main -f dry_run=true`.
3. Run the Release workflow: `gh workflow run release.yml --ref main`, or the Actions tab, Release, Run workflow, branch `main`. It also fails when there are no commits since the last tag or when the computed tag already exists. The `main`-only check is advisory: a branch carries its own copy of `release.yml`, so it stops a mistaken dispatch, not a deliberate one.
4. The workflow tags the commit and creates the GitHub Release with generated notes.
5. In the app, bump the `ref` in its `pubspec.yaml`, run `flutter pub get`, and commit `pubspec.yaml` and `pubspec.lock`.

## Comments

Code explains itself through names. Keep comments rare.

- No commented-out code.
- No TODO without an issue reference (`// TODO(#123): ...`).
- Add a short `///` on a class only when its contract is not obvious from its name.

## Definition of Done

- [ ] Import rules respected, names follow [Naming](#naming)
- [ ] No `Color(0x...)` outside `lib/src/tokens/`, no magic numbers, no hardcoded strings
- [ ] `components.json` entry added or updated, manifest test green
- [ ] Use cases for every variant x state plus one `playground` with a knob for every prop, CI goldens committed, `widgetbook` analyze and test green
- [ ] Tokens changed in JSON and Dart together, parity test green
- [ ] Format check (as CI) clean and `flutter analyze --fatal-infos` reports 0 issues
- [ ] No generated files committed
- [ ] Conventional Commit messages and PR title (the release notes are built from PR titles)
