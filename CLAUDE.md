# CLAUDE.md

All project guidance for agents lives in AGENTS.md, so other agent tools can share it.
Current work status lives in tasks.md.

@AGENTS.md
@tasks.md

Key rules (details in AGENTS.md):
- Always commit your work in small, working increments.
- Keep `tasks.md` (and `AGENTS.md` when a durable fact changes) up to date **as you work**, not
  at the end. Assume you can be cut off or auto-compacted at any moment and another agent may
  take over, so the repo alone must show where you stopped and what's next.
- Flutter runs through FVM with no pinned version. Use `~/fvm/versions/stable/bin/flutter`
  (see AGENTS.md §3).
