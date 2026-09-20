# The local layer — how to make this rulebook yours without forking it

*The decision and the alternatives rejected are in
[`../adr/0004-the-local-layer.md`](../adr/0004-the-local-layer.md). This guide is
how to use it.*

---

## The problem it solves

This README has always said *install these rules and make them your own*. Until
version 0.1.16, "make them your own" meant editing the installed files — and
that made every update a merge. The install guide had to say "stop and ask
before replacing anything", and you had to re-apply your tailoring by hand or
stay behind.

The cost was measured on one real installation: a hand-merged fork of this
playbook, kept by hand for weeks. Of fourteen shared rule files, three were
byte-identical to upstream, seven differed by two to eight lines, and four
differed substantially. And the fork had drifted the wrong way — it still
carried a rule number from a numbering scheme retired a week earlier, and
wording this playbook had since improved.

**Hand-merging loses upstream fixes silently.** That is the failure the local
layer exists to prevent.

The same measurement showed something useful about the differences: almost all
of them *supplied a value*, *bound a generic term to something the person
actually had*, or *added a rule the playbook lacks*. Very few changed what a
rule says. So the design does not need to be a merge tool. It needs three kinds
of entry and one check.

## The two files

| Your file | Loads | For |
|---|---|---|
| `~/.claude/rules/LOCAL.md` | every session | everything |
| `~/.claude/rules/LOCAL_dev.md` | with the six source-scoped sections | entries about sections 1, 2, 3, 6, 8 and the roster |

Start from `templates/LOCAL.md` and `templates/LOCAL_dev.md` in this repository.
**If you have only a few lines of customization, use the first file and delete
the second.** A local file that is absent means nothing is customized.

The second file exists for one reason. The playbook deliberately scopes six of
its files — `CODE`, `TESTING`, `REVIEWS`, `WORKFLOW`, `SUBAGENTS`, `ROSTER` — to
source work, so a session that never opens a source file does not pay for
development and review detail. Most of a heavy customizer's entries are about
exactly those sections. Putting them all in `LOCAL.md` would load every one of
them in every session and throw that property away.

`LOCAL_dev.md` therefore carries the **same `paths:` frontmatter** as those six
files, byte for byte. If it drifts, the file arrives at different moments than
the rules it modifies — and an entry can be missing precisely when its rule is
being read. `tests/rules_text_test.sh` compares the blocks.

## Why precedence is a sentence, not a reading order

The obvious design is "read the local file last, so it wins". It does not work.
The harness loads every file under `rules/` with **no promised order**, and
nothing in a Markdown file can change that.

So the precedence is written down instead, once, in the one file that is always
read. Section 0, `rules/AUTHORITY.md`, under *The local layer*:

> **where an entry there changes a rule, the entry wins over the playbook's
> wording.**

Each of the six source-scoped files carries one line pointing back at that
sentence, because a session may be reading one of them without section 0 in
front of it.

**A local entry never adds authority the approval table doesn't have** — unless
it adds a row to that table in so many words. The layer tailors the rules; it
does not invent new gates.

## The three kinds of entry

### Fill — supply a value the rule leaves open

The commonest kind, and the cheapest: it creates no second text at all.

```markdown
- **Fill — rule 9.1, the registry home.** The claims registry here is
  `~/.config/my-fleet/ports/`, one file per project; machine-specific gotchas
  live in `~/.config/my-fleet/machine.md`.
```

Use it for the generic terms the rules leave deliberately open: where your port
registry lives, which tool implements a procedure, what "the deep-tier model"
means in your setup, which channel is "the owner's channel".

**Your git identity is a Fill.** It is the one value the playbook ships blank,
and `templates/LOCAL.md` has the entry ready. It lives in `LOCAL.md` rather
than `LOCAL_dev.md` because a commit is not always a source touch.

### Add — a rule the playbook does not have

Also cheap: it contradicts nothing.

```markdown
## L1 · Housekeeping

- **Add — nothing but rule files lives under `rules/`.** Claude Code loads that
  folder recursively, so any Markdown file in any subfolder becomes law in every
  session. Backups go to `~/.claude/rules-backups/`; drafts go to a repo.
```

**Number your own sections `L1`, `L2`, …** The playbook promises never to use an
`L` number, so your numbering and its numbering cannot collide as either grows.

An Add is also the right shape for provenance — *why* a rule is there for you,
whose word it was, what incident produced it. That kind of note is worth
keeping and is nobody else's business.

### Override — change what a named rule says

The only kind that leaves two texts alive for one rule, so it carries the most
obligation. It must:

1. **name the rule** it changes;
2. **say what is different in whole sentences** — not a diff, not a patch;
3. carry a `**Dead words:**` line quoting the playbook's exact words that no
   longer apply, each with the file they are in;
4. say which playbook version it was written against.

```markdown
- **Override — rule 8.1, the top tier never runs a dev lane.** The top tier is
  reserved for planning and review — a role rule, not an economy rule. So the
  hard domains — security, concurrency, Rust, unsafe code — skip the low tiers
  and start on the **Strong** tier, and the dev escalation ladder is
  Fast → Standard → Strong and ends there. Written against 0.1.16.
  **Dead words:** `start on the Top tier` (in `SUBAGENTS.md`)
```

**Why quote dead words rather than replace the whole rule?** Because replacing a
rule to change one clause freezes the rest of it. Rule 3.5 is twenty kilobytes
and changed five times in a single day; an override that had copied it would
have silently held four of those revisions out. Quoting keeps an override as
small as the disagreement — and it is what makes the staleness check possible.

