# Pinned deep security and data-loss review — 34013e3

**Verdict: PASS for the requested frozen change.** No blocking security or data-loss defect found. The two P2 documentation findings from the parent review are resolved in this commit. This is a review verdict, not publication or native Windows/macOS acceptance.

Target: `34013e3b4a98b2509a42963c645f728ec4d0d447`

Direct parent/base: `b2fd2553d4bad4786d7e817c1c2c28a39cfae5bc`

## Scope and independence

I read the changed `INSTALL.md` and tests from Git objects, then wrote [the cold-read note](cold-read.md) before opening earlier review files. The assigned brief already disclosed the two parent findings, and this is a child agent with inherited context, so the note is a cold source read, not a fully blind second process. All executable checks used the exact target `git archive` in `snapshot/` or other files under this scratch directory. I did not inspect the live source worktree or live `~/.claude`, and did not edit the repository, tag, push, or use other repositories. The requested model was GPT-6 Sol; actual runtime model identity, effort, and token usage were not independently exposed.

## Findings and dispositions

**CONFIRMED fixed — P2 Windows target selection.** `INSTALL.md:30` identifies `%USERPROFILE%\.claude` as the target. Lines 37-42 now give `windows_config="$(cygpath -u "$USERPROFILE")/.claude"`, require that full path wherever later steps show `~/.claude`, and stop on unset `USERPROFILE` or failed conversion. The appended component is the missing part in the parent finding. A scratch shell probe with a spaced profile path produced `/c/Users/Ada Name/.claude`. That probe confirms the expression's shell quoting and appended component; it is not native `cygpath` execution. A Git-object search found no competing current target instruction outside historical review reports: `README.md:88` also names `%USERPROFILE%\.claude`.

**CONFIRMED fixed — P2 quiescence coverage.** `INSTALL.md:84-91` puts the requirement in the shared source/destination preflight section, before the first-install-only Step 0. It expressly names first install, update, migration, restore, and uninstall, and says to stop if either tree has another writer through the last copy or deletion. Update invokes the shared guards in U1/U2/U5; migration invokes them in M1/M1b/M4/M5; uninstall/restore invokes them in the uninstall preflights and also repeats the quiescence warning at line 890. No route directs a mutation around this stated condition. This is an operator condition, not an atomicity guarantee or a claim that the prose detects concurrent writes.

**CONFIRMED preserved — hard-link and source-trust safeguards.** The exact `source_trust_preflight` body has the same SHA-256 at base and target (`b6de2283985b215934b4b69364939d27b02c878bdf921da0f9470d3156e249b4`); `destination_root_preflight` likewise matches (`43d3c8b96c2c8064fbea8711aa25d962327e3eec2ff07f7645fdb5e15ae25639`). The added test covers unavailable `find -links` with an existing managed file and asserts no continuation and preserved bytes. The independent scratch probe found clean destination **0**, managed hard link **2**, unavailable `-links` on an existing destination **2**, and unavailable `-links` on an absent destination **2**; external owner bytes were unchanged. The archived preflight suite passed **267** assertions, including source-trust cases. No guard or trust boundary was weakened by changed lines.

**CONFIRMED clean — entire diff whitespace.** `git diff --check b2fd2553d4bad4786d7e817c1c2c28a39cfae5bc 34013e3b4a98b2509a42963c645f728ec4d0d447` exited **0** with no diagnostics. This includes the normalized historical review report; the former Markdown hard-break trailing spaces no longer fail the check.

**UNVERIFIED platform limit.** Native Git Bash/MSYS2, macOS, NTFS hard-link accounting, and live canonical GitHub tag lookup were not exercised in this Linux scratch review. The local test suite uses an authenticated Git fixture for source-trust cases. No current exploit is inferred from those unrun platforms. Quiescence remains a manual prerequisite and does not lock either tree.

## Direct checks

| Check | Direct exit | Decisive result |
|---|---:|---|
| Target commit object and direct parent | 0 | `parent b2fd2553d4bad4786d7e817c1c2c28a39cfae5bc` |
| Exact target `git archive` extraction with pipefail | 0 | Snapshot under this scratch directory |
| Full frozen `sh tests/run.sh` with pipefail | 0 | `all suites passed`; suite assertions 207, 93, 53, 147, 40, 267 |
| Shell syntax for `scripts/` and `tests/` | 0 | No diagnostics |
| ShellCheck on changed `install_preflight_test.sh` and `rules_text_test.sh` | 0 | No diagnostics |
| ShellCheck on all three changed tests | 1 | Existing SC2034 unused `HOOK2` at `rules_text_mutation_test.sh:104`; the parent blob returns the same warning and exit 1, so this is not introduced by this commit |
| Independent scratch probe (`probe.sh`) | 0 | Guard statuses 0/2/2/2; owner bytes preserved; Windows expression includes `/.claude` |
| Full frozen diff whitespace | 0 | No diagnostics |

**REFUTED as current defects:** the parent review's missing `.claude` component and first-install-only quiescence scope. **New blocking findings: none.** No scratch artifacts were deleted.
