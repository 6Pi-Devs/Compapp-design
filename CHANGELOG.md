# Changelog

All notable changes are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/). Releases are git tags `vX.Y.Z`.

## [Unreleased]

### Fixed

- `CompappTheme` sets the icon theme color to ink, so icons no longer fall back to Material's black87 or white.

## [0.1.0] - 2026-11-04

### Added

- Package scaffold: analysis rules, CI, `components.json` manifest and its test.
- `tokens/compapp.tokens.json` (DTCG-style) and the hand-written Dart tokens `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppMotion`, `AppSizes` and `AppTypography`, with a parity test.
- Bundled Bricolage Grotesque (variable font, `opsz` set to the font size, `wght` driven by `fontWeight`) and Instrument Sans (static TTF), both OFL and `CompappDesign.registerLicenses()`.
- `CompappTheme.light` and `CompappTheme.dark`: Material 3 themes on an explicit `ColorScheme`.
- `context.appColors` extension.

[Unreleased]: https://github.com/6Pi-Devs/Compapp-design/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/6Pi-Devs/Compapp-design/releases/tag/v0.1.0
