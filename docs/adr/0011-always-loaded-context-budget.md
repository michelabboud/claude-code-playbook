# 0011 — Summarise only what is not already in context

- **Status:** accepted, 2026-09-26 (owner asked for the measured context findings to be fixed).
- **Scope:** `rules/AUTHORITY.md`'s "rules, by subject" section, `rules/QUARANTINE.md`'s loading, and the three rules that existed only as summaries.

## Context

A measurement on 2026-09-26 found the always-loaded rules at 75,696 bytes on a
live Linux installation (roughly 19,000–22,000 tokens, estimated at 3.5–4 bytes
per token; no token counter was available). Three costs were avoidable:

1. `AUTHORITY.md` carried a one-line-law table for every section, including the
   seven whose full file already loads every session (4, 5, 7, 9, 10.1–10.2, 11,
   12). For those, the summary is a second copy of text already in context —
   about 8.8 KB — and a second place for the law to drift.
2. The section 3 summary had grown to 4.4 KB: the review file condensed, not a
   one-line law.
3. `QUARANTINE.md` (7.9 KB) loaded every session although it is procedure needed
   only at the moment of a quarantine, and `DESTRUCTIVE.md`, which does load
   every session, already tells the agent to read it first.

Checking the summaries against their files found the drift already real: four
statements existed only in a summary — "asked once and I moved on = answered"
(7.2), "never fix during a review" (7.4), "never during a review" (5.1, already
covered by the classification table), and "only this machine's platform file is
installed; never carry a command across" (11.1, in no platform file).

## Decision

- `AUTHORITY.md` keeps short-form laws only for sections whose file may be
  absent from context: 1, 2, 3, 6, 8 (source-scoped) and 10.3 (quarantine). The
  always-loaded sections get one line naming their files, and nothing else.
- The section 3 summary is cut to one sentence per rule plus the instruction to
  read `REVIEWS.md` before any reviewer dispatch or batch decision.
- Every summary-only statement moves into its full file before its summary is
  removed, so no law is lost.
- `QUARANTINE.md` gains a `paths:` scope on `**/.quarantine/**`. `DESTRUCTIVE.md`
  (always loaded) keeps the principle — in doubt, quarantine — and states that
  the procedure file must be read by path before the first quarantine of a
  session. The glob is best effort; the read-by-path instruction is the
  mechanism relied upon.

## Alternatives rejected

- **Move `QUARANTINE.md` out of `rules/`.** Saves the same bytes but changes the
  managed inventory, the installer, the recursive-tree preflight and every
  existing installation's layout — a large change for no extra saving.
- **Drop the summaries entirely.** The five source-scoped sections are not in
  context during planning or in non-code sessions; their short form is the only
  copy the agent has then.
- **Fix only the local installation.** Every user of the playbook pays the same
  cost; the fix belongs upstream.

## Consequences

- About 18 KB leaves the always-loaded set (measured in the 0.1.17 close-out).
- A session that never opens the quarantine vault no longer carries the
  quarantine procedure; an agent that skips the read-by-path instruction would
  quarantine from `DESTRUCTIVE.md`'s principle alone. Whether the `paths:` glob
  auto-loads for a vault outside the project root is unverified (BACKLOG).
- `tests/rules_text_test.sh` gains a third file class — trigger-scoped — so the
  source-scoped invariants (hook 2, identical frontmatter) do not apply to it.
