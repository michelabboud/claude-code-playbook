# The cost of the per-task documentation chain

**Status:** proposal, awaiting decision. Nothing here is implemented.
**Written:** 2026-09-15 · **Author:** Claude Opus 5, at Michel's request
**Becomes an ADR when decided** — it has multiple viable options with real
trade-offs and it rejects an obvious alternative, which is rule 4.2's test.

---

## 1. The question

Michel's observation, in his words: *"updating docs is a very expensive action
when done after each task."* His proposal: *"can we update the rules so
documents will run on its own sub-agent with a mechanical model, is this right
to do, will a low cheap mechanical model be able to update documents
correctly? Or maybe something like Sonnet instead of Opus or Fable."*

So there are two questions, and they have different answers:

1. Is the documentation chain too expensive at per-task frequency? **Yes.**
2. Is "delegate it to a cheap model" the right fix? **No — not as stated.**

---

## 2. Recommendation, ranked

| # | Change | Expected saving | Quality risk | Verdict |
|---|---|---|---|---|
| 1 | Move the doc chain from **per-task to per-batch** | Largest — proportional to tasks per batch | None | **Do this first** |
| 2 | **Script** the mechanical half (version carriers) | Eliminates a whole class, permanently | None — it *improves* correctness | **Do this second** |
| 3 | A **Sonnet drafter** subagent at batch boundaries only | Modest | Some, bounded | Only after 1 and 2 |
| 4 | A cheap mechanical model writing **all** docs | Modest | High | **Rejected — see §6** |
| 5 | Do nothing | — | — | Baseline |

The headline: **the cost driver is frequency, not model tier.** Changing how
often the chain runs is worth more than changing who runs it, and it carries no
quality risk at all. Reaching for a cheaper model first would be optimising the
second-biggest lever while accepting the only real downside on the table.

---

## 3. The load-bearing distinction

"Updating docs" is two different jobs sharing one name. Every recommendation
above follows from separating them.

### 3a. The mechanical half

Version carriers, dates, table rows, index entries, link integrity. Fully
deterministic: given a new version number, the correct edit to every carrier is
computable with no judgment whatsoever.

**No model should do this work at all.** Not Opus, not Sonnet, not Haiku. A
script does it faster, for free, and — critically — *the same way every time*.
This is the part that currently costs tokens for no reason.

### 3b. The judgment half

The CHANGELOG's *why*. BACKLOG reasoning. ADRs. Noticing that `PROGRESS.md` has
silently gone stale. Connecting today's defect to an existing backlog item.

This requires knowing what was just built and why it mattered — context that
lives in the session that did the work. Handing it to a subagent means briefing
that subagent, and **the brief costs approximately what writing the doc costs.**
That is rule 8.1's own stated test failing: *"do it inline when briefing costs
more than doing the task."*

A doc written by an agent that did not do the work, from a summary of the work,
is how you get documentation that is fluent and subtly wrong. Rule 4.1 already
names the consequence: stale docs are worse than none.

---

## 4. Evidence from the session that prompted this (2026-09-15)

One session, so **N = 1** — see §8 on measurement honesty. But it is direct
evidence, not speculation.

**What ran:** three releases (0.1.9, 0.1.10, 0.1.11) in one sitting, each
running the full rule 6.1 chain, each touching five carrier files.

**Where the tokens actually went.** The doc *writing* was three small scripted
edits — cheap. The expensive parts were:

- rediscovering which files carry the version (a `grep` sweep, twice)
- reading `rules/WORKFLOW.md` to check the closed tag-namespace list
- verifying tag→commit SHAs against git

A cheaper model would have reduced **none** of those three. This is the central
empirical point: the per-task doc cost is dominated by *rediscovery and
verification*, not by generation. Cheaper generation does not touch it. A script
that knows where the carriers live removes the first item outright.

**Judgment a mechanical model would have lost.** Each of these changed the
content of a doc, and none is inferable from a diff:

1. `main`'s section-11 row was not merely older than `shipping`'s — it had been
   *deliberately superseded* by v0.1.7, which exists specifically to fix it.
   Resolving that conflict correctly required knowing why the newer text is
   newer. A mechanical merge could plausibly have restored the bug that v0.1.7
   was released to remove.
