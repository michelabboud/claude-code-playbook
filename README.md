# Claude Code rules — a rulebook you install and make your own

![An oversized friendly robot stands beside a towering, perfectly squared stack of finished paperwork that runs off the top of the frame. It holds out one single small slip of paper to a woman sitting nearby with a coffee and a book, who looks relaxed rather than managerial. At the robot's feet a wastebasket overflows, crumpled paper balls spilling across the floor.](docs/assets/playbook-hero.png)

*A mountain of work delivered. A bin full of questions it answered itself. Exactly one thing escalated to the human. That is rule 7.2 — **decide by default, a stall is a defect** — and it is the rule this whole bundle is really about.*

---

*Shared as a resource, not a mandate. Nothing here is an IT policy or a requirement — it is one working rulebook, offered to anyone who wants a starting point instead of a blank file. Take it whole, take one section, or take the idea and write your own.*

A complete, opinionated operating manual for working with Claude Code: what
needs your approval and what doesn't, how code and tests and docs are held to a
standard, how reviews are tiered, how versions and tags and releases work, when
a subagent is worth dispatching, and how the assistant should talk to you.

It is written in the **first person on purpose**. "My motto", "I decide when we
stop", "bring it to me" — you install these files and you are the "I". That
voice is the point: it makes the rulebook a working agreement between you and
the model, not a policy document nobody reads twice.

## Why this exists

Working well with an AI coding agent comes down to one thing almost nobody writes
down: **what may it do without asking, and what must it bring to you.** Leave that
unwritten and you re-litigate it every session — the agent stops to ask about
things you don't care about, and quietly decides things you did. Both are
expensive, and the second one is how work gets damaged.

This is one answer to that, written down and used daily on real production work.
It exists because the costly part was never writing rules — it was finding out
*which* rules matter, which is usually learned by getting burned. Every rule here
earned its place that way: a near-miss, a silent data loss, an upgrade that
bricked itself, a review that passed something it shouldn't have.

It is shared so nobody else has to start from a blank file and learn the same
lessons the same way.

## Who it's for

- **Anyone using Claude Code on work that matters** — where a wrong move costs
  real time, real data, or real money.
- **People who've noticed the failure modes.** The agent that asks permission for
  everything and gets nothing done. The one that never asks and deletes something
  it shouldn't have. Section 0's approval table is the answer to both.
- **Teams who want a shared baseline** — so "how we work with agents" is a
  document rather than an oral tradition that differs per person.
- **People who will take one section and ignore the rest.** That's a completely
  valid use. The review cadence, the approval table, and the close-out chain each
  stand alone.

**Who it isn't for:** anyone looking for a policy to enforce on other people. It
is written in the first person because it only works when the person installing
it agrees with it.

## See it before you read it

**[Open the visual map →](https://michelabboud.github.io/claude-code-playbook/)**

An explorable page covering all thirteen sections and fifty rules: click a
section to see its trigger and its rules, plus the tables that carry the real
structure — the approval table, the review ladder, the model roster, the close-out
chain, and the three-way platform matrix.

It ships in this repo as [`docs/index.html`](docs/index.html) — one HTML file,
no server or build step. The page works offline with fallback fonts; its
optional Google Fonts styling needs network access. The link above is the same
file served by GitHub Pages.

## Install

**Giving this repo to an AI agent?** Point it here and say "install this". The
full procedure — preconditions, backup-first, platform selection, verification,
and the conditions under which it must refuse — is in
**[`INSTALL.md`](INSTALL.md)**. It is written to be executed, not just read.

To do it by hand, copy the top-level managed rules and one matching platform
file into your Claude Code configuration directory:

```
CLAUDE.md                  →  ~/.claude/CLAUDE.md
rules/*.md (top level)      →  ~/.claude/rules/
rules/platform/<your-os>.md →  ~/.claude/rules/platform/
```

On Windows that directory is `%USERPROFILE%\.claude\`.

If either destination already exists, **back it up first** and follow the
complete preflight in `INSTALL.md`; do not replace the whole rules directory.
(Rule 10.2, in this very bundle, says the same thing about any file you did
not create.)

There is a third thing you may want, and it is optional:

```
templates/LOCAL.md      →  ~/.claude/rules/LOCAL.md
templates/LOCAL_dev.md  →  ~/.claude/rules/LOCAL_dev.md
```

Those two are **yours**. This repository never ships them, and an update never
writes to them, copies over them, or replaces them — it reads them only to check
them. See *Make it yours* below.

## Nothing you install needs editing

Earlier versions asked you to paste your git email into `rules/WORKFLOW.md`.
They don't any more. That value — and everything else you want to change —
goes in your own `LOCAL.md`, which an update cannot touch. The placeholder
stays in the playbook's file as a blank, and `templates/LOCAL.md` has the entry
ready for you to fill.

## Pick your platform file

`rules/platform/` holds one file per operating system — `LINUX.md`, `MACOS.md`,
`WINDOWS.md`. They contain only what genuinely differs between systems: listing
ports, measuring host capacity before a fan-out, hashing a file, creating a
directory only you can read, inspecting and stopping a process, moving a file
atomically.

**Install only the file for this machine.** Keep all three in the source
repository; on another machine, install its matching file separately. The
preflight rejects extra installed platform Markdown. The rules refer to "your
platform file" and never inline a command that only works on one OS. Never
carry a command from one file to another: a command that exists on Linux is
frequently absent or subtly different on macOS, and Windows usually does the
job a different way entirely.

## The model roster

**[`rules/ROSTER.md`](rules/ROSTER.md) is the only file that names a model.**
Every rule names a role — a tier, or a kind of review — and the roster says which
model fills it today. Models change several times a year; when one does, you edit
that one file. This table is a copy of it for readers, not a second source:

| Tier | Claude model | Optional second family | Trusted with |
|---|---|---|---|
| **Top** | Claude Fable | GPT-6 Astra | Planning, design, architecture, and **high deep** review — milestones and releases. Never down-tiered. |
| **Strong** | Claude Opus 5.5 | GPT-6 Sol, high or maximum available effort | **Deep** review, per batch. The escalation step between Standard and Top. |
| **Standard** | Claude Sonnet | GPT-6 Sol, medium effort when validated | Implementation, and every **mechanical** review. |
| **Fast** | Claude Haiku | GPT-6 Luna, after a task-specific trial | Mechanical work that is not review — renames, formatting, single-file edits to spec. |

The Claude column is sufficient on its own. The second-family column is optional
and only for setups that can genuinely reach such a model through another coding
CLI: it exists to decorrelate a dual-blind review, because two instances of one
model share the same blind spots.

The 2026-09-23 [roster note](rules/ROSTER.md) compares the new GPT-6 options and
their listed API prices. Luna is a low-cost candidate for bounded work, not a
measured replacement for Standard mechanical review; Sol is the stronger
second-family deep-review option when available.
Opus 5.5 is the current Strong Claude choice; Opus 5 is not the default.

For plan execution, agent/team communication, and Herdr when it hosts the
session, see the [capability guide](docs/guides/advanced-task-execution-and-communication.md).

**Mechanical review is deliberately Sonnet and not Haiku, and that was
measured.** Given an identical brief over a file with nine real defects, Haiku
found five with no false positives; Sonnet found all nine. What Haiku missed
included a declared-but-never-enforced input limit and a doc-says-X-code-does-Y
mismatch — both inside the classes the brief named. Haiku is precise but not
thorough, and thoroughness is the whole job of a safety net. If you change this,
re-measure rather than assume.

Substitute your own models freely — the tiers are the design, the names are
configuration, and the configuration lives in one file.

## Review without stalling development

Reviews are slow, and the deep ones are expensive too. A review that development
sits waiting for is a stall, so the rulebook pipelines them:

| Kind | Closes | While it runs, development… |
|---|---|---|
| **Mechanical** | every task | never waits |
| **Deep** | every batch of 3–10 tasks | keeps going — a line carries at most **three unruled** batches, the one being built included (*unruled*: started, and not yet settled — a review that has returned with open findings still counts); every landing belongs to the open batch — an ad-hoc one for unplanned work — except a reviewed fix for a recorded finding, so at three with none open only fixes land; counted by git ancestry as a set, against a ledger the coordinator keeps; worked cases are part of the rule |
| **High deep** | a milestone or a release | waits — it may revise the plan, and the wait works the queue of minor findings |

What makes that safe is mechanics, not optimism: **a review's input is a commit,
never a working tree**; the reviewer reads git objects only; the brief defines
what counts as blocking; a blocker stops the line, whichever kind of review found it. The rule is 3.3 and 3.5 in
[`rules/REVIEWS.md`](rules/REVIEWS.md); the reasoning and the evidence are in
[`docs/guides/non-blocking-review-pipeline.md`](docs/guides/non-blocking-review-pipeline.md).

## How it is organised

Thirteen numbered sections across fourteen files. `CLAUDE.md` holds the Mantra
and an index; `rules/AUTHORITY.md` (section 0) holds precedence, the local
layer's force, how to classify a request, and **the approval table — the
complete list of what needs your OK**. The rest are subject files you open when
their trigger fires.

Six of them (`CODE`, `TESTING`, `REVIEWS`, `WORKFLOW`, `SUBAGENTS`, `ROSTER`) carry a
`paths:` scope so they load only when source is touched — a session that never
opens a source file shouldn't pay for development detail.

**Nothing but rule files lives under `rules/`.** Claude Code loads that folder
recursively, so a backup, a draft or an example saved there becomes law in every
session. That is why the templates in this repo sit in `templates/`, and why
`INSTALL.md` puts backups in a *sibling* of `rules/`.

**A subject file carries procedure, never new authority.** If you are about to
ask permission and can't point at a row in the approval table, you don't need
permission. That single property is what keeps the rulebook from turning into
bureaucracy.

## Make it yours

**Don't edit the installed files.** Write your customizations in a **local
layer** of your own — two files this repository never ships, and that an update
never writes to, copies over or replaces (it reads them only to check them):

| Your file | Loads |
|---|---|
| `~/.claude/rules/LOCAL.md` | every session |
| `~/.claude/rules/LOCAL_dev.md` | with the six source-scoped sections |

Start from `templates/LOCAL.md` and `templates/LOCAL_dev.md`. A few lines of
customization need only the first.

Section 0 gives the local layer its force in one sentence: **where an entry
there changes a rule, the entry wins over the playbook's wording.** Reading
order cannot carry that — the harness loads everything under `rules/` with no
promised order — so it is stated, once, in the one file that is always read.

**An entry is one of three kinds:**

| Kind | What it does | Example |
|---|---|---|
| **Fill** | Supplies a value a rule leaves open, or binds a generic term to what you actually have. | your git identity; where your port registry lives; which tool implements a procedure |
| **Add** | A rule or note the playbook lacks. Sections numbered `L1`, `L2`, … — numbers the playbook promises never to use. | a house convention; why a rule exists for you |
| **Override** | Changes what a named rule says — and quotes, after a **Dead words:** line, the playbook's exact words that no longer apply. | "deep review at task grain is not required for this language, and here is the sentence that no longer holds" |

Only an Override leaves two texts alive for one rule, and that is why it quotes
the words it replaces. If a later release rewrites that sentence, the quoted
words are gone, the override is **stale** — arguing with text nobody will read —
and you are told before you rely on it:

```sh
sh scripts/check-local.sh ~/.claude/rules ./rules
```

Exit 0, every quoted string still present. Exit 1, at least one stale override,
each reported with its file, its line and the words. Exit 2, something the check
could not read or could not parse — an unreadable local file, a line that does
not parse, an Override that never quoted any dead words — which is never treated
as a pass, because "no override went stale" and "no override was looked at" must
never come out the same. The update procedure in
[`INSTALL.md`](INSTALL.md) runs it against the **staged** new text before
anything is copied, so an update stops *before* it can surprise you.

The guide is [`docs/guides/local-layer.md`](docs/guides/local-layer.md); the
decision and the alternatives rejected are in
[`docs/adr/0004-the-local-layer.md`](docs/adr/0004-the-local-layer.md).

**Where people usually start:**

- **`rules/WRITING.md` (section 12)** — how the assistant writes to you. The
  most personal section in the bundle: it leads with the next action, bans
  preambles and "let me know if", and restates state every turn. Excellent for
  some people, too clipped for others.
- **The approval table in `rules/AUTHORITY.md`** — it encodes one person's risk
  tolerance. Add or move a row if yours differs. Keep it as *the* complete list,
  in one place.
- **The review cadence in `rules/REVIEWS.md`** — 3 to 10 tasks per batch, and at
  most three unruled batches on a line, the open one included. If your work is
  riskier or your batches larger, change the numbers and say why.
- **The model roster in `rules/ROSTER.md`** — the models you actually have. It
  is the only file that names one.

Each of those is an entry in your local layer, not an edit to the file.

**If an entry would be a better rule for everyone, send it upstream** and then
delete it from your local file. A local layer that grows into a second rulebook
has stopped doing its job.

## If your team shares this

The bundle needs nothing but a shell and git. There is no tool to install and no
account to be granted — every procedure in it is complete by hand, on purpose.

Three things are worth agreeing on once, before everyone starts:

- **Each person keeps their own local layer**, starting with their git identity
  as a Fill in `LOCAL.md`. Nobody edits an installed rule file, and nobody
  shares a `LOCAL.md` — that is the file where one person's setup lives.
- **Decide which mode each repo is in.** `rules/WORKFLOW.md` rule 6.1 has two:
  solo developers commit straight to `main`; a repo with a second contributor
  runs the same chain on a feature branch and lands by pull request. Read it from
  the repo itself — contributors, branch protection, an existing PR flow — and
  say which one you took. Never push to a shared `main` because the rule's solo
  half allowed it.
- **A shared repo needs `CONTRIBUTING.md`** the moment it has a second
  contributor (rule 5.2): dev setup, the test/lint/build commands, and the commit
  trailer. That is where your team's local conventions belong — not in these
  rules, which every person installs identically.

The rulebook stays in the first person for everyone. Each teammate is the "I" in
their own copy; it is not a shared voice speaking for the team.

## Versions

Current: **v0.1.16**. Full detail in [`CHANGELOG.md`](CHANGELOG.md).

| Version | What changed |
|---|---|
| **v0.1.16** | "Make it yours" stopped meaning "edit the installed files". Customizations now live in a **local layer** — `rules/LOCAL.md` and `rules/LOCAL_dev.md`, two files this repository never ships and an update never writes to, copies over or replaces — and section 0 says in one sentence that an entry there wins over the playbook's wording. An entry is a **Fill**, an **Add**, or an **Override** that quotes the dead words it replaces, so `scripts/check-local.sh` can prove mechanically that it still bites before an update copies anything. An update is a copy plus a check; the git-email edit is gone; `INSTALL.md` gained an update procedure and a migration procedure for installations tailored the old way, and its file count was wrong (13, actually 14). |
| **v0.1.15** | A second independent review, this time of the finished Codex port, failed it — and four of its six blockers were in this rulebook's text: the ceiling was off by one at the boundary (now an admission rule, with a normative table of worked cases), "mechanical review never blocks" read as absolute, an isolation condition no filesystem can satisfy, and a roster that claimed single ownership while the rules restated it. A third review, of that repair and before anything was published, found the admission could be granted twice on one count: and a fourth found two more states the wording missed and said to stop patching — so the ceiling is now one invariant: a line carries at most three unruled batches, the open one included. A fifth review found the restatement had made unplanned work unlandable and left fixes unreviewed; both are closed, and the rule now ends in a clause that resolves anything it does not name toward review. Twenty worked cases. |
| **v0.1.14** | The review-ahead rule's accounting corrected after an independent review: the ceiling says what it counts (two closed batches plus the one being built — three ranges worst case), a merge is a union not a sum, every lower review is settled before a gate, "commit only that path" replaces "stage only that path", and blindness controls are controls, not proof. |
| **v0.1.13** | Reviews no longer stall development: three kinds of review (mechanical · deep · high deep), the mechanics of pipelining a review against a commit, a ceiling of two unreviewed batches counted by git ancestry, and `rules/ROSTER.md` — the one file that names a model. Rule 3.5 is new. |
| **v0.1.12** | A report on what the per-task documentation chain costs, and why a cheaper model is the wrong fix. Awaiting decision. |
| **v0.1.11** | The 0.1.9 note omitted that the merge published four previously-local tags, and that two commits both carry version 0.1.1. |
| **v0.1.10** | `HANDOFF.md` still pointed at v0.1.0, nine versions stale. |
| **v0.1.9** | One branch history instead of two: the published branch was a local branch named `shipping` while `main` was an unrelated abandoned root. Joined by a merge, `main` now tracks the remote. |
| **v0.1.8** | A ready-to-paste announcement for handing the bundle to a team. |
| **v0.1.7** | Found by installing it: the section index pointed at platform files an install never copies. |
| **v0.1.6** | The Mantra was missing from the visual map — the five points that precede every rule. Added, with a full visual refresh. |
| **v0.1.5** | The published site root served a 404 — only the deep link worked. The page is now `docs/index.html`, so the bare URL serves it. |
| **v0.1.4** | `INSTALL.md` — a procedure an AI agent can follow from the repo URL alone, with backup-first and explicit refusal conditions. Why-this-exists and who-it's-for. The rulebook now states its own version so it can tell when it's stale. |
| **v0.1.3** | A README illustration arguing rule 7.2 — decide by default, a stall is a defect. |
| **v0.1.2** | The visual map: every section and rule as an explorable page, hosted and shipped in-repo. |
| **v0.1.1** | Needs nothing but a shell and git — every helper-tool reference removed, so nobody receives a rulebook describing something they can't install. Team guidance added. |
| **v0.1.0** | First distributable release, generalised from a private single-owner rulebook. Section 11 became the platform split; the model roster became explicit; two cross-references broken since the sections were numbered were fixed. |

## Licence

MIT — see `LICENSE`. `rules/WRITING.md` adapts prior work under MIT and carries
its own attribution in the file; keep it, because rule 1.6 of this bundle says
vendored code keeps its provenance.
