# Pinned mechanical review — destination capability repair

**Verdict: PASS for the requested fail-closed capability repair.** No blocking defect was found in the frozen change. One P3 formatting/check failure remains in an added historical review report; it does not change install behavior, but `git diff --check` must not be reported as green.

Target: `b2fd2553d4bad4786d7e817c1c2c28a39cfae5bc`

Direct parent/base: `c0bd8795aaffc4d790025dab76e5d1c5bbd8da27`

Scope: Git objects from `/home/michel/projects/claude-code-playbook` and a `git archive` snapshot in `/tmp/claude-capability-mechanical.lrvqyWwX/snapshot`. All mutations were confined to scratch test fixtures and the two review notes. I did not inspect live source worktree changes, touch live `~/.claude`, use another repository, tag, push, or clean up. The independent [cold note](cold-read.md) was written before I opened the earlier `docs/reviews/*c0bd879.md` reports. This child inherited a task brief and shared context; it is not a fully blind separate process. The requested GPT-6 Sol label came from the assignment; the runtime did not expose a verifiable actual model identifier or reasoning effort.

## Findings

1. **Capability gap repaired; no blocker.** `INSTALL.md:275-280` runs `find / -prune -links +1 -print` unconditionally before checking destination components or managed files. An implementation that rejects `-links` returns nonzero and the guard returns 2, whether the destination is absent or already populated. The `-prune` expression applies to `/`, prevents descent, and has no write action. The subsequent existing-file check at `INSTALL.md:321-330` still rejects hard-linked managed files and `find` errors. My [adversarial probe](probe.sh) ran with a `find` function that rejects `-links`: an absent destination, an existing clean managed file, and an existing hard-linked managed file each returned **2**, with continuation absent. Under normal GNU `find`, absent and existing clean destinations each returned **0**; the existing hard link returned **2**. External, hard-linked, and clean managed bytes remained identical. The probe itself exited **0**. `find -D search / -prune -links +1 -print` exited **0** and logged only `/` at depth 0, with no descendant visit.

2. **P3 / nonblocking — diff hygiene check exits 2.** `git diff --check c0bd879 b2fd255` flags trailing spaces in the newly added `docs/reviews/2026-09-23-gpt6-sol-source-trust-mechanical-c0bd879.md:5-6`. These are two-space Markdown hard breaks after the Target and Base lines, so they do not misstate behavior; still, the check is red on the exact candidate. The close-out must record it or change the formatting in a later commit if a clean diff check is required.

3. **Test coverage gap, informational.** `tests/install_preflight_test.sh:482-497` adds a genuine unsupported-`-links` first-install regression. It asserts guard exit 2 and no continuation, but tests only the absent destination for this capability failure. The independent probe above covers an existing clean destination too. A repository regression for that branch and preserved bytes would make future guard changes easier to assess; this gap is not a demonstrated defect in this candidate.

## Platform and procedure assessment

The [FreeBSD 14.3 `find(1)` manual](https://man.freebsd.org/cgi/man.cgi?manpath=FreeBSD+14.3-RELEASE&query=find&sektion=1) documents `-links n`, `+n` numeric arguments, and `-prune` preventing descent. The [GNU Findutils manual](https://www.gnu.org/software/findutils/manual/html_mono/find.html) documents the same predicates. [MSYS2 packages GNU findutils](https://packages.msys2.org/packages/findutils?variant=x86_64) as `/usr/bin/find.exe`, and [Git for Windows says its launcher puts its POSIX `find.exe` before Windows' different `find.exe`](https://gitforwindows.org/git-wrapper.html). These support the expression's intended syntax. They are documentation evidence, not native execution proof: macOS, Git Bash, MSYS2, NTFS hard-link counts, and Windows path conversion were **not run here**.

`INSTALL.md:36-45` now directs Windows installation through Git Bash or MSYS2, an absolute POSIX path derived from `%USERPROFILE%`, and the Windows platform file. It explicitly excludes WSL's Linux home and `uname` from Windows target selection. Step 0 (`INSTALL.md:343-364`) asks for the target OS, both preflights before mutation, rechecks before copy, and quiescent source/destination; this accurately describes the manual, non-atomic design. `uninstall_managed_file_preflight` still selects from `uname` at `INSTALL.md:838-842`, unchanged in this commit; in WSL against a Windows target it would look for Linux's platform file and refuse rather than delete a Windows file. The documented Git Bash/MSYS2 Windows path does not have that mismatch.

The root probe tests predicate availability, not whether a particular filesystem reports link counts correctly. No native Windows or macOS acceptance was available. This is a verification limit, not evidence of a current bypass.

## Direct checks

- Frozen target parent verified as `c0bd8795aaffc4d790025dab76e5d1c5bbd8da27`; `git archive` snapshot extracted for all executable checks.
- Six archived suites, invoked individually with scratch `TMPDIR`: direct exits **0** each. Assertion counts: `check_local_test` **207**, `dead_words_vectors_test` **93**, `mutation_test` **53**, `rules_text_test` **144**, `rules_text_mutation_test` **38**, `install_preflight_test` **264**.
- `find scripts tests -type f -name '*.sh' -exec sh -n {} +`: direct exit **0**.
- `shellcheck --severity=warning -s sh` on extracted destination and source guard functions and `tests/install_preflight_test.sh`: direct exits **0**, **0**, **0**.
- `bash /tmp/claude-capability-mechanical.lrvqyWwX/probe.sh`: direct exit **0**, expected individual statuses and byte comparisons recorded above.
- `git diff --check c0bd879 b2fd255`: direct exit **2**, exactly the two added Markdown hard-break lines above.

No live canonical published-tag verification or actual installation was attempted; neither is part of this read-only review.
