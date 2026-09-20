# Architecture

This is a documentation bundle, not a program. Its structure is the design.

## The layering, and the one property that matters

```
CLAUDE.md                 the Mantra + the section index        (always loaded)
  └── rules/AUTHORITY.md  §0 precedence · the local layer ·     (always loaded)
                             classification · THE APPROVAL TABLE
                             · critical rules
        └── rules/*.md    §1–§12 subject files                  (trigger-loaded)
              └── rules/platform/<os>.md   §11 OS specifics     (read by path)

rules/LOCAL.md            the user's entries                    (always loaded)
rules/LOCAL_dev.md        the user's entries for §1 2 3 6 8     (source-scoped)
                          — never shipped, never touched by an update
```

**A subject file carries procedure, never new authority.** The approval table in
`AUTHORITY.md` is the complete list of things that need the owner's OK. Nothing
below it may add a gate — not a subject file, not a skill, not a harness default,
not a subagent.

That single property is load-bearing. Without it, every file added to the bundle
is a potential new reason to stop and ask, and a rulebook that grows new gates as
it grows pages becomes bureaucracy. With it, the bundle can be extended
indefinitely and the cost of asking stays fixed.

## Why the rules are split across files

The bundle started as one document and outgrew it. Splitting achieves two things
a single file cannot:

1. **Conditional loading.** Six files (`CODE`, `TESTING`, `REVIEWS`, `WORKFLOW`,
   `SUBAGENTS`, `ROSTER`) carry a `paths:` scope and enter context only when source files
   are touched. A session that never opens code shouldn't pay for development
   detail.
2. **Stable numbering.** Rules are numbered `<section>.<rule>`, so adding a rule
   never renumbers its neighbours and cross-references stay valid.

## Why the platform split exists

Rules state intent; platform files state commands. Listing a port, measuring host
load, hashing a file, and creating a private directory are spelled differently on
Linux, macOS and Windows — and several commands present on one are simply absent
on another.

Inlining one OS's command into a rule quietly makes the rule wrong on the other
two, and the failure is silent: a safety check that cannot run is a safety check
that stops checking. Keeping commands in one file per OS makes that impossible,
and makes it obvious which file a contributor must update.

## Why customizations live outside the bundle

The bundle is replaced wholesale by an update. That is only safe because
nothing a user wrote is inside it: their entries live in `rules/LOCAL.md` and
`rules/LOCAL_dev.md`, which this repository never ships, copies over, or opens.
An update is therefore a copy plus a check, not a merge.

Precedence between the two texts is a **sentence**, not a loading order. The
harness loads every file under `rules/` with no promised order, so "read the
local file last" cannot be relied on; section 0 states once, in the file that is
always read, that a local entry wins over the playbook's wording.

The one kind of entry that leaves two texts alive for one rule — an **Override** —
quotes the playbook's exact words that no longer apply. That is what makes
staleness mechanically checkable: `scripts/check-local.sh` searches the new text
for each quoted string before an update copies anything, and a string that is
gone means the override is arguing with text nobody will read.

## Why `rules/` holds nothing but rule files

Claude Code loads `rules/` **recursively** — measured: a platform file in a
subfolder arrived in a fresh session unasked. So any Markdown file in any
subfolder becomes law in every session. A backup kept there, a draft, or an
example template would all load as rules.

Hence three placements that are not aesthetic: the templates live in
`templates/`, the check lives in `scripts/`, and `INSTALL.md` puts backups in a
*sibling* of `rules/`. `tests/rules_text_test.sh` enforces the first.

## The repository's own layout

| Directory | What it is |
|---|---|
| `rules/` | the payload — the rule files, and nothing else |
| `templates/` | starting points for the user's two local files |
| `scripts/` | `check-local.sh`, the staleness check the update procedure runs |
| `tests/` | POSIX-`sh` suites over the script and over the rulebook's own text |
| `docs/` | the visual map, guides, plans, reports, and the decision records |

`tests/` carries two mutation harnesses as well as two suites. A green suite
proves nothing on its own, so each harness breaks one behaviour in a scratch
copy and requires the suite to notice.
