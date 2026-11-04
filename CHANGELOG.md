# Changelog

All notable changes are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/). Releases are git tags `vX.Y.Z`.

## [Unreleased]

### Added

- Package scaffold: analysis rules, CI, `components.json` manifest and its test.
- `tokens/compapp.tokens.json` (DTCG-style) and the hand-written Dart tokens `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppMotion`, `AppSizes` and `AppTypography`, with a parity test.
- Bundled Bricolage Grotesque (variable font, `opsz` set to the font size, `wght` driven by `fontWeight`) and Instrument Sans (static TTF), both OFL and `CompappDesign.registerLicenses()`.
- `CompappTheme.light` and `CompappTheme.dark`: Material 3 themes on an explicit `ColorScheme`.
- `context.appColors` extension.
