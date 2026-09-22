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

**What the procedures below need on the machine.** Copying files needs nothing
special. Two steps do: the version fetch needs `curl` (PowerShell's
`Invoke-WebRequest -UseBasicParsing` is the equivalent), and the staleness check
`scripts/check-local.sh` is a POSIX shell script, so it needs `sh` — on Windows
that means Git Bash, WSL, or MSYS2, all of which ship one. A live Override also
needs `sha256sum`, `shasum -a 256`, or `openssl` for its section digest. **If you
cannot run the required check on this machine, say so and stop before the update
or migration procedure** rather than skipping it: an update that skips the check
is the merge this design exists to avoid. A first install needs neither, because
there is no local layer to check yet.

**Touch nothing else in that directory.** `~/.claude/` also holds the user's
settings, their own skills, their own slash commands, and their session history.
None of that is yours to move, merge, tidy, or "clean up".

**Two files in `~/.claude/rules/` are the user's and never yours:**

| File | What it is |
|---|---|
| `LOCAL.md` | their customizations, loaded in every session |
| `LOCAL_dev.md` | their customizations for the source-scoped sections, loaded with those |

**Never copy over them, never move them, never delete them, never write to them
unless the user asks you to, and do not read them except where a step below tells
you to.** They are the whole reason an update is a copy instead of a merge. This
repository does not ship either file; it ships *templates* for them, in
`templates/`. The update, migration, uninstall, and backup procedures open them
only at their named compatibility or preservation steps; the staleness check is
the only mechanism that interprets an Override and it writes nothing.

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
these rules goes in their own two files — which this repository never ships, and
which an update never writes to, copies over or replaces:

| Template | Copy it to | Loads |
|---|---|---|
| `templates/LOCAL.md` | `~/.claude/rules/LOCAL.md` | every session |
| `templates/LOCAL_dev.md` | `~/.claude/rules/LOCAL_dev.md` | with the six source-scoped sections |

**Offer both, copy neither without being asked.** A user with a few lines of
customization needs only the first; `LOCAL_dev.md` exists so that entries about
code, tests, reviews, workflow, subagents and the roster load when those
sections do, rather than in every session. **If either file already exists, do
not copy the template over it and do not merge into it** — say it is there and
leave it alone.

**The one value the bundle leaves blank is the git identity.** `rules/WORKFLOW.md`
carries it as a placeholder:

```
<YOUR GIT EMAIL — use your provider's noreply address if your real one is push-blocked>
```

**Do not edit that file.** The value belongs in `~/.claude/rules/LOCAL.md` as a
**Fill**. `templates/LOCAL.md` carries the entry as a fenced example — a template
ships no live entry, because a copy taken as shipped would otherwise say "commits
use [nothing]" — so the entry has to be written out of the fence with the real
address in it. Ask the user for their git email, then:

| What you found | What you do |
|---|---|
| No `~/.claude/rules/LOCAL.md`, and the user wants one | Copy the template, then write the Fill into the copy with their address, out of its fence. |
| `~/.claude/rules/LOCAL.md` already exists | **Show them the entry to add** — the three lines, with their address filled in — and let them paste it. Do not write into a local file they already have unless they ask you to. |
| The user declines the template | Show them the entry and say where it goes. Nothing is copied. |

Do not guess the address, do not read it out of their global git config and
assume it is the right one, and do not leave the entry blank silently. It must
not be shared between people.

If the user is not available to answer, leave the value unset and tell them
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
second is the **staged** rules, not the installed ones. The script reads a live
Override's complete verifier: it extracts the anchored staged rule section,
checks its SHA-256 digest, and searches that section for the quoted words. It
writes nothing.

| Exit | Meaning | What you do |
|---|---|---|
| **0** | every quoted string and section digest is current, or the user has no local layer | Go on to step U3. |
| **1** | at least one **stale override** — its section digest changed or its quote disappeared | **Stop.** Show the user each reported line and ask what the override should become. Do not copy anything. |
| **2** | a usage error, a missing file, a malformed or oversized verifier, an **Override** with no complete verifier, an ambiguous heading, a short or repeated quote, UTF-8 BOM or NUL bytes, a misplaced marker, an unclosed fence, an unreadable local file, or an unavailable check | **Stop.** Report exactly what the script said. An unreadable check is not a passed check, and a skipped entry is not a checked one. |

