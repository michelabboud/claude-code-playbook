# Backlog

Dated one-liners for everything deferred or spotted and not done.

- **2026-09-14 · verification · open** — `rules/platform/LINUX.md` commands have
  not been executed on Linux. Source: generalisation task. Needs one pass on a
  real Linux box.
- **2026-09-14 · verification · open** — `rules/platform/WINDOWS.md` commands
  have not been executed on Windows. The load-average mismatch found during
  review is now handled in-file (CPU% / 100, never also divided by cores, with
  0.85 as the heavy band), but that arithmetic has not been checked against a
  real busy Windows machine.
- **2026-09-14 · idea · open** — an install script (Unix shell + PowerShell)
  that backs up an existing `~/.claude/CLAUDE.md` before copying. Deliberately
  not written yet: it touches a file the user created, which rule 10.2 says to
  handle carefully, so it deserves its own small design rather than a
  convenience one-liner.
- **2026-09-14 · idea · open** — a short worked example showing one task running
  the full close-out chain end to end. The rules describe the chain; a new reader
  would benefit from seeing one.
- **2026-09-14 · hygiene · open** — the version now has **four** carriers:
  `VERSION`, the line in `CLAUDE.md`, the README table, and the eyebrow in
  `docs/index.html`. They drift — the published map shipped one version behind at
  v0.1.7 and had to be caught by hand. A check comparing all four before a commit
  is the fix; not written yet. Source: v0.1.4, widened v0.1.7.
- **2026-09-14 · rule question · open** — `INSTALL.md` requires a verified backup
  before overwriting anything, and treats a failed backup as a refusal. Applying
  the v0.1.7 fix overwrote two *already-installed* files without one, on the
  reasoning that both were byte-identical to a published tag and so trivially
  recoverable. That reasoning was not written down and the guide grants no such
  exception. Either add one — "an update may skip the backup when every file it
  replaces is byte-identical to a published tag" — or the rule stands as written.
  Needs a ruling; source: the first real install.
- **2026-09-15 · review · open** — the recovered report
  `docs/reports/2026-09-14-generalisation-conventions.md` came from the abandoned
  0.1.1 history and describes generalisation conventions as they stood before
  0.1.2. It has not been read against the current rules and may document
  superseded decisions. Either confirm it still holds, mark it historical, or
  supersede it. Source: the history merge in 0.1.9.
- **2026-09-15 · hygiene · open** — `PROGRESS.md` had drifted eight versions
  (stuck at "v0.1.0") in both histories before 0.1.9 touched it, which is the
  same drift already logged for the four version carriers. Whatever check gets
  written for those should cover `PROGRESS.md`'s own header line too.
- **2026-09-15 · rule change · awaiting decision** — the per-task documentation
  chain is expensive, and the fix is frequency plus a script, not a cheaper
  model. Full analysis, five options, the concrete rule edits and four batched
  questions in `docs/reports/2026-09-15-documentation-chain-cost.md`. Deferred by
  Michel to a session with budget to do it properly. Supersedes the narrower
  "version carriers drift" item above, which is Option 2 of this report.
- **2026-09-20 · measurement · open** — the ceiling of two unreviewed batches
  (rule 3.5) and the claim that a deep review lasts "one to three tasks" rest on
  one programme, a behaviour-preserving refactor. Needs the close-out metric
  (how often a line reached the ceiling) from at least one feature-work programme
  with real dependencies before the number is treated as settled. Source: v0.1.13,
  ADR 0001.
- **2026-09-20 · verification · open** — *why* context crossed the blind-review
  boundary between a session and its in-process subagent is a hypothesis
  (session-level injection: task notifications, file-change notices, memory,
  diagnostics), untested. One test settles it: give an in-process subagent a
  scratch directory outside the project and record which channels still fire.
  Rule 3.3 states only the effect until then. Source: v0.1.13.
- **2026-09-20 · rule question · open** — the roster gained a Strong tier between
  Standard and Top. Rule 8.1 still says risk domains (security, concurrency,
  unsafe code) *start on the Top tier* for implementation. With a Strong tier
  available, should they start there instead, keeping the Top tier for planning
  and review? Not decided; the wording was left as it was. Source: v0.1.13.
- **2026-09-20 · hygiene · open** — the roster now has **three** display copies
  besides `rules/ROSTER.md`: the README table, the published page, and ADR 0001's
  prose. The first two are marked as copies and will drift exactly as the version
  carriers do; the check proposed for those should cover the roster too, and the
  rule count ("fifty") in README, `docs/ANNOUNCE.md` and the page. Source: v0.1.13.
- **2026-09-20 · discrepancy · open, cause unconfirmed** — the 0.1.9 and 0.1.11
  changelog entries say four tags were published to the remote. On 2026-09-20
  `git tag -l` and `git ls-remote --tags origin` both return nothing, and there
  are no GitHub releases. Either the tags were removed afterwards (which rule 6.4
  forbids and the changelog does not record) or those entries are wrong. v0.1.13
  was therefore **not tagged** — adding one is reversible, removing one is not.
  Needs the owner's word: what happened to the tags, and should this repo carry
  `checkpoint/` tags at all. Source: v0.1.13 close-out.
