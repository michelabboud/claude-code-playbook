# Plan

| Plan | Status | Written | Last updated |
|---|---|---|---|
| [The local layer](docs/plans/2026-09-21-local-layer-plan.md) | **running** — focused blocker repairs built locally; held for focused deep re-review | 2026-09-21 | 2026-09-23 |
| Generalise the private rulebook into a distributable bundle | **done 2026-09-14** | 2026-09-14 | 2026-09-14 |

**The local layer (0.1.16)** — approved 2026-09-21. Customizations move out of
the installed files and into `rules/LOCAL.md` and `rules/LOCAL_dev.md`, which
this repository never ships and an update never writes to, copies over or
replaces, so an update is a copy plus a check instead of a merge. Decision record:
[`docs/adr/0004-the-local-layer.md`](docs/adr/0004-the-local-layer.md).

All five tasks are built: the rules text and its three hooks, the staleness
check `scripts/check-local.sh` with its tests and mutation harness, the two
templates, `INSTALL.md`'s update and migration procedures, and the propagation
through README, ARCHITECTURE, the guide and the records. The batch's mechanical
review returned FAIL with four blocking findings and eight minor ones; every one
was validated and every one is fixed (`docs/reviews/2026-09-21-local-layer-mechanical-review-validation.md`,
and the fix round's report). **Nothing is published until the batch's deep review
is ruled** — task 2 is the risk-class one and
gets a deep review at task grain as well.

**Repair round two — 2026-09-21.** The deep review found ten blockers. The
authority boundary, parser fail-closed cases, restore preflight, and install
guide contradictions are repaired in local commits. The remaining section
anchor contract is now implemented and recorded in ADR 0005; all changes remain
local pending Sol's focused re-review.

**Focused blocker repair — 2026-09-23.** BOM rejection, normalized anchor
headings, migration preflight of both local paths, refusal to uninstall/restore
with active local files, and current-contract guide/map examples are repaired
locally. Parser and lifecycle regressions reproduced the missing safeguards
before the fixes. The review/publication hold remains in force; no tag, push,
or real installation follows from this repair.

**Generalise the private rulebook** — delivered: private references removed,
section 11 repurposed as the platform section, three platform files written, the
model roster made Claude-only with mechanical review measured onto Sonnet, and
two broken cross-references fixed.

The open items are in `BACKLOG.md`.
