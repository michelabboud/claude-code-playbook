# Architecture decision records

Decisions with real trade-offs, written at decision time (rule 4.2). An ADR is
never edited or deleted — it is superseded by a later one.

| # | Decision | Status |
|---|---|---|
| [0001](0001-development-runs-ahead-of-review.md) | Development runs ahead of review, to a ceiling of two batches counted by git ancestry; high deep reviews are gates; models are named in one file, `rules/ROSTER.md` | accepted 2026-09-20; amended by 0002 |
| [0002](0002-review-ahead-accounting-corrected.md) | The review-ahead accounting corrected after an independent review: the ceiling counts closed batches (worst case three ranges), a merge is a union, the coordinator keeps a ledger, every lower review is settled before a gate | accepted 2026-09-20; amended by 0003 |
| [0003](0003-ceiling-as-admission-rule.md) | The ceiling is one invariant — a line carries at most three unruled batches, the open one included — enforced at admission; fixes get a focused review before their batch is ruled; only closed work merges between lines; what the rule does not name is resolved toward review; rule 3.5 carries a normative table of worked cases; pending-versus-returned mechanical review; reachable-scope isolation; rules own assignments, the roster owns models | accepted 2026-09-20 |
| [0004](0004-the-local-layer.md) | Customizations live in a local layer the playbook never touches: `rules/LOCAL.md` and `rules/LOCAL_dev.md`, section 0 giving them precedence in a sentence, three kinds of entry (Fill · Add · Override), an Override quoting the dead words it replaces so staleness is mechanically checkable, templates outside `rules/`, and the git-email edit becoming a Fill | accepted 2026-09-21 |
| [0005](0005-verifiable-local-overrides.md) | A live Override binds to one unique Markdown section, its normalized SHA-256 digest, and a unique quote of at least 16 non-whitespace bytes; ambiguous or incomplete evidence refuses | accepted 2026-09-21 |
| [0006](0006-recursive-rules-preflight.md) | Refuse unaccounted Markdown and symlinks anywhere under recursively loaded rules before mutation; preserve files for an owner decision | accepted 2026-09-23 |
| [0007](0007-platform-rule-preservation.md) | Admit only the host platform rule, scan a symlinked rules root, and preserve non-managed platform contents on uninstall | accepted 2026-09-23 |
| [0008](0008-no-backup-uninstall-proves-content.md) | Prove each managed file is unchanged before no-backup uninstall; preserve edited bytes | accepted 2026-09-23 |
| [0009](0009-uninstall-preserves-current-installation.md) | Prove source and current content on both uninstall paths, refuse linked roots, and snapshot current destinations before mutation | accepted 2026-09-23 |
| [0010](0010-authenticate-playbook-checkouts-before-mutation.md) | Verify the canonical published commit or an owner-pinned fork before staged code or managed mutation; compare literal source bytes and refuse linked roots | accepted 2026-09-23 |
