# 0007 — Preserve platform contents and admit only the host rule

- **Status:** accepted, 2026-09-23 (repair of independent review findings).
- **Scope:** recursive rules preflight and no-backup uninstall.
- **Supersedes:** ADR 0006's implication that every staged platform rule is allowed in one installation.

## Context

The staged bundle has three platform Markdown files, but an installation must
have exactly the one for its host. A membership-only preflight allowed an
installed wrong-OS file to remain active. The no-backup uninstall wording also
said to delete the platform directory, which could erase a user's non-Markdown
file that the recursive rule scan intentionally does not classify.

## Decision

The preflight follows a symlink when it is the rules-directory root, and
admits only the installed platform Markdown file for the detected host OS.
Unknown platforms refuse rather than guessing. Other unexpected Markdown and
symlinks still refuse as ADR 0006 requires.

No-backup uninstall deletes only exact managed files. It attempts `rmdir` on
the platform directory after the managed platform file is removed; any
remaining content is preserved and reported. It never recursively deletes
the platform or rules directories.

## Trade-off

An installation moved across OS families must be corrected before update,
and a directory with stray content remains after uninstall. Both are visible
maintenance work, preferable to loading contradictory rules or losing data.
