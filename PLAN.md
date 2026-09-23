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

The pinned `a7e690e` deep re-review failed: a plus-bullet Override was silently
skipped, and recursively loaded Markdown outside the two named local files was
not inspected. The plus-bullet class and unsafe template example are repaired
locally. The owner approved fail-closed recursive-file preflight on 2026-09-23;
the checker and migration/uninstall guards now refuse unaccounted Markdown
before mutation. Focused re-review is still owed. See the candidate deep and
mechanical reports under `docs/reviews/`.

**Generalise the private rulebook** — delivered: private references removed,
section 11 repurposed as the platform section, three platform files written, the
model roster made Claude-only with mechanical review measured onto Sonnet, and
two broken cross-references fixed.

The open items are in `BACKLOG.md`.

**Hygiene and GPT-6 routing, 2026-09-23.** The owner requested both additions
while the local-layer batch remains held. The hygiene checkpoint preserves logs
outside Git by default and commits reports, documents, and guides; Sol and Luna
are dated roster options, without lowering the mechanical-review floor. These
edits join the unpublished candidate and need its review before publication.

**Candidate review and repair, 2026-09-23.** Independent review of local commit
`2606360` failed despite a green suite: a symlinked rules root escaped the scan,
wrong-OS platform Markdown was admitted, and no-backup uninstall could remove
user-created non-Markdown content with the platform directory. The checker now
scans a linked root and checks the host platform; uninstall names exact managed
files and removes the directory only when empty. The owner's updated plan-mode,
agent communication, Herdr, Opus 5.5, and GPT-6 routing requests join this
held candidate. Re-run all suites, then focused independent re-review before
tagging or pushing.

Both GPT-6 Sol reviewers of `ab05129` found a remaining no-backup uninstall
data-loss case: a user-edited managed file could pass the path-only checker.
The separate content guard now compares every deletion target with the exact
installed release and refuses mismatches. The mechanical reviewer also found
README platform/offline contradictions; both were corrected. The new candidate
needs full tests and a focused GPT-6 Sol re-review before publication.

The focused GPT-6 Sol review of `03fcf9b` failed on backup restoration losing
post-install edits, linked rules roots redirecting deletion, and unverified
source provenance; mechanical re-check also found an ambiguous README copy
recipe. Both uninstall branches now share the exact-content guard, which
requires a clean tagged checkout of the installed version, refuses linked
roots, and requires a fresh verified snapshot before mutation. The copy recipe
is explicit. Run full tests and a new pinned Sol re-review before publication.

The fresh GPT-6 Sol deep and mechanical reviews of `a20bca7` **failed** on checkout trust:
uninstall executes a staged checker before authenticating the source, local
tags can be forged, and update/migration still accept linked roots that point
outside the intended destination. The mechanical reviewer also reproduced a
guard bypass using a tracked file marked `assume-unchanged`. The candidate remains local. The next
repair defines a new source-trust boundary. The owner approved canonical
published-commit verification as the default and an expressly pinned fork as
the only alternative on 2026-09-23; ADR 0010 records the decision. Repair tasks:
(1) red-to-green tests for checkout provenance, literal source bytes, and
linked destinations; (2) apply the authenticated preflight consistently to
first install, update, migration, and uninstall; (3) run all suites and two
independent GPT-6 Sol re-reviews before publication. No tag or push yet.