**Step U3 — List the rules the update touched that the user overrides.** The
check in U2 detects changes anywhere in the anchored section. It cannot judge
whether an entry relaxes protection or whether another section changes its
meaning. So:

1. Read the user's `LOCAL.md` and `LOCAL_dev.md` and list every rule named by an
   **Override** entry.
2. From the `CHANGELOG.md` entries between the installed version and the new
   one, list every rule the update touched.
3. Show the user the intersection, by rule, with one line each on what changed.

If the intersection is empty, say so. Do not skip this because U2 exited 0 —
they answer different questions.

**Step U4 — Ask, and wait for the answer.** Nothing has been copied yet. Put in
front of the user, in one message: the version gap from U0, the result of the
check from U2, the intersection from U3, and the backup path step 1 will write.
Then **ask whether to proceed, and stop until they answer.** This is the
"stop and ask before replacing anything" that the rulebook's own front page
promises; an update that copies on its own judgement has broken that promise even
when nothing goes wrong.

**Step U5 — Back up, then copy.** Only after the user has said yes. Run **step 1**
(back up, sibling of `rules/`, verified), then **step 2** (copy file by file,
never replacing the directory), then **step 3** (one platform file — the same OS
as before), then **step 5** (verify and report).

`LOCAL.md` and `LOCAL_dev.md` are not copied over, not moved, and not written to
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

Two checkouts are needed before the end, so name them now and use the names
literally in every command below:

| Directory | What is in it |
|---|---|
| `<scratch>/published/` | this repository at the tag the installation records — the baseline for step M2 |
| `<scratch>/new/` | this repository at the version being installed — what step M4 checks against and step M5 copies from |
| `<scratch>/local/` | the `LOCAL.md` and `LOCAL_dev.md` being drafted in step M3, before they go anywhere near `~/.claude/` |

**Step M1b — Stage the new version too.** Clone or fetch this repository at the
new version into `<scratch>/new/`, exactly as step U1 does. **Do not copy
anything into `~/.claude/` yet.** Step M4's check must run against the *new*
text: pointing it at the old checkout makes it pass by construction, because the
entries were written from that text. The old checkout also has no
`scripts/check-local.sh` at all if it predates 0.1.16.

**Step M2 — Compare, file by file.** Diff each installed file against its
counterpart in `<scratch>/published/`. Do it read-only, into a scratch
directory, and keep the result.

**Step M3 — Turn every difference into a decision.** For each one, propose
exactly one of:

| The difference | Becomes |
|---|---|
| A value the rule leaves open, or a generic term bound to something real — a git identity, a registry path, a tool name | a **Fill** in the local layer |
| A rule or note the playbook does not have | an **Add**, in a section numbered `L1`, `L2`, … |
| A changed sentence in a named rule | an **Override**, with an Anchor, Rule digest, and `**Dead words:**` line binding it to that published section |
| Something that would be a better rule for everyone | a **candidate to send upstream** — show it to the user as that, and keep it as an entry until it lands |
| Upstream text the installation simply fell behind on | nothing — the update supplies it |

Write the entries into copies of `<scratch>/new/templates/LOCAL.md` and
`<scratch>/new/templates/LOCAL_dev.md`, placed in `<scratch>/local/` — **not**
into `~/.claude/` yet, and never into a `LOCAL.md` the user already has. Section 0
of the rulebook, under "The local layer", defines the three kinds;
`templates/LOCAL.md` carries the grammar of a complete Override verifier and a
worked example of each, all of them fenced. Copy an example out of its fence before you
fill it in: a fenced entry is an example and is not checked.

**Write every entry to that grammar, and it will pass the check in step M4.**
Four points catch people out: the quoted words are the **exact bytes between
the backticks**, so the line is scanned over its code spans and never split on
the ` · ` separator — a quotation may itself contain one; **every item names the
file its words are in**; the marker is an error anywhere but the start of a
line, so prose that names it writes it inside a code span; and **every Override
needs its complete Anchor, Rule digest, and `**Dead words:**` verifier** — a
mistyped marker is refused rather than skipped, which is the point. A closing
`.` after the last item is fine.

**Show the user the whole list and ask.** This is the step that decides what
their rulebook says; it is not yours to settle.

