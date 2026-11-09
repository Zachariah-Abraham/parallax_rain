# tasks.md

Current state and pending work only. **Keep it short and current:** update it as you work, so
another agent can continue if you're cut off. Delete finished items (git history and
`CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute dates. See
AGENTS.md §1.

_Last updated: 2026-11-09_

## Current state
- **parallax_rain 1.1.1** is the latest release. `pubspec.yaml`: `sdk: ">=2.12.0 <4.0.0"`,
  `flutter: ">=1.17.0"`.
- On Flutter 3.47.7, `flutter analyze` reports 2 issues: deprecated `withOpacity`
  (`lib/src/parallax_rain.dart`), and `example/analysis_options.yaml` includes
  `package:flutter_lints` without depending on it.
- `test/parallax_rain_test.dart` is entirely commented out. No CI.
- `AGENTS.md`, `tasks.md` and `CLAUDE.md` were added 2026-11-09 (not committed yet when written).

## Decisions
- **SDK minimum:** don't raise it unless code needs a newer API. Fixes should stay compatible
  with the current minimum (for example use `Color.withAlpha` instead of `withValues`, plain
  `Key? key` instead of `super.key`). A bump to Flutter 3.29 happens only if glass rain (below)
  ships.
- The 2.0.0 label is only needed if public classes (`ParallaxRainState`, `ParallaxRainPainter`,
  `Drop`) become private. Raising the SDK minimum alone is not breaking.

## Pending (rough priority order)

### 1. Bugs (patch release)
- [ ] `runAnimation()` is an endless loop that never stops: no `dispose()`. Every removed widget
      keeps animating. Replace it with a `Ticker` (`SingleTickerProviderStateMixin`) and dispose
      it and the `ValueNotifier`.
- [ ] Frame timing: `Future.delayed(Duration())` isn't vsync-based. Move drops by elapsed time
      (keep `dropFallSpeed` meaning "pixels per frame at 60 fps" so the defaults look the same).
- [ ] `ParallaxRain` re-declares `final Key? key`, shadowing `Widget.key`. Remove the field.
- [ ] Parameter changes are ignored after the first build. Add `didUpdateWidget` that updates
      the painter's settings without resetting drops (respawned drops pick up the new values).
- [ ] Drops aren't re-scattered when the size changes (rotation, window resize).
- [ ] `trail: true` creates a new `Paint` and gradient shader per drop per frame. Reuse it, or
      batch all drops into one `drawVertices` call (per-vertex colors give the trail gradient
      for free).
- [ ] Replace deprecated `withOpacity` without raising the minimum (for example `withAlpha`).
- [ ] Fix the `flutter: ">=1.17.0"` constraint: null safety (Dart 2.12) needs Flutter 2.0, so the
      honest lower bound is at least `>=2.0.0`.

### 2. Housekeeping
- [ ] Add `flutter_lints` (a version that resolves on the minimum SDK) and `analysis_options.yaml`.
      Add `flutter_lints` to `example/` dev deps too, or drop the include.
- [ ] Write widget tests (see AGENTS.md §4 "Testing").
- [ ] CI like `../glass/.github/workflows/ci.yml`: analyze and test on the minimum and on stable,
      format check, `pub publish --dry-run`. Open question: can Flutter 2.0.x still run on
      `ubuntu-latest`? If not, pick the oldest Flutter that CI can run and set the minimum to
      that (and note it in the changelog).
- [ ] Remove committed `doc/api/` and gitignore it. Remove tracked `example/macos/` and
      `example/linux/` (generated), or decide to keep them.
- [ ] Example: fix `example/pubspec.yaml` `sdk: <3.0.0`, replace the boilerplate
      `example/test/widget_test.dart`, use `const`.
- [ ] `pubspec.yaml`: add `repository`, `issue_tracker`, `topics`, `screenshots`; strip template
      comments.
- [ ] README: `flutter pub add parallax_rain` instead of `pub get`; list all parameters.
- [ ] Optional: release-please + OIDC publishing like `../glass` (needs human setup on pub.dev
      and a `RELEASE_PLEASE_TOKEN` secret).
- [ ] Decide whether to make `ParallaxRainState`, `ParallaxRainPainter`, `Drop` private (major).

### 3. Features (ideas, not committed to)
- [ ] Custom drop look: drop shapes (rounded, streak/line, circle) and/or a sprite `ui.Image`
      drawn with `drawRawAtlas`. A per-drop widget builder is too slow (hundreds of widgets per
      frame).
- [ ] Glass rain: drops that refract what's behind them. Needs `ImageFilter.shader` (Impeller,
      Flutter 3.29+), one full-area backdrop filter, not one per drop. Drop data via uniforms
      (check impellerc's uniform array limits) or computed procedurally in the shader from time.
      Fall back to plain translucent drops on Skia/web (`ImageFilter.isShaderFilterSupported`).
      Reuse what worked in `../glass` (`shaders/liquid_glass.frag`, `_LiquidBackdropLayer`).
- [ ] `paused`/`enabled`, child alignment (TODO in source), wind/angle, reduced motion.
