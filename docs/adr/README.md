# Architecture decision records

Decisions with real trade-offs, written at decision time (rule 4.2). An ADR is
never edited or deleted — it is superseded by a later one.

| # | Decision | Status |
|---|---|---|
| [0001](0001-development-runs-ahead-of-review.md) | Development runs ahead of review, to a ceiling of two batches counted by git ancestry; high deep reviews are gates; models are named in one file, `rules/ROSTER.md` | accepted 2026-09-20; amended by 0002 |
| [0002](0002-review-ahead-accounting-corrected.md) | The review-ahead accounting corrected after an independent review: the ceiling counts closed batches (worst case three ranges), a merge is a union, the coordinator keeps a ledger, every lower review is settled before a gate | accepted 2026-09-20 |
