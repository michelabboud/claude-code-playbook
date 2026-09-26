# 0013 — Economy mode for code review

- **Status:** accepted, 2026-09-26 (the owner specified it: "in economy mode, use opus5.5-xhigh instead of fable, use gpt-6-sol-xhigh instead of Astra").
- **Scope:** the Top tier's code-review seats (rule 3.1, rule 3.4, `ROSTER.md`). Planning and design are untouched.

## Context

High deep reviews — every milestone and every release — run on the Top tier,
dual-blind: Claude Fable and GPT-6 Astra. They are the most expensive reviews in
the rulebook, and until now "the tier never drops" had no exception.

## Decision

An owner-switched **economy mode** seats the Top tier's review seats on Claude
Opus 5.5 at `xhigh` effort and GPT-6 Sol at `xhigh` effort. The rule (in
`REVIEWS.md`) names no model; the roster does. It is on the owner's word only —
the agent never enables it to save cost — it covers code review only, it keeps
the pair dual-blind and cross-family, and every review it runs records
*economy mode* in its header, the release gate included.

## Alternatives rejected

- **Let the agent choose economy when budget is tight.** Turns a gate's
  strength into a silent runtime variable; the owner decides what a gate is
  worth.
- **Economy for milestones only, never for a release.** Stricter, and it was
  the author's recommendation, but the owner's specification covers every
  high deep review; the release record's *economy mode* line keeps the
  difference visible instead.
- **One reviewer instead of a pair.** Saves more but loses decorrelation — the
  reason a gate is dual-blind at all.

## Consequences

- In economy mode a gate is reviewed by the same model families, at higher
  effort, that run deep reviews. Its extra strength over a deep review comes
  from effort, fresh sessions and the plan-conformance pass, not from a
  stronger model. The header line makes that visible after the fact.
- The Top tier still owns planning, design, and validation outside code review.
