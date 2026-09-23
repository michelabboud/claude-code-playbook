# Mechanical review: repaired Claude source trust candidate

**Verdict: FAIL — one P2 blocking conformance finding.** The previously demonstrated inherited-Git, managed hard-link, and newline-path failures did not reproduce against this candidate. The remaining finding is narrower: a clean first install can pass when the required `find -links` capability is unavailable, contrary to the guide's explicit fail-closed prerequisite.

Target: `c0bd8795aaffc4d790025dab76e5d1c5bbd8da27`  
Base and direct parent: `5441cd8542fb2ac7c90f7e0c35aea3a1ded8915f`  
Scope: read-only Git-object diff plus dedicated `git archive` scratch at `/tmp/claude-final-mechanical-gpt6-sol.CR6CYf`; `INSTALL.md`, changed shell tests, and related changed text. All adversarial mutations were in that scratch. I did not inspect the live project worktree, write the repository, touch `~/.claude`, use another repository, tag, push, or clean existing material.

The cold-read note at `cold-read.md` was written after reading the frozen diff and `INSTALL.md`, before opening the prior `docs/reviews/*-5441cd8.md` reports. Those reports were subsequently read to check that the previously reported faults had been covered. This child review inherited a scoped coordinating context; the cold-read order does not establish a fully blind process.

## Finding

### P2 / blocker — first install does not establish the required hard-link-check capability

`INSTALL.md:40-43` says the destination guard uses `find -links`, an environment without that check **must refuse**, and a required check that cannot run stops the procedure before backup or copy. `INSTALL.md:311-320` invokes `find ... -links +1` only inside `[ -e "$destination_file" ]`. With no existing managed file, `destination_root_preflight` never checks whether that predicate is supported and returns success. The first-install path (`INSTALL.md:336-348`) explicitly accepts a configuration with no installed rules; it would continue to the copy step after this false success.

Direct reproduction in `adversarial.sh` used a disposable shell `find` shim: normal `-print` delegated to the system `find`, while `-links` returned 1 as an implementation lacking that predicate would. On the locally published fixture, `source_trust_preflight` exited **0**; on an empty destination, `destination_root_preflight` exited **0**. For a destination with an existing managed hard link, the destination guard exited **2**. The last result limits impact: this does **not** show an external-file overwrite on an actually empty destination, and an update with an existing managed file refuses. It does show that the stated prerequisite is not enforced on the first-install branch. The regression tests cover hard links only where a managed file exists (`tests/install_preflight_test.sh:441-448`); they do not cover unsupported `-links` with an empty destination.

To satisfy the written contract, probe `find -links` on an existing harmless path even when no managed destination file exists, and test that unsupported-predicate failure prevents continuation. This finding blocks the claimed fail-closed installation gate; it is not a claim that the repaired hard-link detection fails for existing managed files.

## Repaired behavior verified

- Canonical fixture accepted: source guard direct exit **0**; it preserved the documented physical `trust_root` postcondition. A forged checkout with inherited `GIT_DIR` and a local `url.*.insteadOf` rewrite was rejected, direct exit **2**. A separate inherited `GIT_CONFIG_COUNT=1` rewrite was rejected, direct exit **2**. An explicitly supplied full forged-commit pin followed the documented offline path, direct exit **0**. The source guard clears repository and object selectors in its subshell and sets `GIT_CONFIG_COUNT=0` before Git calls (`INSTALL.md:115-131`); the canonical lookup runs from `/` after a root-repository check (`INSTALL.md:175-184`). [Git's configuration documentation](https://git-scm.com/docs/git-config) defines the environment config pairs and their `COUNT=0` behavior.
- Existing top-level `CLAUDE.md` and nested `rules/AUTHORITY.md` hard links were both rejected with direct exit **2** (`INSTALL.md:297-320`). Simulated failure of `find` on an existing managed file also returned **2**. No copy into either linked inode was attempted.
- Newline-containing source and destination paths each returned direct exit **2** (`INSTALL.md:103-107`, `INSTALL.md:264-269`). Clean destination returned **0**.
- First-install prerequisites now state POSIX shell, Git, network for the default canonical check, and Windows shell choices (`INSTALL.md:32-44`). The accepted full-pin fork is correctly described as the offline branch.

## Checks and limits

- Exact commit parent from `git cat-file -p`: `5441cd8542fb2ac7c90f7e0c35aea3a1ded8915f`, direct exit **0**. `git archive` extraction: direct exit **0**. `git diff --check base target`: direct exit **0**.
- `find scripts tests -type f -name '*.sh' -exec sh -n {} +`: direct exit **0**. `shellcheck --severity=warning -s sh` on each extracted inline source/destination guard: direct exit **0** for each.
- `TMPDIR=<review scratch>/test-tmp sh tests/run.sh`: direct exit **0**. Six suites passed with 207, 93, 53, 144, 38, and 262 assertions; final line `all suites passed`.
- `shellcheck --severity=warning -s sh scripts/*.sh tests/*.sh`: direct exit **1** for the unused `HOOK2` warning at `tests/rules_text_mutation_test.sh:104`. The same assignment exists in the exact parent object at line 104, so this warning is not attributed to the candidate. The full lint command was **not** clean.
- `sh adversarial.sh`: direct exit **0**, all expected statuses observed, including the unsupported-`-links` gap above. The script and both rounds of fixture data remain in this scratch for inspection.

Native macOS, Windows/Git Bash, the real canonical GitHub tag, and a live install were not exercised. The local fixture substitutes the canonical endpoint solely to test decision logic without publication or live mutation. The requested GPT-6 Sol label came from the assignment; this runtime did not expose a verifiable model identifier or reasoning effort, so neither is claimed as measured. The review is bounded evidence, not a proof of all Git or filesystem race cases.
