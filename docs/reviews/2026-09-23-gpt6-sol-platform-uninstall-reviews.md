# GPT-6 Sol reviews of the held Claude candidate — 2026-09-23

**Reviewed commit:** `ab05129` (base `2606360`). **Verdict: FAIL.**
The repaired worktree described below has not yet been reviewed.

Two independent read-only GPT-6 Sol agents reviewed pinned archives: one
mechanical pass and one deep pass. Neither edited the repository. Both ran the
six-suite `sh tests/run.sh` with direct exit 0 (207 checker, 93 vector, 53
parser-mutation, 143 rule-text, 38 text-mutation, and 112 install-preflight
assertions). Syntax and diff checks also exited 0. Native macOS/Windows and
an actual uninstall were not run.

## Confirmed blocker

The no-backup uninstall deletes exact named managed files after a checker that
only validates path membership, not file contents. A user can edit
`rules/AUTHORITY.md` or the installed platform file after first install;
both reviewers reproduced a clean preflight on such a fixture. Deletion would
lose the edit without a backup. This is confirmed independently of the green
suite and blocks publication.

## Other findings

The mechanical reviewer found that README allowed keeping all three installed
platform rules, contrary to the host-only preflight, and claimed the visual
page needs no network despite its optional Google Fonts stylesheet. The deep
reviewer found `INSTALL.md`'s phrase “every `.md` file in `rules/`” ambiguous
beside its single-platform step. These documentation mismatches are confirmed.

## Repair to re-review

An executable separate no-backup content guard now compares all deletion
targets with a trusted clean checkout of the exact installed release and
refuses a mismatch. Its test was red before the guard and passes with clean,
edited subject-file, and edited platform-file fixtures. README and INSTALL
wording now agree on one installed platform file and the page's optional font
network request. A new pinned GPT-6 Sol review is owed before publication.
