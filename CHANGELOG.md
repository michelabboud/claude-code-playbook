# Changelog

All notable changes to this rulebook. Newest first. Dates are absolute.

---

## 0.1.16 — 2026-09-21

### Added
- **A local layer: two files the playbook never ships, copies over, or opens.**
  `rules/LOCAL.md` loads in every session; `rules/LOCAL_dev.md` carries the same
  `paths:` scope as the six source-scoped files and loads with them. Until now
  "make it yours" meant editing the installed files, which made every update a
  merge — and a merge done by hand loses upstream fixes silently. Measured on one
  real hand-merged installation: of fourteen shared rule files, three were
  identical, seven differed by two to eight lines, four differed substantially,
  and the fork still carried a rule number from a scheme retired a week earlier.
- **Section 0 gives the layer its force, in a sentence:** where an entry there
  changes a rule, the entry wins over the playbook's wording. It has to be a
  sentence rather than a reading order, because the harness loads everything
  under `rules/` with no promised order. Each of the six source-scoped files
  carries one line pointing back at it.
- **Three kinds of entry.** A **Fill** supplies a value a rule leaves open or
  binds a generic term to something real. An **Add** is a rule the playbook
  lacks, in sections numbered `L1`, `L2`, … — numbers the playbook now promises
  never to use. An **Override** changes a named rule and quotes, after a
  **Dead words:** line, the playbook's exact words that no longer apply. Only the
  Override leaves two texts alive for one rule, which is why it is the only one
  that has to quote anything.
- **`scripts/check-local.sh`** — POSIX `sh`, no dependency. Reads every
  `**Dead words:**` line and searches the named rule file for each quoted string
  as a fixed string. Exit 0, every string still present; exit 1, at least one
  stale override, reported with `file:line`, the words, and the file searched;
  exit 2, a usage error, a missing named file, or a line that does not parse —
  **never a pass**. It takes the rules directory as an argument so it can run
  against *staged* new text before an update copies anything.
- **The line is scanned over its code spans, never split on the separator**, and
  the quoted words are the exact bytes between the backticks — never trimmed,
  never re-split. A real entry quotes `` `### 11 · Your platform` ``, so ` · `,
  `(in ` and `)` all occur inside quoted words. One closing `.` after the last
  item is allowed; any other trailing text is an error.
- **The check fails closed.** The bare marker anywhere but the start of a line is
  an **error**, never a silently skipped entry — prose that needs to name it puts
  it inside a code span. Lines inside a fenced code block are ignored, and a
  fence left open at end of file is an error, because everything after it was.
- **`tests/fixtures/dead-words-vectors.tsv`** — 47 conformance vectors for that
  grammar, shared **byte for byte** with `codex-playbook` so the two editions
  cannot drift apart quietly. Both editions run every vector; this one also
  asserts the file's SHA-256, so a local edit to a shared fixture cannot pass
  unnoticed.
- **`templates/LOCAL.md` and `templates/LOCAL_dev.md`** — the header, the three
  kinds, the grammar of a **Dead words:** line, a worked example of each kind
  (fenced, so a copied template checks clean), and the git-identity Fill left
  blank. They live in `templates/` and not under `rules/` because that folder
  loads recursively: an example saved there would become law in every session.
- **`INSTALL.md` gained an update procedure and a migration procedure.** The
  update stages the new text, runs the check against it, stops on exit 1 or 2,
  lists from this changelog every rule the update touched that the user
  overrides, backs up to a **sibling** of `rules/`, then copies file by file —
  never replacing the directory, because the user's two files live in it. The
  migration turns each difference in a hand-tailored installation into an entry
  or an upstream candidate, compared against the published text of the version
  that installation records.
- **A guide** — `docs/guides/local-layer.md` — and the decision record,
  `docs/adr/0004-the-local-layer.md`, with five alternatives rejected.
- **Tests.** `tests/check_local_test.sh` (89 assertions) over the script,
  `tests/dead_words_vectors_test.sh` (88) over every shared vector plus the cases
  one vector line cannot express — a fenced entry, an unclosed fence, the exact
  bytes of a quotation, and the two templates checking clean as shipped — and
  `tests/rules_text_test.sh` (94) over the rulebook's own text: the three hooks
  present exactly where they belong and absent everywhere else, the template's
  frontmatter byte-identical to the six scoped files, nothing but rule files
  under `rules/`, and `INSTALL.md`'s counts matching reality. Each side has a
  mutation harness — `tests/mutation_test.sh` (31) and
  `tests/rules_text_mutation_test.sh` (17) — that breaks one behaviour at a time
  in a scratch copy and requires a suite to notice, naming the assertion that
  caught it, because a green suite proves nothing on its own. 319 assertions in
  total; `sh tests/run.sh` runs them all.

