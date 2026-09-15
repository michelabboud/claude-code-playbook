# Changelog

All notable changes to this rulebook. Newest first. Dates are absolute.

---

## 0.1.11 — 2026-09-15

### Fixed
- **The 0.1.9 entry was incomplete.** It described the merge but not one of its
  user-visible consequences: the merge published four previously-local tags and
  left two different commits both tagged as 0.1.1. Both facts are now written
  into the 0.1.9 entry, where they happened, rather than being discoverable only
  by noticing four unexpected tags after a fetch.

---

## 0.1.10 — 2026-09-15

### Fixed
- `HANDOFF.md` announced "v0.1.0 is complete" nine versions later. Rule 5.1 calls
  a stale pointer a lie, so this is that lie removed; the file now also records
  the single-branch shape, because an old clone showing two branches is exactly
  the thing a returning session needs explained. Found immediately after 0.1.9
  shipped, which makes it the fourth doc-drift instance in four releases — the
  backlog item asking for an automated carrier check should cover every file that
  states a version, not just the four already listed.

---

## 0.1.9 — 2026-09-15

### Changed
- **The repository now has one branch history instead of two.** The local branch
  named `main` was an unrelated root commit — the first attempt at this rulebook,
  abandoned at 0.1.1 — while `origin/main` had tracked a local branch called
  `shipping` since 0.1.1. The two shared no merge base, so `git merge-base`
  returned nothing and `main` could not be fast-forwarded. They are now joined by
  a true merge commit (never a squash, so every checkpoint tag stays reachable),
  with all six shared files resolved to the published tree.
- Local `main` fast-forwarded onto that merge and set to track `origin/main`; the
  redundant `shipping` branch retired. A local branch that pushed to `origin/main`
  under a different name was the direct cause of the confusion this release fixes.
- **Four tags that had only ever existed locally are now published**, because the
  merge made them reachable and they are annotated, so `--follow-tags` carried
  them: `v0.1.1` (commit `51f0fc3`), `checkpoint/0.1.2` (`94baff3`) and
  `checkpoint/0.1.3` (`768e443`) all sit on the published lineage and were simply
  never pushed, while `checkpoint/0.1.1` (`f419afc`) sits on the merged-in
  abandoned side and is **not** on the first-parent mainline. Anyone who fetches
  receives all four.
- **`v0.1.1` and `checkpoint/0.1.1` point at different commits.** Both lineages
  independently reached a version numbered 0.1.1 and tagged it, so the number is
  genuinely ambiguous in this repository's history. Tags never move (rule 6.4),
  so both stand as they are; read `v0.1.1` as the published 0.1.1 and
  `checkpoint/0.1.1` as the abandoned attempt's final state. Only `checkpoint/*`
  and `v*` feed version allocation, and the greatest of them is unaffected.

### Added
- `docs/reports/2026-09-14-generalisation-conventions.md`, recovered from the
  abandoned history where it was the only file that existed nowhere else. Its
  content predates 0.1.2 and has not been re-checked against the current rules.

### Fixed
- `PROGRESS.md` still announced itself as "v0.1.0 — first distributable release"
  eight versions later, identically in both histories.
- **The published map was a version behind again** — the eyebrow on
  `docs/index.html` read v0.1.7 at v0.1.8, the same drift v0.1.8 was released to
  fix. All four version carriers (`VERSION`, `CLAUDE.md`, the README table, the
  map eyebrow) are aligned in this release; the backlog item asking for an
  automated check across them now has three recorded occurrences behind it.

---

## 0.1.8 — 2026-09-14

### Added
- `docs/ANNOUNCE.md` — a ready-to-paste message for handing the bundle to a team,
  with the manual install commands **tested into a throwaway home directory**
  rather than written from memory, and two notes for the sender: lead with the
  visual map because nobody clones a repo to evaluate it, and say the bit about
  platform files because copying all three produces a rulebook with three
  contradictory answers.

