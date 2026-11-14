# AGENTS.md

Guide for AI coding agents (and humans) working on this repository. Read this file and
[`tasks.md`](tasks.md) before starting any work.

---

## 1. Working agreement (read first)

### Treat all work as hand-off-able
Assume that **at any moment** your context may be auto-compacted, your session may be cut off
mid-task, or another agent may take over your work. The human auto-compacts often, so anything
that lives only in your context is likely to be lost. The human or the next agent must be able to
learn the current state from the repo alone. So:

1. **Update [`tasks.md`](tasks.md) as you work, not at the end.** Do it when you start a task,
   reach a milestone within one, finish one, find a new problem, make a decision, or change plans.
   If you were cut off right now, `tasks.md` should say exactly where you stopped and what to do
   next (branch name, files touched, what's verified, what isn't). It holds only the current
   state: what's in progress, pending work, blockers, and open questions. **Delete finished
   items** instead of keeping a history (git and `CHANGELOG.md` are the record), and move facts
   every future agent needs into this file.
2. **Update this file (`AGENTS.md`)** whenever you learn something every future agent needs: a
   new command, a tooling quirk, a convention, a design decision, or an architecture change. Keep
   it accurate. Delete stale information instead of piling notes on top of it.
3. Commit `tasks.md` and `AGENTS.md` updates **together with the work they describe** (or right
   after it), not at the end of the session.
4. Write notes for a reader with no context. Name files, functions, commands, and decisions
   explicitly. Avoid phrases like "as discussed" or "the earlier fix".
5. When you pick up work, trust `tasks.md` and `git log`/`git status` over your own memory or a
   summary. Check the branch and any uncommitted changes before you continue.

### Commit your work
- **Always commit your work.** Make small, focused commits as you go. Don't leave a large
  uncommitted diff, because uncommitted work is lost work when a session ends.
- Each commit should leave the repo in a working state: `flutter analyze` is clean and tests
  pass. If you have to commit something broken, say so in the commit message and in `tasks.md`.
