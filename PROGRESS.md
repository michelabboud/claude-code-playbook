# Progress & current standing

**Last updated:** 2026-09-21 (v0.1.16 — customizations moved into a local layer the playbook never touches, with a script that proves an override still bites before an update copies anything)

The bundle is complete and installable: thirteen numbered sections across
fourteen rule files, the model roster (`rules/ROSTER.md`, the only file that
names a model), three platform files, a README, and an optional-tools note.
Every rule file has been swept for private references and none remain.

**Nothing installed needs editing.** Customizations live in a local layer —
`rules/LOCAL.md` and `rules/LOCAL_dev.md`, two files this repository never
ships, copies over or opens — so an update is a copy plus a check rather than a
merge. `scripts/check-local.sh` proves every **Dead words:** quotation still
exists in the new text before anything is copied; `templates/` holds the
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

**Verified by test, on every change:** four POSIX-`sh` suites — 197 assertions
in total — over `scripts/check-local.sh` and over the rulebook's own text. Two
of the four are mutation harnesses: they break one behaviour at a time in a
scratch copy and require the suite to notice, so a green run is evidence rather
than a habit. Run them with `sh tests/run.sh`.

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
