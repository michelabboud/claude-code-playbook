# Handoff — hygiene, back-to-back tasks, and two installs

**Date:** 2026-09-29
**Repos touched:** `~/projects/claude-code-playbook` (published, `checkpoint/0.1.22`),
`~/projects/codex-playbook` (published, `checkpoint/0.1.7`), `~/.claude` (local,
no remote), `~/.codex` (not a git repo).

## Where things stand

**claude-code-playbook** — `main` = `origin/main` = `bafad2d`, tag
`checkpoint/0.1.22` on the same commit, both pushed. Working tree clean except
one untracked file: `docs/plans/2026-09-26-behaviour-suite-plan.md` (Fable's
plan for the behaviour-suite eval harness — 30 scenarios, blind judges, a load
log, a baseline; approved in scope 2026-09-26, **size not chosen** — small
recommended, about $40–60, vs. lean ~$300 or full ~$500 as written). All six
test suites pass on the tagged commit (207, 93, 53, 275, 129, 267; exit 0).

**codex-playbook** — `main` = `origin/main` = `fa37a28`, tag `checkpoint/0.1.7`
on the same commit, both pushed. Working tree clean. `scripts/verify.sh`
passes (122 rulebook, 217 local-layer, 689 installer checks).

**~/.claude** (owner's live installation, its own git repo, no remote) —
`HEAD` = `e9812e1`. Two commits made this session:
- `bf9b445` — installed 0.1.22 file by file (was 0.1.15, migrated), folded
  `rules/MAI.md` into `LOCAL.md` as rule M.1, dropped the `unsafe`-code review
  exception (a local layer may not relax a protection), added the 3 % disk
  floor (rule 13.5) to `LOCAL.md`.
- `e9812e1` — `skills/ari-dual-review/SKILL.md` renamed to `gpt-6-sol`/`gpt-6-luna`.

Left **uncommitted on purpose**: `skills/fabridge/SKILL.md` (a 241-line rewrite
from another session — not mine to commit) and one untracked backup file,
`skills/ari-dual-review/SKILL.md.bak-2026-09-26`.

**~/.codex** — not a git repo, so no history. `playbook-local.md` installed
this session (owner's first Codex local layer): Mai boundary as rule M.1 word
for word, git identity, Task Orc bindings, the model roster binding, quarantine
+ `qshelf`, owner channels, and the 3 % disk floor. Checked 3/3 against
`checkpoint/0.1.7`. `AGENTS.md` and all 17 skills installed, byte-identical to
the tag. Recovery checkpoint:
`~/.codex/backups/codex-playbook-preinstall-20260928T141644Z-0MXwrI`.

**Disk:** `/dev/sdf` (root) is at ~94 % used, ~61 GB free of 1007 GB (3 %
free floor now applies in both edition's local layers, changed from 10 % on
the owner's word 2026-09-29). Large items identified but **not touched**
(none provably mine): `~/.codex/.tmp/marketplaces` (79 GB), `~/.cache/mai-build`
(64 GB, Mai's — never inspected), old `/tmp` folders >2 days (34 GB across
~7,352 dirs), `~/.codex/sessions` (21 GB, session history — keep).

## What was done this session (chronological)

1. **0.1.21, Hygiene (section 13)** — new `rules/HYGIENE.md` / `codex-playbook-hygiene`
   skill: classify before removing (six classes, most-protective-wins on
   overlap), remove only what's provably yours, worktrees through git after
   three checks, a `.hygiene.json` creation-time marker, a disk floor with a
   fixed report shape, refusal ends the attempt. Two Opus deep reviews (first
   FAIL — three blockers: session-created items could override protected/evidence,
   a marker was ownership proof on its own, branch-deletion check was circular;
   fixed and re-reviewed PASS).
2. **0.1.22** — every platform file gained a "process using a directory" step
   (the hygiene idle-check pointed at a command that didn't exist). Found by
   the Codex port's review, ported back to Claude same day.
3. **Codex port (0.1.7)** — ported source 0.1.19–0.1.21 into the Codex edition:
   new `codex-playbook-hygiene` skill, refusal rule adapted for Codex's sandbox/
   escalation model (one escalated retry of the *same, unchanged* refused
   command is allowed — it's how Codex asks for approval — never under the
   `never` policy, never after a decline), economy mode, free-disk rows. **Four**
   Opus deep reviews before it passed: (1) wrongly passed — reviewer hadn't run
   `scripts/verify.sh`; (2) FAIL — three version carriers still said 0.1.6;
   (3) FAIL — new "tasks run back to back" wording (below) had an incomplete
   stop list and would let worker lanes admit their own next task; (4) PASS.
4. **Rule 7.1: tasks run back to back** (owner's word, both editions) — every
   plan states in its header that the next approved task starts immediately
   when a close-out (hygiene included) finishes, addressed to *whoever runs
   the plan* (coordinator or solo session) — a lane still ends its turn by
   returning its close-out and never admits work itself (rule 3.5: one
   coordinator admits). The stop list is closed and now names every gate
   either rulebook keeps: high deep review, rule 3.5's ceiling + waits, a
   review's blocking finding (stop-the-line), a real blocker (`ESCALATE:`), a
   direction change or plan gap, an uncovered approval, a release blocked by
   an unfixable advisory (rule 6.3), or the owner's word.
5. Both editions installed on this machine (details above); Codex got its
   first local layer.
6. Owner set the hygiene disk floor to **3 %** in both local layers (was 10 %,
   the playbook default; the published default is unchanged — see Backlog).

## Next steps, in order

1. **Choose the behaviour-suite plan's size** — small (recommended) / lean /
   full. Nothing is built until this is answered; the untracked plan file is
   waiting in `docs/plans/`.
2. **Decide whether the published 10 % disk-floor default should change to
   3 %.** The owner set 3 % locally for this machine only; I recommended
   against lowering the published default (10 GB is very late to start
   cleanup on a small disk). If yes: edit rule 13.5 in both editions, update
   tests/mutations, deep review (it's on the data-safety path), release.
3. **`codex-playbook-environment` rule 9.1 names a private path** (`~/.config/fleet/ports/`)
   in public text, vs. the source edition's generic `~/.config/agent-rules/`.
   Logged in `codex-playbook/BACKLOG.md` 2026-09-28. Fix: restore the generic
   path, move the owner's value to his own `playbook-local.md` as a Fill.
4. **`~/.claude/skills/fabridge/SKILL.md` has an uncommitted 241-line rewrite**
   from another session — not touched here; its owner should review and commit
   it directly in that repo.
5. Disk cleanup candidates above are the owner's call, largest first.

## Gotchas

- **The hygiene test suites in both editions self-validate every new assertion**
  by mutation (Claude: `tests/rules_text_mutation_test.sh`, 129 mutations;
  Codex: inline mutation checks in the review process, not a committed script)
  — if you add a rule clause, add both the assertion and a mutation that proves
  it can fail, or the suite green-lights nothing.
- **`tests/rulebook_test.sh` (Codex) must never call `scripts/verify.sh`** — it
  checks version carriers itself with an inline snippet; `verify.sh` calls the
  rulebook test, so the reverse call creates an infinite fork bomb. This
  actually happened once this session (caught within ~10 minutes, ~1,548
  processes in one process group, killed with `kill -TERM -- -<pgid>` — nothing
  else on the machine was touched). If you ever see runaway `sh scripts/verify.sh`
  / `sh tests/rulebook_test.sh` pairs in `ps`, that's the failure mode.
- **`~/.claude` has no git remote.** Nothing there can be "pushed" — it's a
  local-only history for the owner's own reference/rollback.
- **Local-layer files (`LOCAL.md`, `LOCAL_dev.md`, `playbook-local.md`) are
  never touched by an update/install script** — the 3 % floor and all other
  owner customizations survive every future `checkpoint/*` upgrade
  automatically; nothing needs to be re-applied.