### Changed
- **Nothing installed needs editing any more.** The git-identity placeholder
  stays in `rules/WORKFLOW.md` as a blank; the value is a Fill in the user's
  `LOCAL.md`. `INSTALL.md`'s old step 4 is gone and the README's "the one thing
  you must edit" with it.
- **`CLAUDE.md`'s self-update paragraph no longer says an update overwrites
  files you may have tailored** — it cannot any more. It now says customizations
  live in the local layer and survive an update, and that the check runs against
  the new text first. It still calls an update a rule 10.2 action and still stops
  to ask before replacing anything.
- **README's "Make it yours" is written around entries** rather than around four
  files to edit.

### Fixed
- **The first `check-local.sh` split each line on the ` · ` separator, and
  refused eight of the ten entries in the author's own local files.** The
  separator occurs *inside* quoted words — `` `### 11 · Your platform` `` is a
  real entry — and a closing period after the last item, natural in prose, was a
  parse error. The parser is now a scanner over code spans, and the same ten
  entries produce nine searches and one refusal: an entry that names no file, a
  refusal that is correct and stays. Found before publication by running the
  check against real data rather than against its own fixtures.
- **`INSTALL.md`'s verification step said `~/.claude/rules/` should contain 13
  `.md` files. It contains 14** — thirteen numbered sections, but `AUTHORITY.md`
  is section 0 *and* a file, so the count of sections and the count of files were
  never the same number. Found by counting, and now asserted by a test.

---

## 0.1.15 — 2026-09-20

### Fixed
- **Rule 3.5's ceiling was off by one at its boundary — in the sentence 0.1.14 had just
  rewritten.** "At most two closed, unruled batches… plus the one being built" then let batch
  N+2 close with two still unruled: three closed. Found by a second independent review, this
  time a deep review of the finished Codex port, which it failed. The ceiling is now an
  **admission rule — a new batch starts only while at most two closed batches are unruled**;
  when a third closes, all three reviews run and nothing new starts until one is ruled. Worst
  case three batch ranges, unchanged. A merge waits when its union would exceed three.
- **The admission rule could be granted twice on one count** — found by a third independent
  review, of this repair, before anything was published. "A new batch starts only while…"
  never said what *starts* means or that one batch is open at a time, so at a count of two a
  coordinator could admit N+2 and N+3 together. Now: **one batch is open per line at a time**;
  a batch starts at the first dispatch of a task the plan allocates to it, and admission is
  checked again when it closes. **At three, the line accepts only the fixes that rule a
  batch** — a fix is never a new batch; a merge that carries no fix waits even when its union
  stays three; a later task already dispatched may finish, and its result is preserved, not
  accepted, until a ruling reopens admission.
- **Then the ceiling was restated as one invariant rather than patched a fifth time** — a
  fourth independent review, still before publication, found two more omitted states (a batch
  that rule 3.2 closes early with a task still running; a branch cut from an *open* batch) and,
  asked directly, said the rule was too intricate to patch. Every defect had sat between
  *closed* batches, which the rule counted, and *open* work, which admission, branching and
  merging act on. Now: **a line carries at most three unruled batches, the open one
  included.** A batch is unruled from its first dispatch; closing pins the review target,
  freezes membership and never changes the count; only a ruling brings it down; nothing lands
  on a line outside a batch. Same exposure as before — two in review plus the one being built.
  Rows 7 and 13–16 reworded.
- **The restatement was reviewed too, and failed on what it had newly created** — a fifth
  independent review, still before publication. "Nothing lands outside a batch" made an
  authorized hotfix with no plan unlandable and contradicted the gate-time docs row; fixes
  attached to a closed batch owed no review of their own; and merging a line whose batch was
  still open let a fourth unruled range in. Now: **every landing belongs to the line's open
  batch** — the plan's, or an **ad-hoc batch** the coordinator names in the ledger, never a
  new approval — **except the fix for a recorded finding**, which gets a focused review, at
  the depth of the review that found the defect, before its batch is ruled. **Only closed
  work merges between lines**; a task's own worktree is not a line. The sentence equating the
  invariant with "two closed batches" is gone — it was not exact. And the rule now closes
  itself: **what it does not name is resolved toward review** — the work counts as unruled,
  belongs to a new batch, and waits at three. Twenty worked cases.
- Public summaries said the ceiling counts "unreviewed" batches; a returned review with open
  findings is reviewed and still counts. They say *unruled*, defined in place.
