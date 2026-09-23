# Progress & current standing

**Last updated:** 2026-09-23 (v0.1.16, local unpublished repairs; pinned focused deep review failed).

**Current hold:** the independent review of `2606360` also failed on three
recursive preflight/uninstall safety gaps. All are repaired in the current
unpublished worktree, with symlinked-root and wrong-platform regressions. New
plan execution, communication, model, and log-ignore guidance is included.
Nothing is published until the repaired candidate passes its suites and
focused independent reviews.

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
