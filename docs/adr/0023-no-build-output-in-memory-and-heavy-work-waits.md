# 0023 — Build output never lives in memory, and heavy work waits for a quiet host

- **Status:** accepted, 2026-10-16 (the owner: "check the codex-playbook repo and see if we can fix the hygiene protocol", then "yes"; and "it did not check computer load as well, that alone should have caused a pause").
- **Scope:** rules 13.1, 13.4 and 13.5 (`rules/HYGIENE.md`); new rule 9.7 (`rules/ENVIRONMENT.md`); one clause in rule 8.1 (`rules/SUBAGENTS.md`); one or two rows in every platform file; the section table in `CLAUDE.md`.

## Context

On 2026-10-15 a lane building a Rust project set its cargo target directory to
`/dev/shm`. The disk was at 96 % used with the owner's floor at 3 % free, so the
one filesystem with room was the memory-backed one; nothing in the rules said
it was off limits. The build finished, the lane ended, and 44 GB stayed resident
in RAM for 26 hours — invisible to every disk measurement, and never anyone's to
remove: a build target is "regenerable and idle" (rule 13.1), a class with no
owner and no close-out duty. On 2026-10-16 four Rust builds started at once on
the same machine. Available memory was 2.8 GB of 94, swap was full, and more than
half the host's time was stalled on memory; the load reached 145 on 28 cores.
None of the four lanes had measured the host: rule 8.1 measures only before a
*fan-out of subagents*, and a lane's own `cargo build` is not one.

Section 13 as written only measured disk and only governed removal. Nothing
said where build output may live, nothing obliged a lane to remove the target
it created, and nothing watched memory or load once work was under way.

## Decision

1. **Rule 13.4:** build output and large scratch never live on a memory-backed
   filesystem (`/dev/shm`, any tmpfs, a RAM disk). A lane checks the filesystem
   type of a target path before using it; the platform file gives the command.
   No room on disk means the disk needs the hygiene procedure, never that memory
   is the next disk.
2. **Rule 13.1:** a build target a lane created for itself outside the
   repository's own output folder is in the "disposable, created by this
   session" class — removed at the lane's close-out, never left for a later
   sweep. The shared `target/` stays in the regenerable-and-idle class.
3. **Rule 13.5:** hygiene also runs when available memory falls below a floor
   (the local layer's value, 10 % of the machine's memory otherwise) or a
   memory-backed filesystem is more than a quarter full. Memory-backed items are
   the first candidates in the report. The platform files gain the measurements.
4. **Rule 9.7, new, always loaded:** heavy work — a build, a full test suite, a
   fan-out — waits for a quiet host. Load is read as a factor, load ÷ cores,
   in three bands the owner named on 2026-10-16 for a 28-core machine ("up to 25
   is green, up to 35 to orange, above 50 is red", then "or we should calculate
   according to available cores"): green below 0.9 starts; orange, 0.9 to 1.8,
   starts nothing new and heavy; red, 1.8 and above or available memory below
   the floor, pauses a running lane before its next heavy step too. The step
   waits and re-measures; a running lane measures again before each heavy step.
   Rule 8.1 points at it. The gap the owner left between 35 and 50 is read as
   the top of orange; the local layer may state the absolute numbers for one
   box.

## Alternatives rejected

- **A rule against `/dev/shm` only.** The tell is the filesystem's nature, not
  its name: a `tmpfs` mounted anywhere, or a RAM disk on another platform, is the
  same leak. The platform file gives the type check instead.
- **Leave removal to the regenerable-and-idle sweep.** That class has no owner
  by design (rule 13.2), which is exactly why the target sat for 26 hours. The
  lane that made a private target is the one party that knows it is done with
  it; close-out is the moment.
- **Fold the load check into rule 8.1.** Rule 8.1 loads only with source-scoped
  work and speaks of fan-outs; a planning session that runs a test suite, or a
  lane mid-build, needs the rule in front of it every session. Section 9 is
  always loaded and already carries the host's operational guardrails.
- **Rule 8.1's four bands, reused as they stand.** They size a fan-out; they
  say nothing about pausing work already under way, and "heavy, above 1.0"
  would halt a lane on a machine the owner calls orange. Rule 9.7 keeps its own
  three bands with a red line at 1.8 and points back at 8.1 for sizing.
- **A fixed memory floor or tmpfs ceiling in the playbook.** As with the disk
  floor (ADR 0014), machines differ; the local layer sets the floor and the
  playbook's values are fallbacks.
- **Raise the owner's 3 % disk floor instead.** That is the local layer's value
  and the owner's call. The rules must hold on a full disk too: the correct
  failure is a lane that waits for disk, not one that leaks into RAM.

## Consequences

- A lane on a full disk now stalls and reports rather than building in memory.
  That is the intended failure; the disk hygiene pass is the fix, and it is now
  triggered by the memory floor as well.
- Every platform file carries one or two more rows; the Linux one gains the
  `findmnt` type check and the `shared`-column tell.
- Section 9's header reads 9.1–9.7. No gate is added: rule 9.7 makes a step
  wait, never ask.
- The Codex edition ports the same in its next version.