- **Rule 3.1: "never blocks the next task" read as absolute** and contradicted stop-the-line.
  Now: a *pending* mechanical review never delays the next reversible task; a *returned*
  blocking finding stops the line, whatever kind of review found it.
- **Rule 3.3: "no programme material anywhere above" a reviewer's scratch directory is
  unsatisfiable** — every path has the filesystem root above it. Scoped to a dedicated parent
  within the task-managed workspace, with the review header recording when the runtime cannot
  provide it.
- **`rules/ROSTER.md` claimed single ownership while rules 3.1 and 8.1 restated who does what.**
  Boundary stated: rules own assignments; the roster owns which model is each tier, the optional
  second family, and the evidence. Its "trusted with" column and kinds-of-review table are gone;
  rule 8.1 now states the Strong tier's job itself.

### Added
- **Rule 3.5: a normative table of twenty worked cases** — the boundary states of the ceiling,
  a second batch proposed while one is open, work in flight when the third closes, a merge at
  exactly three, a fix arriving at three,
  union on merge, a branch cut inside a batch, cherry-picks, a fix reachable from one line only,
  a dead mechanical review holding a gate, a mechanical blocker, a docs fix during a gate. Where
  the prose and a row disagree, the row wins. Prose failed at the same boundary twice in a day,
  and keyword tests passed while it was wrong.
- The guide's blindness controls no longer ask for the unsatisfiable "nothing anywhere above" a
  reviewer's directory; they carry rule 3.3's scoped wording.
- ADR 0003, amending ADR 0002 — including the plain statement that 0.1.13 and 0.1.14 were
  published before an independent review, which is what this rule now forbids.

---

## 0.1.14 — 2026-09-20

### Fixed
- **Rule 3.5's accounting, corrected within hours of 0.1.13 by an independent review.** The
  rule was reviewed by a second model family — as a separate process, against a pinned commit,
  cold-read note first — while reviewing a plan to port it to the Codex edition. Eleven
  findings, all confirmed; five were in this rulebook's own text:
  - **The ceiling now says what it counts:** at most two *closed*, unruled batches under a
    line's tip, plus the one being built. 0.1.13 allowed batch N+2 to start and also said "a
    third never starts". The honest worst case is **three** batch ranges of unreviewed code,
    not two; the guide's "worst-case rework doubles" was wrong and is corrected in place.
  - **A merge is a union, not a sum.** "A merge adds the two counts" double-counted a shared
    unruled ancestor. The count is the set of unruled batches with any commit reachable from
    the tip; a branch cut inside a batch inherits it; cherry-picks, squashes and copied code
    carry no ancestry; a ruling clears a line only when its fixes are reachable from it; a
    merge result is itself new work.
  - **Every lower review is settled before a high deep gate — mechanical included.** 0.1.13
    drained only the deep reviews, so a mechanical review that died or timed out could be left
    owed while the gate claimed completion. The gate's candidate is frozen, and gate-time work
    happens on a line not merged into it.
  - **A finding's impact decides what it stops, never the kind of review that found it.** "A
    mechanical finding is local" overclaimed: the roster's own measurement cites an unenforced
    input limit, which can be a security defect.
  - **"Commit only that path", index checked first** replaces "stage only that path" — anything
    already staged rides along.
- `rules/WORKFLOW.md` still cited "rules 3.1–3.4", and its close-out ledger example named models
  in lower case — so 0.1.13's claim that no model is named outside `rules/ROSTER.md` was false
  by one example. The verifying search matched capitals only. The example now names tiers.

### Added
- **Rule 3.5: the coordinator keeps a ledger, and one coordinator admits work.** Git knows
  ancestry; it does not know which commits form a batch, which reviews are owed, or whether one
  was ruled. Two coordinators admitting from the same stale count can exceed the ceiling with
  correct arithmetic.
- **Rule 3.3:** pin the base as well as the target; whoever holds the permission prepares the
  reviewer's snapshot; *review-only is an authority, read-only is a filesystem* — a reviewer
  that cannot write returns its notes through its reply, and its permissions are never widened
  to make the rule look satisfied; an exited reviewer is not an accepted review; a fork of the
  coordinating session is never a blind reviewer; the instruction environment (global rules,
  skills, memory, hooks) is a review input; blindness controls are controls, not proof.
- **Rule 3.5:** review capacity is not host load — rule 8.1's cap measures the machine, not a
  remote model's allowance; never raise the ceiling to hide a starved review lane.
- ADR 0002, amending ADR 0001.

