---
paths:
  - "**/.worktrees/**"
---

# 13 · Hygiene — rules 13.1–13.6

*Read by path before any cleanup: a request to clean up, free space or remove stale builds, a close-out checkpoint, or a disk warning. It does not load every session. It carries procedure; the authority stays in rules 10.1–10.2 (`DESTRUCTIVE.md`, always loaded): destructive acts need my OK, and they run alone, after validation.*

13.1 **Classify before you remove.** Every candidate falls into exactly one class, and the class decides the action. A name (`tmp`, `old`, `backup`) or a `.gitignore` entry never decides it, because both describe intent, not what the item holds.

| Class | Examples | Action |
|---|---|---|
| **Regenerable and idle** | toolchain build output next to the manifest that rebuilds it — `target/` beside `Cargo.toml`, `node_modules/` beside `package.json`, `dist/`, `__pycache__/`, test caches | remove, alone, one directory per call, after checking no process uses it (your platform file gives the command) |
| **Created by this session** | the task's scratch files, a `mktemp` directory it made, fixtures it built | remove when done, including a read-only inventory's own temporary files |
| **Restorable by git** | tracked, committed, unmodified files; merged branches; worktrees that pass the checks in rule 13.3 | remove through git |
| **Evidence** | logs, reports, reviews, benchmark results, debug dumps a document refers to | keep; compress rotated logs (rule 9.4); archive large evidence only with its references updated |
| **Protected** | `.env`, credentials, keys, databases, state files, backups, anything I created | only on my word (rule 10.2) |
| **Unknown** | anything that fits none of the above | quarantine it (rule 10.3) |

13.2 **Remove only what is provably yours.** Proof is one of: this session created it, your lane holds its lock, or its marker (rule 13.4) names your task. What belongs to another lane, another agent, a running service or a person goes in the report (rule 13.5) and is not touched. A familiar name is naming, not permission (rule 9.2).

13.3 **Worktrees are removed through git, never by deleting their folder, and only after three read-only checks.**
    1. `git -C <worktree> status --short --ignored`. Commit or quarantine uncommitted work first; after quarantining a modified tracked file, restore its committed version (`git -C <worktree> restore <file>`) — the content is safe in quarantine, and git refuses the removal until you do. Treat every git-ignored file that is not regenerable build output — a `.env`, a local database, a log — as protected: `git worktree remove` deletes ignored files silently, so preserve or quarantine them first.
    2. Its commits are reachable from a branch or tag: `git -C <worktree> for-each-ref --contains HEAD refs/heads refs/tags` must print a ref. A stash or a remote-tracking ref alone is not enough — one `git stash drop` loses it. A detached worktree's commits live on no branch, and removing it makes them unreachable, so branch or tag them first.
    3. It is not in use: no running process works in it, and no other lane has it locked.

    Then run `git worktree remove <path>`, without `--force`, alone. If git refuses, fix the cause it names instead of forcing. `git worktree prune` clears the bookkeeping of worktrees whose folders are already gone, and skips locked ones. Deleting a worktree's folder with `rm`, or passing `--force`, skips git's checks and is a destructive act under rule 10.1. The lane that creates a worktree owns it — including a detached one made for a reviewer: it locks it with `git worktree lock` while it is in use, and unlocks and removes it at close-out. Never remove a worktree another lane has locked. Delete a branch with `git branch -d` only after the reachability check: `-d` refuses a branch not merged into its upstream, or into HEAD when it has none, which is not the same as merged into `main`. Never use `git branch -D` on a branch with unique work.

13.4 **Make things cleanable when you create them.** Put work products where their class is obvious: the task's scratch directory, a locked worktree, the toolchain's own output folder. Anything large or long-lived you create elsewhere gets a marker file beside it, `.hygiene.json`, recording `owner`, `task`, `created`, `disposable` (`true` or `false`) and `regenerate` (the command that rebuilds it, or `null`). Cleanup then reads the marker instead of investigating. A marker you did not write is evidence, not permission; rule 13.2 still applies.

13.5 **When hygiene runs, and what it reports.** Run it at every task close-out and phase end (rule 6.2's checkpoint), before work that uses a lot of disk, and whenever free space on the working filesystem falls below the floor — the one your local layer sets, or 10 % free when it sets none. Check free space and running processes first; your platform file gives the commands. Low space calls for this procedure, never for broader deletion. Every pass ends with a report: what was removed, how, and the space reclaimed; what was kept, and why; and the next candidates for me, largest first, each with what would be lost and whether it can be regenerated. When I ask what to remove, answer in that same shape.

13.6 **A refusal ends the attempt.** When a guard or I refuse a removal, rule 10.1 applies: do not re-issue the same effect in another form. A refusal usually means the item was not provably in the first three classes. Reclassify it, then quarantine it or list it in the report as a candidate for me.
