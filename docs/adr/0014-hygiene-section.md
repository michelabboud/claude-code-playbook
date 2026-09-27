# 0014 — Hygiene is its own section, read by path

- **Status:** accepted, 2026-09-27 (the owner: "we should build a proper Hygiene rules", then "update the rules").
- **Scope:** new `rules/HYGIENE.md` (section 13); rule 10.2 and rule 6.2's checkpoint point at it; one free-disk row per platform file.

## Context

Two sessions on 2026-09-27 hit a refusal while cleaning up legitimate build
output and routed around it: `rm -r --` for a refused `rm -rf`, and
`find -delete` for a refused removal of the agent's own temporary files. 0.1.20
answered the second half — a refusal is a stop, not a spelling problem — and put
a worktree procedure in rule 10.2. The first half remained: nothing told an agent
how to decide what is safe to remove. Under disk pressure agents decide by name
(`tmp`, `old`) and by `.gitignore`, and neither says what an item holds. The
worktree paragraph had also grown into procedure inside an always-loaded law
file, which ADR 0011 set out to avoid.

## Decision

A new section 13, `rules/HYGIENE.md`, carries cleanup as procedure:

1. **Classify before removing** — six classes (regenerable and idle, created by
   this session, restorable by git, evidence, protected, unknown), each with one
   action. A name or a `.gitignore` entry never decides the class. Unknown is
   quarantined.
2. **Provably yours** — created by this session, locked by your lane, or marked
   for your task.
3. **Worktrees** — the 0.1.20 procedure moved here, with the re-review's fixes:
   reachability counts only `refs/heads refs/tags`, and a quarantined tracked
   file is restored so the removal can proceed.
4. **Cleanable at creation** — a `.hygiene.json` marker beside large or
   long-lived output (owner, task, created, disposable, regenerate).
5. **When and what it reports** — every close-out and phase end, before
   disk-heavy work, below a free-space floor (the local layer's value, 10 %
   otherwise); the report lists removed, kept, and the next candidates.
6. **A refusal ends the attempt** — rule 10.1 restated where cleanup happens.

The file is scoped to `**/.worktrees/**` and, like `QUARANTINE.md`, read by
path: the always-loaded `DESTRUCTIVE.md` keeps the law ("worktrees only through
git; deleting the folder or `--force` is destructive") and sends every cleanup
to section 13. The section adds no gate; every act it describes is still bound
by rules 10.1 and 10.2.

## Alternatives rejected

- **Keep growing rule 10.2.** The law file loads every session; a procedure a
  session may never use belongs behind a trigger (ADR 0011). 10.2 was already
  the longest rule in the file.
- **A skill instead of a rule file.** Measured on 2026-09-26: a skill is invoked
  2/5 times when its subject is only implied (ADR 0012), and cleanup is usually
  implied ("free some space"). The trigger line in the always-loaded file is the
  reliable route.
- **An age- or size-based sweep** ("remove build output older than N days").
  Age is not ownership; it would delete another lane's live worktree. The class
  and the proof of ownership decide, not the clock.
- **Trust any `.hygiene.json` marker as permission.** A marker is a file anyone
  can write; one you did not write is evidence, and rule 13.2 still applies.
- **A fixed disk floor in the playbook.** Machines differ by orders of
  magnitude; the local layer sets the floor and 10 % is only the fallback.

## Consequences

- The rulebook has fourteen sections and fifteen managed files; `INSTALL.md`'s
  staged-tree trust check expects 20 entries.
- Cleanup now needs one read by path before it starts. A session that never
  cleans up pays nothing.
- The marker convention only helps once agents write markers; until then, 13.1
  and 13.2 carry the load.
- Enforcement is still advisory. The phase-2 guards of the behaviour-suite plan
  are the deterministic complement; the plan's reserved ADR numbers move to
  0015–0019.
