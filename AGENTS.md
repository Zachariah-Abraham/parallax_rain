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
  (Release automation from commit messages is planned, see `tasks.md`. Use the format now.)
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
| `example/` | Demo app (`example/lib/main.dart`, four rain variants in a 2x2 grid) that depends on the package through `path: ../`. Shown on pub.dev. |
| `example/screenshots/` | `1.PNG` and `1.gif`. `README.md` loads them by URL from `main`, including the READMEs of already published versions, so don't rename or delete them. |
| `doc/api/` | Old generated dartdoc output that is committed by mistake. pub.dev generates its own docs. Pending removal (see `tasks.md`). |
| `CHANGELOG.md` | Displayed on pub.dev. Update it for every user-visible change. Current format: `## x.y.z` followed by bullets. |

### How it works (as of 1.1.1)
- `ParallaxRainState.initState()` creates one `ParallaxRainPainter` and starts `runAnimation()`,
  an endless `async` loop that flips a `ValueNotifier` and awaits `Future.delayed(Duration())`.
  The painter repaints when the notifier changes (`super(repaint: notifier)`).
- The painter is created once, so later changes to the widget's parameters are ignored. This was
  intentional in 1.1.0 so that a parent's `setState` doesn't reset the rain. Keep that property
  (drops must not reset on rebuild) when changing this.
- `build()` returns `ClipRect > CustomPaint(painter or foregroundPainter) > Container > child`.
  The widget sizes itself to its child (1.0.2). Unbounded constraints (inside a `Row`/`Column`)
  must not stop the rain (1.0.4 fix).
- On the first `paint`, `initialize()` scatters `numberOfDrops` drops randomly over the canvas.
  Each drop gets a random layer `0..numberOfLayers-1` (0 = furthest back).
  With `effectiveLayer = layer * distanceBetweenLayers`, size and speed are scaled by
  `(1 + effectiveLayer)` and opacity is `(layer + 1) / numberOfLayers`. A drop that falls past the
  bottom respawns above the top with a new random x, layer, and color.
- `trail: true` paints each drop with a vertical `LinearGradient` from its color (at
  `trailStartFraction`) to transparent.
- Known problems are listed in `tasks.md`.

---

## 3. Tooling and commands

Flutter is managed with **FVM**. `flutter` and `dart` are shell aliases for `fvm flutter` and
`fvm dart`, but **no version is pinned** for this project and there's no global FVM version, so
`fvm flutter` (and the bare `flutter` alias) fail in non-interactive shells. Call the cached SDK
directly:

```bash
F=~/fvm/versions/stable/bin/flutter   # Flutter 3.47.x / Dart 3.13.x as of 2026-11-09
D=~/fvm/versions/stable/bin/dart

$F pub get                      # root package
$F analyze                      # root package (must be clean before committing)
$F test                         # root package tests
(cd example && $F pub get && $F analyze && $F test)
$D format lib test example/lib example/test
$F pub publish --dry-run        # validates the package; NEVER run without --dry-run unless the human asks
```

Other installed SDKs: `~/fvm/versions/3.29.0`. Install more with `fvm install <version>`.

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
  a new feature means a minor bump, and a fix means a patch. Bump `version` in `pubspec.yaml` and
  add a `CHANGELOG.md` entry in the same change (until release automation exists).
- New parameters must be optional and keep today's defaults, so existing users see identical
  rendering.
- Every public member gets a `///` dartdoc comment that describes it and its default.
- **SDK constraints: don't raise the minimum without a reason.** Raise it only when the code
  needs a newer API or language feature (for example `Color.withValues` needs Flutter 3.27,
  `ImageFilter.shader` needs Flutter 3.29), and then mention it in the changelog. Raising the
  minimum is not a breaking change: pub resolves users on older SDKs to the older release. The
  lower bounds must be honest, which means CI tests the minimum (see `tasks.md`). The Dart upper
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
- Respect reduced motion (`MediaQuery.disableAnimationsOf`) once supported.

### Testing
- Every behavior change needs **widget tests** in `test/` using `flutter_test`. Useful checks:
  builds with defaults; `rainIsInBackground` selects `painter` vs `foregroundPainter`; disposing
  the widget leaves no pending timers or tickers; works inside `Row`/`Column` (unbounded
  constraints); a parent `setState` doesn't reset the drops.
- Run `analyze` and `test` for **both** the root package and `example/` before committing.

### Example app
- `example/` is the package's showcase on pub.dev. Keep it minimal, idiomatic, warning-free, and
  in step with the current API.
- Platform folders are not committed, except `example/linux/` and `example/macos/` which are
  currently tracked (pending cleanup, see `tasks.md`). Don't add generated platform code unless the
  human asks.

---

## 5. Definition of done (per change)
1. `$F analyze` is clean in the root and in `example/`.
2. `$F test` passes in the root and in `example/`.
3. `dart format` is applied.
4. Public API changes have dartdoc, a `CHANGELOG.md` entry, and a `pubspec.yaml` version bump.
5. `README.md` is updated if usage changed.
6. `tasks.md` (and `AGENTS.md` if applicable) is updated and **everything is committed**.

---

## 6. Publishing to pub.dev

**Agents never publish.** Publishing is permanent: pub.dev generally doesn't allow unpublishing,
so only the human runs the real `flutter pub publish` (or pushes a release tag once automated
publishing exists). Agents prepare the release and run `--dry-run`.

- Releases are currently manual: bump `version:`, update `CHANGELOG.md`, run the dry run, and
  hand over to the human. Setting up release-please and OIDC publishing like `../glass` is a
  pending task.
- What gets uploaded: everything except hidden files and anything matched by `.gitignore` (or
  `.pubignore` if one is added, in which case pub ignores `.gitignore`, so keep them in sync).
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
