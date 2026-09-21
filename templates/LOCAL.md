# LOCAL · my local layer — loads every session

*This file is mine, not the playbook's. The playbook never ships it, and an update never writes to, copies over or replaces it — it replaces the playbook's own files and reads this one only to check it. Section 0 ("The local layer") limits its force: it may fill open values, add non-authorizing guidance, or tighten a constraint; it never expands authority, removes approval, relaxes protection, changes precedence, or overrides that boundary. Its sibling `LOCAL_dev.md` carries the entries for the source-scoped sections (1, 2, 3, 6, 8 and the roster) and loads with them.*

*Written against **playbook <VERSION>** — fill in the number on the `This rulebook is version` line of `CLAUDE.md`, so a later reader knows what this file was checked against.*

---

## How to use this file

Copy it to `~/.claude/rules/LOCAL.md` and edit it. It is loaded in every
session, so keep it short: everything in it is read whether or not it is
needed. If you only have a few lines of customization, this file is all you
need — `LOCAL_dev.md` exists only so that entries about code, tests, reviews,
workflow, subagents and the roster load when those sections do, and not before.

**An entry never adds authority or removes approval.** It never relaxes a
safety, destructive, security, or secret-handling constraint, changes
precedence, or overrides the paragraph that sets those limits. The local layer
tailors rules only within that boundary.

**If an entry here would be a better rule for everyone, send it upstream** and
then delete it from this file. A local layer that grows into a second rulebook
has stopped doing its job.

## The three kinds of entry

| Kind | What it does | What it must say |
|---|---|---|
| **Fill** | Supplies a value a rule leaves open, or binds one of its generic terms to the thing you actually have. | Which rule, and the value. |
| **Add** | A rule or a note the playbook does not have. It contradicts nothing. Its own sections are numbered `L1`, `L2`, … — numbers the playbook promises never to use. | What the rule is. |
| **Override** | Changes what a named rule says. | The rule it names, what is different **in whole sentences**, and an Anchor, Rule digest, and `**Dead words:**` line that bind it to one current rule section. |

**Why an Override has a section verifier.** It is the one kind that leaves two
texts alive for one rule, so it has to name precisely which bounded text lost.
Its literal Markdown heading must occur once, its normalized section has a
SHA-256 digest, and its quote must contain at least 16 non-whitespace bytes and
occur exactly once inside that section. If the playbook changes either the
section or the quote, the override is **stale** and suspended: it has no force
until its owner re-reads the rule and rewrites it. If its scope or freshness is
unclear, use the stricter constraint and hold the affected action for the owner.
`scripts/check-local.sh` checks that mechanically before an update or restore
changes managed text.

## The Override verifier

Immediately after the Override's own sentence, write these three lines in this
order:

```
  **Anchor:** `# The literal section heading` (in `FILE.md`)
  **Rule digest:** `sha256:64-lowercase-hex-characters`
  **Dead words:** `at least sixteen non-whitespace bytes, unique in that section` (in `FILE.md`)
```

The Anchor's literal heading must occur exactly once in its named managed file.
The Rule digest covers that heading through the line before the next heading of
equal or higher level, with CRLF normalized to LF and trailing blanks ignored.
The checker reports the current digest when it is stale; after re-reading the
changed rule, copy that value into the rewritten entry. `sha256sum`, `shasum -a
256`, or `openssl` supplies the digest. If none is available, the checker
refuses the Override rather than guessing. The quoted words name the same file
as the Anchor. A standalone `**Dead words:**` line remains a non-authorizing
compatibility probe; it cannot activate an Override.

## The grammar of a Dead-words line

A script reads these lines, so their shape is fixed:

```
  **Dead words:** `some exact words` (in `FILE.md`) · `other words` (in `A.md` and `B.md`)
```

- Optional leading whitespace, then the literal `**Dead words:**`, then a space
  or a tab, then the first item.
- Items are separated by ` · ` — space, middle dot, space.
- Each item is one code span of the quoted words, then ` (in `, then one or
  more code spans naming files, then `)`. **Every item names its file** — an
  item without one is an error, not a guess at which file you meant.
- Several file names are joined by `, `, ` and `, or `, and `.
- Quoted words may not contain a backtick and may not be empty. They are taken
  **verbatim between the backticks** — never trimmed, never re-split — so they
  may contain ` · `, brackets, the word "in", and anything else: the script
  scans the line's code spans rather than splitting it on the separator.
- File names carry no spaces, no `/` and no glob character (`*`, `?`, `[`): they
  name a file in the playbook's rules directory, and `CLAUDE.md` means the
  playbook's front page. **No item may name a path outside those two places** —
  `../CLAUDE.md` is rejected, deliberately — and a name is never a pattern
  matched against whatever directory the check happened to run from.
- After the last item, **one closing `.` is allowed** — a sentence may end
  normally — and so is trailing whitespace. Any other trailing text is an error.
- Lines inside a ``` fenced code block are skipped, which is why the examples
  below are fenced: a copy of this template checks clean before you edit it. A
  fence you forget to close is an error, because everything after it is ignored.
- Whitespace before the line is ignored. Whitespace *inside* the grammar is not
  — a doubled space is an error, not a guess.
- The whole line may be at most **4,096 bytes**.

A `**Dead words:**` line the script cannot parse is an error, never a pass.
**So is the bare marker anywhere but the start of a line**: an entry buried
mid-line would otherwise be skipped in silence, which is the one failure a
staleness check may never have. Prose that needs to name the marker writes it
inside a code span, the way this paragraph does.

**And so is an Override with no complete verifier** — reported at the Override's
own line. One mistyped marker would otherwise turn an override into something
nothing can ever call stale. The script looks for the three lines between the
Override and the next entry or the next heading; an entry is a line that, after
optional indentation and an optional `- ` or `* ` bullet, begins with `**Fill`,
`**Add` or `**Override`. A Fill and an Add owe no verifier. An Override inside a
fenced code block is an example and owes none either, which is why every example
here is fenced.

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

An **Override**, with the verifier the check reads:

```
- **Override — rule 9.1, the registry home.** My claims registry is
  `~/.config/my-fleet/ports/`, and machine-specific gotchas live in
  `~/.config/my-fleet/machine.md`. Written against 0.1.16.
  **Anchor:** `# 9 · Environment & operations` (in `ENVIRONMENT.md`)
  **Rule digest:** `sha256:0000000000000000000000000000000000000000000000000000000000000000`
  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
```

---

# The entries

## Who and where

**The one value the playbook leaves blank is your git identity.** Copy the
entry below out of its fence, put your own address in it, and the bundle needs
no other edit anywhere:

```
- **Fill — git identity (section 6, "Git identity, every repo").** Commits use
  `you@example.com` — use your provider's noreply address if your real one is
  push-blocked. The trailer stays as the rule gives it.
```

*It lives in this file rather than in `LOCAL_dev.md` because a commit is not
always a source touch, and the identity is needed at every commit. Until you
copy the entry out, that value is unset — an address left inside the fence is an
example, not your identity, and no agent will use it.*

## 0 · Authority

## 4 · Documentation & ADRs

## 5 · Repository structure

## 7 · Planning, autonomy & handoffs

## 9 · Environment & operations

## 10 · Destructive actions & quarantine

## 12 · Writing to me
