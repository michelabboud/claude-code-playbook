# 0022 — Claude Haiku 5.5 is qualified for the mechanical review seat

- **Status:** accepted, 2026-10-10 (the owner: "add haiku5.5 as valid mechanical model for code-review").
- **Scope:** `rules/ROSTER.md` (a new mechanical review seat table and its evidence paragraph); rules 3.1 and 8.1 and section 0's summary, which now say "never an unqualified Fast model"; README and site.

## Context

Since September 2026 mechanical review ran on the Standard tier only. The reason was measured:
on one file with nine real defects, the Haiku of that time found five and Sonnet found all nine,
and what Haiku missed sat inside the classes the brief named. The rule was written as "never the
Fast tier", which tied the exclusion to the tier rather than to the model that was measured.

Claude Haiku 5.5 arrived on 2026-10-10. A first comparison the same day, against GPT-6 Luna,
found all ten seeded defects in a 175-line file in both runs with no decoy reported, and on a real
446-line file found the one known subtle defect in both runs plus eight or nine further real
defects per run, against two or three for Luna. That comparison is two runs, one hard file, and
not blind: its author wrote the fixtures and judged the answers. The owner then admitted Haiku 5.5
to the mechanical review seat.

## Decision

1. The roster names the **mechanical review seat** and the models qualified for it: the Standard
   tier, and Claude Haiku 5.5. Earlier Haiku models are named as not qualified, and so is GPT-6
   Luna until it passes the nine-defect comparison.
2. Rules 3.1 and 8.1 say mechanical review runs on the Standard tier or a roster-qualified model,
   never on an **unqualified** Fast model. No rule outside the roster names a model.
3. Haiku 5.5's qualification rests on the owner's word and one first comparison; a review run on
   it says so in its header until a broader comparison is recorded in the roster.
4. Haiku 5.5 does not move up a tier: it fills the mechanical review seat and the Fast tier's
   mechanical work, nothing else.

## Alternatives rejected

- **Move Haiku 5.5 into the Standard tier.** The Standard tier also carries multi-file
  implementation, and nothing here measured that.
- **Keep it as an extra reader beside the lane until three real reviews are scored** — the first
  evaluation's own recommendation. The owner chose to admit it now; the scoreboard in the owner's
  local layer keeps checking it on real reviews.
- **Drop the Fast-tier exclusion altogether.** The September measurement still describes earlier
  Haiku models, and a seat qualification is per model, not per tier.

## Consequences

- Mechanical review gets cheaper and faster where Haiku 5.5 runs it, and on the first evidence
  broader. The risk is that one hard file over-states it; the header note and the scoreboard keep
  that visible.
- The roster now owns seat qualifications as well as tier assignments, so a future model can be
  admitted to a review seat without a change to the rules that name roles.
