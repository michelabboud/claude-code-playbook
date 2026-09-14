# Backlog

Dated one-liners for everything deferred or spotted and not done.

- **2026-09-14 · verification · open** — `rules/platform/LINUX.md` commands have
  not been executed on Linux. Source: generalisation task. Needs one pass on a
  real Linux box.
- **2026-09-14 · verification · open** — `rules/platform/WINDOWS.md` commands
  have not been executed on Windows. The load-average mismatch found during
  review is now handled in-file (CPU% / 100, never also divided by cores, with
  0.85 as the heavy band), but that arithmetic has not been checked against a
  real busy Windows machine.
- **2026-09-14 · idea · open** — an install script (Unix shell + PowerShell)
  that backs up an existing `~/.claude/CLAUDE.md` before copying. Deliberately
  not written yet: it touches a file the user created, which rule 10.2 says to
  handle carefully, so it deserves its own small design rather than a
  convenience one-liner.
- **2026-09-14 · idea · open** — a short worked example showing one task running
  the full close-out chain end to end. The rules describe the chain; a new reader
  would benefit from seeing one.
- **2026-09-14 · hygiene · open** — the version now has three carriers: `VERSION`,
  the line in `CLAUDE.md`, and the README table. They can drift. Source: v0.1.4.
  A pre-commit check comparing all three is the obvious fix; not written yet.
