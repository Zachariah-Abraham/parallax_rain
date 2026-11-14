# tasks.md

Current state and pending work only. **Keep it short and current:** update it as you work, so
another agent can continue if you're cut off. Delete finished items (git history and
`CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute dates. See
AGENTS.md §1.

_Last updated: 2026-11-15_

## Current state
- **parallax_rain 1.3.0** is the latest release on pub.dev (published 2026-11-14 through the
  automated release flow, AGENTS.md §6). The release pipeline works end to end.

## Decisions
- **SDK minimum:** don't raise it unless code needs a newer API. Fixes should stay compatible
  with the current minimum (for example use `Color.withAlpha` instead of `withValues`, plain
  `Key? key` instead of `super.key`).
- The 2.0.0 label is only needed if public classes (`ParallaxRainState`, `ParallaxRainPainter`,
  `Drop`) become private. Raising the SDK minimum alone is not breaking.
- Maintainer files (`AGENTS.md`, `CLAUDE.md`, `tasks.md`, `release-please-config.json`) are
  excluded from the published package via `.pubignore`.

## Decisions (features)
- The state/painter/`Drop` classes stay public (decided 2026-11-14). `runAnimation` stays deprecated.
- **Glass rain (refracting drops via `ImageFilter.shader`) was built and rejected on 2026-11-15**:
  the maintainer didn't like the look. Don't retry it. It would also have raised the SDK minimum to 3.29.

## Pending (in this order)
1. [ ] Drop shapes (rounded, streak/line, circle) and/or a sprite `ui.Image` drawn with
       `drawRawAtlas`. A per-drop widget builder is too slow (hundreds of widgets per frame).
2. [ ] Child alignment (TODO in source).