- Use [Conventional Commits](https://www.conventionalcommits.org): `feat:` (minor), `fix:`
  (patch), `feat!:` or a `BREAKING CHANGE:` footer (major), and `docs:`, `chore:`, `ci:`, `test:`,
  `refactor:`, `perf:` (no release). Example: `fix: stop the animation loop on dispose`.
  release-please builds `CHANGELOG.md` and the version bump from these subjects (§6), so write
  `feat:`/`fix:` subjects for users: they appear verbatim in the changelog on pub.dev.
- **PRs are squash-merged** (the repo allows nothing else, set 2026-11-10). The squash commit's
  subject is the PR title and its body is blank, so **the PR title is the changelog entry**:
  give every PR a Conventional Commit title written for users. Commits inside the branch don't
  reach the changelog. (Merge commits were turned off because their body repeated the PR title,
  and release-please listed the fix twice.)
- Work on `main` only if the human asks you to. Otherwise use a feature branch. Never force-push,
  rewrite published history, or run `flutter pub publish` without explicit human approval.

---

## 2. Project overview

**`parallax_rain`** is a small, published Flutter **package** on
[pub.dev](https://pub.dev/packages/parallax_rain) (repo:
`github.com/Zachariah-Abraham/parallax_rain`, BSD-3-Clause). It paints an animated, layered
("parallax", pseudo-3D) rain effect behind or in front of a child widget:

```dart
import 'package:parallax_rain/parallax_rain.dart';

ParallaxRain(
  dropColors: [Colors.red, Colors.blue],
  trail: true,
  child: Text('Hello'),
);
```

This is a **library that other people depend on**, not an app. Public API stability, semver,
documentation, and the changelog matter more than they would in an app. The same author maintains
the [`glass`](https://pub.dev/packages/glass) package in `../glass`; its `AGENTS.md` is a useful
reference for conventions that already work (CI, release-please, shaders, golden tests).

### Layout

| Path | Purpose |
|---|---|
| `lib/parallax_rain.dart` | Public library entry point. Only exports `src/`. |
| `lib/src/parallax_rain.dart` | The whole implementation: `ParallaxRain` (widget), `ParallaxRainState`, `ParallaxRainPainter` (`CustomPainter`), `Drop` (model). |
| `test/parallax_rain_test.dart` | Widget tests (see §4 "Testing"). |
| `example/` | Demo app (`example/lib/main.dart`, four rain variants in a 2x2 grid) that depends on the package through `path: ../`. Shown on pub.dev. Has a smoke test. |
| `doc/screenshots/` | `rain.png` and `rain.webp` (animated), listed under `screenshots:` in `pubspec.yaml` and shown in `README.md`. pub.dev limits each screenshot to 4 MB; `rain.webp` (3.8 MB) was made from `example/screenshots/1.gif` with `gif2webp -lossy -q 50 -m 4`. |
| `example/screenshots/` | `1.PNG` and `1.gif`. READMEs of already published versions (1.1.1 and older) load them by URL from `main`, so don't rename or delete them. Excluded from the package by `.pubignore`. |
| `.pubignore` | Controls what gets published. Because it exists, pub ignores `.gitignore`, so it starts with a copy of `.gitignore`: **keep the two in sync**. It also excludes `example/screenshots/` and the maintainer files (`AGENTS.md`, `CLAUDE.md`, `tasks.md`, `release-please-config.json`). |
| `.github/workflows/` | `ci.yml`, `release-please.yml`, `publish.yml` (§3, §6). |
| `release-please-config.json`, `.release-please-manifest.json` | release-please setup (§6). The manifest holds the current version. |
| `CHANGELOG.md` | Displayed on pub.dev. Generated by release-please from Conventional Commits, so don't edit it by hand except to fix wording. Keep the `# Changelog` title on the first line: release-please inserts new entries right after it (without it, they land below the first entry). |

### How it works
- `ParallaxRainState` (`SingleTickerProviderStateMixin`) creates one `ParallaxRainPainter` in
  `initState()` and starts a `Ticker`. Each tick stores the elapsed time in the painter
  (`_elapsed`) and flips a `ValueNotifier`; the painter repaints on it (`super(repaint:
  notifier)`). `dispose()` disposes the ticker and the notifier. `runAnimation()` is deprecated
  (it only starts the ticker, which `initState()` already does). Remove it in the next major.
- When a painter setting changes (`didUpdateWidget`), the state creates a new painter that takes
  over the old one's drops (`ParallaxRainPainter._takeOver`). Drops keep their positions and get
  the new size, speed, layer (if out of range) and color (if no longer in `dropColors`); extra
  drops are removed and missing ones are scattered on the next paint. A parent `setState` with
  unchanged settings keeps the same painter. Drops must never reset on rebuild (1.1.0).
- The `ParallaxRain` constructor is `const`, so its asserts can only use constant expressions. The
  non-constant check (`dropColors.isNotEmpty`) lives in `ParallaxRainState._assertSettings()`.
- `build()` returns `ClipRect > CustomPaint(painter or foregroundPainter) > Container > child`.
  The widget sizes itself to its child (1.0.2). Unbounded constraints (inside a `Row`/`Column`)
  must not stop the rain (1.0.4 fix).
- On the first `paint`, `initialize()` scatters `numberOfDrops` drops randomly over the canvas
  (`_respawn(drop, size, top: ...)`). Each drop gets a random layer `0..numberOfLayers-1`
  (0 = furthest back). Size and speed are scaled by `1 + layer * distanceBetweenLayers`, and
  opacity is `(layer + 1) / numberOfLayers`. A drop that falls past the bottom is respawned just
  above the top with a new random x, layer, and color. When the canvas size changes, `_resize`
  scales each drop's position to the new size, so drops keep their relative place.
- Movement is time-based: `dropFallSpeed` is pixels per 60 fps frame (`_referenceFrame`), so each
  paint moves drops by `speed * elapsed / 16.667 ms`, clamped to `_maxFramesPerPaint` (6) so they
  don't jump after a pause. Without ticker time (painter used on its own), drops move one frame
  per paint.
- The `Ticker` runs only while `_shouldAnimate` (`dropFallSpeed != 0` and not reduced motion with
  `reducedMotion ?? device setting`). `_syncTicker()` starts/stops it from `didChangeDependencies` and
  `didUpdateWidget`, and sets the painter's `_frozen` so other repaints (resize) don't move drops.
  Reduced motion is read with `dependOnInheritedWidgetOfExactType<MediaQuery>()` because
  `MediaQuery.disableAnimationsOf` doesn't exist on Flutter 2.0 (the minimum).
- `angle` tilts the fall direction: each paint moves a drop by `distance * (sin, cos)` of the angle,
  and a tilted drop is drawn rotated by `-angle` around its center. `_respawn` starts drops above
  the top over a range widened by `height * tan(angle)` towards the side they come from, so the
  tilted rain still covers the whole canvas, and a drop that leaves through the side it falls
  towards is respawned too. At angle 0 nothing changes (same paths, same random draws).
- Paints are cached per (color, layer) in `_paints`. With `trail: true` the paint holds a vertical
  `LinearGradient` shader (drop color from the bottom up to `trailStartFraction`, then fading to
  transparent at the top), created in the drop's local coordinates. Each drop is drawn with
  `canvas.translate` to its position, so one shader serves every drop of that color and layer.
  Batching into `drawVertices` was considered and rejected, because it loses antialiasing and
  changes the look.
- Known problems are listed in `tasks.md`.

---

## 3. Tooling and commands

Flutter is managed with **FVM**. `flutter` and `dart` are shell aliases for `fvm flutter` and
`fvm dart`, but **no version is pinned** for this project and there's no global FVM version, so
`fvm flutter` (and the bare `flutter` alias) fail in non-interactive shells. Call the cached SDK
directly:

```bash
F=~/fvm/versions/stable/bin/flutter   # Flutter 3.47.x / Dart 3.13.x as of 2026-11-10 (CI uses 3.50.x)
D=~/fvm/versions/stable/bin/dart

$F pub get                      # root package
$F analyze                      # root package (must be clean before committing)
$F test                         # root package tests
(cd example && $F pub get && $F analyze && $F test)
$D format lib test example/lib example/test
$F pub publish --dry-run        # validates the package; NEVER run without --dry-run unless the human asks
```

Other installed SDKs: `~/fvm/versions/3.29.0` and `~/fvm/versions/3.50.0` (matches CI stable). Install more with `fvm install <version>`.
**Flutter 2.0.x (the minimum) can't run on this Mac.** Its Dart SDK is x64-only and Rosetta isn't
installed. The minimum is only tested in CI.

**CI** (`.github/workflows/ci.yml`, on pushes to `main` and on PRs) runs analyze and test for the
root and `example/` on Flutter `2.0.0` (the minimum in `pubspec.yaml`) and `stable`. On stable
only, it also runs the format check (`dart format --output=none --set-exit-if-changed lib test
example/lib example/test`) and `flutter pub publish --dry-run`. A separate job builds the example
for web. If you raise the minimum, update the matrix too. `flutter_lints` is pinned to `^1.0.4`,
the newest version that resolves on Dart 2.12.

**Branch protection:** the repository ruleset "Protect main" (id `26963718`) blocks force-pushes
and deletion of `main`, and requires the CI checks `Analyze and test (Flutter 2.0.0)`,
`Analyze and test (Flutter stable)` and `Build example (web)` to pass before a PR merges. Repo
admins can bypass it. The required names are the CI job names, so if you rename a job or change
the matrix (for example a new minimum), update the ruleset in the same PR (`gh api
repos/Zachariah-Abraham/parallax_rain/rulesets/26963718`), or every PR stays blocked.

**Tooling side effects:** `pub get` and `analyze` on a newer SDK rewrite `pubspec.lock` and
`example/pubspec.lock`, and may add excludes to `example/analysis_options.yaml`. Don't commit
those incidental changes as part of unrelated work. Either revert them
(`git checkout -- <file>`) or commit them on purpose in their own commit.

---

## 4. Flutter / Dart best practices for this repo

### Package and API design
- Keep the public surface small. Export only from `lib/parallax_rain.dart`. Implementation lives
  in `lib/src/`, and other packages must never need to import `src/`.
- Follow [semver](https://dart.dev/tools/pub/versioning): a breaking change means a major bump,
  a new feature means a minor bump, and a fix means a patch. Don't bump `version` or edit
  `CHANGELOG.md` by hand; release-please does both from the commit types (§6).
- New parameters must be optional and keep today's defaults, so existing users see identical
  rendering.
- Every public member gets a `///` dartdoc comment that describes it and its default.
- **SDK constraints: don't raise the minimum without a reason.** Raise it only when the code
  needs a newer API or language feature (for example `Color.withValues` needs Flutter 3.27,
  `ImageFilter.shader` needs Flutter 3.29), and then mention it in the changelog. Raising the
  minimum is not a breaking change: pub resolves users on older SDKs to the older release. The
  lower bounds must be honest, which means CI tests the minimum (§3). The Dart upper
  bound `<4.0.0` is already the highest allowed. pub ignores upper bounds on `flutter:`.
- Before release, aim for a high pub.dev score: `$F pub publish --dry-run` with no warnings, an
  example present, documented API, and up-to-date dependencies.

### Dart style
- Follow [Effective Dart](https://dart.dev/effective-dart). Format with `dart format` (default
  page width).
- Lint with `flutter_lints`. Fix analyzer warnings instead of suppressing them. If an
  `// ignore:` is truly necessary, add a reason next to it.
- Use sound null safety. Avoid `!` unless an invariant guarantees the value.
- Don't use the `new` keyword. Prefer `final` for locals that aren't reassigned and `const`
  constructors and literals wherever possible.
- Replace deprecated APIs instead of ignoring them, within what the minimum SDK allows.
- Use `lowerCamelCase` for members, `UpperCamelCase` for types, and `snake_case.dart` for files.

### Animation and painting performance
- This widget repaints every frame, so `paint()` is a hot path. Don't allocate per drop per frame
  (no new `Paint`, `Shader`, `Rect` lists, or closures in the loop if avoidable). Batch drawing
  (`drawVertices`, `drawRawAtlas`) beats hundreds of separate draw calls.
- Drive animation from a `Ticker` (vsync), never from an endless `Future` loop. Stop it in
  `dispose()`. Scale movement by elapsed time so speed doesn't depend on the refresh rate.
- Don't rebuild the widget tree each frame. Repaint the painter only (`CustomPainter(repaint:)`).
- Avoid `saveLayer` and per-drop `BackdropFilter`s. A backdrop-sampling effect (glass rain) must
  be one filter for the whole area.

### Accessibility
- The rain is decorative and must not change the child's semantics or hit testing.
- Reduced motion is supported through `reducedMotion` (`bool?`, default `null` = follow the
  device). This is a deliberate exception to the "keep today's defaults" rule in §4, because it
  only changes rendering for users who turned on reduce-motion. The device decides the default,
  the dev can override it either way.

### Testing
- Every behavior change needs **widget tests** in `test/` using `flutter_test`. Useful checks:
  builds with defaults; `rainIsInBackground` selects `painter` vs `foregroundPainter`; disposing
  the widget leaves no pending timers or tickers; works inside `Row`/`Column` (unbounded
  constraints); a parent `setState` doesn't reset the drops.
- Run `analyze` and `test` for **both** the root package and `example/` before committing.

### Example app
- `example/` is the package's showcase on pub.dev. Keep it minimal, idiomatic, warning-free, and
  in step with the current API.
- Platform folders are not committed and are gitignored. Generate one locally to run the app
  (`flutter create --platforms=macos .` in `example/`). Don't commit generated platform code
  unless the human asks.
- The example widget test only uses `pump`, never `pumpAndSettle`: the rain animates forever, so
  `pumpAndSettle` times out.

---

## 5. Definition of done (per change)
1. `$F analyze` is clean in the root and in `example/`.
2. `$F test` passes in the root and in `example/`.
3. `dart format` is applied.
4. Public API changes have dartdoc and a Conventional Commit subject that describes them for
   users (release-please writes the changelog entry and the version bump).
5. `README.md` is updated if usage changed.
6. `tasks.md` (and `AGENTS.md` if applicable) is updated and **everything is committed**.

---

## 6. Publishing to pub.dev

**Agents never publish.** Publishing is permanent: pub.dev generally doesn't allow unpublishing.
Agents never run the real `flutter pub publish`, never push `v*` tags, and never merge the
release PR. Only the human does those. Agents can run `--dry-run`.

Releases are automated like `../glass`:
1. Conventional Commits land on `main` (via PRs).
2. `.github/workflows/release-please.yml` opens or updates a release PR that bumps `version:` in
   `pubspec.yaml`, `.release-please-manifest.json`, and `CHANGELOG.md`. `bootstrap-sha` in
   `release-please-config.json` is the 1.1.1 commit (`dbe5c08`), so only later commits count.
3. When the human merges that PR, release-please tags `vX.Y.Z`, and
   `.github/workflows/publish.yml` publishes to pub.dev through OIDC
   (`dart-lang/setup-dart/.github/workflows/publish.yml@v1`).

This needs one-time human setup (status in `tasks.md`): the `RELEASE_PLEASE_TOKEN` repo secret (a
PAT with contents, pull-requests and issues write; the default `GITHUB_TOKEN` can't trigger
`publish.yml`), and automated publishing enabled at
https://pub.dev/packages/parallax_rain/admin for this repo with tag pattern `v{{version}}`.

- What gets uploaded: everything except hidden files and anything matched by `.pubignore` (see
  the Layout table). Check the file list in the `--dry-run` output after changing it.
- Only hosted pub.dev and SDK dependencies are allowed in the published package. The `example/`
  app may use `path: ../`.
- pub.dev generates API docs from `///` comments. Don't commit `dart doc` output.
- Mistakes after publishing: versions can't be deleted. Publish a fixed patch. Retract (pub.dev
  Admin tab) only within 7 days and only for truly broken versions.
- Links: [publishing](https://dart.dev/tools/pub/publishing),
  [versioning](https://dart.dev/tools/pub/versioning),
  [pubspec](https://dart.dev/tools/pub/pubspec),
  [scoring](https://pub.dev/help/scoring),
  [automated publishing](https://dart.dev/tools/pub/automated-publishing).