**Step M4 — Prove the entries before installing them.** With the drafted local
files in `<scratch>/local/` and the new version staged in `<scratch>/new/`, run
the check **from the new checkout** so that both the script and the rules are the
new ones:

```sh
cd <scratch>/new && sh scripts/check-local.sh <scratch>/local ./rules
```

Exit 0 means every Override still bites against the text that is about to be
installed. Exit 1 or 2: fix the entries and run it again. Do not install a local
layer that has not passed this.

**Step M5 — Preflight both local paths, then install.** Before copying either
local file or changing any managed file, check **both** destinations together.
An existing path includes a directory or dangling symlink, not only a readable
file. Run this read-only guard; exit 2 stops the migration:

```sh
migration_local_preflight() {
    if [ ! -d "$1" ] || [ ! -x "$1" ]; then
        printf 'Migration blocked: cannot inspect rules directory: %s\n' "$1" >&2
        return 2
    fi
    for local_path in "$1/LOCAL.md" "$1/LOCAL_dev.md"; do
        if [ -e "$local_path" ] || [ -L "$local_path" ]; then
            printf 'Migration blocked: local path already exists: %s\n' "$local_path" >&2
            return 2
        fi
    done
    return 0
}
migration_local_preflight ~/.claude/rules || exit 2
```

| Preflight result for both destinations | What you do |
|---|---|
| Neither path exists | Back up first (step 1), re-run the guard immediately before copying, then copy both approved local files from `<scratch>/local/`. If either copy fails, stop and report the partial result; do not change managed files or attempt rollback over user files. |
| Either path exists | **Stop this migration and do not copy.** Show the user the difference between their file and the approved one, and let them merge it by hand. Do not run steps 2, 3, or 5: the managed text and the approved local layer must arrive as one checked change. |

In particular, an existing `LOCAL_dev.md` must be found **before** an absent
`LOCAL.md` is installed. A half-migrated installation is not permission to merge
or overwrite the user's file, even when a backup exists.

If neither local file already existed, run steps 2, 3 and 5. Tell the user which
of their edits became which entry and which ones you are holding as upstream
candidates. If either existed, report the migration as blocked on its owner-led
merge; leave every managed file unchanged.

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

**Preflight before any restore or deletion.** Claude Code recursively loads
local files from `rules/` even after the base rulebook is removed. An old backup
may also lack the local-layer boundary. A successful Override check says nothing
about a Fill or Add, so it cannot authorize leaving those files active without
their base. Run this read-only guard before changing anything:

```sh
uninstall_local_preflight() {
    if [ ! -d "$1" ] || [ ! -x "$1" ]; then
        printf 'Uninstall/restore blocked: cannot inspect rules directory: %s\n' "$1" >&2
        return 2
    fi
    for local_path in "$1/LOCAL.md" "$1/LOCAL_dev.md"; do
        if [ -e "$local_path" ] || [ -L "$local_path" ]; then
            printf 'Uninstall/restore blocked: local path remains active: %s\n' "$local_path" >&2
            return 2
        fi
    done
    return 0
}
uninstall_local_preflight ~/.claude/rules || exit 2
```

**If either local path exists, stop before restoring or deleting managed files.**
This applies to Fill-only, Add-only, empty, unreadable, and dangling-link local
files as well as Overrides. Keep the installation and local files unchanged.
Explain that the owner must first decide how to preserve the local files outside
the recursively loaded `rules/` directory, or adapt their installation in a
separately approved operation. This procedure never moves, edits, or deletes
them. Re-run the guard after the owner has resolved the active local paths.

Only when both local paths are absent may the approved uninstall/restore
continue. Re-run the guard immediately before the first mutation. No checker
invocation with a nonexistent staged `CLAUDE.md` is needed.

Restore the timestamped backups from step 1 over `~/.claude/CLAUDE.md` and the
rule files in `~/.claude/rules/` — **file by file, and never `LOCAL.md` or
`LOCAL_dev.md`.** Restoring a whole backup directory over `rules/` would put back
an old copy of a local file the user has changed since, and that is the one loss
this design exists to prevent. If there were no backups, the user had no previous
rulebook — delete the fourteen rule files, `~/.claude/rules/platform/`, and
`~/.claude/CLAUDE.md`, and nothing else.

If a local path appears during the operation, stop and report exactly what has
already changed. It is the user's own writing, not this bundle's — never restore
over it, delete it, or claim the uninstall completed safely.
