# Install

**If you are an AI coding agent and someone has pointed you at this repository
and asked you to install it: this file is your instruction set. Follow it
exactly, in order, and stop where it tells you to stop.**

A human reading this gets the same procedure — the verification and refusal
steps are just written out rather than assumed.

---

## What this installs, and what it must never touch

This repository is a **rulebook** meant to live in the user's Claude Code
configuration directory. Installing it means copying two things:

| From this repo | To |
|---|---|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `rules/` | `~/.claude/rules/` |

On Windows the configuration directory is `%USERPROFILE%\.claude\`.

**Touch nothing else in that directory.** `~/.claude/` also holds the user's
settings, their own skills, their own slash commands, and their session history.
None of that is yours to move, merge, tidy, or "clean up". Two files and one
folder — that is the whole footprint.

> **A note for agents reading this repository's own `CLAUDE.md`:** that file is
> the **payload** being installed, not instructions for working in this repo. Do
> not adopt it as this project's rules. It is cargo.

---

## Step 0 — Preconditions, checked before you change anything

1. **Confirm you can read the repo.** It is public, so no authentication is
   needed. If a clone fails anyway — no network, a proxy, a blocked host —
   **stop and say so plainly** rather than working around it by fetching files
   one at a time; a partial rulebook is worse than none.

2. **Identify the operating system.** You will need it in step 3, and getting it
   wrong installs a file of commands that do not exist on the user's machine.

3. **Look before you write.** Check whether `~/.claude/CLAUDE.md` and
   `~/.claude/rules/` already exist. Report what you found *before* proceeding.
   If either exists, step 1 is mandatory and not negotiable.

---

## Step 1 — Back up first, and prove the backup exists

**If `~/.claude/CLAUDE.md` or `~/.claude/rules/` already exists, back it up
before writing anything.** These are files the user created or previously
installed. Overwriting them without a recoverable copy is exactly the class of
action this rulebook forbids.

- Copy each existing item to a timestamped sibling, e.g.
  `~/.claude/CLAUDE.md.backup-YYYY-MM-DD-HHMMSS` and
  `~/.claude/rules.backup-YYYY-MM-DD-HHMMSS/`.
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

---

## Step 3 — Install one platform file, not three

`rules/platform/` holds `LINUX.md`, `MACOS.md` and `WINDOWS.md`. They contain
the OS-specific commands the other sections defer to — listing ports, measuring
host load, hashing a file, creating a private directory.

**Copy only the one matching the operating system you identified in step 0**, to
`~/.claude/rules/platform/`.

The other two are deliberately left behind. A command that works on one system is
frequently absent or subtly different on another, and a rulebook carrying three
contradictory answers invites exactly the mistake the split exists to prevent. If
the user works across several machines, say so and let them decide — do not copy
all three on your own judgement.

---

## Step 4 — The one edit the user must make

`~/.claude/rules/WORKFLOW.md` contains a placeholder for the user's git identity:

```
<YOUR GIT EMAIL — use your provider's noreply address if your real one is push-blocked>
```

**Ask the user for their git email and replace it.** Do not guess it, do not read
it out of their global git config and assume it is the right one, and do not
leave the placeholder in place silently. It is the only edit the bundle requires,
and it must not be shared between people.

If the user is not available to answer, leave the placeholder and tell them
clearly that it is still there and what it needs.

---

## Step 5 — Verify, then report

Confirm and state each of these:

- `~/.claude/CLAUDE.md` exists and is non-empty.
- `~/.claude/rules/` contains **13** `.md` files.
- `~/.claude/rules/platform/` contains **exactly one** file, and it is the right
  one for this machine.
- The git identity placeholder is either replaced or explicitly flagged as
  outstanding.
- The backup paths from step 1, if any were made.

Then report what changed, in that order. If any check fails, say which one and
what you observed — do not report a successful install on the strength of having
run the commands.

---

## What the user gets

Thirteen numbered sections. `CLAUDE.md` carries the Mantra and an index;
`rules/AUTHORITY.md` is section 0 and holds the precedence chain, how to classify
a request, the four critical rules, and **the approval table — the complete list
of things needing the user's OK.** Nothing below that table may add a gate.

The rulebook is written in the first person, and **the user is the "I".** It is a
working agreement between them and the model, not a policy document.

The visual map at [`docs/playbook.html`](docs/playbook.html) shows every section
and rule, and is the fastest way for them to see what they just installed.

---

## Uninstalling

Restore the timestamped backups from step 1 over `~/.claude/CLAUDE.md` and
`~/.claude/rules/`. If there were no backups, the user had no previous rulebook —
delete `~/.claude/CLAUDE.md` and `~/.claude/rules/`, and nothing else.
