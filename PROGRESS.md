# Progress & current standing

**Last updated:** 2026-09-14 (v0.1.0 — first distributable release)

The bundle is complete and installable: thirteen numbered sections, three
platform files, a README, and an optional-tools note. Every rule file has been
swept for private references and none remain.

**Verified:** every command in `rules/platform/MACOS.md` was executed on real
macOS hardware and confirmed working, including negative controls for the four
tools that file claims are absent on a stock install. The `sha256sum` control
found the tool *present* on the test machine (outside both the stock system and
Homebrew), which is recorded in the file as a portability trap rather than
silently ignored.

**Not yet verified:** the Linux and Windows platform files have not been
executed on their own operating systems. The Windows load measurement is flagged
in-file as CPU-percentage, not a true load average — the concurrency formula in
rule 8.1 assumes a load average, so a Windows user should read that note before
trusting the cap.

**Next:** run each platform file's commands on its own OS and record the result
here.
