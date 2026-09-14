# Claude Code rules — a rulebook you install and make your own

A complete, opinionated operating manual for working with Claude Code: what
needs your approval and what doesn't, how code and tests and docs are held to a
standard, how reviews are tiered, how versions and tags and releases work, when
a subagent is worth dispatching, and how the assistant should talk to you.

It is written in the **first person on purpose**. "My motto", "I decide when we
stop", "bring it to me" — you install these files and you are the "I". That
voice is the point: it makes the rulebook a working agreement between you and
the model, not a policy document nobody reads twice.

## Install

Copy two things into your Claude Code configuration directory:

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

## Optional tools

Some sections mention helper tools. **No rule depends on one.** See
`OPTIONAL-TOOLS.md`.

## Licence

MIT — see `LICENSE`. `rules/WRITING.md` adapts prior work under MIT and carries
its own attribution in the file; keep it, because rule 1.6 of this bundle says
vendored code keeps its provenance.
