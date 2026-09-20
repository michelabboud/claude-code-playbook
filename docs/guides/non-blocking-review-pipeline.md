# The non-blocking review pipeline — why it works, and how it fails

*The reasoning behind rules 3.3 and 3.5 in `rules/REVIEWS.md`. The rules are
self-contained; this guide is for the reader who asks "why is it done this way?"
and for anyone about to change a number. Written 2026-09-20.*

## The problem

Reviews are slow. Deep reviews are slow *and* expensive in tokens. If development
waits for each one, a project with a review after every task spends most of its
wall-clock time idle — and the pressure that creates is to review less, which is
the wrong fix. The right fix is to stop waiting, safely.

## The one idea

**A review is a function of a commit, not of a working tree.**

If the reviewer's input is a fixed commit, the working tree is free the instant
that commit exists, and review and development are two independent processes
that happen to run at the same time. If the reviewer's input is "the current
state of the repository", they are one process, and one of them must wait.

Everything in rule 3.3's mechanics follows from that sentence.

## The loop

1. Finish a unit of work and **commit it**. That commit is the review target and
   it never moves.
2. **Dispatch the reviewer against the commit.**
3. **Start the next task at once**, in the working tree. No waiting, no polling,
   no "are you done?" messages — the harness notifies on completion.
4. The reviewer returns findings, each **pinned to the commit** it was found on.
5. **Re-check every finding against the current tip** before acting: it may be
   fixed already, the code may have moved, or it may be moot. All three are
   useful answers.
6. Act on what survives. A blocking finding stops the line; the rest queue.

## The ways it fails silently

Each mechanic in rule 3.3 exists because skipping it produces a pipeline that
looks right and quietly is not.

**The reviewer reads the working tree.** It sees the half-written next task and
reports defects that do not exist in what it was asked to review — or reads a
file mid-write and reports garbage. Both waste a review and, worse, teach you to
distrust reviews. Hence *git objects only*. In the programme this guide draws
on, the committed tip almost never moved under a running review; the uncommitted
working tree moved constantly. This rule carried the load.

**The reviewer has to build, and builds in the shared tree.** Reading git
objects is enough for a reviewer that only reads. A mechanical review is defined
as *tests and lint actually run*, and a single file extracted from a commit does
not build a project. The general form is a **detached worktree of the reviewed
commit, in the reviewer's own scratch directory, with its own build-output
directory**. It costs disk and a cold build. Sharing the build directory with
the developing lane avoids that cost and replaces it with lock contention and
cross-contaminated artefacts, which is worse.

**Nobody defined "blocking".** Then every finding is negotiable under schedule
pressure, and "non-blocking review" decays into "ignored review". The brief
defines it, before the findings exist.

**The reviewer's output stays open in scratch.** Then the record is whatever the
file became later. Committing it the moment the findings are complete makes the
reviewed version the record — and makes "this review was blind" demonstrable
from the history rather than self-reported. The coordinator commits it, never
the reviewer, and stages that one path only: the working tree holds someone's
half-written task, and a broad `git add` would sweep it into the wrong commit.

**The dispatch is pipelined and the coordinator waits anyway.** The easiest
failure to commit, because the review feels important. It has the pipeline's
shape and none of its benefit.

### What validation does and does not buy

The coordinator re-derives each finding against the repository before acting on
it (rule 3.1). This is sometimes credited with making non-blocking review
*possible*. It does not: a coordinator that merely relayed findings could
pipeline just as well — it would simply act on false findings. Validation buys
**correctness**, not concurrency. What makes running ahead *safe* is the
stop-the-line rule, the three waits and the ceiling in rule 3.5.

## Why deep review gets a ceiling and mechanical review does not

The test is never what the review costs. It is what being wrong costs.

- A **mechanical** finding is local: a missed input check, a wrong comment.
  Fixing it three tasks later costs what fixing it now would. It never needs to
  hold development.
- A **deep** finding is structural: a concurrency model, a data path, an API
  shape. Its fix grows with everything built on top of it while the review ran.

So the trade is: gating costs the review's full latency on every batch,
guaranteed; running ahead costs the probability of a blocker multiplied by the
rework on what was built meanwhile. Blockers are rare and a deep review takes
about as long as one to three tasks, so running ahead wins — until the rework is
unbounded or the step cannot be undone. Those are the three waits.

### Why the ceiling is two, not one

