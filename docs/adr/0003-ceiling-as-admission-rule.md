# 0003 — The ceiling is an admission rule, and the rule carries worked cases

- **Status:** accepted, 2026-09-20. **Amends ADR 0002** (decision 1); 0001 and 0002 are left as written.
- **Rules it changed:** 3.1, 3.3, 3.5 in `rules/REVIEWS.md`; the ownership boundary in `rules/ROSTER.md`.

## Context

ADR 0002 corrected rule 3.5 after an independent review of the Codex port *plan*. The finished
port was then given a deep review by another reviewer from the second model family — separate
process, pinned base and target, cold-read note first. Verdict: FAIL, six blocking findings, all
confirmed. Four were in this rulebook's text, ported faithfully; one of them was in the very
sentence ADR 0002 had just rewritten.

## Decision

1. **The ceiling is an admission rule:** a new batch starts only while at most two closed
   batches are unruled. 0002's "at most two closed, unruled batches… plus the one being built"
   let batch N+2 *close* with two still unruled — three closed, breaking its own invariant.
   Now: when N+2 closes there are three closed and unruled, all three reviews run, and nothing
   new starts until one is ruled. Worst case three batch ranges, unchanged. A merge waits when
   its union would exceed three.
2. **Rule 3.5 carries a normative table of worked cases**, and the table wins over the prose.
   Prose failed at this boundary twice in one day; keyword tests passed while it was wrong.
3. **"A pending mechanical review never delays the next reversible task; once any review
   returns a blocking finding, stop-the-line applies."** "Never blocks the next task" read as
   absolute and contradicted rules 3.3 and 3.5.
4. **Reviewer isolation is scoped to what the reviewer can reach:** a dedicated scratch
   directory whose parent holds only that reviewer's material, within the task-managed
   workspace; the review header records when the runtime cannot provide it. "Nothing anywhere
   above it" is unsatisfiable — every path has the filesystem root above it.
5. **Ownership boundary:** numbered rules own assignments (which tier does which work and which
   review); `ROSTER.md` owns which model is each tier, the optional second family, and the
   evidence. The roster's "trusted with" column and its kinds-of-review table are removed.

## Alternatives rejected

- **"N+2 may be built but may not close"** — the reviewer's repair. It preserves the words "two
  closed" by redefining "closed"; the code is unreviewed either way, and delaying the dispatch
  of a review is the opposite of the rule's purpose.
- **A strict ceiling of two including the batch being built** — rejected in ADR 0001 and 0002
  for the same reason: any slow review halts the line.
- **Another prose rewrite with no cases.** Two rewrites had already failed.

## Consequences

- The Codex edition's tests assert every row of the worked-cases table, not keywords.
- Three corrections to one rule in one day is the cost of publishing before an independent
  review rather than after. The rule now says a publish never runs ahead of its review; the
  Codex port obeyed that and was stopped before it shipped. This rulebook's own 0.1.13 and
  0.1.14 did not — they were pushed on the author's say-so. Recorded, not excused.
