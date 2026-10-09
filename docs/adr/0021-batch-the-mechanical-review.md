# 0021 — Batch the mechanical review; deep review per task only on the attack surface

- **Status:** accepted, 2026-10-09 (the owner: "we must update the intervals between code reviews, its making dev very slow … of course we must have code quality but we should batch more code at the same time"; "I approve, please do these changes to claude and codex playbooks").
- **Scope:** rules 3.1, 3.2 and 3.5's worked case 10; rule 14.2's table; section 0's summary; the front page's section table. ADR numbers 0016–0020 stay reserved for the behaviour-suite plan.

## Context

Development already ran ahead of review (ADR 0001), yet sessions were still slow. Two triggers
fired far more often than the ladder intended. First, a mechanical review ran after **every
task**. Development did not wait for its verdict, but each one still cost a brief, a detached
build of the commit, the coordinator's validation and a commit of the record. The rule's own
reasoning said mechanical findings are local and cost the same to fix three tasks later, which
argues against reviewing them one task at a time. Second, "risk overrides cadence" sent every
concurrency, data-safety and public-API task to a deep review at task grain. In a Rust registry
or any service with state, that is nearly every task, so batching never happened. The batch
size limit was "a few hundred changed lines", a figure taken from human review and never
measured for models.

A review's cost is mostly fixed (loading the code, building it, writing the brief, validating
the findings); the variable part is the lines read. Per-task review pays the fixed part every
time.

## Decision

1. **Per task, the automated checks are the gate:** tests, lint and type checks (rule 2.2). A
   task whose checks fail does not close.
2. **Mechanical review moves to the batch**, side by side with the deep review on the same
   pinned range, on the same tiers as before (Standard for mechanical, Strong for deep).
3. **A batch is 5–15 tasks or about 2,000 changed lines**, whichever comes first. The 2,000 is a
   starting value; the close-out's defects-per-review numbers move it. The brief lists the
   risk-class files first.
4. **Deep review per task only for the security floor and unsafe code.** Concurrency, public-API
   and other data-path tasks stay in the batch: the planner places them early and the brief names
   them. Rule 8.1's implementation tiering for them is unchanged.
5. **Dev modes follow:** poc, mvp and production batch both reviews; sensitive keeps smaller
   batches (3–6 tasks or about 1,000 lines) and per-task deep review on floor work.
6. **Unchanged:** stop-the-line on any blocker, the three-batch ceiling, milestone and release
   gates, the security floor, economy mode on the owner's word only.

## Alternatives rejected

- **Drop mechanical review entirely and rely on automated checks.** Mechanical review reads
  input handling, ignored return values and conformance to the brief, which tests miss.
- **Make milestone reviews non-blocking in production too.** A milestone review may revise the
  plan; work built past it may be redone. Held back until the batching above is measured.
- **Raise the three-batch ceiling.** Bigger batches recover the same time with less unreviewed
  code in flight; a ceiling reached often means the review lane needs fixing.
- **Keep per-task deep review for concurrency.** Correct in principle, but it turned "batch"
  into "per task" on the projects that matter; early placement in the batch and a named brief
  keep the closest read where it belongs.

## Consequences

- Up to 15 tasks of local defects can wait for one mechanical review. The rule's premise is that
  they cost the same to fix later; if batch reviews start finding defects that later tasks built
  on, the batch size comes down.
- A concurrency defect can now be built on for part of a batch before its deep review reads it.
  Early placement bounds that; a blocker still stops the line.
- The batch size and the 2,000-line figure are preferences until close-outs record tokens and
  defects per review.