2. The version drift found that day was the **fourth** instance, which is what
   turns it from a typo into evidence for an existing backlog item. A per-task
   agent with no history sees one typo.
3. Four SHAs initially reported were **tag objects, not commits** — annotated
   tags resolve differently under `git rev-parse`. Catching that before it
   entered the permanent changelog required knowing the distinction existed.

**The four drift instances, for the record** (this is the case for item 2 in §2):

| When | What was stale | How stale |
|---|---|---|
| v0.1.7→0.1.8 | `docs/index.html` eyebrow | one version — *at the release that fixed the map being a version behind* |
| pre-0.1.9 | `PROGRESS.md` header | eight versions, identically in both histories |
| post-0.1.9 | `HANDOFF.md` pointer | nine versions |
| 0.1.9 entry | CHANGELOG omitted the tag consequences | caught same session |

Every one of these is mechanically detectable. **Not one was prevented by a
model reading the rules carefully** — including in a session where the rules
were read carefully. That is the argument for a script rather than diligence.

---

## 5. The options in full

### Option 1 — Doc chain at batch grain (recommended, do first)

Per-task keeps: standards, tests run and shown, `VERSION` bump, one logical
commit, `checkpoint/<VERSION>` tag, push. Those are cheap and the tags are
Michel's debug checkpoints — they must stay per-task.

Per-batch takes: CHANGELOG narrative, PROGRESS, README/ARCHITECTURE, BACKLOG
consolidation.

- **Pros:** largest saving, scales with batch size, zero quality risk, needs no
  new machinery, and a batch-grain changelog entry is arguably *better* — it
  describes a coherent unit of work rather than three adjacent commits.
- **Cons:** a session that dies mid-batch loses unwritten doc context. Mitigated
  by rule 7.7's handoff, which already exists for exactly this.
- **Impact:** edits rule 4.3 and rule 6.1 step 3. Section 3's batch definition
  already exists and can be reused as-is — no new concept needed.

### Option 2 — Script the carriers (recommended, do second)

A check that reads `VERSION` and asserts every carrier agrees, run before
commit; and optionally a bump command that writes all of them at once.

Carriers known today: `VERSION`, the version line in `CLAUDE.md`, the README
"Current:" line, the `docs/index.html` eyebrow, and the `HANDOFF.md` "is
complete" line. **The fifth was discovered only on 2026-09-15** — the existing
backlog item lists four — so the script must *discover* carriers by pattern, not
hardcode a list, or it will rot the same way.

- **Pros:** ends a proven failure class permanently; free after it is written;
  improves correctness rather than trading it away; already a backlog item with
  four recorded occurrences behind it.
- **Cons:** one more thing to maintain. A carrier check that silently stops
  matching is worse than none — so it must fail loudly when it finds *zero*
  carriers in a file it expected to cover.
- **Impact:** new script plus a line in rule 6.1 step 3. Self-contained; no rule
  restructuring.

### Option 3 — Sonnet drafter at batch boundaries (conditional)

At a batch boundary only, dispatch Sonnet with the batch diff as its brief to
draft the CHANGELOG entry; the coordinator keeps and edits the *why*.

- **Pros:** this is the one case where briefing is genuinely cheap, because the
  brief is a diff the subagent reads itself rather than context the coordinator
  must reconstruct. Bounded blast radius — a draft, not a commit.
- **Cons:** the coordinator still has to read and fix the draft, which is most of
  the cost. Real risk the draft's fluency discourages the correction it needs.
- **Impact:** a line in rule 8.1. **Worth doing only after 1 and 2**, because
  those two change the arithmetic this option is evaluated against.

### Option 4 — Cheap mechanical model for all docs (rejected)

See §6.

### Option 5 — Do nothing

Honest baseline. The chain works and produces unusually good docs. The cost is
real but it buys something. If only one change is made, make it Option 2 —
smallest, self-contained, and it improves quality instead of trading it.

---

## 6. Why the original proposal is rejected, specifically

Not because Sonnet or Haiku is too weak to edit a markdown file. They are not.
Three concrete reasons:

1. **It optimises the wrong half.** The mechanical work should reach *no* model.
   Routing it to a cheap one keeps a token cost that should be zero.
