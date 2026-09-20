# 0001 — Development runs ahead of review, to a ceiling of two batches; models are named in one file

- **Status:** accepted, 2026-09-20
- **Rules it produced:** 3.1 (three kinds of review), 3.3 (pipelining mechanics), 3.5 (the ceiling), `rules/ROSTER.md`

## Context

Rule 3.3 already said "review batch N while batch N+1 builds", but gave no
mechanics, no limit, and no answer to the question that matters in practice:
mechanical reviews are slow and deep reviews are slow *and* expensive, and in
both cases development halts while it waits. The owner's requirement was that
development proceed faster without reviewing less.

Separately, model names were written into four files and the published page.
Models change several times a year, and each change meant hunting every mention.

## Decision

1. **Three kinds of review, defined by what they close:** mechanical (a task),
   deep (a batch, or a risk-class task), high deep (a milestone or a release).
2. **Mechanical review never holds development.**
3. **Deep review is pipelined, to a ceiling of two unruled batches under a
   line's tip.** One is the normal state; the second is announced loudly; a
   third never starts. The count follows git ancestry: a branch off unreviewed
   work inherits its count, a merge adds the counts, and a merge that would
   exceed the ceiling waits. Three waits hold at any depth: work that is
   expensive to undo, anything irreversible or outward-facing, and a blocker.
4. **High deep review is a gate.** The count drains to zero before one starts;
   the wait works the queue of minor findings.
5. **A review's input is a commit, never a working tree** — with the mechanics
   in rule 3.3.
6. **`rules/ROSTER.md` is the only file that names a model.** Rules name tiers
   (Top · Strong · Standard · Fast) and kinds of review. The roster carries a
   Claude default per tier and an optional second-family model for setups that
   can reach one. A **Strong** tier was added, because deep review had been
   running on the same tier as implementation and mechanical review.

## Alternatives rejected

- **Gate every deep review (the status quo in practice).** Safe and simple, and
  it charges the review's full latency on every batch whether or not anything is
  wrong. Rejected: blockers are rare, and the rework they cause is bounded by
  the ceiling and the three waits.
- **A ceiling of one.** In normal running it is never reached, because a deep
  review is shorter than a batch. It binds only when the review lane is
  abnormally slow — and then it converts a review outage into a development
  outage, which is the stall this decision exists to remove. Rejected for two.
- **No ceiling.** Unbounded exposure to the hidden couplings that deep reviews
  exist to find. Three unreviewed batches is not a pipeline. Rejected.
- **Counting per worktree.** Almost right; leaks when a branch starts from
  unreviewed work and when lines merge. Rejected for ancestry, which needs no
  extra rule and is answerable by git.
- **Pipelining high deep reviews too.** They may revise the plan, and a release
  tag must sit on the reviewed commit. No ceiling bounds building against a plan
  that is about to change. Rejected.
- **Defining the kinds by model** ("high deep is the Fable-class review").
  Goes stale at the next model release. Rejected for "what it closes".
- **Keeping model names inline and updating them by search.** That is the
  version-carrier drift this repository already suffers from, applied to a fact
  that changes more often than the version. Rejected for one file.

## Consequences

- The planner now owns the stall: it must place independent work after every
  batch boundary and risk-class tasks early in a batch. A plan in which batch
  N+1 depends wholly on batch N cannot be kept moving by any review rule.
- Reviewers that must build need their own detached worktree and build
  directory — a real disk and cold-build cost.
- Review capacity is shared across lines even though the counts are not; rule
  8.1's concurrency cap governs it.
- The ceiling of two rests on one friendly programme (a behaviour-preserving
  refactor). Every close-out records how often the ceiling was reached, so the
  number can be revised on evidence. See
  `docs/guides/non-blocking-review-pipeline.md`.
- The escalation ladder gained a step (Standard → Strong → Top). Whether
  risk-domain *implementation* should now start on the Strong tier rather than
  the Top is undecided and logged in `BACKLOG.md`.
- The README and the published page still display a copy of the roster for
  readers. They are display copies, marked as such, and they can drift — added
  to the existing version-carrier drift item in `BACKLOG.md`.
