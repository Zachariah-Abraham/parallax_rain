# tasks.md

Current state and pending work only. **Keep it short and current:** update it as you work, so
another agent can continue if you're cut off. Delete finished items (git history and
`CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute dates. See
AGENTS.md §1.

_Last updated: 2026-11-10_

## Current state
- **parallax_rain 1.1.1** is the latest release on pub.dev. `main` has the housekeeping and perf
  work (PR #2) and the Flutter 2.0 test fix (PR #4), and CI on `main` passes.
- The `RELEASE_PLEASE_TOKEN` secret, the rulesets (AGENTS.md §3) and squash-only merges
  (AGENTS.md §1) are set up (2026-11-10).

## In progress: release 1.1.2 (PR #3)
1. [x] On branch `release-please--branches--main--components--parallax_rain`, `CHANGELOG.md`
       was fixed by hand:
       - Added a `# Changelog` title. Without it, release-please inserts new entries below the
         first `##` entry instead of at the top.
       - Moved 1.1.2 to the top.
       - Removed the duplicate line from the PR #2 merge commit `8ec7ec2`.
2. [ ] Human: merge PR #3 **before anything else lands on `main`**, because release-please would
       rebuild the branch and undo the fix. Merging tags `v1.1.2`, and `publish.yml` publishes
       to pub.dev.
3. [ ] Human: confirm automated publishing is enabled at
       https://pub.dev/packages/parallax_rain/admin (GitHub Actions, repo
       `Zachariah-Abraham/parallax_rain`, tag pattern `v{{version}}`). Not yet confirmed.
       Without it the publish job fails.
4. [ ] After the merge, check the `Publish to pub.dev` run and https://pub.dev/packages/parallax_rain.
5. [ ] `../glass/CHANGELOG.md` has the same ordering problem (2.4.0 is below 2.0.0+2) and glass
       still allows merge commits. Fix in the glass repo if the human wants.

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
