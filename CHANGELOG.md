# Changelog

All notable changes to this rulebook. Newest first. Dates are absolute.

---

## 0.1.3 — 2026-09-14

### Added
- `docs/assets/playbook-hero.png` — a README illustration, carried with a caption
  naming what it argues: a mountain of work delivered, a bin full of questions
  answered without asking, and exactly one thing escalated. That is rule 7.2, and
  it is the rule the bundle is really about. Full alt text, since a picture that
  makes an argument has to make it to everyone.

---

## 0.1.2 — 2026-09-14

### Added
- `docs/playbook.html` — a single self-contained visual map of all thirteen
  sections and forty-nine rules, with the approval table, the review ladder, the
  model roster, the close-out chain and the three-way platform matrix rendered as
  real tables. No server, no network, no build step: clone and open it.
- `README.md` links both the hosted version and the in-repo file, above the
  install steps — the page is the fastest way to decide whether the bundle is
  worth adopting.

---

## 0.1.1 — 2026-09-14

Prepared for handing to a team. The bundle now assumes **no tooling beyond a
shell and git**, so nobody receives a rulebook that describes something they
cannot install.

### Removed
- `OPTIONAL-TOOLS.md`, and every reference to it. A rule file that mentions a
  helper — even as optional — makes a reader wonder whether they are missing a
  prerequisite. The procedures were always complete without one; now they say so
  and nothing else.

### Changed
- `QUARANTINE.md`'s accelerator note became a **contract for automation the
  reader might write themselves**: validation evaluated before the move and in
  its own step, a manifest byte-compatible with a hand-written one, and final
  deletion still refusing without approval. It advertises nothing.
- Two lessons worth keeping independently of any tool were relocated rather than
  deleted:
  - **"an isolated working directory is not a sandbox"** → `SUBAGENTS.md`, where
    dispatched work is decided. A worktree isolates files, a process sandbox
    limits capability, a permission set limits actions; only the controls your
    setup genuinely implements are real.
  - **"a tool that quietly becomes load-bearing is a dependency nobody vetted"**
    → `CODE.md` rule 1.5, which is where dependencies are already vetted.
- `README.md` gained a short section on using the bundle across a team.

---

## 0.1.0 — 2026-09-14

First distributable release. Generalised from a private, single-owner rulebook
so anyone can install it as their own.

### Added
- `rules/platform/LINUX.md`, `MACOS.md`, `WINDOWS.md` — section 11. Every
  OS-specific command the other sections defer to: listing ports, measuring host
  capacity before a fan-out, hashing a file, creating an owner-only directory,
  inspecting and stopping a process, moving a file atomically. The rules now
  state intent and the platform file states the command.
- `OPTIONAL-TOOLS.md` — helper tools described as accelerators only, with the
  standing guarantee that no rule depends on one.
- `README.md` — install steps, the one required edit, and the three sections
  most worth tailoring.

### Changed
- **The model roster is Claude-only and explicit:** Fable for planning, design
  and deep review; Sonnet for implementation and every mechanical review; Haiku
  for mechanical work that is not review.
- **Mechanical review moved from the fast tier to Sonnet, on measurement.**
  Given an identical brief over a file containing nine real defects, Haiku found
  five with no false positives; Sonnet found all nine, a strict superset. Haiku
  missed a declared-but-never-enforced input limit and a doc-versus-behaviour
  mismatch — both inside the classes the brief named. Recorded in `REVIEWS.md`
  so the decision can be re-measured rather than re-argued.
- Section 11 was a private-project boundary; it is now **Your platform**.
- `QUARANTINE.md` inverted to lead with the hand procedure, with any helper tool
  demoted to an explicitly optional accelerator.
- Port and host-capacity commands moved out of `ENVIRONMENT.md` and
  `SUBAGENTS.md` into the platform files.
- `~/.config/fleet/` → `~/.config/agent-rules/`.
- Dated personal rulings became plain rationale: **every reason kept, every
  attribution and incident date dropped.**

### Fixed
- Two broken cross-references left over from before the rules were split into
  numbered sections: `REPO.md` rule 5.1 cited "rule 29" for the secrets rule
  (now 9.5), and `WORKFLOW.md` cited "rule 31" for the destructive-actions gate
  (now 10.1).

### Removed
- All references to one owner's private projects, teammates, repositories and
  machine-local tooling. The first-person voice is deliberately **kept** — the
  reader installs the files and becomes the "I".
