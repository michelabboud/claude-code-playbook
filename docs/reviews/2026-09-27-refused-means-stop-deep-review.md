# Refused means stop; worktrees through git (0.1.20) — deep review, 2026-09-27

- **Target:** commit `a20e3df` against `7b00cf6`. Risk class (destructive / data-safety), so deep review at task grain.
- **Reviewer:** Strong tier (Claude Opus), read-only; git behaviour verified in a throwaway repository. Coordinator reproduced both blockers independently before fixing.
- **Verdict:** **FAIL** on the first draft — two blocking findings, six minor. All fixed in the follow-up commit.

## Blocking — both reproduced by the coordinator (git 2.43.0)

1. **`git worktree remove` without `--force` silently deletes git-ignored files.**
   A worktree holding an ignored `.env.local` was removed with exit 0 and the file
   was gone. The draft presented plain `remove` as safe; ignored `.env`, local
   databases and logs are rule 10.2's protected classes. Fix: check 1,
   `git -C <worktree> status --short --ignored`, preserve or quarantine first.
2. **"Committed work survives on its branch" is false for a detached worktree.**
   A commit made in a detached worktree was unreachable after `remove`. Detached
   worktrees are what reviewers use. Fix: check 2,
   `git -C <worktree> for-each-ref --contains HEAD` must print a ref.

## Minor — all fixed

- `git branch -d` checks the branch's upstream (or HEAD without one), not `main`;
  the text now says so and ties `-d` to the reachability check.
- "Unless it is yours" also excused the running-process condition; the in-use
  check now has no exception.
- `git worktree prune` skips locked entries; stated.
- Nobody owned a reviewer's detached worktree; the creating lane now owns, locks
  and removes it (an orphan `/tmp/wt-1121aad` from the 0.1.19 review proved the gap).
- Rule 10.1 now also covers the owner declining a command, gives `cargo clean`
  as a same-effect example, and names quarantine as the one sanctioned move.
- The rule now says what to do when git refuses a removal: fix the cause, never force.

## Verified correct by the reviewer

`remove` refuses a locked worktree even with one `--force` (only `-f -f`
overrides); no conflict with the build-output carve-out, rule 6.4, or the
quarantine procedure; tests paragraph-scoped and each mutation able to fail;
version carriers and counts consistent.

## Re-review of the fixes — PASS

Strong tier (Opus 5.5), same brief, against the fix commit `531cec8` on an
archived tree: **PASS**, both blockers and all six minors fixed. The reviewer
re-ran every git fact in a throwaway repository (git 2.43.0): ignored files are
listed by check 1's command; a detached commit prints no ref; `prune` skips a
locked worktree; a quarantined tracked-file change makes `remove` refuse, which
fails safe. Suites: 206/206 wording, 77/77 mutations.

Three new minor findings, all fixed in 0.1.21 (section 13):

1. Check 2 passed on `refs/stash` alone — one `git stash drop` loses the
   commit. Now `for-each-ref --contains HEAD refs/heads refs/tags`, with an
   assertion and a mutation.
2. Check 1 did not say what to do after quarantining a modified tracked file.
   Now: restore its committed version with `git -C <worktree> restore <file>`.
3. No mutation covered the `cargo clean` example, "the one sanctioned move", or
   the reviewer-worktree ownership clause. All three now have one.