---

## 0.1.7 — 2026-09-14

### Fixed
- **The section index pointed at files an install never copies.** Section 11 was
  listed as `rules/platform/LINUX.md · MACOS.md · WINDOWS.md`, but `INSTALL.md`
  correctly installs exactly one — so on any real machine the index named two
  files that were not on disk, and a session following it would try to open them.
  Now written as `rules/platform/<your-os>.md` in both `CLAUDE.md` and
  `AUTHORITY.md`: correct whichever platform file is present, and needing no
  edit at install time.

  **Found by installing the bundle on a real machine and verifying the result** —
  not by reading it. The rule about platform commands existing in one file per OS
  was right; the index describing them was written as if all three shipped.

---

## 0.1.6 — 2026-09-14

### Fixed
- **The Mantra was missing from the visual map entirely** — the five points that
  open `CLAUDE.md` and precede every rule in the book. The page showed the
  procedure and omitted the working relationship the procedure assumes. Added as
  its own band ahead of precedence, closing on the line it should have led with:
  *that is the job; agreeing with me is not.*
- A CSS selector applied card styling to the rule numbers inside the critical-rule
  cards as well as the cards themselves, rendering each as a box inside a box.

### Changed
- **Visual refresh.** Layered surfaces with real depth in place of hairline boxes,
  a larger and more confident type scale, generous spacing, a pill-style section
  nav with a solid active state, and a short rise on panel change that respects
  `prefers-reduced-motion`. The identity is unchanged — monospace rule numbers,
  cobalt for structure, brass for authority, and red and green reserved strictly
  for the approval table, where ask-versus-proceed is the actual information.

### Verified
- Every rule is present: **49 defined across the rule files, 49 shown on the
  page**, checked by extracting both sets and diffing them rather than by eye.

---

## 0.1.5 — 2026-09-14

### Fixed
- **The published site root returned 404.** GitHub Pages serves `index.html` at a
  directory URL, and the page was named `playbook.html` — so the deep link worked
  while `https://nice-michel.github.io/claude-code-playbook/` did not, which is
  the URL GitHub's own Pages control links to and the one anyone gets by trimming
  the path. Renamed to `docs/index.html`; the bare URL now serves the map and is
  the canonical link.

---

## 0.1.4 — 2026-09-14

### Changed
- **Relocated to a public personal repository** — this is a personal guide, and it
  reads better as one. Every internal reference went with it: the repo URL, the
  "internal repository" precondition in `INSTALL.md`, and the masthead of the
  visual map. The self-check now uses an unauthenticated `curl` against the raw
  `VERSION` file rather than `gh`, so it works for anyone with no setup at all.
- The visual map is served by **GitHub Pages** instead of a share link carrying an
  access token. A public URL that can be turned off beats a token that can only be
  revoked by unsharing.

### Added
- **`INSTALL.md`** — an install procedure written to be *executed by an AI agent*
  handed nothing but the repo URL, not just read by a human. Preconditions checked
  before anything changes; backup-first with the backup read back and **a failed
  backup treated as a refusal, not a warning**; exactly one platform file copied,
  never all three; the git-identity placeholder raised with the user rather than
  guessed from their git config; and an explicit list of what must never be
  touched, since `~/.claude/` also holds their settings, skills and history.
  It also warns an agent that this repo's own `CLAUDE.md` is the payload being
  installed, not instructions for working in this repo.
- **`CLAUDE.md` now states its own version and how to check for a newer one**, with
  a tested command reading the repo's `VERSION` file — the single source of truth,
  since not every version carries a release tag. An update is treated as a rule
  10.2 action: it stops and asks, because it would overwrite files the user was
  explicitly invited to tailor.
- **README: why this exists and who it's for.** The rules were expensive to learn,
  not to write, and that is the reason to share them.
- **README: a version history table**, starting at v0.1.0.

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
