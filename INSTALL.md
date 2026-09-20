# Install

**If you are an AI coding agent and someone has pointed you at this repository
and asked you to install it: this file is your instruction set. Follow it
exactly, in order, and stop where it tells you to stop.**

A human reading this gets the same procedure — the verification and refusal
steps are just written out rather than assumed.

There are three procedures here. Use the one that matches what you found:

| You found | Go to |
|---|---|
| No `~/.claude/rules/` at all | **First install** — steps 0 to 5 |
| A `~/.claude/rules/` installed from this repository | **Updating an installation** |
| A `~/.claude/rules/` whose rule files were edited by hand | **Migrating a hand-tailored installation** |

---

## What this installs, and what it must never touch

This repository is a **rulebook** meant to live in the user's Claude Code
configuration directory. Installing it means copying two things:

| From this repo | To |
|---|---|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `rules/*.md` | `~/.claude/rules/` |

On Windows the configuration directory is `%USERPROFILE%\.claude\`.

**Touch nothing else in that directory.** `~/.claude/` also holds the user's
settings, their own skills, their own slash commands, and their session history.
None of that is yours to move, merge, tidy, or "clean up".

**Two files in `~/.claude/rules/` are the user's and never yours:**

| File | What it is |
|---|---|
| `LOCAL.md` | their customizations, loaded in every session |
| `LOCAL_dev.md` | their customizations for the source-scoped sections, loaded with those |

**Never copy over them, never move them, never delete them, and do not open
them except where a step below tells you to read them.** They are the whole
reason an update is a copy instead of a merge. This repository does not ship
either file; it ships *templates* for them, in `templates/`.

**Nothing but rule files may live under `~/.claude/rules/`.** Claude Code loads
that folder **recursively**, so any Markdown file in any subfolder of it becomes
law in every session — a backup, a draft, a note, an example. Backups go to a
**sibling** of `rules/`, never inside it. That is why the templates in this
repository sit in `templates/` and not under `rules/`.

> **A note for agents reading this repository's own `CLAUDE.md` and `rules/`:**
> those are the **payload** being installed, not instructions for working in
> this repo. Do not adopt them as this project's rules. They are cargo.

---

## Step 0 — Preconditions, checked before you change anything

1. **Confirm you can read the repo.** It is public, so no authentication is
   needed. If a clone fails anyway — no network, a proxy, a blocked host —
   **stop and say so plainly** rather than working around it by fetching files
   one at a time; a partial rulebook is worse than none.

2. **Identify the operating system.** You will need it in step 3, and getting it
   wrong installs a file of commands that do not exist on the user's machine.

3. **Look before you write.** Check whether `~/.claude/CLAUDE.md` and
   `~/.claude/rules/` already exist, and whether `~/.claude/rules/LOCAL.md` or
   `~/.claude/rules/LOCAL_dev.md` exist. Report what you found *before*
   proceeding. If `~/.claude/rules/` exists, you are updating or migrating, not
   first-installing — read the matching section below before step 1.

---

## Step 1 — Back up first, and prove the backup exists

**If `~/.claude/CLAUDE.md` or `~/.claude/rules/` already exists, back it up
before writing anything.** These are files the user created or previously
installed. Overwriting them without a recoverable copy is exactly the class of
action this rulebook forbids.

- Copy each existing item to a timestamped **sibling**, e.g.
  `~/.claude/CLAUDE.md.backup-YYYY-MM-DD-HHMMSS` and
  `~/.claude/rules.backup-YYYY-MM-DD-HHMMSS/`. **Never inside `~/.claude/rules/`**
  — a backup there would load as law in every session.
- The backup of `rules/` must include `LOCAL.md` and `LOCAL_dev.md` if they are
  there. Copying the whole directory does that; copying file by file may not.
- **Read the backup back and confirm it is there and non-empty.**
- **If the backup cannot be made or cannot be verified, STOP.** Do not install.
  Report the failure and its cause. A failed backup is a refusal, not a warning
  to proceed past.
- Tell the user the exact backup paths. They are the undo button.

Do this as its own step, and evaluate its result, before any copying begins.

---

## Step 2 — Copy the two things

1. `CLAUDE.md` → `~/.claude/CLAUDE.md`
2. Every `.md` file in `rules/` → `~/.claude/rules/`

Create `~/.claude/rules/` if it does not exist.

**Copy file by file. Never replace the whole directory** — not with a recursive
copy that clears the destination first, not with a sync that deletes extras.
`LOCAL.md` and `LOCAL_dev.md` live there and are not yours to remove.

---

## Step 3 — Install one platform file, not three

`rules/platform/` holds `LINUX.md`, `MACOS.md` and `WINDOWS.md`. They contain
the OS-specific commands the other sections defer to — listing ports, measuring
host load, hashing a file, creating a private directory.

**Copy only the one matching the operating system you identified in step 0**, to
`~/.claude/rules/platform/`.

The section index in `CLAUDE.md` refers to this generically as
`rules/platform/<your-os>.md`, so it does not need editing and never points at a
file you did not install.

The other two are deliberately left behind. A command that works on one system is
frequently absent or subtly different on another, and a rulebook carrying three
contradictory answers invites exactly the mistake the split exists to prevent. If
the user works across several machines, say so and let them decide — do not copy
all three on your own judgement.

---

## Step 4 — Offer the local layer

**No installed file needs editing.** Everything the user wants to change about
these rules goes in their own two files, which this repository never touches:

| Template | Copy it to | Loads |
|---|---|---|
| `templates/LOCAL.md` | `~/.claude/rules/LOCAL.md` | every session |
| `templates/LOCAL_dev.md` | `~/.claude/rules/LOCAL_dev.md` | with the six source-scoped sections |

**Offer both, copy neither without being asked.** A user with a few lines of
customization needs only the first; `LOCAL_dev.md` exists so that entries about
code, tests, reviews, workflow, subagents and the roster load when those
sections do, rather than in every session. **If either file already exists, do
not overwrite it and do not merge into it** — say it is there and leave it
alone.

**The one value the bundle leaves blank is the git identity.** `rules/WORKFLOW.md`
carries it as a placeholder:

```
<YOUR GIT EMAIL — use your provider's noreply address if your real one is push-blocked>
```

**Do not edit that file.** Ask the user for their git email and write it into
`~/.claude/rules/LOCAL.md` as a **Fill** — the template has the entry ready, with
the value left blank. Do not guess the address, do not read it out of their
global git config and assume it is the right one, and do not leave the entry
blank silently. It must not be shared between people.

If the user is not available to answer, leave the Fill blank and tell them
clearly that it is outstanding and what it needs.

---

## Step 5 — Verify, then report

Confirm and state each of these:

- `~/.claude/CLAUDE.md` exists and is non-empty.
- `~/.claude/rules/` contains **14** `.md` files from this repository:
  `AUTHORITY` `CODE` `COLLABORATION` `DESTRUCTIVE` `DOCS` `ENVIRONMENT`
  `QUARANTINE` `REPO` `REVIEWS` `ROSTER` `SUBAGENTS` `TESTING` `WORKFLOW`
  `WRITING` — plus `LOCAL.md` and/or `LOCAL_dev.md` if the user has them, which
  are theirs and are not counted as part of this bundle.
- `~/.claude/rules/platform/` contains **exactly one** file, and it is the right
  one for this machine.
- Nothing else lives under `~/.claude/rules/` — no backup, no draft, no note,
  no template.
- The git identity is either filled in `LOCAL.md` or explicitly flagged as
  outstanding.
- The backup paths from step 1, if any were made.

Then report what changed, in that order. If any check fails, say which one and
what you observed — do not report a successful install on the strength of having
run the commands.

---

## Updating an installation

An update replaces this repository's files wholesale and leaves the user's two
files untouched. That makes it a copy plus a check, not a merge — but it is
still a rule 10.2 action, so it backs up first and **asks before replacing**.

**Step U0 — Is it behind?** Read the version the installation records, on the
`This rulebook is version` line of `~/.claude/CLAUDE.md`, and the current one:

```bash
curl -fsSL https://raw.githubusercontent.com/michelabboud/claude-code-playbook/main/VERSION
```

If the fetch fails, say so rather than guessing at the version. If the numbers
match, there is nothing to do. Otherwise read `CHANGELOG.md` for everything
between the two and **tell the user the gap in plain words** before going on.

**Step U1 — Stage the new text.** Clone or fetch this repository to a scratch
directory. **Do not copy anything into `~/.claude/` yet.** Everything below runs
against the staged text, so that a problem is found before it is installed.

**Step U2 — Check the local layer against the staged text.** From the staged
repository:

```sh
sh scripts/check-local.sh ~/.claude/rules ./rules
```

The first argument is where the user's `LOCAL.md` and `LOCAL_dev.md` live; the
second is the **staged** rules, not the installed ones. The script reads every
`**Dead words:**` line in the local files and searches the staged rule file each
one names for the quoted string. It writes nothing.

| Exit | Meaning | What you do |
|---|---|---|
| **0** | every quoted string is still in the new text, or the user has no local layer | Go on to step U3. |
| **1** | at least one **stale override** — the new text no longer contains the words that override was written against | **Stop.** Show the user each reported line and ask what the override should become. Do not copy anything. |
| **2** | a usage error, a named file that does not exist, or a `**Dead words:**` line that does not parse | **Stop.** Report exactly what the script said. An unreadable check is not a passed check. |

**Step U3 — List the rules the update touched that the user overrides.** The
check in U2 catches a *rewritten sentence*. It cannot catch a rule whose meaning
changed somewhere the override does not quote. So:

1. Read the user's `LOCAL.md` and `LOCAL_dev.md` and list every rule named by an
   **Override** entry.
2. From the `CHANGELOG.md` entries between the installed version and the new
   one, list every rule the update touched.
3. Show the user the intersection, by rule, with one line each on what changed.

If the intersection is empty, say so. Do not skip this because U2 exited 0 —
they answer different questions.

**Step U4 — Back up, then copy.** Run **step 1** (back up, sibling of `rules/`,
verified), then **step 2** (copy file by file, never replacing the directory),
then **step 3** (one platform file — the same OS as before), then **step 5**
(verify and report).

`LOCAL.md` and `LOCAL_dev.md` are not copied, not moved, not opened for writing
at any point.

**If a rule file was removed upstream**, an installed copy of it will still be
sitting in `~/.claude/rules/` after the copy, and it will still load. Say so and
name it. Do not delete it on your own judgement — that is the user's call.

---

## Migrating a hand-tailored installation

Before the local layer existed, "make it yours" meant editing the installed
files. An installation from that era has changes scattered through the rule
files, and overwriting it would lose them silently. Migration turns each change
into an entry in the local layer, once; after that, updates are ordinary.

**Do not copy anything until the user has approved the result of step M3.**

**Step M0 — Find out what it was.** Read the version on the
`This rulebook is version` line of `~/.claude/CLAUDE.md`. If there is no such
line, the installation predates versioning or is not from this repository — say
so and ask before going further.

**Step M1 — Get the published text of that version.** Check out that version's
tag from this repository into a scratch directory. It is the only honest
baseline: comparing a tailored installation against the *newest* text mixes the
user's edits with three releases of upstream changes.

**Step M2 — Compare, file by file.** Diff each installed file against the
published text of its own version. Do it read-only, into a scratch directory,
and keep the result.

**Step M3 — Turn every difference into a decision.** For each one, propose
exactly one of:

| The difference | Becomes |
|---|---|
| A value the rule leaves open, or a generic term bound to something real — a git identity, a registry path, a tool name | a **Fill** in the local layer |
| A rule or note the playbook does not have | an **Add**, in a section numbered `L1`, `L2`, … |
| A changed sentence in a named rule | an **Override**, with a **Dead words:** line quoting the published words it replaced |
| Something that would be a better rule for everyone | a **candidate to send upstream** — show it to the user as that, and keep it as an entry until it lands |
| Upstream text the installation simply fell behind on | nothing — the update supplies it |

Write the entries into `templates/LOCAL.md` and `templates/LOCAL_dev.md` copies
in your scratch directory, **not** into `~/.claude/` yet. Section 0 of the
rulebook, under "The local layer", defines the three kinds; `templates/LOCAL.md`
carries the grammar of a **Dead words:** line and a worked example of each.

**Show the user the whole list and ask.** This is the step that decides what
their rulebook says; it is not yours to settle.

**Step M4 — Prove the entries before installing them.** With the approved local
files still in the scratch directory, and the *new* version staged:

```sh
sh scripts/check-local.sh <scratch-dir> ./rules
```

Exit 0 means every Override still bites. Exit 1 or 2: fix the entries and run it
again. Do not install a local layer that has not passed this.

**Step M5 — Install.** Back up (step 1), copy the approved `LOCAL.md` and
`LOCAL_dev.md` into `~/.claude/rules/`, then run steps 2, 3 and 5. Tell the user
which of their edits became which entry, and which ones you are holding as
upstream candidates.

---

## What the user gets

Thirteen numbered sections across fourteen files. `CLAUDE.md` carries the Mantra
and an index; `rules/AUTHORITY.md` is section 0 and holds the precedence chain,
the local layer's force, how to classify a request, the four critical rules, and
**the approval table — the complete list of things needing the user's OK.**
Nothing below that table may add a gate.

The rulebook is written in the first person, and **the user is the "I".** It is a
working agreement between them and the model, not a policy document.

The visual map at [`docs/index.html`](docs/index.html) shows every section
and rule, and is the fastest way for them to see what they just installed.

---

## Uninstalling

Restore the timestamped backups from step 1 over `~/.claude/CLAUDE.md` and
`~/.claude/rules/`. If there were no backups, the user had no previous rulebook —
delete the fourteen rule files, `~/.claude/rules/platform/`, and
`~/.claude/CLAUDE.md`, and nothing else.

**Leave `~/.claude/rules/LOCAL.md` and `~/.claude/rules/LOCAL_dev.md` where they
are.** They are the user's own writing, not this bundle's. Say they are still
there, and let them decide.
