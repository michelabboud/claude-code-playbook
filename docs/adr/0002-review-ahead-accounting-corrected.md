# 0002 — The review-ahead accounting, corrected

- **Status:** accepted, 2026-09-20. **Amends ADR 0001** (decision 3 and its consequences);
  0001 is left as written.
- **Rules it changed:** 3.3 and 3.5 in `rules/REVIEWS.md`; one example in `rules/WORKFLOW.md`.

## Context

ADR 0001 was written, implemented and published as 0.1.13 in one session. The same day, the
rule was put in front of an independent reviewer from another model family — reviewing a plan
to port it to the Codex edition of this rulebook, as a separate process, against a pinned
commit, with a cold-read note first. It returned eleven findings. All eleven were confirmed
against the pinned commits; five were defects in rule 3.5 and rule 3.3 themselves.

This is the rule doing its job on itself, within hours: the second family found what the
author's family could not see in its own sentence.

## Decision

1. **The ceiling counts closed batches.** "At most two closed, unruled batches under a line's
   tip, plus the one being built." 0001's wording allowed batch N+2 to start and also said "a
   third never starts" — with N and N+1 closed and N+2 building, three ranges are exposed. The
   owner's intent (N+2 may start, so a review outage does not halt development) is kept and
   stated honestly: **worst case three batch ranges**, not the "double" 0001 implied.
2. **A merge is a union, not a sum.** 0001 said "a merge adds the counts"; a shared unruled
   ancestor would count twice. The count is the set of unruled batches with any commit
   reachable from the tip. Ancestry cannot see cherry-picks, squashes or copied code, and a
   ruling clears a line only when its fixes are reachable from it.
3. **The coordinator keeps a ledger, and one coordinator admits work.** Git knows ancestry, not
   which commits form a batch, which reviews are owed, or whether one was ruled.
4. **Every lower review is settled before a high deep gate — mechanical included**; a review
   that died or timed out is still owed. The gate's candidate is frozen.
5. **A finding's impact decides what it stops, never the kind of review that found it.**
   "A mechanical finding is local" was an overclaim.
6. **"Commit only that path", index checked first** — not "stage only that path".
7. **Blindness controls are controls, not proof**; the cold-read note comes after the brief and
   the material under review; a fork of the coordinating session is never a blind reviewer; a
   reviewer that cannot write returns its notes through its reply, and its permissions are
   never widened to make the rule look satisfied.

## Alternatives rejected

- **Two slots including the batch being built** — the reviewer's own preference. Literal and
  simplest to enforce, exposure two ranges. It is ADR 0001's rejected ceiling of one under
  another name: any slow review halts the line. The owner had already weighed that trade; what
  he was owed was the corrected cost, which this ADR records.
- **Keeping 0001's prose and adding a clarifying footnote.** A rule that needs a footnote to
  say what it counts will be enforced two ways. Rewritten instead.
- **Counting from git alone, without a ledger.** Cannot be computed: a batch is not a git
  object.

## Consequences

- The Codex edition ports the corrected text, so its rule 3.5 is a direct port.
- The search that "verified" no model was named outside `rules/ROSTER.md` matched capitals
  only and missed a lower-case example in `rules/WORKFLOW.md`. Fixed; the lesson — a check that
  passes is a claim about the check — goes in `BACKLOG.md` with the carrier-drift item.
- The evidence base is unchanged and still one friendly programme. The close-out metric stands.