---

## 0.1.13 — 2026-09-20

### Added
- **Rule 3.5 — how far development may run ahead of review.** Mechanical review
  never holds development. Deep review is pipelined to a ceiling of **two unruled
  batches under a line's tip**: one is the normal state, the second is announced
  loudly because it means the review lane is in trouble, and a third never
  starts. The count follows **git ancestry** — a branch started from unreviewed
  work inherits its count, a merge adds the counts, and a merge that would exceed
  the ceiling waits — so independent worktrees count separately and fan-out is
  not a way around the limit. Three waits hold at any depth: work that is
  expensive to undo, anything irreversible or outward-facing, and a blocker. The
  planner now owns the stall: independent work after every batch boundary,
  risk-class tasks early in a batch.
- **`rules/ROSTER.md` — the one file that names a model.** Four tiers (Top ·
  Strong · Standard · Fast), the three kinds of review and who runs each, the
  measurement behind the mechanical-review tier, and an **optional second-family
  column** (Astra 6, Sol) for setups that can reach such a model through another
  coding CLI. Every other rule now names a role. A model release is an edit to
  this file and to nothing else; a model named anywhere else in `rules/` is a
  defect. It carries the same `paths:` scope as `REVIEWS.md` and `SUBAGENTS.md`,
  so six files are now source-scoped, not five.
- **A Strong tier (Claude Opus).** Deep review had been running on the Standard
  tier — the same tier as implementation and as the mechanical review it is
  supposed to out-think. It now has a tier of its own, which is also the new
  escalation step between Standard and Top.
- `docs/guides/non-blocking-review-pipeline.md` — the reasoning, the ways the
  pipeline fails silently, the evidence and its limits.
- `docs/adr/` with ADR 0001, recording the decision and the six alternatives
  rejected (a ceiling of one, no ceiling, per-worktree counting, among others).

### Changed
- **Rule 3.1: two kinds of review became three.** Mechanical closes a task; deep
  closes a batch; **high deep** closes a milestone or a release. They are defined
  by what they close, not by the model that runs them today. High deep is a
  **gate**, because it may revise the plan and no ceiling bounds work built
  against a plan that is about to change; the count of unreviewed batches drains
  to zero before one starts, and the wait works the queue of minor findings.
- **Rule 3.3 gained its mechanics.** "Review batch N while N+1 builds" was an
  instruction with several implementations that look right and quietly fail. Now:
  a review's input is a commit, never a working tree; the reviewer reads git
  objects only, and builds in its own detached worktree with its own build
  directory; the brief defines what counts as blocking; the coordinator — never
  the reviewer — commits the review's output, that one path only, the moment its
  findings are complete; in-process subagents of one session do not count as
  blind, and only a blind reviewer's cold-read note counts as independent
  corroboration.
- `SUBAGENTS.md`, `AUTHORITY.md` and the `CLAUDE.md` index name tiers instead of
  models; the roster table left `SUBAGENTS.md` and `REVIEWS.md` for `ROSTER.md`.
  The roster's top tier is renamed **Deep → Top**, because "the Deep tier" and
  "a deep review" would otherwise name two different models.
- The rule count is fifty (was forty-nine) in the README, the announcement and
  the published page; the page's review ladder and roster show the new shape.
- README: a section on reviewing without stalling development; the roster table
  is marked as a display copy of `rules/ROSTER.md`; four places to tailor, not
  three.

### Not verified
- The ceiling of two rests on one programme — a sixteen-task behaviour-preserving
  refactor, the friendliest possible case. Rule 3 now asks every close-out to
  record how often the ceiling was reached, so the number can be revised on
  evidence rather than preference.
- *Why* context crossed the blind-review boundary is a hypothesis (session-level
  context injection by the harness), untested. The rule states only the observed
  effect and does not depend on the explanation.

---

## 0.1.12 — 2026-09-15

### Added
- `docs/reports/2026-09-15-documentation-chain-cost.md` — an analysis of what the
  per-task documentation chain actually costs, written because the obvious fix
  (delegate docs to a cheap model) is the wrong one. The finding: the cost is
  dominated by rediscovery and verification rather than generation, so a cheaper
  generator does not touch it. Recommends moving the doc chain to batch grain
  first and scripting the version carriers second, and rejects the cheap-model
  proposal with its steelman stated. Carries no token figures deliberately —
  rule 2.3 forbids unmeasured claims, and it says instead what measurement would
  settle it. Awaiting decision; becomes an ADR when decided.

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
  while `https://michelabboud.github.io/claude-code-playbook/` did not, which is
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
