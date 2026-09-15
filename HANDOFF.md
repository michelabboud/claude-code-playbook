# Handoff

**Current:** no session is mid-work. v0.1.12 is complete.

Where we are: the bundle is installable and swept clean of private references.
The macOS platform file is verified on real hardware; Linux and Windows are
written but unexecuted (see `BACKLOG.md`). The one edit a new user must make is
the git identity placeholder in `rules/WORKFLOW.md`.

The repository carries one branch, `main`, tracking `origin/main`. Before 0.1.9
the published branch was a local branch named `shipping` and the local `main`
was an unrelated abandoned root; they are now joined by a merge commit.
