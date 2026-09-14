# Backlog

Dated one-liners for everything deferred or spotted and not done.

- **2026-09-14 · verification · open** — `rules/platform/LINUX.md` commands have
  not been executed on Linux. Source: generalisation task. Needs one pass on a
  real Linux box.
- **2026-09-14 · verification · open** — `rules/platform/WINDOWS.md` commands
  have not been executed on Windows, and the load measurement is CPU-percentage
  rather than a load average, which rule 8.1's concurrency formula assumes.
  Either verify an equivalent or restate the formula for Windows.
- **2026-09-14 · idea · open** — an install script (Unix shell + PowerShell)
  that backs up an existing `~/.claude/CLAUDE.md` before copying. Deliberately
  not written yet: it touches a file the user created, which rule 10.2 says to
  handle carefully, so it deserves its own small design rather than a
  convenience one-liner.
- **2026-09-14 · idea · open** — a short worked example showing one task running
  the full close-out chain end to end. The rules describe the chain; a new reader
  would benefit from seeing one.
