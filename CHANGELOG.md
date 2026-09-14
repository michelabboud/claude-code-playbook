# Changelog

All notable changes to this rulebook. Newest first. Dates are absolute.

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
