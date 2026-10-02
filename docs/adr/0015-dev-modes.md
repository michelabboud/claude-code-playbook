# 0015 — Dev modes set review depth and the security bar

- **Status:** accepted, 2026-10-02 (the owner: "the AI wastes TONS of time and tokens on extreme edge cases … security is very important, but we do not need to solve every exotic edge case before v1"; "we should make different level of security for different dev modes"; "add extra-hardening to be its own phase after production"; "add a skill for /dev-mode"; "the dev mode should affect the amount and type of code review"; "you have my go for both playbooks").
- **Scope:** new `rules/DEV_MODES.md` (section 14) and `skills/dev-mode/SKILL.md`; rules 3.1–3.5, 7.1 and 7.4; the installer's trust, copy, verify and uninstall lists.

## Context

Reviews asked to make an app "production ready" spent most of their effort on
exotic security edge cases, and every finding was validated against source
before it reached the owner. Rule 3.2 sent every security-flavoured task to a
deep review at task grain, so the cost landed on the schedule as well as the
token bill. Nothing in the rulebook said how much review or how much security a
throwaway test owes compared with a live product holding personal data.

## Decision

1. **A project has a dev mode** — spike, poc, mvp, production, sensitive — one
   line in its `CLAUDE.md`. Only the owner changes it; the data sets a minimum
   (real personal, financial or health data means sensitive).
2. **The mode scales section 3's ladder:** from no review in a spike to per-task
   deep reviews on floor work in sensitive. An MVP's milestone review is
   pipelined, not a gate; the release review gates wherever a release happens.
3. **A floor holds in every mode** (secrets, injection, unauthenticated
   exposure, data loss, dependency vetting), and a floor finding always blocks.
4. **No attack story, no blocker.** A security finding blocks when its
   who / through what / what they get is open at the current mode. Otherwise it
   is due at a higher mode or at hardening. Downgrading takes a reason, and an
   incomplete story counts as realistic, so the burden sits on the downgrade.
5. **Effort follows the class:** non-blocking findings get one line from the
   reviewer and go to the backlog unverified. Only realistic ones are validated
   against source.
6. **A security backlog keeps every finding**, with the mode it is due at. Open
   realistic entries stay out of a public tree.
7. **Moving up a mode starts a hardening phase**, with the owner's move as the
   go for its plan. **Extra hardening is its own phase after production**, on
   its own line, never blocking a release.
8. **Security is designed in:** every plan opens with a threat sketch, and splits
   into independent lines so development runs in parallel while reviews run.
9. **`/dev-mode` is a shipped skill with `disable-model-invocation: true`**, so a
   mode change is mechanically the owner's word, not an agent's judgment.

## Alternatives rejected

- **Lower the bar for everyone.** The floor exists because some defects are
  never acceptable, even in a demo: a leaked secret is leaked for good.
- **Skip security review before v1.** The owner rejected it outright, and
  retrofitting authentication or a data model is the expensive path.
- **Let the agent pick the mode.** A deadline would always argue for a lower one;
  the mode is the owner's risk decision.
- **A tracked backlog everywhere.** In a public repository an open, realistic
  finding is a map for an attacker.
- **Mode as a local-layer Fill.** The mode belongs to a project, not a machine,
  and a local layer may not relax a review.

## Consequences

- Sixteen managed rule files and one managed skill; the installer's staged-tree
  check expects 21 rules entries and 3 skills entries.
- The installer touches exactly one folder under `~/.claude/skills/`, and stops
  on a first install if the user already has a skill named `dev-mode`.
- Behaviour-suite ADR numbers move up again, to 0016–0020.
- The risk that an agent labels a real finding "exotic" is bounded by the
  required reason and by the release review re-reading the backlog. It is not
  eliminated.
