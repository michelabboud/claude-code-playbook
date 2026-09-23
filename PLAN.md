# Plan

| Plan | Status | Written | Last updated |
|---|---|---|---|
| [The local layer](docs/plans/2026-09-21-local-layer-plan.md) | **source published** — `checkpoint/0.1.16` verified; private installation acceptance separate | 2026-09-21 | 2026-09-23 |
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
The six-suite local run exited 0 with counts 207, 93, 53, 143, 38, and 243.
The re-reviews, not the green suite alone, decide whether the hold can lift.

The later pinned `5441cd8` re-reviews both failed on inherited Git state and
hard-linked destination data loss; the mechanical lane additionally found
newline-path and first-install-prerequisite gaps. Those were repaired at
`c0bd879` and its focused deep re-review passed, but the mechanical lane found
one more fail-closed gap: an empty destination did not probe `find -links`
support. A red-to-green regression and unconditional non-traversing probe now
cover it. The current six-suite run exited 0 (207, 93, 53, 144, 38, 264).
The exact repaired commit still needs pinned review before `main` and
`checkpoint/0.1.16` can be published.

At `b2fd255`, mechanical review passed the capability repair but deep review
failed on a Windows example that dropped `/.claude` and a quiescence warning
scoped only to first install. The example now names the full target directory;
quiescence is a shared preflight instruction for every procedure. Tests were
red before these wording repairs and the focused suites are green. The next
exact candidate needs all suites and focused pinned review before publication.

At `34013e3`, both focused GPT-6 Sol reviews passed and the committed-tree
six-suite run exited 0 (207, 93, 53, 147, 40, 267). The next administrative
commit may contain only review records and status text; compare the source-file
tree to `34013e3`, then publish `main` and `checkpoint/0.1.16` and verify both
remote refs. This review clearance does not claim native Windows/macOS or live
installation acceptance.