A batch is 3–10 tasks and a deep review lasts about one to three tasks, so in
normal running batch N's review lands long before batch N+1 is finished. A
ceiling of one is therefore never reached in normal running. It is reached only
when the review lane is abnormally slow — an exhausted allowance, a dead lane, a
dual-blind pair held up on one side. With a ceiling of one, that outage halts
development too, which is exactly the stall the pipeline exists to remove. A
ceiling of two buys one more batch of room.

It costs two things. Worst-case rework doubles — the exposure is the ceiling
multiplied by the batch size, which is why the planner runs smaller batches
whenever two are outstanding. And batch N+1's deep review examines code built on
unreviewed batch N, so a blocker in N can make parts of that second review moot
after it has been paid for. Both are bounded, and both are cheaper than a halted
line. There is no third slot: three unreviewed batches is no longer a pipeline,
it is unreviewed development.

### Why the count follows ancestry

Counting per worktree is almost right and leaks in two places. A branch started
from unreviewed work is standing on that work, so it starts at one, not zero.
And two lines each carrying two unruled batches produce, when merged, a line
carrying four — so fan-out and merge-back would be a way around the ceiling.
Defining the count as *the unruled batches reachable from the tip* closes both
with no extra rule, and it is a question git already answers
(`git merge-base --is-ancestor <batch-tip> <line-tip>`).

### Why high deep reviews are gates

A deep review hunts for defects; the ceiling bounds what a defect can cost. A
high deep review also re-reads the plan against reality and may *revise the
plan*. Work done past a milestone risks being built against a plan that is about
to change, and no ceiling bounds that. At a release, the tag must sit on exactly
the commit that was reviewed, so nothing can be added on top while it runs.

Two consequences follow. A high deep review takes every batch review below it as
input, so all of them are ruled first — **the count drains to zero at every
milestone**, and unreviewed work never survives past one however the batches
went. And the wait is not idle: the queue of minor findings, the backlog, test
hardening and docs depend on nothing the review might change, and they are
exactly the work the pipeline has been deferring.

## Blindness is a convention, not a platform property

Two reviews of one commit can run concurrently, which is what makes dual-blind
review affordable: neither reviewer is on anyone's critical path. But in the
programme behind this guide, context crossed the blind boundary **in both
directions** between a coordinating session and an in-process subagent reviewer,
with neither side composing a read: after its findings were complete, the
reviewer found another reviewer's output and the coordinator's documents in its
context, while the coordinator had been receiving automated diagnostics naming
the reviewer's scratch files as it created them.

The likely mechanism is ordinary: a harness injects context — task
notifications, file-change notices, memory, editor diagnostics — at session
level, below the reach of any brief. **That explanation has not been tested**,
and the rule deliberately does not depend on it. The controls, in increasing
order of value:

1. **Enumerate excluded paths; do not describe them.** "Read nothing outside
   your scratch directory" is ambiguous about whose.
2. **No sibling reviewers and no programme material anywhere above a reviewer's
   directory.** Two sibling reviewers are one `ls ..` apart.
3. **A cold-read note written to disk before anything else is opened**, with
   only the findings in that note counted as independent corroboration. This one
   generalises: it costs nothing, it works whether or not the isolation leaks,
   and it turns "it was blind" from a claim into evidence. Anything the reviewer
   adds later is still a finding — an ordinary one.
4. **A separate process for the second reviewer.** Two in-process subagents of
   one session are not decorrelated at all. A model reached through another
   coding CLI is a separate process by construction — one more reason the
   roster's optional second-family column exists.

## What it costs

Findings arrive after you have moved on, so some need re-checking against a tip
that changed, and occasionally one is moot by the time it lands. That is
strictly cheaper than serialising. The cost that is easy to miss is disk and
build time for reviewers that must build, above.

## The evidence, and its limits

One programme, September 2026: a sixteen-task, behaviour-preserving refactor of
one large module, with sixteen mechanical reviews and four batch deep reviews,
two of them dual-blind across model families. In six of seven consecutive task
pairs examined, the mechanical review of task N was committed 9 to 24 minutes
after that task closed and before task N+1's commit existed. One batch deep
review landed four minutes *after* the next batch's first task was committed;
its one real finding was fixed while that task closed out. Nothing stalled and
nothing was reworked.

**That is the friendliest case there is.** The tasks were nearly independent and
"correct" meant "unchanged". It shows the mechanics work; it does not show that a
ceiling of two is right for feature work with heavy dependencies. That is why
rule 3's closing paragraph asks every close-out to record how often the ceiling
was reached — the number is a starting point with a measurement attached, not a
finding.
