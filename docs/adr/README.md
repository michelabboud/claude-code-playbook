# Architecture decision records

Decisions with real trade-offs, written at decision time (rule 4.2). An ADR is
never edited or deleted — it is superseded by a later one.

| # | Decision | Status |
|---|---|---|
| [0001](0001-development-runs-ahead-of-review.md) | Development runs ahead of review, to a ceiling of two batches counted by git ancestry; high deep reviews are gates; models are named in one file, `rules/ROSTER.md` | accepted 2026-09-20; amended by 0002 |
| [0002](0002-review-ahead-accounting-corrected.md) | The review-ahead accounting corrected after an independent review: the ceiling counts closed batches (worst case three ranges), a merge is a union, the coordinator keeps a ledger, every lower review is settled before a gate | accepted 2026-09-20; amended by 0003 |
| [0003](0003-ceiling-as-admission-rule.md) | The ceiling is one invariant — a line carries at most three unruled batches, the open one included — enforced at admission; fixes get a focused review before their batch is ruled; only closed work merges between lines; what the rule does not name is resolved toward review; rule 3.5 carries a normative table of worked cases; pending-versus-returned mechanical review; reachable-scope isolation; rules own assignments, the roster owns models | accepted 2026-09-20 |
