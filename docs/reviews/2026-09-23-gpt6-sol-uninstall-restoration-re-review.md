# GPT-6 Sol uninstall/restoration re-review — 2026-09-23

**Reviewed commit:** `03fcf9b` (base `ab05129`). **Verdict: FAIL.**
The current worktree repairs are not yet reviewed.

The read-only deep reviewer confirmed the new no-backup content guard refuses
ordinary owner edits against a clean source, but found three further safety
gaps. First, restore-from-backup did not run the content guard or preserve
current managed files, so post-install edits could be overwritten by old
backups. Second, a linked `~/.claude/rules` root passed both guards and could
redirect exact-path deletion to external files. Third, the helper's executable
checks accepted a modified source with matching owner edits and merely
required a `VERSION` file; the clean exact-release condition existed only in
prose. The mechanical reviewer also found that README's manual copy recipe
implied copying all three platform files.

The deep reviewer ran the focused pinned install-preflight suite: 120/120,
direct exit 0, plus syntax and diff checks at exit 0. Its redundant full-suite
run was stopped while other runs remained active; it has **no full-suite
verdict**. The mechanical reviewer independently reproduced the wrong-VERSION
source gap and ran the focused suite at 120/120, exit 0. No native macOS or
Windows uninstall or real user-file mutation was performed.

The new repair applies exact-content proof to both uninstall branches, checks
clean tagged source provenance, refuses linked configuration/rules roots, and
requires a fresh verified snapshot of current destinations before mutation.
Tests now cover linked roots/parents, wrong source VERSION, and a dirty source
mirroring an installed edit. A new pinned GPT-6 Sol re-review is required.
