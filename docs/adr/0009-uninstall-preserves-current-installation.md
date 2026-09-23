# 0009 — Uninstall preserves the current installation first

- **Status:** accepted, 2026-09-23 (repair of GPT-6 Sol focused review).
- **Scope:** both backup restore and no-backup uninstall.
- **Extends:** ADR 0008's content proof from only no-backup deletion to every overwrite or deletion.

## Context

An old pre-install backup does not contain changes made to the currently
installed files afterward. Restoring it over managed filenames can therefore
lose owner edits just as no-backup deletion can. A symlinked configuration or
rules directory can also redirect exact-path deletion to an external tree.
Finally, file equality is meaningful only when the reference is a clean
checkout of the installed release, not a modified source tree.

## Decision

Before either uninstall path, refuse local files, unaccounted loaded Markdown,
symlinked configuration/rules roots, and any managed file that differs from a
trusted clean checkout of the installed tagged release. The executable guard
checks the checkout root, worktree cleanliness, tag at HEAD, recorded version,
and exact file bytes. A mismatch or unverifiable source stops the procedure.

Immediately before any overwrite or deletion, preserve and verify a new
snapshot of the **current** configuration at unique sibling paths. It is
separate from the old pre-install backup. Re-run the read-only guards after
the snapshot and check each target just before changing it; concurrent writers
make this manual procedure unsafe, so wait until they are quiescent.

## Trade-off

Uninstall may need owner-led reconciliation or a recovered exact release
checkout. That cost is preferable to silently losing current edits or writing
through an unexpected directory link.
