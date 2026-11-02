# 0024 — Every worktree is claimed, declared, and removed once it holds nothing git cannot give back

- **Status:** accepted, 2026-10-26 (the owner: "please update and fix the hygiene rules in the playbook", after "keeping 100 worktrees, that's a bad hygiene maintenance that I fight against non stop"; then, on the first draft: "what if that lane dies and I have left-overs", "when task is done, commit and push and check if possible and declare if you are ready for merge to the orchestrator", "we should not remove a worktree that is paused ... or uncommitted or not ready", "merged branch should continue with worktree removal after validations ... and that it's really all merged"; and on adoption: "the orchestrator can take authority, check the dead lanes, inspect them and act by itself ... do that only if there are conflict that can't be resolved or things that are unclear, or major decisions to take"; on the pause schedule: "a grace time of X days before we remove the cache", "after X time, clear cache, quarantine and compress them, archive ... deletion will require my consent specially if there is code inside"; and "worktree with no essence, special code, or data, it's considered empty to me and can be removed"; and on where they live: "there should be one home for worktrees but nowadays I don't think it should be under the main repo, I think we should open <repo>_lanes/<worktree>").
- **Scope:** new rule 13.7; the header and rules 13.3, 13.4 and 13.5 (`rules/HYGIENE.md`); the section 13 trigger and summary (`rules/AUTHORITY.md`); the cleanup trigger in rule 10.2 (`rules/DESTRUCTIVE.md`); the hygiene checkpoint in rule 6.1 (`rules/WORKFLOW.md`); the section table in `CLAUDE.md`.

## Context

On 2026-10-25 the owner's largest project held 100 git worktrees. Every one of
them passed rule 13.3's three checks, or failed them only for build output, and
almost every tip was already on the remote. Nothing was at risk, yet most of
them were stale: 22 finished lanes whose branches were already merged into
their integration branch, 33 detached review snapshots in `/tmp`, and a dozen
lanes paused weeks earlier, each keeping a worktree and a build cache. The
owner had been asking, session after session, "list all worktrees, tell me
which are stale, why do we keep them". The free space on the disk was below the
floor, and two passes freed 19 GB.

Section 13 already said "the lane that creates a worktree owns it ... and
unlocks and removes it at close-out", in the middle of rule 13.3's removal
procedure. It failed for four reasons:

1. **The duty was read too late.** Section 13 loads only on a cleanup trigger,
   and its `paths:` scope matches `.worktrees/` inside the project. A lane that
   *creates* a worktree, usually as a sibling folder or a snapshot in `/tmp`,
   never matches the scope and has no trigger that sends it to the file.
2. **Nothing made the hand-back carry it.** A lane ends its turn by returning
   its close-out; nothing asked that close-out to account for the worktrees it
   made, so a coordinator had nothing to check.
3. **State was invisible.** A paused lane's worktree said nothing about who
   paused it or why, a finished lane never declared whether its work was ready
   to merge, and a lane whose branch was merged into an integration branch
   (not the default branch) was never called finished by anyone. A lane that
   died left its worktree with no one to account for it.
4. **The report had no inventory.** Rule 13.5's report listed removals and
   candidates, but not the worktrees themselves, so the owner's recurring
   question had no standard answer.

## Decision

New rule 13.7, **every worktree is claimed, declared, and removed once it holds
nothing git cannot give back**:

1. Every worktree lives in one home, `<repo>_lanes/<name>`, beside the
   repository: never inside it (searches, builds and editors would read other
   lanes' copies) and never in a temporary directory (the system may empty it,
   and review snapshots there carried evidence). One home makes one `ls` the
   start of every inventory; a stray worktree is moved with `git worktree
   move`.
2. The creator claims it at creation with `git worktree lock --reason`, as
   `key=value` pairs (owner, task, created, state; a pause adds since, until,
   why), and re-locks it when the state changes. The lock reason is the
   worktree's marker, and a script can read it.
3. When the task is done, the lane commits, pushes, runs its checks and
   declares to the coordinator *ready to merge* (branch, head, evidence) or
   *not ready* and why. It does not remove the worktree: a fix round may need
   it.
4. An **empty** worktree (HEAD on a pushed branch, only build output in the
   status, no stash, nothing running) may be removed by the coordinator at any
   time. A merged one is always removed, after an ancestry check against the
   line it was made for.
5. A paused or not-ready worktree stays while it holds work. The coordinator
   reports it every pass, removes its build output after a grace period (7
   days by default), and after a stale period (its `until=` date, or 30 days)
   archives it: work pushed to a `rescue/` branch, other non-build files
   quarantined compressed with a manifest. Then it is empty and goes. Deleting
   anything in neither git nor quarantine needs the owner's consent.
