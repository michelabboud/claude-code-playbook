# 0012 — Path scopes stop at the project; code outside it reads the dev rules by path

- **Status:** accepted, 2026-09-26 (owner approved the fix after the measurement).
- **Scope:** section 0's header and `CLAUDE.md`'s loading paragraph. Amends ADR 0011's "unverified" consequence with a measurement.

## Context

The six source-scoped files (`CODE`, `TESTING`, `WORKFLOW`, `SUBAGENTS`,
`REVIEWS`, `ROSTER`) and `LOCAL_dev.md` load through a `paths:` scope. Measured
on 2026-09-26 (`docs/reports/2026-09-26-loading-measurements.md`), the scope
loads them 2/2 for a `.sh` file inside the session's project and **0/2 for a
`.sh` file outside it**, including a directory added with `--add-dir`. The same
boundary makes 0.1.17's quarantine glob inert for `~/.quarantine/`.

Much real work is outside any project: dotfiles, `~/.config`, `~/.local/bin`,
another repository opened by absolute path. There, only section 0's one-line
dev laws were in context, and nothing told the agent that the full rules had not
loaded.

## Decision

Section 0's header and `CLAUDE.md` state the boundary and the duty: path scopes
match only files inside the session's project; before writing or changing code
outside it, read `CODE.md` and `TESTING.md` by path — and `LOCAL_dev.md` if it
exists — and the other dev files when their own triggers fire.

## Alternatives rejected

- **Widen the globs.** A `paths:` pattern is matched inside the project; no
  pattern reaches `~/.config`. Measured, not assumed.
- **Make the dev files always loaded.** Undoes the context budget for every
  session to cover one case a sentence covers.
- **Move the dev rules into skills.** Measured 2/5 invocation when the need is
  implied; strictly worse than a scope plus a stated duty.
- **A hook that injects the dev rules on out-of-project edits.** Deterministic,
  but the playbook ships rules, not harness settings; a hook is an owner-side
  choice and would bypass the local layer's contract. Recorded as an idea.

## Consequences

- Out-of-project code work depends on the agent following an always-loaded
  instruction, the same mechanism the quarantine procedure relies on.
- ADR 0011's open question about the quarantine glob is answered: it does not
  fire for a vault outside the project; read-by-path is the mechanism.
