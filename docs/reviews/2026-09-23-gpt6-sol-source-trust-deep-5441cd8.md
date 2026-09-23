# Pinned deep security and data-loss review

Verdict: **FAIL — two blocking findings.**

Candidate: `5441cd8542fb2ac7c90f7e0c35aea3a1ded8915f`.
Base: `a20bca7bf363b60c7ff48a2bed7cdb07e4941442`.
Scope: read-only review of Git objects and a dedicated `git archive` scratch snapshot, with adversarial fixtures confined to fresh `/tmp/claude-playbook-*` directories. No source-repository edits, installs, uninstalls, commits, tags, pushes, or other-repository access. `docs/reviews/*` was excluded from the initial read; no prior or sibling review output was opened. This child inherited a shared conversation, so this is an independent cold read by procedure, not a blind process. The runtime did not expose a verifiable model identifier, reasoning effort, or token count; GPT-6 Sol was the requested model in the brief, not a measured runtime fact.

Cold-read note: `/tmp/claude-playbook-review-unvKfN/cold-read-note.md` (written before any test or prior-review read).

## Blocking findings

### 1. High: managed destination hard links can overwrite files outside the installation

`INSTALL.md:273-284` rejects symbolic links and non-regular files but accepts a regular file with multiple hard links. `INSTALL.md:348-359` then directs a file-by-file copy into that path on first install and update; `INSTALL.md:839-846` can do the same on restore. Ordinary `cp` truncates the existing destination inode, so a hard link from `~/.claude/rules/AUTHORITY.md` or `~/.claude/CLAUDE.md` to an external owner file alters that external file. The directory roots can all be genuine directories; the root and managed-path guards return success. Backing up the installation does not prevent this external overwrite.

Direct reproduction used only `/tmp/claude-playbook-hardlink-hJb5Vx`. A scratch owner file was hard-linked to scratch `config/rules/AUTHORITY.md`; the pinned guide's exact `destination_root_preflight` was extracted and evaluated. The guard exited `0`. `cp rules/AUTHORITY.md config/rules/AUTHORITY.md` exited `0`; `stat` showed the same inode `8191997` and link count `2` for both paths before and after. `cmp` then confirmed the external owner file matched the playbook rule (exit `0`), replacing its prior content. This is an unauthorized data-loss path and a blocking review finding. The existing destination-link tests cover symlinks, not hard links.

### 2. High: inherited Git repository environment redirects the canonical HTTPS trust lookup

`INSTALL.md:152-158` clears global/system Git config and `GIT_CONFIG_PARAMETERS`, but leaves `GIT_DIR` and `GIT_WORK_TREE` inherited. When those point to the staged checkout, its local Git config remains active for `git -C / ls-remote`, despite `-C /`. A local `url.file://...insteadOf=https://github.com/michelabboud/claude-code-playbook.git` mapping rewrites the supposed canonical HTTPS lookup to a local attacker-controlled bare repository. The local tag and forged remote tag match, and all later byte checks succeed because the attacker committed their own files. This lets an unpublished fork pass the default path, authorizing its staged checker for execution and its rules for copying without an owner-supplied pin.

Direct end-to-end reproduction used `/tmp/claude-playbook-full-bypass-VGTUlY`. The source was an archive of the candidate with one forged rule line appended; it was committed/tagged locally as `checkpoint/0.1.16` at `35ad67532d0f3809980ff418fa6bbb962e617521`, mirrored to a local bare repository, and given the URL rewrite in its local config. With `GIT_DIR=<scratch>/source/.git` and `GIT_WORK_TREE=<scratch>/source` inherited, the pinned guide's exact `source_trust_preflight <scratch>/source 0.1.16` exited **`0`** without contacting GitHub. A smaller direct `ls-remote` probe under the same environment also exited `0` and returned the local fake tag. This is a wrong trust decision and a blocking finding. Existing tests isolate some Git config but do not exercise inherited repository environment variables.

## Conformance and residual limits

The intended sequence is present on the page: first install, update, migration, and uninstall all call source and destination guards before the staged checker or managed mutation; owner pin syntax and local byte/mode verification are covered by tests. The two findings above break the design's destination-preservation and canonical-source guarantees. The local tag comparison itself works in an ordinary environment; the problem is that the HTTPS command is not isolated from inherited repository configuration.

`INSTALL.md:74-87` supplies the guard as inline shell from the guide being read, and `INSTALL.md:307-313` expects an operator to run it. If an attacker can replace the guide before it is read or copied into a shell, that guide can change the guard or include arbitrary commands before provenance is established. ADR 0010:58-60 explicitly disclaims protection against malicious preflight instructions, so I record this as an accepted bootstrap limitation, not a third new blocker. A trusted copy of the guard is necessary for its result to mean anything.

The instructions re-run guards immediately before the **first** copy (`INSTALL.md:359`, `INSTALL.md:532-535`) and admit the manual uninstall is non-atomic (`INSTALL.md:834-837`). A concurrent writer can still replace a later source or destination path after a successful check. ADR 0010:37-38 says quiescence is required; the explicit stop-on-concurrent-writer instruction appears only in uninstall. This is a residual time-of-check/time-of-use limit; the report does not claim atomicity from successful preflights. I did not reproduce a concurrent race because the two deterministic blockers already settle the gate.

I found no further deterministic bypass in the pinned source-file list, Git blob mode acceptance (regular blobs only), `hash-object --no-filters` byte comparison, owner-pin length/equality test, baseline historical-mode handling, or named-file uninstall content comparison. This is a bounded review, not a proof that those paths are vulnerability-free. Native Windows/macOS shell behavior and the real canonical GitHub tag were not exercised; the candidate version `0.1.16` is not a published tag in the local checkout at review time.

## Direct checks

- `git rev-parse --verify` candidate and base: both exit `0`, exact IDs above.
- `git diff --check base candidate`: exit `0`.
- `sh -n scripts/check-local.sh tests/*.sh` in the candidate archive: exit `0`.
- `TMPDIR=<review scratch>/test-tmp sh tests/run.sh` in the candidate archive: exit `0`, final `all suites passed`; `install_preflight_test.sh` printed `1..243` and `# passed 243`.
- `shellcheck -S warning -s sh scripts/check-local.sh tests/*.sh`: exit `1`, only SC2034 unused `HOOK2` at `tests/rules_text_mutation_test.sh:104`. The same warning and exit `1` reproduce on base `a20bca7` for that file, so it is pre-existing, not attributed to this candidate.
- Hard-link guard: exit `0`; copy: exit `0`; external-file comparison to rule: exit `0` (external scratch file overwritten).
- Forged Git environment full source guard: exit `0` against unpublished forged commit; no canonical network request was needed.

The review did not alter the source repository. The scratch fixtures and this report were retained for coordinator inspection.
