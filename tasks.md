# tasks.md

Current state and pending work only. **Keep it short and current:** update it as you work, so
another agent can continue if you're cut off. Delete finished items (git history and
`CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute dates. See
AGENTS.md §1.

_Last updated: 2026-11-10_

## Current state
- **parallax_rain 1.1.1** is the latest release on pub.dev. `main` is at `dbe5c08` (1.1.1).
- Branch `chore/housekeeping-and-perf` (pushed, PR https://github.com/Zachariah-Abraham/parallax_rain/pull/2) holds the housekeeping
  and perf work, committed in Conventional Commits:
  - Ticker-based, time-based, paint-cached painter.
  - Widget tests and a cleaned-up example.
  - pubspec metadata and screenshots.
  - `.pubignore`.
  - CI, release-please and publish workflows.
  - README and AGENTS.md updates.

  Analyze and tests pass on Flutter 3.47.7 for the root and `example/`. `pub publish --dry-run`
  is clean apart from the git-state warning.

## In progress: get `chore/housekeeping-and-perf` merged
1. [ ] Wait for CI on PR #2. It is the only way to verify the Flutter `2.0.0` minimum (see
       AGENTS.md §3).
2. [ ] If the `2.0.0` CI job fails, check why:
       - If 2.0.0 itself can't run on `ubuntu-latest`, or the lockfiles won't resolve there, pick
         the oldest Flutter that works. Set `flutter:` (and `sdk:` if needed) in `pubspec.yaml`
         and the CI matrix to it, and mention it in the PR / commit body.
       - If it's only an old-analyzer lint difference, fix the code.
3. [ ] Human, one-time setup before the first automated release (started 2026-11-10):
       - Add the `RELEASE_PLEASE_TOKEN` repo secret. It needs a token value that only the human
         can create, for example a fine-grained PAT for this repo (glass has its own). Set it
         with `gh secret set RELEASE_PLEASE_TOKEN -R Zachariah-Abraham/parallax_rain`, which
         prompts for the value.
       - Enable automated publishing at https://pub.dev/packages/parallax_rain/admin (GitHub
         Actions, repo `Zachariah-Abraham/parallax_rain`, tag pattern `v{{version}}`).
       See AGENTS.md §6.
4. [ ] After the merge, release-please should open a release PR for **1.1.2** (the `fix:`
       commit). Check that its changelog reads well before the human merges it.

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
- [ ] Parameter changes are ignored after the first build. Add `didUpdateWidget` that updates
      the painter's settings without resetting drops (respawned drops pick up the new values).
      The painter's fields are `final` and public, so this needs care to stay non-breaking.
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
