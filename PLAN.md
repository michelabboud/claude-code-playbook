# Plan

| Plan | Status | Written | Last updated |
|---|---|---|---|
| [The local layer](docs/plans/2026-09-21-local-layer-plan.md) | **running** — five tasks built, held for the batch's deep review | 2026-09-21 | 2026-09-21 |
| Generalise the private rulebook into a distributable bundle | **done 2026-09-14** | 2026-09-14 | 2026-09-14 |

**The local layer (0.1.16)** — approved 2026-09-21. Customizations move out of
the installed files and into `rules/LOCAL.md` and `rules/LOCAL_dev.md`, which
this repository never ships or touches, so an update is a copy plus a check
instead of a merge. Decision record:
[`docs/adr/0004-the-local-layer.md`](docs/adr/0004-the-local-layer.md).

All five tasks are built: the rules text and its three hooks, the staleness
check `scripts/check-local.sh` with its tests and mutation harness, the two
templates, `INSTALL.md`'s update and migration procedures, and the propagation
through README, ARCHITECTURE, the guide and the records. **Nothing is published
until the batch's deep review is ruled** — task 2 is the risk-class one and
gets a deep review at task grain as well.

**Generalise the private rulebook** — delivered: private references removed,
section 11 repurposed as the platform section, three platform files written, the
model roster made Claude-only with mechanical review measured onto Sonnet, and
two broken cross-references fixed.

The open items are in `BACKLOG.md`.