## The staleness check

An Override is written against a sentence. If a later release rewrites that
sentence, the override is arguing with text nobody will read. It is **stale**,
and you must be told before you rely on it.

```sh
sh scripts/check-local.sh <local-dir> <rules-dir> [claude-md-path]
```

It reads every `**Dead words:**` line in your two files and searches the named
rule file for each quoted string, as a **fixed string** — never a regular
expression, and with the string passed as data so one beginning with a dash is
still a string. It writes nothing.

| Exit | Meaning |
|---|---|
| **0** | every quoted string was found — or you have no local layer at all |
| **1** | at least one stale override, each reported with `file:line`, the words, and the file it was sought in |
| **2** | a usage error, a named file that does not exist, a `**Dead words:**` line that does not parse, the bare marker anywhere but the start of a line, or a fenced code block left open |

**Exit 2 is never a pass.** A line the check cannot read is a check that stopped
checking, and the update stops on it exactly as it stops on a stale override.

The second argument is the point of the design: **point it at the staged new
text**, before anything is copied. `INSTALL.md`'s update procedure does exactly
that, so an update fails *before* it can surprise you rather than after.

### The grammar, because a script reads it

```
  **Dead words:** `some exact words` (in `FILE.md`) · `other words` (in `A.md` and `B.md`)
```

- Optional leading whitespace, then the literal `**Dead words:**`, then a space
  or a tab, then the first item.
- Items separated by ` · ` — space, middle dot, space.
- Each item: one code span of the quoted words, then ` (in `, then one or more
  code spans naming files, then `)`. Several names join with `, `, ` and `, or
  `, and `. **Every item names its file**; one that names none is an error.
- Quoted words may not contain a backtick and may not be empty, and are taken
  **verbatim between the backticks** — never trimmed, never re-split. A file
  name carries no whitespace and no `/`: it names a file in the rules directory,
  and `CLAUDE.md` means the playbook's front page, which resolves to the parent
  of the rules directory (or to an explicit third argument). **No item may name
  a path outside those two places** — `../CLAUDE.md` is rejected on purpose.
- After the last item, one closing `.` is allowed, and so is trailing
  whitespace. Any other trailing text is an error.
- Lines inside a fenced code block are skipped, so your file can quote this
  grammar without the example being checked. A fence that is never closed is an
  error: everything after it was ignored.
- Whitespace before the line and after the last item is ignored — an invisible
  trailing space should not halt an update. Whitespace *inside* the grammar is
  not ignored: a doubled space is an error.

**The line is scanned, never split.** A real entry quotes
`` `### 11 · Your platform` ``, so the separator, `(in ` and `)` all occur
*inside* quoted words; only a backtick ends a code span. The first implementation
split the line on ` · ` and refused eight of the ten entries in the author's own
local files — which is how this paragraph came to exist.

**And the check fails closed.** The bare marker anywhere but the start of a line
is an **error**, never a skipped entry: an override buried mid-line would
otherwise be dropped in silence, and a staleness check that silently checks
nothing is worse than none. Prose that needs to name the marker puts it inside a
code span, as this guide does throughout.

### What the check cannot do

It catches a **rewritten sentence**. It does not catch a rule whose *meaning*
changed somewhere your override does not quote — the words you pinned are still
there, and the paragraph around them now says something else.

That is why `INSTALL.md`'s update procedure has a second step: list, from
`CHANGELOG.md`, every rule the update touched that you override, and read those.
The two steps answer different questions; running one is not running both.

## Installing, updating, migrating

All three procedures are in [`../../INSTALL.md`](../../INSTALL.md), written to be
executed by an agent or a person. In short:

- **Install** — copy `CLAUDE.md` and `rules/*.md`, one platform file, and offer
  the two templates. Nothing installed needs editing.
- **Update** — stage the new text, run the check against it, stop on 1 or 2,
  list the overridden rules the changelog touched, back up to a *sibling* of
  `rules/`, then copy file by file. Your two files are never copied over, never
  moved, never opened for writing.
- **Migrate** — for an installation tailored the old way: diff it against the
  published text *of the version it records*, turn each difference into a Fill,
  an Add, an Override or an upstream candidate, get the list approved, prove it
  with the check, then install.

## Keeping a local layer honest

**Send entries upstream.** An entry that would be a better rule for everyone
belongs in this repository, and then leaves your local file. A local layer that
grows into a second rulebook has stopped doing its job — you are back to
maintaining a fork, with extra steps.

**Record the version an Override was written against.** When you read it a year
later, that line is what tells you whether it was ever re-examined.

**Keep `LOCAL.md` short.** It loads in every session, so everything in it is
paid for whether or not it is needed. Anything about code, tests, reviews,
workflow, subagents or the roster belongs in `LOCAL_dev.md`.

**Never put anything else under `rules/`.** Not a backup, not a draft, not a
note. The folder loads recursively; a Markdown file saved there becomes law in
every session.

## How it was proven

The design was installed on the owner's own rules on 2026-09-21 — the
hand-merged fork described at the top of this guide, converted entry by entry —
and tested in two fresh sessions started outside any project:

- the always-loaded file answered with no source file touched;
- the source-scoped file arrived only when a source file was opened;
- where the two texts disagreed, the local entry won.

The check itself is covered by `tests/check_local_test.sh`, and that suite is
covered by `tests/mutation_test.sh`, which breaks one behaviour of the script at
a time in a scratch copy and requires the suite to notice. A green suite proves
nothing on its own.
