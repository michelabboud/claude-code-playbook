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
- **2026-09-14 · hygiene · open** — the version now has **four** carriers:
  `VERSION`, the line in `CLAUDE.md`, the README table, and the eyebrow in
  `docs/index.html`. They drift — the published map shipped one version behind at
  v0.1.7 and had to be caught by hand. A check comparing all four before a commit
  is the fix; not written yet. Source: v0.1.4, widened v0.1.7.
- **2026-09-14 · rule question · open** — `INSTALL.md` requires a verified backup
  before overwriting anything, and treats a failed backup as a refusal. Applying
  the v0.1.7 fix overwrote two *already-installed* files without one, on the
  reasoning that both were byte-identical to a published tag and so trivially
  recoverable. That reasoning was not written down and the guide grants no such
  exception. Either add one — "an update may skip the backup when every file it
  replaces is byte-identical to a published tag" — or the rule stands as written.
  Needs a ruling; source: the first real install.
