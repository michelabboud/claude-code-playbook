---
paths:
  - "**/*.{rs,py,ts,tsx,js,jsx,mjs,cjs,go,java,kt,swift,c,cc,cpp,h,hpp,cs,rb,php,sh,bash,sql}"
  - "**/Cargo.toml"
  - "**/package.json"
  - "**/pyproject.toml"
  - "**/go.mod"
  - "**/Dockerfile"
  - "**/Makefile"
  - "**/VERSION"
  - "**/CHANGELOG.md"
  - ".github/workflows/**"
---
# 8 · The roster — definitions for rules 3.1–3.5 and 8.1

*Read before dispatching any reviewer or subagent. **This is the only file in the rulebook that names a model.** Every other rule names a role — a tier, or a kind of review — and this file says which model currently fills it. **The boundary: numbered rules own the assignments — which tier does which work (rule 8.1) and which review (rule 3.1); this file owns which model *is* each tier, the optional second family, and the evidence.** It does not restate who does what. Models change several times a year; when one does, edit this file and nothing else. It carries definitions, never authority and never procedure.*

**Last revised:** 2026-09-20. If that date is more than a few months old, check the names below against what your harness actually offers before trusting them.

## Tiers — which model fills each

| Tier | Claude model | Optional second family — only if your setup has it |
|---|---|---|
| **Top** | **Claude Fable** | Astra 6 |
| **Strong** | **Claude Opus** | Sol, at its highest reasoning effort |
| **Standard** | **Claude Sonnet** | — |
| **Fast** | **Claude Haiku** | — |

What each tier is trusted with is rule 8.1; which review each tier runs is rule 3.1.

**Escalation ladder:** Fast → Standard → Strong → Top, one tier at a time (rule 8.1).

**The Claude column is the default and is sufficient on its own.** The second-family column is optional: use an entry only when that model is genuinely reachable from your setup — through another coding CLI or a dispatcher — and leave it out otherwise. Its purpose is decorrelation: it is the second reviewer of a dual-blind pair, because two instances of one model share the same blind spots (REVIEWS.md, "Dual review"). A model reached through another CLI is also a separate process by construction, which is what blind review requires (rule 3.3). With no second family, the pair is two **separate sessions** of the Claude model, and the review header says so: *same-family pair*.

## Measurements behind this roster

**Why mechanical review is Standard and not Fast — measured September 2026, not assumed.** Claude Haiku and Claude Sonnet were given an identical mechanical-review brief over one file containing nine real defects. Haiku found five, with zero false positives; Sonnet found all nine, a strict superset. What Haiku missed was not exotic: a declared-but-never-enforced input limit, and a doc-says-X-code-does-Y mismatch — both squarely inside the classes the brief named. Haiku is precise but not thorough, and thoroughness is the entire job of the review that is supposed to be the safety net. It keeps mechanical *work*; it does not get mechanical *review*.

**A measurement belongs to the models it was taken on.** When you change the model in a row, the measurement for that row is stale: re-measure before you move a review down a tier, and record the new result here with its date.

## Changing this file

Substitute your own models freely — the tiers and the kinds are the design, the names are configuration. Change a name here and no other file needs an edit; if you find a model named anywhere else in `rules/`, that is a defect in the rulebook.