6. A worktree whose lane died is adopted by the coordinator, which takes the
   lane's authority: it commits and pushes any uncommitted work first, then
   removes, declares, pauses or finishes it as the lane would. Not merging is
   never deleting. The owner hears only of a conflict it cannot resolve,
   unclear provenance, or a decision outside the plan.
7. Every hygiene report lists all worktrees with their lock reasons and
   build-output size: running, ready to merge, paused or not ready, merged or
   empty, unclaimed or orphaned.
   `scripts/worktree-inventory.sh` produces it read-only and, with `--write`,
   keeps it as the status page `<repo>_lanes/README.md`; a coordinator runs it
   at the start of its session too. A rule sentence only works when an agent
   remembers it, and the sentence this replaces had already failed; a script
   gives the same answer every time.

Section 13's trigger now also names creating a worktree and pausing a lane, in
the file's header, in section 0's summary, in rule 10.2 and in the section
table. The header says the `paths:` scope cannot fire for a worktree outside
the project folder.

## Alternatives rejected

- **A `.hygiene.json` marker inside the worktree** (rule 13.4's existing
  marker). An untracked file in a worktree makes `git worktree remove` refuse,
  so the marker would block the removal it exists to enable. It was observed:
  five such markers sat untracked in paused lanes on 2026-10-25. The lock
  reason is git's own place for this, travels with `git worktree list
  --porcelain`, and needs no file.
- **A periodic sweep by a coordinator or a scheduled job.** It moves the cost to
  someone who did not create the worktree and cannot prove it is theirs (rule
  13.2), which is the failure we are fixing. The inventory in 13.5 still
  surfaces what a creator left behind.
- **A cap on the number of worktrees.** The owner wants parallel lanes; the
  defect is the leftover, not the count. A cap would throttle real work and
  still leave stale ones under the cap.
- **Removing a worktree at the lane's close-out, before the merge** (the first
  draft of this rule). The work is not merged yet, a fix round may need the
  same worktree, and the lane cannot prove its work landed. The owner moved
  removal to the merge.
- **Removing a paused lane's worktree at once** (also the first draft). A
  pause is the owner's decision to resume later, often for reasons outside the
  work, such as a budget, and the worktree may hold state the lane has not
  committed. It stays while it holds work; only its cost shrinks on a schedule,
  and nothing leaves it without being preserved first.
- **Keeping a paused worktree's build cache indefinitely.** On 2026-10-25 the
  caches, not the worktrees, were most of the lost disk (one paused lane's
  cache was 14 GB). A grace period keeps a quick resume cheap; after it, the
  toolchain rebuilds the cache.
- **Sweeping a dead lane's leftovers by age.** Age says nothing about whether
  the work is safe.
- **Listing every dead lane's worktree for the owner** (the second draft). The
  checks are mechanical and the decision is the lane's, so routing it to the
  owner only adds waiting. Preserving first (commit and push, never discard)
  is what makes it safe for the coordinator to act alone.

## Consequences

- A lane's close-out gains a declaration and one line; a merge gains a
  validation and a removal; a pause gains a re-lock and a handoff line, and
  later a cold build if the lane resumes after its grace period.
- The grace and stale periods are defaults the local layer may set.
- A `rescue/` branch is a push to the remote; it carries work the lane had not
  committed, and it is never deleted by this rule.
- A worktree with no lock is unclaimed by definition, so worktrees made before
  this rule show up as "unclaimed" in the first inventory and come to the owner
  once, with what removing each would lose.
- Another lane's lock still stops removal (rule 13.3). A stale lock is listed,
  never broken.
- Any local-layer Override bound to section 13 goes stale, because the section's
  digest changed; it is re-anchored at install, as designed.

## Review amendments (2026-11-02, before merge)

The owner asked for a review and a merge "if it's OK". Three problems and one gap were fixed on the
branch before merging:

- **Secrets.** Archiving a paused worktree and adopting a dead lane's committed and pushed "any
  uncommitted work", unasked. A stray file holding a token would have reached the remote, and this
  repository is public. Both now check for secrets first (rule 9.5) and quarantine anything that
  may hold one.
- **Rule 3.3 disagreed.** It still put a reviewer's snapshot "in its own scratch directory", which
  in Claude Code is under `/tmp` — the place rule 13.7 forbids, and the one the machine crash of
  2026-10-10 emptied. It now names `<repo>_lanes/review-<task>-<short sha>`.
- **Tool-managed worktrees.** Step 1 told the coordinator to move any worktree outside the home,
  which would break a dispatcher that records its own run checkouts' paths. Those stay where the
  tool put it, are listed, and are never moved or removed by anyone else.
- **Claiming in two steps** left a window in which a dying lane leaves an unclaimed worktree. The
  creation command now claims it: `git worktree add --lock --reason`.

