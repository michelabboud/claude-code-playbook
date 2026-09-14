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

**[Open the visual map →](https://nice-michel.github.io/claude-code-playbook/)**

An explorable page covering all thirteen sections and forty-nine rules: click a
section to see its trigger and its rules, plus the tables that carry the real
structure — the approval table, the review ladder, the model roster, the close-out
chain, and the three-way platform matrix.

It ships in this repo as [`docs/index.html`](docs/index.html) — one
self-contained file, no server, no network, no build step. The link above is the
same file served by GitHub Pages.

## Install

**Giving this repo to an AI agent?** Point it here and say "install this". The
full procedure — preconditions, backup-first, platform selection, verification,
and the conditions under which it must refuse — is in
**[`INSTALL.md`](INSTALL.md)**. It is written to be executed, not just read.

To do it by hand, copy two things into your Claude Code configuration directory:

```
CLAUDE.md   →  ~/.claude/CLAUDE.md
rules/      →  ~/.claude/rules/
```

On Windows that directory is `%USERPROFILE%\.claude\`.

If you already have a `~/.claude/CLAUDE.md`, **back it up first** — this replaces
it. (Rule 10.2, in this very bundle, says the same thing about any file you did
not create.)

## The one thing you must edit

`rules/WORKFLOW.md` carries a placeholder for your git identity:

```
<YOUR GIT EMAIL — use your provider's noreply address if your real one is push-blocked>
```

Replace it. Everything else works unedited.

## Pick your platform file

`rules/platform/` holds one file per operating system — `LINUX.md`, `MACOS.md`,
`WINDOWS.md`. They contain only what genuinely differs between systems: listing
ports, measuring host capacity before a fan-out, hashing a file, creating a
directory only you can read, inspecting and stopping a process, moving a file
atomically.

**Keep the one you are on. Delete the others, or keep all three if you work
across machines** — the rules refer to "your platform file" and never inline a
command that only works on one OS. Never carry a command from one file to
another: a command that exists on Linux is frequently absent or subtly different
on macOS, and Windows usually does the job a different way entirely.

## The model roster

| Tier | Model | Runs |
|---|---|---|
| **Deep** | Claude Fable | Planning, design, architecture, milestone and release review. Never down-tiered. |
| **Standard** | Claude Sonnet | Implementation, and every mechanical review. |
| **Fast** | Claude Haiku | Mechanical work that is not review — renames, formatting, single-file edits to spec. |

**Mechanical review is deliberately Sonnet and not Haiku, and that was
measured.** Given an identical brief over a file with nine real defects, Haiku
found five with no false positives; Sonnet found all nine. What Haiku missed
included a declared-but-never-enforced input limit and a doc-says-X-code-does-Y
mismatch — both inside the classes the brief named. Haiku is precise but not
thorough, and thoroughness is the whole job of a safety net. If you change this,
re-measure rather than assume.

Substitute your own models freely — the tiers are the design, the names are
configuration.

## How it is organised

Thirteen numbered sections. `CLAUDE.md` holds the Mantra and an index;
`rules/AUTHORITY.md` (section 0) holds precedence, how to classify a request,
and **the approval table — the complete list of what needs your OK**. The rest
are subject files you open when their trigger fires.

Five of them (`CODE`, `TESTING`, `REVIEWS`, `WORKFLOW`, `SUBAGENTS`) carry a
`paths:` scope so they load only when source is touched — a session that never
opens a source file shouldn't pay for development detail.

**A subject file carries procedure, never new authority.** If you are about to
ask permission and can't point at a row in the approval table, you don't need
permission. That single property is what keeps the rulebook from turning into
bureaucracy.

## Make it yours

Three places worth tailoring before anything else:

- **`rules/WRITING.md` (section 12)** — how the assistant writes to you. It is
  the most personal section in the bundle: it leads with the next action, bans
  preambles and "let me know if", and restates state every turn. Excellent for
  some people, too clipped for others. Adapt it to how you actually read.
- **The approval table in `rules/AUTHORITY.md`** — it encodes one person's risk
  tolerance. Move a row if yours differs. Just keep it as *the* complete list,
  in one place.
- **The review cadence in `rules/REVIEWS.md`** — 3 to 10 tasks per batch. If
  your work is riskier or your batches larger, change the number and say why.

## If your team shares this

The bundle needs nothing but a shell and git. There is no tool to install and no
account to be granted — every procedure in it is complete by hand, on purpose.

Three things are worth agreeing on once, before everyone starts:

- **Each person edits their own git identity** in `rules/WORKFLOW.md`. It is the
  only required edit, and it must not be shared.
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

Current: **v0.1.7**. Full detail in [`CHANGELOG.md`](CHANGELOG.md).

| Version | What changed |
|---|---|
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
