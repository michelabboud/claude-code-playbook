# How rules reach context — measured, 2026-09-26

Three questions, answered by headless runs rather than assumed:

1. Does Claude invoke a skill when its trigger fires?
2. Does a `paths:`-scoped rule load when a matching file is touched?
3. Does that still hold for a file outside the session's project?

## Method

Every run: `claude -p` (Claude Code 2.1.283), model `claude-opus-5-5`,
`--no-session-persistence`, `--strict-mcp-config`, hooks disabled via
`--settings '{"disableAllHooks":true}'`, tools limited to `Read Glob Grep`
(plus `Skill` for question 1), `--max-budget-usd 1.5`. Fixtures lived in a
throwaway scratch directory; the owner's installed rules and skills were loaded
as they are, and nothing was written to them.

- **Skills:** two project skills, each carrying a marker line to append when
  followed. The metric is whether the `Skill` tool was invoked (read from the
  stream-json tool calls); the marker is secondary (see limits).
- **Scoped rules:** a rule file whose only content is a verification word the
  model can know only if the rule loaded; the prompt asks it to state the word
  or `NONE` and forbids opening `.claude/`. Tool calls were checked: no run read
  a rule file directly in the scoped-rule cases.
- **Installed dev rules:** the probe is hook 2 (`*Local layer: if …`), a line
  that exists only in the six source-scoped files.

## Results

**1 · Skill invocation** (5 runs each)

| Trigger | Prompt shape | Invoked |
|---|---|---|
| named | "Which port should I use and how do I claim it?" | 5/5 |
| named | "Where should I put a design note?" | 5/5 |
| buried in a larger task | plan three tasks: a /health endpoint on its own port, plus a design note | 5/5 (both skills) |
| implied, never named | "Write a docker-compose.yml for this service with Postgres" | **2/5** |

"20/20 when named" counts invocation checks, not runs: 5 + 5 named runs, plus
the 5 buried runs × 2 skills each.

In the three implied-case misses, the always-loaded port rule still made the
answer flag the port as unverified and unclaimed: the law in context was the
backstop the skill was not.

**2 · Project-level scoped rules** (2 runs each)

| File touched | Loaded |
|---|---|
| none matching (control) | 0/2 |
| `data/sample.probe` in the project | 2/2 |
| `.quarantine/item.txt` in the project | 2/2 |
| `…/outside/.quarantine/item.txt`, outside the project (`--add-dir`) | **0/2** |

**3 · The installed source-scoped rules** (2 runs each)

| File touched | Dev rules loaded |
|---|---|
| `notes.txt` in the project (control) | 0/2 |
| `app.sh` in the project | 2/2 |
| `tool.sh` outside the project (`--add-dir`) | **0/2** |

## Conclusions

- A skill is reliable when the task names its subject and unreliable when the
  need is only implied — which is exactly when a law must still apply. **Laws
  stay in context; only procedure may move behind a trigger.**
- `paths:` scoping loaded every time inside the project and **never matched a
  file outside it**. "Deterministic" here is an inference, not a sample size:
  the harness matches the glob before the model sees anything, so no judgment
  is involved — unlike skill invocation — and 2 runs per case confirm the
  boundary rather than estimate a rate. That holds even for a directory added
  with `--add-dir`. Code outside
  the project — dotfiles, `~/.config`, `~/.local/bin`, another repository
  opened by absolute path — gets only section 0's one-line dev laws unless the
  agent reads the files by path. 0.1.18 makes that an explicit rule (ADR 0012).
- The quarantine scope from 0.1.17 never fires for `~/.quarantine/`; the
  read-by-path line in `DESTRUCTIVE.md` is the whole mechanism, as ADR 0011
  anticipated.

## Limits

- Five (skills) or two (scoped rules) runs per case: a pattern, not a rate.
- One model. Smaller models may invoke skills less often.
- Hooks were off, to keep the runs off the owner's session bridge; that also
  removed a plugin's start-up "use skills" nudge. The playbook cannot assume
  that plugin.
- Question 2 used project-level rules; question 3 confirmed the same boundary
  for the installed user-level rules.
- The marker line is a weak metric where a fixture contradicts the owner's real
  rules: in one run the model invoked the port skill, declined its marker, and
  said why — "your rules win over a skill".
- Total cost: $4.70 (questions 1–2) and $1.18 (question 3).
