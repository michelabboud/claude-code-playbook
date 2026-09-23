# Pinned deep security and data-loss re-review — b2fd255

**Verdict: FAIL — two P2 blocking documentation safety findings.** The new hard-link capability probe itself passed the focused Linux checks. This verdict concerns frozen commit `b2fd2553d4bad4786d7e817c1c2c28a39cfae5bc` against its direct parent `c0bd8795aaffc4d790025dab76e5d1c5bbd8da27`; it is not a review of later edits, a publication decision, or native Windows/macOS acceptance.

## Scope and independence

I read the changed guard, guide, tests, and task records from Git objects and wrote `cold-read.md` in `/tmp/claude-playbook-b2fd255-deep-R6NjHA/` before opening ADR 0010 or the prior review files. The brief itself supplied the earlier review outcomes, and this child agent inherited coordinating context, so this is a cold source read, not a fully blind process. I then extracted the exact candidate with `git archive` to `/tmp/claude-playbook-b2fd255-deep-R6NjHA/snapshot` and ran only scratch tests. The live project worktree, live `~/.claude`, tags, pushes, and other repositories were untouched. Runtime model identity, reasoning effort, and token usage are not exposed to this reviewer; the assignment requested GPT-6 Sol, but I cannot independently attest to that runtime identity.

## Findings

### 1. P2 blocker — Windows path example omits `.claude`

`INSTALL.md:30` names `%USERPROFILE%\.claude` as the Windows configuration directory. The new instruction at `INSTALL.md:37-39` says to convert it to a POSIX path and use it wherever later steps show `~/.claude`, but its only example is `cygpath -u "$USERPROFILE"`. That command converts **only `%USERPROFILE%`**, not `%USERPROFILE%\.claude`. An agent following the example literally would preflight and copy into the profile root. If that root already contains a regular `CLAUDE.md` or `rules/` tree, the guard can accept those names and the copy instructions can overwrite or mingle unrelated user material there, even with a backup. This is a target-selection and data-safety error newly introduced by the candidate. The correct example must append `/.claude` to the converted profile path (or convert the complete Windows path), and every later path substitution must use that resulting directory.

### 2. P2 blocker — quiescence instruction does not reach update and migration

ADR 0010:37-38 requires quiescence because the manual preflights do not make concurrent filesystem changes atomic. The candidate adds that instruction at `INSTALL.md:361-363`, inside **Step 0**. The routing table at `INSTALL.md:10-14` sends Step 0 only to first install. Update's Step U5 invokes steps 1, 2, 3, and 5 (`INSTALL.md:579-584`); migration's M5 leads to steps 1, 2, 3, and 5 (`INSTALL.md:729-747`). Neither route invokes Step 0 or repeats the quiescence condition. Uninstall explicitly does (`INSTALL.md:885-888`). Thus an update or migration reader can follow the complete written route without being told to stop when another writer is changing the source or target. This is a missing safety condition in the documentation, not a claim that the guard can make a race atomic or that a race was reproduced. Put the requirement in the shared preflight section, or state it explicitly in both update and migration before their first backup/copy.

### 3. P3 check hygiene — full `git diff --check` is nonzero

The full pinned diff check returned **2** for two trailing-space Markdown line breaks in the newly added `docs/reviews/2026-09-23-gpt6-sol-source-trust-mechanical-c0bd879.md:5-6`. This is separate from the trust findings. The focused diff check over changed guard, tests, guide, and task records returned **0**. The added review text uses the spaces as Markdown hard breaks, but a release gate that requires a clean full diff check must either remove them or record an intentional waiver; the full command cannot be claimed green.

## Confirmed behavior and limits

- The added `find / -prune -links +1 -print` check at `INSTALL.md:275-280` is unconditional, so the empty first-install branch now executes the `-links` predicate. On the tested GNU find, `-prune` prevents descent below `/`. An unsupported predicate returns nonzero and the guard returns 2 before a continuation marker; its supported empty-destination path returns 0. The same guard still refuses a managed hard link, and the external scratch file remained unchanged.
- The new regression in `tests/install_preflight_test.sh:482-497` directly models a `find` that rejects `-links` and requires the first-install continuation marker to remain absent. It addresses the prior mechanical finding for the ordinary unsupported-predicate behavior.
- This capability probe demonstrates parser/exit-status support in the current `find`; it does not independently prove that another platform reports NTFS or other filesystem link counts correctly. Native Git Bash/MSYS2, macOS, real canonical GitHub tag lookup, and a live install were not run. On a platform where `find -links` returns an error, the documented guard fails closed. A concurrent writer remains outside what a manual preflight can make atomic, per accepted ADR 0010. The bootstrap trust limit accepted there was not re-litigated.
- The Windows target path issue is proved from the command's missing `.claude` component and guide control flow. No Windows filesystem was changed and no native Windows execution is claimed. The quiescence finding is likewise a source-level procedure omission; no race exploit is claimed.

## Direct checks

- Candidate and base `git rev-parse --verify '<sha>^{commit}'`: **0** each. `git rev-list --parents -n 1` confirmed the exact parent above: **0**. `git archive` extraction with pipefail: **0**.
- `sh tests/run.sh` in the frozen archive: direct **0**, `all suites passed`. Counts in suite order: 207, 93, 53, 144, 38, 264 assertions. This checks Linux/scratch behavior, not the Windows example or operator quiescence.
- `/tmp/claude-playbook-b2fd255-deep-R6NjHA/adversarial.sh`: direct **0**; supported empty destination **0**; managed hard link **2**; unsupported `-links` on empty destination **2**; external owner bytes preserved.
- Direct `find / -prune -links +1 -print`: **0**. Direct invalid-predicate control, `find / -prune -definitely_unsupported -print`: **1**.
- `shellcheck --severity=warning -s sh` on extracted destination guard: **0**. `find scripts tests -type f -name '*.sh' -exec sh -n {} +`: **0**. ShellCheck on the two changed shell tests: **0**.
- Focused `git diff --check` for changed guide, tests, and task records: **0**. Full `git diff --check c0bd879 b2fd255`: **2**, with the two review-file whitespace diagnostics above.

The complete cold note and this report are preserved under `/tmp/claude-playbook-b2fd255-deep-R6NjHA/`; the adversarial fixture and exact archive remain there for audit. No cleanup was performed.
