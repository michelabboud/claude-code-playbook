# Mechanical review of 5441cd8542fb2ac7c90f7e0c35aea3a1ded8915f

Base: `a20bca7bf363b60c7ff48a2bed7cdb07e4941442`.
Verdict: **FAIL**. Keep the candidate unpublished.
Scope: `INSTALL.md` source/destination guards and procedure calls, install preflight and rules-text tests, `.gitattributes`, and changed user documentation. All source inspected from Git objects at the pinned SHA or a dedicated `git archive` of that SHA. No project repository writes, live installation, deletion, push, or other repository access. I did not read `docs/reviews/*` or sibling review output. A cold-read note was saved first at `/tmp/claude-playbook-mechanical-EQQf4n/cold-read.md`.

## Findings, ranked

### P1 / blocker — inherited `GIT_DIR` defeats the canonical HTTPS trust anchor

`INSTALL.md:152-158` tries to isolate the canonical `git ls-remote` by clearing global/system Git config and running from `/`. It does not clear `GIT_DIR`. When the caller has `GIT_DIR` exported, Git reads that repository's local `.git/config` even with `-C /`. A staged checkout can contain `url.file:///.../false-canonical.git.insteadOf=https://github.com/michelabboud/claude-code-playbook.git`. The guard then queries the local false repository, sees the same attacker-created tag object, and returns success without contacting the canonical HTTPS repository. The source bytes are self-consistent with the forged HEAD, so the later blob checks cannot repair this provenance failure.

Reproduction, wholly in disposable scratch: copied the pinned release payload into `forged-source`, made a new local commit/tag and bare `false-canonical.git`, set that checkout's local URL rewrite, and ran the verbatim extracted guard with `GIT_DIR=/tmp/claude-playbook-mechanical-EQQf4n/forged-source/.git`. Direct guard exit was **0** with no owner pin. Under the same environment and the guard's config overrides, `git -C / ls-remote --exit-code --refs https://github.com/michelabboud/claude-code-playbook.git refs/tags/checkpoint/0.1.16` returned local fake tag `32eb2f1c9c79d744ec29fbb47a7d711c6aa607cd`, exactly the staged local tag. This violates the approved canonical-or-explicit-pin design. The existing tests replace the canonical URL literal with a fixture path (`tests/install_preflight_test.sh:37-41`), so they do not exercise this inherited Git-environment route.

### P2 / installation documentation — first-install prerequisites are false

`INSTALL.md:32-41` says copying needs nothing special, lists `sh` only for the staleness check, and says a first install needs neither `curl` nor `sh`. The new mandatory first-install step at `INSTALL.md:307-313` requires executing the POSIX-shell source and destination guards at `INSTALL.md:86-289`, including `git ls-remote` over HTTPS. The page therefore sends a Windows/PowerShell first-installer into a procedure for which its prerequisites are not stated. The prose needs to include a POSIX shell, Git, and network access for first install, with the supported Windows execution route. This is a candidate-introduced contradiction, not a test failure.

### P3 / guard input validation — newline path is accepted as unambiguous

`INSTALL.md:242` and `INSTALL.md:100` attempt to reject control characters with `printf '%s' ... | grep -q '[[:cntrl:]]'`. Line-oriented `grep` does not match a newline used as a record separator. I extracted `destination_root_preflight` verbatim and passed an absolute disposable path with an embedded newline (`.../newline\nconfig`); direct guard exit was **0**, although the guard promises `Destination blocked: ambiguous path encoding`. The same pattern is used by source-trust input validation. Quoted path use still limits immediate traversal impact, but this is a false acceptance of explicitly refused input and can make logs/approval records ambiguous. No project destination was touched.

## Checks and evidence

- `sh tests/run.sh` from the pinned archive: **direct exit 0**. Six suites passed: `check_local_test` 207, `dead_words_vectors_test` 93, `mutation_test` 53, `rules_text_test` 143, `rules_text_mutation_test` 38, `install_preflight_test` 243. Full log: `/tmp/claude-playbook-mechanical-EQQf4n/test-run.out`.
- `find scripts tests -type f -name '*.sh' -exec sh -n {} +`: **direct exit 0**.
- `shellcheck --severity=warning -s sh` on extracted inline source/destination guards: **direct exit 0**.
- `shellcheck -s sh scripts/*.sh tests/*.sh`: **direct exit 1** with informational warnings and an `SC2034` warning at `tests/rules_text_mutation_test.sh:104`; these warnings are on unchanged code (the same `HOOK2` line and checker code exist in base `a20bca7`). `shellcheck --severity=warning` on the scripts/tests also exits **1** solely for that `HOOK2` warning. Full output: `/tmp/claude-playbook-mechanical-EQQf4n/shellcheck.out` and `shellcheck-warning.out`. I did not claim a clean full lint run.

## Limits

The agent assignment requested GPT-6 Sol, but the runtime does not expose its exact model identifier or reasoning effort to this reviewer. This was a child session with a scoped brief, not an independently launched fresh process; the cold note establishes reading order but not full context isolation. Live canonical network/install/uninstall was outside the review boundary. The local fake-remote test establishes the guard bypass without depending on network state. No previous review files were opened.
