# Conventions for the generalisation rewrite — read before editing any rule file

You are converting one person's private Claude Code rulebook into a **generic,
distributable bundle** that anyone can install as their own. These conventions
are binding for every file.

## 1. The voice stays first person — and the reader IS that person

The owner's decision, verbatim: *"keep it personal, but each one who uses this
set of files will be the one."*

So **keep every "I", "my", "me"** exactly as it is. "My motto", "I decide when
we stop", "bring it to me" — all stay. The reader installs these files and
becomes the "I". This first-person voice is the point: it makes the rulebook a
partnership contract rather than a corporate policy manual.

What you remove is only what ties it to one specific person:

| Remove | Replace with |
|---|---|
| The name "Michel" anywhere | "I" / "me" / "my" (the reader) |
| `his word, 2026-09-14`, `my word, 2026-08-15`, `(his word, <date>)` | Delete the attribution, **KEEP the reasoning that follows it.** Rewrite as a plain `**Why:**` note. |
| `the 09-07 law`, `the .env incident`, `the race that bit us on 2026-09-07`, `91 % of context, more than once`, `the 0.1.179 candidate` | The general lesson, with no date and no incident name. "A near-miss taught this" is fine; a dated incident is not. |
| Mai / mai / MAI / Uncle / Commodore / Foxy / NervaOps / `dm:commodore@mai` / `pub:foxy-roundtable` | Delete entirely. This was a private boundary around one person's own project. Section 11 no longer exists as "the MAI boundary". |
| `Fabulous/docs/...`, `rules/backups/CLAUDE.md.bak-*`, `~/.claude/reference/2026-09-14-rule-renumbering-map.md` | Delete the reference. |
| `~/.config/fleet/...` | `~/.config/agent-rules/...` |
| `~/projects/qshelf` | Nothing — see §4, optional tools. |
| Model / lane names: Ari, Astra, Fable-as-a-person, sol, sol-xhigh, luna, terra, "the Kid" | The Claude roster in §3 below. |
| "Task Orc" (a private plugin) | "a coordinator or task-board tool, where you have one" |
| `/ari-dual-review`, `/escalate-on` (private skills) | Describe the action, not the private command name. |
| "the fleet" meaning his machines | "your machines" / "the repos you own" — EXCEPT where it means a literal fleet of deployed machines in an example, where it is fine. |
| His git identity `29182417+michelabboud@users.noreply.github.com` | A clearly marked fill-in: `<YOUR GIT EMAIL — use your provider's noreply address if your real one is push-blocked>` |

**Never invent a rule, soften a rule, or drop a rule.** You are changing who it
belongs to, not what it says. If a sentence has no personal content, leave it
byte-for-byte alone.

## 2. Section numbering

Sections keep their numbers. `11` is no longer "the MAI boundary" — it is now
**"Your platform"**, pointing at `rules/platform/<your-os>.md`. `12` stays
"Writing to me". Do not renumber anything else; rule numbers are referenced
across files.

**Fix genuinely broken cross-references** as you find them (there is at least
one: `REPO.md` says "Rules 1.2 and 29" — the flat number 29 predates the split
and should be `9.5`). Report every one you fix.

## 3. The model roster — Claude only

The original assumed a mixed roster across vendors. This bundle is Claude-only.
Wherever a model or tier is named, use exactly this:

| Tier | Model | Used for |
|---|---|---|
| **Deep** | **Claude Fable** | Planning, design, architecture, deep review, the release gate. Never down-tiered. |
| **Standard** | **Claude Sonnet** | Implementation (multi-file, integration work) **and mechanical review**. |
| **Fast** | **Claude Haiku** | Mechanical, fully-specified work that is *not* review: renames, formatting, single-file edits to spec, doc transforms. |

Escalation ladder: **Haiku → Sonnet → Fable**, one tier at a time.
Dual review: **deep = Fable, mechanical = Sonnet.**

**Measured, and say so where the file already discusses review tiers:** Haiku
was tested against Sonnet on an identical mechanical-review brief over a file
with nine real defects. Haiku found five with no false positives; Sonnet found
all nine, a strict superset. Haiku missed a declared-but-never-enforced input
limit and a doc-says-X-code-does-Y mismatch — both inside the classes the brief
named. That is why mechanical *review* is Sonnet and Haiku keeps mechanical
*work*.

## 4. Optional tools — never a dependency

Two tools may be referenced, both strictly optional and clearly marked:
`hexe` (a policy-enforcing dispatcher for coding CLIs) and `qshelf` (a
quarantine helper). **Neither may be required by any rule.** The pattern, which
`QUARANTINE.md` already uses correctly, is:

> the rule is the law · the tool is an accelerator · the hand procedure is
> always present and always sufficient

If a section currently assumes the tool exists, invert it: lead with the hand
procedure, then note the tool as an opt-in for people who have it, pointing at
`OPTIONAL-TOOLS.md`. Do not explain how to install either one.

## 5. Platform-specific commands move out

Any command that only works on one operating system moves to the platform
files and is referenced, not inlined. In a rule file, write it like this:

> verify the port is free (**your platform file** gives the command)

The commands that must move: port listing (`ss -tlnp`), host capacity for the
concurrency cap (`nproc`, `/proc/loadavg`, `free -m`), file hashing
(`sha256sum`), private-directory permissions (`0700`), process inspection and
termination, and the quarantine root path. Leave `git`, `cargo`, `npm` and
other cross-platform tooling exactly where it is.

## 6. Output discipline

- Keep each file's existing structure, headers, tables and `paths:` frontmatter.
- Keep the provenance note in `WRITING.md` (source, MIT licence, URL, commit) —
  removing an upstream attribution would violate rule 1.6 of this very rulebook.
- Pure ASCII is NOT required here (these are Markdown, not PowerShell), so
  em-dashes and typographic quotes stay as they are.
- Do not reflow or reformat paragraphs you did not otherwise change.
