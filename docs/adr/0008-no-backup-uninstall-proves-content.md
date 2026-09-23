# 0008 — A no-backup uninstall proves content before deletion

- **Status:** accepted, 2026-09-23 (repair of independent GPT-6 Sol review).
- **Scope:** uninstall when first installation made no backup.
- **Extends:** ADR 0007's exact-path deletion rule.

## Context

Deleting only named managed paths avoids removing unrelated files, but a user
can edit a named file after installation. The local-layer checker verifies
active Markdown path membership and Override compatibility, not ownership of
the bytes at a managed path. Without a prior backup, an exact-path deletion
could destroy those edits.

## Decision

Before a no-backup uninstall, compare every named managed file and the global
`CLAUDE.md` byte-for-byte with a trusted, clean checkout of the exact installed
release. Any missing file, symlink, mismatch, unknown platform, or unavailable
source refuses deletion. A passing local-layer check alone never authorizes
removing a file. A mismatch is preserved for the owner to reconcile; the
uninstall procedure does not silently copy, quarantine, or delete it.

## Trade-off

An old installation whose matching release checkout cannot be recovered may
need manual owner-guided preservation before uninstall. That is preferable to
guessing that a familiar filename contains only playbook text.
