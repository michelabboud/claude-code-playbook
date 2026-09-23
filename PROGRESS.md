# Progress & current standing

**Last updated:** 2026-09-23 (v0.1.16, local unpublished source-trust repair; second pinned re-review pending).

**Latest gate:** two pinned reviews of `5441cd8` failed despite all six suites
passing. Both independently reproduced an inherited-`GIT_DIR` bypass of the
canonical tag lookup; the deep review also reproduced an external overwrite
through a hard-linked managed file. The mechanical review found a newline-path
acceptance and false first-install prerequisite text. All four findings now
have local repairs and disposable regressions. The full six-suite rerun passed
with 207, 93, 53, 144, 38, and 262 assertions, direct exit 0. A focused
review of the repaired exact commit is still owed. No tag, push, or live
installation has occurred.

**Current hold:** the independent review of `2606360` also failed on three
recursive preflight/uninstall safety gaps. All are repaired in the current
unpublished worktree, with symlinked-root and wrong-platform regressions. New
plan execution, communication, model, and log-ignore guidance is included.
Nothing is published until the repaired candidate passes its suites and
focused independent reviews.

Both GPT-6 Sol reviews of `ab05129` failed on the no-backup uninstall of an
owner-edited managed file. A separate content preflight, exercised against
clean, edited subject-rule, and edited platform fixtures, now refuses
unproven deletion. Documentation contradictions are repaired. This is still
unpublished and needs a focused re-review.

The GPT-6 Sol focused review of `03fcf9b` failed: backup restore could lose
later edits, linked roots could redirect deletion, and source provenance was
only asserted in prose. The current worktree extends fail-closed preflight to
both uninstall paths, checks a clean tagged release, refuses linked roots,
and requires a fresh current snapshot. New fixtures cover these cases; a full
suite and independent review are still owed.

The deep and mechanical GPT-6 Sol reviews of `a20bca7` failed on checkout
provenance and pre-verification script execution, plus linked-root handling in
update and migration. The mechanical reviewer reproduced a deletion guard
bypass using a tracked source file marked `assume-unchanged`. The six local
suites passed, but publication is held. The owner approved canonical published
source verification with explicit full fork pins as the only alternative;
ADR 0010 records it. The current local candidate adds a source guard, linked
destination and managed-file guards, and red-to-green lifecycle regressions.
The six-suite run exited 0 (207, 93, 53, 143, 38, and 243 assertions); pinned
independent GPT-6 Sol re-reviews remain the publication gate. No tag or push
has occurred.

The focused repair covers encoding-safe Override detection, normalized heading
uniqueness, all-destination migration preflight, uninstall/restore refusal while
local files remain active, and the guide/map's current authority contract. The
Linux shell fixtures test those paths without changing any real installation.
The `a7e690e` deep re-review found a plus-bullet silent skip and a recursively
loaded extra-Markdown blind spot. Both are fixed in the current local repair;
the owner approved refusing extra Markdown under `rules/` on 2026-09-23.
Neither playbook is published on the strength of passing tests alone.

The bundle is complete and installable: thirteen numbered sections across
fourteen rule files, the model roster (`rules/ROSTER.md`, the only file that
names a model), three platform files, a README, and an optional-tools note.
Every rule file has been swept for private references and none remain.

**Nothing installed needs editing.** Customizations live in a local layer —
`rules/LOCAL.md` and `rules/LOCAL_dev.md`, two files this repository never
ships and an update never writes to, copies over or replaces — so an update is a
copy plus a check rather than a merge. `scripts/check-local.sh` verifies every
live Override's anchored section digest and unique substantial quotation
against the new text before anything is copied; `templates/` holds the
starting points, deliberately outside `rules/`, which the harness loads
recursively.

**Verified:** every command in `rules/platform/MACOS.md` was executed on real
macOS hardware and confirmed working, including negative controls for the four
tools that file claims are absent on a stock install. The `sha256sum` control
found the tool *present* on the test machine (outside both the stock system and
Homebrew), which is recorded in the file as a portability trap rather than
silently ignored.

**Measured once, on a friendly case:** the ceiling of three unruled batches per
line (rule 3.5) rests on one behaviour-preserving refactor programme. Close-outs now
record how often the ceiling was reached; revise the number on that evidence.
See `docs/guides/non-blocking-review-pipeline.md` and ADR 0001.

**Test coverage:** six POSIX-`sh` suites cover `scripts/check-local.sh`, the
rulebook's own text, and executable migration/uninstall preflights. Two
are mutation harnesses: they break one behaviour at a time in a
scratch copy and require the suite to notice, naming the assertion that caught
it, so a green run is evidence rather than a habit. Run them with
`sh tests/run.sh`.

**Not yet verified:** the Linux and Windows platform files have not been
executed on their own operating systems. The Windows load measurement is flagged
in-file as CPU-percentage, not a true load average — the concurrency formula in
rule 8.1 assumes a load average, so a Windows user should read that note before
trusting the cap.

**Repository shape:** one history on `main`, tracking `origin/main`. Until 0.1.9
the published branch was a local branch named `shipping` and the local `main` was
an unrelated abandoned root — see the 0.1.9 changelog entry if an old clone or
checkout looks wrong.

**Next:** run each platform file's commands on its own OS and record the result
here.
