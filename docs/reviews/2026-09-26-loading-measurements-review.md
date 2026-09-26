# Loading measurements (0.1.18) — mechanical review, 2026-09-26

- **Target:** commit `37362c7` against `69bc58c`, read from git objects only.
- **Reviewer:** Standard tier (Claude Sonnet), read-only. Coordinator validated every finding against source.
- **Verdict:** **PASS**, no blocking findings.

## What was checked

- `rules/AUTHORITY.md` and `CLAUDE.md` state the same project boundary and the
  read-by-path duty; README, ARCHITECTURE and the visual map agree; nothing in
  `rules/` contradicts it.
- Report, ADR 0012 and the changelog agree on every number; the reviewer
  re-measured the suite counts at both commits (179 → 182, 53 → 57).
- ADR 0011 is untouched; ADR 0012 follows the house format.
- Each new assertion is paragraph-scoped, and each new mutation is caught by
  exactly the assertion it targets — including the header-relocation mutation,
  traced by hand.
- Version carriers read 0.1.18; the backlog item is closed with its answer.

## Findings — both minor, both validated, both fixed in the follow-up commit

1. The report called path scoping "deterministic" on two runs per case without
   saying why. It now states the reasoning — the harness matches the glob
   before the model sees anything — and that the runs confirm a boundary rather
   than estimate a rate.
2. "20/20 when named" counted invocation checks, not runs. The report and the
   changelog now show the arithmetic: 10 named runs, plus 5 buried runs needing
   both skills.

## Verification

Committed-tree `bash tests/run.sh` at `37362c7`, direct exit 0: 207, 93, 53,
182, 57, 267.
