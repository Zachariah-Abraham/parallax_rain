# tasks.md

Current state and pending work only. **Keep it short and current:** update it as you work, so
another agent can continue if you're cut off. Delete finished items (git history and
`CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute dates. See
AGENTS.md §1.

_Last updated: 2026-11-10_

## Current state
- **parallax_rain 1.1.2** is the latest release on pub.dev (published 2026-11-10 through the
  automated release flow, AGENTS.md §6). The release pipeline works end to end.

## Decisions
- **SDK minimum:** don't raise it unless code needs a newer API. Fixes should stay compatible
  with the current minimum (for example use `Color.withAlpha` instead of `withValues`, plain
  `Key? key` instead of `super.key`). A bump to Flutter 3.29 happens only if glass rain (below)
  ships.
- The 2.0.0 label is only needed if public classes (`ParallaxRainState`, `ParallaxRainPainter`,
  `Drop`) become private. Raising the SDK minimum alone is not breaking.
- Maintainer files (`AGENTS.md`, `CLAUDE.md`, `tasks.md`, `release-please-config.json`) are
  excluded from the published package via `.pubignore`.

## Pending (rough priority order)

### 1. Bugs
- [ ] Drops aren't re-scattered when the size changes (rotation, window resize).

### 2. Housekeeping
- [ ] Decide whether to make `ParallaxRainState`, `ParallaxRainPainter`, `Drop` private (major).
      If yes, also remove the deprecated `ParallaxRainState.runAnimation`.
- [ ] Optional: make the `ParallaxRain` constructor `const` (non-breaking, a `feat:`).

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