2. **It cannot do the judgment half, and the brief is the cost.** Cheap
   generation does not help when the expense is rediscovery and verification
   (§4). The measured cost structure does not match the proposed fix.
3. **It degrades the thing that makes these docs worth keeping.** This
   repository's changelogs explain *why* a change happened, name the failure, and
   connect to prior instances. That is the product. A mechanical model reliably
   produces "Updated documentation" — and the failure is silent, because the
   output still looks like a changelog. Rule 1.1's "nothing may look complete
   that isn't", applied to prose.

**The steelman, stated fairly:** if Michel's real constraint is total spend
rather than per-doc quality, Option 4 does reduce spend, and a repo with
mediocre-but-present changelogs beats one where the chain gets skipped because
it is too expensive to run. That is a legitimate trade and his call to make. My
position is that Options 1 and 2 get most of the saving *without* making it.

---

## 7. Concrete rule edits, if approved

Nothing below is written yet. Listed so the work is reviewable before it starts.

| File | Rule | Change |
|---|---|---|
| `rules/DOCS.md` | 4.3 | Split into mechanical (scripted, no model) and judgment (inline, batch grain). State which docs move to batch grain and which stay per-task. |
| `rules/WORKFLOW.md` | 6.1 step 3 | Docs at batch grain; add the carrier check as a gate. Steps 4–6 (`VERSION`, commit, tag, push) stay per-task, explicitly, so the checkpoint habit is not read as loosened. |
| `rules/SUBAGENTS.md` | 8.1 | One line: docs are not a per-task delegation target and why (briefing cost ≥ writing cost); the batch-boundary drafter is the bounded exception. |
| `rules/REVIEWS.md` | 3.1–3.2 | Check only. Batch boundaries already exist there; confirm the doc grain lands on the same boundary rather than inventing a second one. |
| new | — | The carrier script plus its own test. |
| `docs/adr/` | — | An ADR recording the decision, superseding nothing. |

**Sequencing:** Option 2 is independent and can ship alone, in one task. Option
1 touches three rule files that cross-reference each other and should be one
task with a single review. Do not interleave them.

---

## 8. Measurement honesty, and the open questions

**On the numbers.** This report deliberately contains no token figures and no
speedup multiple. Rule 2.3 forbids unmeasured performance claims, and any
multiple quoted here would be arithmetic on frequency counts — tasks per batch —
dressed up as a measurement. The honest statement is directional: cost falls
roughly in proportion to how many tasks share one doc update, and the carrier
script removes its slice entirely.

**What would actually settle it:** take the next real batch, record the token
cost of the doc chain at per-task grain, then run the following batch at batch
grain and compare. Two data points beat any estimate in this document. Worth
doing before committing to Option 1 if the budget allows it.

**Questions for Michel, batched:**

1. **Does the CHANGELOG stay per-task or move to batch?** The one genuine
   trade-off in Option 1. Per-task entries are finer-grained debugging history
   and pair with the checkpoint tags; batch entries are cheaper and read better.
   My recommendation: **batch grain for the narrative, with the per-task commit
   message carrying the fine detail** — the information survives either way,
   because the commit messages are already unusually complete.
2. **Is the per-task `VERSION` bump itself worth keeping?** Three releases in one
   session is a lot of version numbers. I assume yes — they are the debug
   checkpoints and rule 6.1 is emphatic — but it is the frequency lever nobody
   has questioned, so it is named here rather than assumed silently.
3. **Should the carrier script block a commit, or only warn?** Blocking is the
   rules' style and catches the failure. Warning avoids a broken script halting
   unrelated work. My recommendation: **block, with a documented override flag**,
   so a real emergency has a door.
4. **Option 4 anyway?** If total spend is the binding constraint rather than doc
   quality, say so and I will build it as specified. The dissent above is on
   record and does not need re-litigating.

---

## 9. How to know it worked

Not theater — each of these is checkable:

- The four drift instances in §4 become impossible: the carrier script fails on
  each of them if reintroduced deliberately as a test.
- A batch-grain CHANGELOG entry describes a coherent unit of work, and no
  information present in the per-task entries is lost — verified by reading one
  batch entry against its commit messages.
- The doc chain's token cost at batch grain, measured against the per-task
  baseline from §8, on two real batches.
