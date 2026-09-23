# Pinned mechanical review — 34013e3

**Verdict: PASS. No blocking finding in the changed lines.**

**CONFIRMED:** both prior safety-instruction gaps are corrected in source text; the added regressions and all six archived suites pass. **REFUTED:** the prior profile-root example and first-install-only quiescence scope do not remain in this commit. **UNVERIFIED:** native Windows/MSYS2 behavior and real installation or concurrent-writer behavior.

Target: `34013e3b4a98b2509a42963c645f728ec4d0d447`

Direct parent/base: `b2fd2553d4bad4786d7e817c1c2c28a39cfae5bc`

Scope: read-only Git objects for `/home/michel/projects/claude-code-playbook` and a dedicated `git archive` at `/tmp/claude-playbook-review-34013e3-A7uTeH`. Scratch-only mutations are at `/tmp/claude-playbook-mut-34013e3-KyXsk4`. No live repository worktree, `~/.claude`, other repository, tag, push, or source file was changed. The [cold note](cold-read.md) was written before opening prior review reports. The task brief already identified earlier defects, and this child inherited context, so the cold read was not fully blind. Runtime model identity, effort, and token usage are unavailable; GPT-6 Sol was requested but cannot be independently attested from this runtime.

## Confirmed changes

1. `INSTALL.md:37-41` now derives the Windows configuration target with `windows_config="$(cygpath -u "$USERPROFILE")/.claude"`. The appended component means a POSIX conversion of the Windows profile directory addresses its `.claude` child; the instruction says to substitute that full absolute path wherever later procedures show `~/.claude`, and to stop if `USERPROFILE` or `cygpath` is unavailable. This removes the prior profile-root target error at source level. Native Git Bash/MSYS2 path conversion was not executed on this Linux host; `cygpath` is unavailable here.
2. `INSTALL.md:86-90` puts quiescence in the shared source and destination preflight section, before first-install Step 0. It explicitly covers first install, update, migration, restore, and uninstall through the last mutation. No changed route bypasses that text. This is an operator instruction, not an atomicity guarantee.
3. `tests/rules_text_test.sh:338-350` asserts the complete Windows example and shared-section placement. The committed mutation suite catches deletion of the example and movement of quiescence out of shared preflight. Independent scratch mutations that removed only `/.claude` and moved the full quiescence paragraph into first-install Step 0 each made the wording suite fail at its intended assertion (direct exit 1 in both cases). Thus the tests detect the specific prior regressions, not only deletion of whole sentences.
4. `tests/install_preflight_test.sh:498-509` exercises an existing destination with an unsupported `find -links` predicate, asserts guard exit 2 and no continuation, and confirms the pre-existing managed file's bytes remain identical. It complements the earlier empty-destination case. The guard itself is unchanged in this commit.
5. The full pinned diff, including normalized committed review reports, passes `git diff --check` (direct exit 0). The changed documentation and records are consistent with the checked behavior. No production runtime path or performance-sensitive algorithm changed.

## Direct checks and limits

- `git rev-list --parents -n 1 <target>`: direct exit 0, confirming the exact parent above. `git archive <target> | tar -tf -` with `pipefail`: direct exit 0.
- `sh tests/run.sh` in the archive: direct exit **0**, `all suites passed`; assertion counts in order **207, 93, 53, 147, 40, 267**. Complete output: [full-suite.log](full-suite.log).
- Scratch wording suite after removing only `/.claude` from the Windows example: direct exit **1**, `not ok 137 - the Windows example targets the configuration directory`. After moving quiescence into Step 0: direct exit **1**, `not ok 139 - quiescence is in the shared preflight, before first-install-only steps`.
- `find tests scripts -type f -name '*.sh' -exec sh -n {} +`: direct exit **0**. Focused ShellCheck on the changed install-preflight and wording tests: direct exit **0**. ShellCheck on all three changed shell tests: direct exit **1** for `SC2034` on `HOOK2` in the wording mutation test; the same check on the exact base version also exits **1** for the same line, so this is inherited lint debt, not a new defect.
- `git diff --check <base> <target>`: direct exit **0**. Native Windows/macOS, real canonical remote lookup, concurrent-writer behavior, live install, and uninstall were not run. No performance benchmark was relevant to the changed documentation and tests.
