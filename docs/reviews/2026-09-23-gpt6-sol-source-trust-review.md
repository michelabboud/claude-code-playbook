# GPT-6 Sol source-trust review — 2026-09-23

**Reviewed commit:** `a20bca7` (base `03fcf9b`). **Verdict: FAIL.**
No tag, push, or real installation follows this review.

The fresh read-only GPT-6 Sol deep reviewer confirmed that the earlier
backup-overwrite and linked-uninstall-root gaps were addressed, but found
three material trust-boundary blockers. An independent GPT-6 Sol mechanical
review found a fourth:

1. `INSTALL.md`'s uninstall preflight executes the supplied checkout's
   `scripts/check-local.sh` before validating that checkout. A dirty or
   substituted source can run arbitrary shell code even if the later content
   guard refuses the operation.
2. A clean local worktree plus locally created `checkpoint/<VERSION>` tag does
   not prove the published release. The test fixture itself creates such a
   repository and tag. A forged source matching owner edits can therefore
   classify those edits as managed and authorize overwrite/deletion.
3. Update and migration still permit linked configuration/rules roots, while
   uninstall now refuses them. Their copy steps can write through the link
   into an external tree.
4. The uninstall guard treats `git status --porcelain` as proof that a tagged
   source matches its commit. A tracked file marked `assume-unchanged` can be
   edited without appearing in status. The mechanical reviewer reproduced a
   tagged fixture in which both source and installed `AUTHORITY.md` were
   owner-edited: status was empty and the uninstall guard exited 0, allowing
   those bytes to be overwritten or deleted. The same risk needs assessment
   for `skip-worktree`; that variant was not reproduced.

The reviewer also noted that fresh-snapshot completeness and an intervening
symlink swap have procedural wording, not executable tests. README's manual
recipe now correctly selects one platform file.

The mechanical reviewer ran the pinned full suite to completion, **exit 0**
with all six suites passing, including install preflight **130/130**. Syntax
and diff checks exited 0. `shellcheck` exited 1 solely on the pre-existing
dynamic `HOOK2` use in the rule-text mutation test. Separately, the
coordinator's full six-suite run on the repair worktree exited 0 with counts
207, 93, 53, 143, 38, and 130. These checks do not override the review's
FAIL or prove the trust boundary safe.

**Decision required before repair:** choose the source of authority for a
playbook checkout. Recommended: validate the exact commit against the
canonical public repository's published ref over an authenticated transport
*before executing any staged script*, and require an explicit owner-approved
commit pin for a fork. With no verifiable source, refuse automated mutation
and preserve all files. Apply the same linked-root refusal to every mutating
path. Compare every staged managed source file, `VERSION`, and `CLAUDE.md`
against authenticated commit blobs rather than trusting worktree status, then
add adversarial fixtures for early code execution, forged local tags,
`assume-unchanged`/`skip-worktree`, linked roots, and failed verification.
