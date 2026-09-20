# LOCAL · my local layer — loads every session

*This file is mine, not the playbook's. An update replaces the playbook's files and never opens this one. Section 0 ("The local layer") gives it its force: **where an entry here changes a rule, the entry wins over the playbook's wording.** Its sibling `LOCAL_dev.md` carries the entries for the source-scoped sections (1, 2, 3, 6, 8 and the roster) and loads with them.*

*Written against **playbook <VERSION>** — fill in the number on the `This rulebook is version` line of `CLAUDE.md`, so a later reader knows what this file was checked against.*

---

## How to use this file

Copy it to `~/.claude/rules/LOCAL.md` and edit it. It is loaded in every
session, so keep it short: everything in it is read whether or not it is
needed. If you only have a few lines of customization, this file is all you
need — `LOCAL_dev.md` exists only so that entries about code, tests, reviews,
workflow, subagents and the roster load when those sections do, and not before.

**An entry never adds authority the approval table doesn't have** — unless it
adds a row to that table in so many words. The local layer tailors the rules;
it does not invent new gates.

**If an entry here would be a better rule for everyone, send it upstream** and
then delete it from this file. A local layer that grows into a second rulebook
has stopped doing its job.

## The three kinds of entry

| Kind | What it does | What it must say |
|---|---|---|
| **Fill** | Supplies a value a rule leaves open, or binds one of its generic terms to the thing you actually have. | Which rule, and the value. |
| **Add** | A rule or a note the playbook does not have. It contradicts nothing. Its own sections are numbered `L1`, `L2`, … — numbers the playbook promises never to use. | What the rule is. |
| **Override** | Changes what a named rule says. | The rule it names, what is different **in whole sentences**, and a **Dead words:** line quoting the playbook's exact words that no longer apply. |

**Why an Override quotes dead words.** It is the one kind that leaves two texts
alive for one rule, so it has to say precisely which text lost. If the playbook
later rewrites that sentence, the quoted words are no longer there — the
override is **stale**, it is arguing with text nobody will read, and you must be
told before you rely on it. `scripts/check-local.sh` in the playbook repository
checks that mechanically, and the update procedure in `INSTALL.md` runs it
against the new text *before* anything is copied.

## The grammar of a Dead-words line

A script reads these lines, so their shape is fixed:

```
  **Dead words:** `some exact words` (in `FILE.md`) · `other words` (in `A.md` and `B.md`)
```

- Optional leading whitespace, then the literal `**Dead words:**`.
- Items are separated by ` · ` — space, middle dot, space.
- Each item is one code span of the quoted words, then ` (in `, then one or
  more code spans naming files, then `)`.
- Several file names are joined by `, `, ` and `, or `, and `.
- Quoted words may not contain a backtick. File names carry no spaces and no
  `/`: they name a file in the playbook's rules directory, and `CLAUDE.md`
  means the playbook's front page. **No item may name a path outside those two
  places** — `../CLAUDE.md` is rejected, deliberately.
- Lines inside a ``` fenced code block are skipped, which is why the examples
  below are fenced: a copy of this template checks clean before you edit it.
- Whitespace before the line and after the last item is ignored. Whitespace
  *inside* the grammar is not — a doubled space is an error, not a guess.

A **Dead words:** line the script cannot parse is an error, never a pass.

## Worked examples — delete these once you have your own

A **Fill**, binding a generic term to something real:

```
- **Fill — rule 9.1, the registry home.** The claims registry here is
  `~/.config/my-fleet/ports/`, one file per project.
```

An **Add**, a note the playbook does not carry:

```
## L1 · Housekeeping

- **Add — nothing but rule files lives under `rules/`.** Claude Code loads that
  folder recursively, so any Markdown file in any subfolder becomes law in every
  session. Backups go to `~/.claude/rules-backups/`.
```

An **Override**, with the line the check reads:

```
- **Override — rule 9.1, the registry home.** My claims registry is
  `~/.config/my-fleet/ports/`, and machine-specific gotchas live in
  `~/.config/my-fleet/machine.md`. Written against 0.1.16.
  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
```

---

# The entries

## Who and where

- **Fill — git identity (section 6, "Git identity, every repo").** Commits use
  `` — use your provider's noreply address if your real one is push-blocked.
  The trailer stays as the rule gives it.

  *This is the one value the playbook leaves blank. It lives here rather than in
  `LOCAL_dev.md` because a commit is not always a source touch, and the identity
  is needed at every commit. Nothing else in the installed bundle needs editing.*

## 0 · Authority

## 4 · Documentation & ADRs

## 5 · Repository structure

## 7 · Planning, autonomy & handoffs

## 9 · Environment & operations

## 10 · Destructive actions & quarantine

## 12 · Writing to me
