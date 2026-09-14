---
paths:
  - "**/*.{rs,py,ts,tsx,js,jsx,mjs,cjs,go,java,kt,swift,c,cc,cpp,h,hpp,cs,rb,php,sh,bash,sql}"
  - "**/Cargo.toml"
  - "**/package.json"
  - "**/pyproject.toml"
  - "**/go.mod"
  - "**/Dockerfile"
  - "**/Makefile"
  - "**/VERSION"
  - "**/CHANGELOG.md"
  - ".github/workflows/**"
---
# 3 · Code reviews — rules 3.1–3.4

*Read when a task lands, at a batch boundary, before a milestone or release, and before dispatching any reviewer. What a review may NOT do is in the classification table and rule 7.4 (read, report, never fix); this file is what a review MUST do, who does it, and when. The record is the persisted review with its CONFIRMED / REFUTED / UNVERIFIED header.*

**Why this shape:** a dual review after every task — one mechanical, one deep — is the right instinct, but on a big project it slows development dramatically. So: run the review without blocking development, in parallel, or batch it every 3 to 10 tasks depending on complexity, with the coordinator or the plan's author deciding. At the end, regardless of task count, run the best review available. Split the tiers so expensive reasoning is not spent on overkill. The cost of a review is mostly the reviewer reloading the codebase; batching pays that once. The cost of a *late* review is rework on everything built on top of the defect; dependencies, not counts, bound the batch.

## The roster

| Tier | Model | Runs |
|---|---|---|
| **Deep** | **Claude Fable** | Planning, design, architecture, milestone review, the release gate. Never down-tiered. |
| **Standard** | **Claude Sonnet** | Implementation, and **every mechanical review**. |
| **Fast** | **Claude Haiku** | Mechanical *work* that is not review — renames, formatting, single-file edits to spec, doc transforms. |

**Why mechanical review is Sonnet and not Haiku — measured, not assumed.** Both were given an identical mechanical-review brief over one file containing nine real defects. Haiku found five, with zero false positives; Sonnet found all nine, a strict superset. What Haiku missed was not exotic: a declared-but-never-enforced input limit, and a doc-says-X-code-does-Y mismatch — both squarely inside the classes the brief named. Haiku is precise but not thorough, and thoroughness is the entire job of the review that is supposed to be the safety net. It keeps mechanical work; it does not get mechanical review. Re-measure before changing this.

3.1 **Two kinds of review, two cadences — and a tier that climbs the ladder.** The planner plans in levels (WORKFLOW.md vocabulary) and each level closes with a stronger review than the one below it:

    | Level | What closes it | Review | Tier | Tag |
    |---|---|---|---|---|
    | **task** | one unit of work, rules 6.1–6.2 | mechanical | Sonnet; coordinator validates | `checkpoint/<VERSION>` |
    | **batch** | 3–10 tasks, boundaries in the plan | deep | Sonnet; coordinator validates, Fable on request | `gate/<VERSION>` on the tip presented |
    | **milestone** | something real shown working end to end | deep + plan conformance — the planner re-reads the plan against reality and revises it here | Fable, dual-blind | `gate/<VERSION>` |
    | **phase → release** | the phase's last task, rule 6.3 chain | the best review, rule 3.4 | Fable, dual-blind, fed every review below it | `v<VERSION>` — never before it passes |

    Levels collapse when the plan is small; the tier of the level that closes never drops.

    - **Mechanical** — tests and lint actually run, input handling, ignored return values, obvious defects, conformance to the brief. **Per task**, on Sonnet, **never blocks the next task**, findings validated by the **coordinator**, not the planner.
    - **Deep** — architecture, concurrency, security, data paths, whether the code still matches the approved plan. **Per batch** of 3–10 tasks by complexity; the **planner writes the batch boundaries into the plan** so nobody decides them under pressure. Sonnet during development; Fable at milestones and the release gate, validating those findings.

3.2 **A batch closes at whichever comes first:** (a) the next task would build on unreviewed work it cannot cheaply undo; (b) the diff has outgrown what one reviewer can hold — the human-review literature puts the cliff at a few hundred changed lines, and models dilute the same way, only later; (c) the planner's cap. **Risk overrides cadence:** security, concurrency, data safety, unsafe code, and public-API tasks get the deep review at task grain, always — the cadence rule never undoes rule 8.1's list.

3.3 **Pipelined, never fire-and-forget.** Review batch N while batch N+1 builds. Every finding pins the commit it was found on and is **re-checked against the current tip** before anyone acts on it. A blocker finding **stops the line** — no further dispatch on top of it until it is ruled. "Non-blocking" without the stop is building on known-bad foundations for a day.

3.4 **The release gate gets the best review, regardless of task count.** Fable, dual-blind, given the plan and every batch review as inputs, diving on the risk-class files rather than reading the whole diff cold. Every finding is validated against source before it reaches me. No `v*` tag before it passes (rule 6.3).

**Dual review, and why it must be decorrelated.** Two reviewers are worth more than one only if they can fail differently. Run them **blind to each other** — each assesses independently, and they compare afterwards. Where your harness offers more than one model family, put the second pass on a different one; two instances of the same model share the same blind spots, and agreeing with yourself is not corroboration. A review that corrects a review can itself be wrong, so disagreement between reviewers is a finding to verify and rule on, never to average.

**Mechanics that do not change:** a review is read-only (classification table); defects found are fixed in their own commit after the review or deferred loudly (rule 7.4); reviewer ≠ worker; reviewers assess independently before they compare.

**A note on dependent work.** If your coordinator gates a dependent task on an *accepted* prerequisite, and accepted means reviewed, that forbids batching a dependent chain. Either give the coordinator a provisional state — checks passed, review pending — or declare in the plan that a batch may span dependents. Until one of those exists, batching covers independent tasks only.

**Measured, not assumed:** record tokens per review and defects found per review in the close-out, so the 3–10 window gets a number behind it rather than a preference.
