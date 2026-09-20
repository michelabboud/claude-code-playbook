# Progress & current standing

**Last updated:** 2026-09-20 (v0.1.15 — rule 3.5's boundary corrected after a second independent review, and its admission semantics after a third, before publication; worked cases are now part of the rule)

The bundle is complete and installable: thirteen numbered sections, fifty rules,
the model roster (`rules/ROSTER.md`, the only file that names a model), three
platform files, a README, and an optional-tools note. Every rule file has been
swept for private references and none remain.

**Verified:** every command in `rules/platform/MACOS.md` was executed on real
macOS hardware and confirmed working, including negative controls for the four
tools that file claims are absent on a stock install. The `sha256sum` control
found the tool *present* on the test machine (outside both the stock system and
Homebrew), which is recorded in the file as a portability trap rather than
silently ignored.

**Measured once, on a friendly case:** the ceiling of two unreviewed batches
(rule 3.5) rests on one behaviour-preserving refactor programme. Close-outs now
record how often the ceiling was reached; revise the number on that evidence.
See `docs/guides/non-blocking-review-pipeline.md` and ADR 0001.

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
