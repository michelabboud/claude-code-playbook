# Pinned deep security and data-loss re-review

Verdict: **PASS for the focused repair**. No new deterministic blocker was found in the changed trust guards. This verdict covers the frozen candidate `c0bd8795aaffc4d790025dab76e5d1c5bbd8da27` against base `5441cd8542fb2ac7c90f7e0c35aea3a1ded8915f`; it is not a release or native-platform acceptance.

## Scope and isolation

I read the pinned diff from Git objects and `INSTALL.md` from a dedicated `git archive` snapshot at `/tmp/ccpb-gpt6-sol.soEV9T/snapshot`. I saved `/tmp/ccpb-gpt6-sol.soEV9T/cold-read.md` before opening the earlier `docs/reviews/*-5441cd8.md` reports. The parent brief itself named the two earlier high findings, so the note records independent source inspection and reading order, not blind discovery. This was a child agent with inherited session instructions, not a separate fresh process; exact runtime model identity, reasoning effort, and token usage are unavailable. The assignment requested GPT-6 Sol, but I cannot verify runtime identity.

No live `~/.claude`, source worktree files, tags, pushes, or other repositories were changed. Fixture Git repositories, test outputs, and this report are confined to this scratch directory.

## Findings and ruling

1. **Earlier canonical-tag impersonation: resolved in the tested variants.** `INSTALL.md:115-131` clears the inherited Git repository/object/config selectors in a subshell, pins global/system config to `/dev/null`, and sets `GIT_CONFIG_COUNT=0`. The `git -C / ls-remote` call at `INSTALL.md:175-185` is made under the same isolated environment, after refusing a repository at `/.git`. The local and remote tag object IDs still have to match; file bytes and committed regular-file modes are then checked at `INSTALL.md:189-225`. My scratch fixture accepted a legitimate local published tag (exit 0) and refused an unpublished forged tag under inherited `GIT_DIR`/`GIT_WORK_TREE` (exit 2, `local tag differs`) and under inherited `GIT_CONFIG_COUNT` URL rewrite (exit 2, same reason). Both hostile variants retained the forged checkout's local `insteadOf` rewrite; neither redirected the canonical fixture lookup.

2. **Earlier external overwrite through a hard-linked managed destination: resolved in the tested path.** `INSTALL.md:298-321` checks every named managed destination, including `CLAUDE.md` and all platform files, for link count greater than one. `find` failure itself returns 2. I hard-linked scratch `config/CLAUDE.md` to an external owner file: the guard returned 2, and the external bytes were unchanged. The install/update/migration/uninstall paths invoke the destination guard before backup or managed mutation (`INSTALL.md:343-347`, `512-513`, `692-693`, `768-769`, `816-817`). The existing test also covers a managed rule file hard link.

3. **Newline and first-install prerequisite repairs: present.** Source and destination arguments reject literal newlines in addition to other controls (`INSTALL.md:103-107`, `264-269`); the disposable regression checks both. `INSTALL.md:32-44` now names shell, Git, canonical-network, and `find -links` requirements for first install, with refusal when a required check is unavailable.

4. **Bootstrap and race limits: nonblocking under the accepted design.** The preflight code is still copied from `INSTALL.md` before that document can authenticate itself. ADR 0010 explicitly excludes protection from malicious instructions read before preflight. The guide reruns guards before the first copy, but multi-file copies are manual and not atomic. ADR 0010 requires quiescence, and the uninstall text says to stop if another writer is active (`INSTALL.md:866-872`). Install/update do not restate that quiescence requirement as explicitly; concurrent source or destination replacement after a check remains a residual risk. This review did not treat a concurrent writer as a new deterministic bypass of the accepted manual design. The safe acceptance claim is confined to quiescent paths.

5. **Cross-platform limit: unverified, fail-closed where implemented.** This review ran on Linux with GNU `find` and Git 2.43. If an implementation lacks `find -links`, the destination guard's nonzero `find` status returns 2. I did not run native macOS, Git Bash, MSYS2, or Windows/WSL acceptance. `INSTALL.md` mentions WSL as a shell for Windows guards, but a WSL shell's `~/.claude` and `uname` refer to the Linux environment; an operator targeting Windows must select the Windows configuration path and platform explicitly. This is an operational documentation caveat, not evidence of an overwrite in the tested path.

No additional changed-file blocker was found in the owner-pin equality check, baseline missing-file behavior, committed mode check, source literal-byte comparison, named managed-file uninstall comparison, or local-layer preservation paths. This is a bounded review, not proof of absence of all vulnerabilities.

## Direct checks

- `git diff --check 5441cd8 c0bd879`: exit **0**.
- Separate `git rev-parse --verify '<sha>^{commit}'` for the candidate and base: exit **0** each, yielding the full IDs above. An initial combined two-revision `--verify` invocation was invalid (exit 128); I corrected the invocation rather than treating that diagnostic error as a repository failure.
- `find scripts tests -type f -name '*.sh' -exec sh -n {} +` in the archive: exit **0**.
- `shellcheck --severity=warning -s sh` on the exact extracted source and destination guards: exit **0**.
- `/tmp/ccpb-gpt6-sol.soEV9T/probe.sh`: exit **0**; canonical fixture accepted (0), both forged Git environment variants refused (2 each), hard-linked `CLAUDE.md` refused (2), external bytes preserved.
- Full six-suite `tests/run.sh` in the archive: direct exit **0**, `all suites passed`. Counts: `check_local_test` 207, `dead_words_vectors_test` 93, `mutation_test` 53, `rules_text_test` 144, `rules_text_mutation_test` 38, `install_preflight_test` 262. The first run's shell session ended before I captured its direct exit, so I reran the same frozen archive once with a retained session; this is the second run's direct result.

The fixture replaces only the canonical URL literal with a scratch bare repository, so these checks validate tag comparison and environment isolation without making a live network request. The real unpublished `0.1.16` canonical tag and native-platform behavior were not tested.
