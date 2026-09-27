# Deep review — 0.1.21, Hygiene (section 13)

- **Reviewed:** `986129f`, archived tree, read-only. Strong tier (Claude Opus 5.5).
- **Why deep at task grain:** data-safety path — the section tells agents what
  they may delete.
- **Verdict:** **FAIL** — three blockers, nine minor. Every git fact the text
  states was reproduced true (git 2.43.0); the failures are wording gaps.

## Blocking — all fixed

1. **"Created by this session" beat the protected and evidence classes.** The
   classes overlapped and "exactly one class" gave no precedence, so an agent
   could delete a log, report or database it had created. Fix: the most
   protective class applies (protected, evidence, unknown, the rest), and the
   row is narrowed to disposable items nobody has used since.
2. **The `.hygiene.json` marker was ownership proof on its own** and replaced
   investigation. After compaction a session cannot tell whether it wrote a
   marker, and anyone can write one. Fix: a marker proves ownership only when
   the task's own close-out report or handoff lists the same path; it starts
   classification, never ends it; it never moves an item out of the protected
   or evidence class.
3. **The reachability check was circular for branch deletion:** a branch always
   contains itself, and `git branch -d` deletes a pushed branch `main` never
   merged (reproduced). Fix: delete a local branch only when
   `git merge-base --is-ancestor <branch> main` succeeds or another ref contains
   it. Re-verified in a lab repo by the author: an unmerged branch fails both.

## Minor — all fixed

1. `status --ignored` collapses an ignored folder to one line — now
   `--untracked-files=all` (re-verified: `local/.env` and `local/state.db`
   listed separately).
2. The regenerable row was partly decided by name — now untracked or ignored
   output that a manifest or build command rebuilds; a tracked or hand-made
   folder of the same name is excluded.
3. Rule 13.2's ownership test was stricter than rule 10.2's build-output
   carve-out — 13.2 now defers to it for that class.
4. "Quarantine" for unknowns ignored in-use files and live databases — those
   are listed in the report instead.
5. "Merged branches" now says local; remote branches and tracked files are not
   cleanup.
6. The worktree's own HEAD log dies with it — check 2 now says to branch
   commits it still needs.
7. `for-each-ref` exits 0 either way — the text says the printed ref is the
   signal.
8. `PROGRESS.md` stale count annotated; `docs/ANNOUNCE.md` left as historical.
9. Untested clauses — every one listed now has an assertion and a mutation.

Also: the Windows free-disk row notes that `Get-PSDrive` does not cover UNC
paths.

## Tests after the fixes

`rules_text_test.sh` 254/254; `rules_text_mutation_test.sh` 112/112;
`install_preflight_test.sh` 267/267.
