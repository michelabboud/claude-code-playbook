# Handoff

**Current:** no session is mid-work. v0.1.14 is complete.

Where we are: the bundle is installable and swept clean of private references.
The macOS platform file is verified on real hardware; Linux and Windows are
written but unexecuted (see `BACKLOG.md`). The one edit a new user must make is
the git identity placeholder in `rules/WORKFLOW.md`; the one file worth checking
against their own setup is the model roster, `rules/ROSTER.md`.

v0.1.13 made reviews non-blocking (rules 3.3 and 3.5, ADR 0001) and moved every
model name into `rules/ROSTER.md`. v0.1.14 corrected rule 3.5's accounting the
same day, after an independent review of the Codex port plan (ADR 0002).

**How this repository is worked (the owner's word, 2026-09-20):** every update
goes straight to `main` — no feature branches — and each task's commit gets a
`checkpoint/<VERSION>` tag, pushed. `checkpoint/0.1.13` is the first one.

The repository carries one branch, `main`, tracking `origin/main`. Before 0.1.9
the published branch was a local branch named `shipping` and the local `main`
was an unrelated abandoned root; they are now joined by a merge commit.
