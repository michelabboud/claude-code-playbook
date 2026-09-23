# 0006 — Refuse unaccounted recursively loaded rules

- **Status:** accepted, 2026-09-23 (owner-approved fail-closed compatibility repair).
- **Scope:** install, update, migration, uninstall, and restore preflight; no automatic removal.

## Context

Claude Code can load Markdown below `rules/` recursively. The local-layer check
formerly inspected only `LOCAL.md` and `LOCAL_dev.md`, so an extra Markdown file
could remain active without any compatibility verdict. A nested backup or an
unexpected symlink could also carry hidden instructions.

## Decision

Before a managed mutation, the checker enumerates the installed rules tree.
Only the two named local files and regular Markdown files present at the same
relative path in the staged managed rules tree are accounted for. Any other
Markdown file or symlink, or an enumeration failure, returns error status 2.
Migration and uninstall/restore invoke the same check before their first
mutation. They preserve the offending file and ask the owner to resolve it;
they never move or delete it themselves.

## Alternatives rejected

- **Check only the two named local files.** This leaves recursively loaded
  instructions outside the check.
- **Delete or move extras automatically.** Their ownership and recoverability
  are unknown; the preflight does not authorize a destructive cleanup.

## Consequences

An old installation with extra Markdown or symlinks cannot be updated until
the owner accounts for them. The refusal is deliberate and leaves files intact.
