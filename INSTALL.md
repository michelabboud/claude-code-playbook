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

**What the procedures below need on the machine.** Every installation,
update, migration, restore, and uninstall needs `sh` and Git; the default
canonical-source check also needs network access. Only an explicitly
owner-approved full commit pin for a fork uses the documented offline path.
On Windows, run the POSIX-shell guards in Git Bash, WSL, or MSYS2; plain
PowerShell alone cannot run them. Fetching a version also needs `curl`
(PowerShell's `Invoke-WebRequest -UseBasicParsing` is an alternative), and
checking a live Override needs `sha256sum`, `shasum -a 256`, or `openssl` for
its section digest. The destination guard uses `find -links` to reject managed
hard links; an environment without that check must refuse the operation.
**If you cannot run a required check, say so and stop before any backup or
copy.** A first install has no local-layer staleness check, but it still needs
the source and destination trust checks.

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

## Source and destination preflights — run before staged code or mutation

The checkout's own tag, `origin`, and clean-looking `git status` are not proof
that it is a published playbook. Before running any script from a staged
checkout, use this read-only guard. Its default trust source is the canonical
public repository over HTTPS. The optional third argument is **only** for a
full commit ID the owner supplied directly and explicitly approved for a fork;
never obtain that argument from the checkout, its remote, a tag, or a local
file. The optional fourth argument `baseline` is for a historical migration
checkout that predates some current files. A missing network, tag, script,
managed file, or byte match is a refusal, not permission to work offline.

```sh
source_trust_preflight() {
    if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
        printf 'Source trust blocked: expected checkout and version.\n' >&2
        return 2
    fi
    trust_checkout=$1
    trust_version=$2
    trust_pin=${3:-}
    trust_mode=${4:-current}
    if [ "$trust_mode" != current ] && [ "$trust_mode" != baseline ]; then
        printf 'Source trust blocked: invalid verification mode.\n' >&2
        return 2
    fi
    trust_newline='
'
    if printf '%s' "$trust_checkout$trust_version$trust_pin" | LC_ALL=C grep -q '[[:cntrl:]]' ||
       case $trust_checkout$trust_version$trust_pin in *"$trust_newline"*) true ;; *) false ;; esac ||
       [ -L "$trust_checkout" ]; then
        printf 'Source trust blocked: ambiguous or linked checkout path.\n' >&2
        return 2
    fi
    trust_root=$(CDPATH='' cd -P "$trust_checkout" && pwd -P) || {
        printf 'Source trust blocked: checkout directory unavailable.\n' >&2
        return 2
    }
    (
    # Git -C alone does not cancel inherited repository, object, or config
    # selectors. Keep their removal inside this subshell so callers retain
    # their environment, while every Git command below sees the same isolation.
    unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_NAMESPACE \
        GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES \
        GIT_CONFIG_PARAMETERS GIT_CONFIG GIT_EXEC_PATH || {
        printf 'Source trust blocked: cannot clear inherited Git environment.\n' >&2
        return 2
    }
    export GIT_NO_REPLACE_OBJECTS=1 GIT_NO_LAZY_FETCH=1 GIT_OPTIONAL_LOCKS=0 \
        GIT_CONFIG_NOSYSTEM=1 \
        GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null \
        GIT_CONFIG_COUNT=0 GIT_SSL_NO_VERIFY=0 GIT_TERMINAL_PROMPT=0 || {
        printf 'Source trust blocked: cannot isolate Git configuration.\n' >&2
        return 2
    }
    trust_ref=refs/tags/checkpoint/$trust_version
    if ! git check-ref-format "$trust_ref" >/dev/null 2>&1; then
        printf 'Source trust blocked: invalid release version.\n' >&2
        return 2
    fi
    trust_git_root=$(GIT_NO_REPLACE_OBJECTS=1 git -C "$trust_root" rev-parse --show-toplevel 2>/dev/null) || {
        printf 'Source trust blocked: checkout is not a Git repository.\n' >&2
        return 2
    }
    if [ "$trust_root" != "$trust_git_root" ] || [ ! -f "$trust_root/VERSION" ] ||
       [ -L "$trust_root/VERSION" ] ||
       [ "$(wc -l < "$trust_root/VERSION")" -ne 1 ] ||
       [ "$(sed -n '1p' "$trust_root/VERSION")" != "$trust_version" ] ||
       [ ! -f "$trust_root/CLAUDE.md" ] ||
       ! grep -Fq "**This rulebook is version $trust_version**" "$trust_root/CLAUDE.md"; then
        printf 'Source trust blocked: checkout/version mismatch.\n' >&2
        return 2
    fi
    trust_head=$(GIT_NO_REPLACE_OBJECTS=1 git -C "$trust_root" rev-parse --verify 'HEAD^{commit}' 2>/dev/null) || {
        printf 'Source trust blocked: commit unavailable.\n' >&2
        return 2
    }
    if [ -n "$trust_pin" ]; then
        case $trust_pin in
            *[!0-9a-f]*) printf 'Source trust blocked: owner pin must be a full commit ID.\n' >&2; return 2 ;;
        esac
        if [ "${#trust_pin}" -ne "${#trust_head}" ] || [ "$trust_pin" != "$trust_head" ]; then
            printf 'Source trust blocked: checkout does not match the owner-approved commit.\n' >&2
            return 2
        fi
    else
        trust_local_tag=$(GIT_NO_REPLACE_OBJECTS=1 git -C "$trust_root" rev-parse --verify "$trust_ref^{object}" 2>/dev/null) || {
            printf 'Source trust blocked: local release tag unavailable.\n' >&2
            return 2
        }
        trust_tag_commit=$(GIT_NO_REPLACE_OBJECTS=1 git -C "$trust_root" rev-parse --verify "$trust_ref^{commit}" 2>/dev/null) || {
            printf 'Source trust blocked: release tag does not resolve to a commit.\n' >&2
            return 2
        }
        if [ "$trust_tag_commit" != "$trust_head" ]; then
            printf 'Source trust blocked: checkout is not at the release tag.\n' >&2
            return 2
        fi
        if [ -e /.git ] || [ -L /.git ]; then
            printf 'Source trust blocked: cannot isolate canonical Git lookup from root repository.\n' >&2
            return 2
        fi
        trust_remote_tag=$(git -C / ls-remote --exit-code --refs \
            https://github.com/michelabboud/claude-code-playbook.git "$trust_ref" 2>/dev/null) || {
            printf 'Source trust blocked: canonical published tag unavailable.\n' >&2
            return 2
        }
        if [ "$trust_remote_tag" != "$trust_local_tag$(printf '\t')$trust_ref" ]; then
            printf 'Source trust blocked: local tag differs from the canonical published tag.\n' >&2
            return 2
        fi
    fi
    for trust_relative in VERSION CLAUDE.md INSTALL.md CHANGELOG.md \
        scripts/check-local.sh templates/LOCAL.md templates/LOCAL_dev.md \
        rules/AUTHORITY.md rules/CODE.md rules/COLLABORATION.md \
        rules/DESTRUCTIVE.md rules/DOCS.md rules/ENVIRONMENT.md \
        rules/QUARANTINE.md rules/REPO.md rules/REVIEWS.md rules/ROSTER.md \
        rules/SUBAGENTS.md rules/TESTING.md rules/WORKFLOW.md \
        rules/WRITING.md rules/platform/LINUX.md rules/platform/MACOS.md \
        rules/platform/WINDOWS.md; do
        trust_path=$trust_root/$trust_relative
        trust_blob=$(GIT_NO_REPLACE_OBJECTS=1 git -C "$trust_root" rev-parse --verify "HEAD:$trust_relative" 2>/dev/null) || trust_blob=
        if [ -z "$trust_blob" ] && [ "$trust_mode" = baseline ] &&
           [ ! -e "$trust_path" ] && [ ! -L "$trust_path" ]; then
            continue
        fi
        if [ -z "$trust_blob" ] || [ -L "$trust_path" ] || [ ! -f "$trust_path" ] ||
           [ -L "$trust_root/rules" ] || [ -L "$trust_root/rules/platform" ] ||
           [ -L "$trust_root/scripts" ] || [ -L "$trust_root/templates" ]; then
            printf 'Source trust blocked: missing or linked source file: %s\n' "$trust_relative" >&2
            return 2
        fi
        trust_tree_entry=$(GIT_NO_REPLACE_OBJECTS=1 git -C "$trust_root" ls-tree HEAD -- "$trust_relative" 2>/dev/null) || {
            printf 'Source trust blocked: cannot inspect committed mode: %s\n' "$trust_relative" >&2
            return 2
        }
        trust_tab=$(printf '\t')
        case $trust_tree_entry in
            "100644 blob $trust_blob$trust_tab$trust_relative"|"100755 blob $trust_blob$trust_tab$trust_relative") ;;
            *) printf 'Source trust blocked: committed file is not a regular blob: %s\n' "$trust_relative" >&2; return 2 ;;
        esac
        trust_actual=$(GIT_NO_REPLACE_OBJECTS=1 git -C "$trust_root" hash-object --no-filters -- "$trust_path" 2>/dev/null) || {
            printf 'Source trust blocked: cannot hash source file: %s\n' "$trust_relative" >&2
            return 2
        }
        if [ "$trust_actual" != "$trust_blob" ]; then
            printf 'Source trust blocked: source bytes differ from the published commit: %s\n' "$trust_relative" >&2
            return 2
        fi
    done
    if [ "$trust_mode" = current ]; then
        # Root + fourteen managed files + platform directory + three platform files.
        trust_expected_rule_entries=19
        trust_rule_listing=$(find "$trust_root/rules" -print 2>/dev/null) || {
            printf 'Source trust blocked: cannot inspect staged rules tree.\n' >&2
            return 2
        }
        trust_rule_entries=$(printf '%s\n' "$trust_rule_listing" | wc -l)
        if [ "$trust_rule_entries" -ne "$trust_expected_rule_entries" ]; then
            printf 'Source trust blocked: unexpected file or directory in staged rules.\n' >&2
            return 2
        fi
    fi
    return 0
    )
}
```

The owner-pinned fork path avoids the network but does **not** infer authority
from a local tag; the owner must supply the full pin independently. A default
operation that cannot verify the canonical tag stops. The guide trusts the
canonical repository and HTTPS transport, not a signature on every release.
On success, the function leaves `trust_root` set to the checkout's physical
path; use that path for the staged checker and every source-file copy, rather
than a caller-supplied path whose ancestor may be a link.

Before any backup, copy, restore, or deletion, also refuse symbolic links at
the destination roots and symbolic or hard links at any managed destination
file. This is a read-only check; a linked dotfile-manager root or managed file
needs a separate owner decision, not an automatic traversal into its target.

```sh
destination_root_preflight() {
    if [ "$#" -ne 1 ]; then
        printf 'Destination blocked: expected configuration directory.\n' >&2
        return 2
    fi
    destination_newline='
'
    if printf '%s' "$1" | LC_ALL=C grep -q '[[:cntrl:]]' ||
       case $1 in *"$destination_newline"*) true ;; *) false ;; esac; then
        printf 'Destination blocked: ambiguous path encoding.\n' >&2
        return 2
    fi
    case $1 in
        /*) destination_remaining=${1#/}; destination_prefix= ;;
        *) printf 'Destination blocked: expected an absolute path.\n' >&2; return 2 ;;
    esac
    while [ -n "$destination_remaining" ]; do
        destination_component=${destination_remaining%%/*}
        case $destination_component in
            ''|.|..) printf 'Destination blocked: ambiguous path component.\n' >&2; return 2 ;;
        esac
        destination_prefix=$destination_prefix/$destination_component
        if [ -L "$destination_prefix" ] ||
           { [ -e "$destination_prefix" ] && [ ! -d "$destination_prefix" ]; }; then
            printf 'Destination blocked: linked or non-directory ancestor: %s\n' "$destination_prefix" >&2
            return 2
        fi
        if [ "$destination_component" = "$destination_remaining" ]; then
            break
        fi
        destination_remaining=${destination_remaining#*/}
    done
    for destination_path in "$1" "$1/rules" "$1/rules/platform"; do
        if [ -L "$destination_path" ] ||
           { [ -e "$destination_path" ] && [ ! -d "$destination_path" ]; }; then
            printf 'Destination blocked: linked or non-directory root: %s\n' "$destination_path" >&2
            return 2
        fi
    done
    for destination_relative in CLAUDE.md \
        rules/AUTHORITY.md rules/CODE.md rules/COLLABORATION.md \
        rules/DESTRUCTIVE.md rules/DOCS.md rules/ENVIRONMENT.md \
        rules/QUARANTINE.md rules/REPO.md rules/REVIEWS.md rules/ROSTER.md \
        rules/SUBAGENTS.md rules/TESTING.md rules/WORKFLOW.md \
        rules/WRITING.md rules/platform/LINUX.md rules/platform/MACOS.md \
        rules/platform/WINDOWS.md; do
        destination_file=$1/$destination_relative
        if [ -L "$destination_file" ] ||
           { [ -e "$destination_file" ] && [ ! -f "$destination_file" ]; }; then
            printf 'Destination blocked: linked or non-file managed path: %s\n' "$destination_file" >&2
            return 2
        fi
        if [ -e "$destination_file" ]; then
            destination_hardlinks=$(find "$destination_file" -links +1 -print 2>/dev/null) || {
                printf 'Destination blocked: cannot inspect managed hard links: %s\n' "$destination_file" >&2
                return 2
            }
            if [ -n "$destination_hardlinks" ]; then
                printf 'Destination blocked: hard-linked managed file: %s\n' "$destination_file" >&2
                return 2
            fi
        fi
    done
    return 0
}
```

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

4. **Authenticate the staged release and destination.** With the published
   version read from the checkout's `VERSION` file (read-only), run
   `source_trust_preflight /path/to/checkout <version> || exit 2` and
   `destination_root_preflight ~/.claude || exit 2`. This happens before any
   script from that checkout, backup, or destination mutation. Re-run both
   immediately before the first copy. If verification cannot be completed,
   preserve the existing installation and report why.

---

## Step 1 — Back up first, and prove the backup exists

**If `~/.claude/CLAUDE.md` or `~/.claude/rules/` already exists, back it up
before writing anything.** These are files the user created or previously
installed. Overwriting them without a recoverable copy is exactly the class of
action this rulebook forbids.

The source and destination preflights above must already have passed. If
either has become unverifiable, do not start a backup or a copy.

- Copy each existing item to a timestamped **sibling**, e.g.
  `~/.claude/CLAUDE.md.backup-YYYY-MM-DD-HHMMSS` and
  `~/.claude/rules.backup-YYYY-MM-DD-HHMMSS/`. **Never inside `~/.claude/rules/`**
  — a backup there would load as law in every session.
- Choose new backup names and refuse any existing file, directory, or symlink
  at either target. A timestamp collision is not permission to overwrite an
  older backup. If no unique target is available, stop before copying.
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
2. Exactly the fourteen named managed subject files listed in step 5,
   individually, from `rules/` → `~/.claude/rules/`. Do not use a wildcard
   copy: a newly added or untracked Markdown file would become a recursively
   loaded rule without having been authenticated.

Create `~/.claude/rules/` if it does not exist.

**Copy file by file. Never replace the whole directory** — not with a recursive
copy that clears the destination first, not with a sync that deletes extras.
`LOCAL.md` and `LOCAL_dev.md` live there and are not yours to remove.
Re-run the source and destination preflights immediately before this first
managed copy; copy from the verified physical `trust_root`, not from the
original checkout spelling. A first install is not an offline exception.

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
the user works across several machines, install the matching single platform
file separately on each machine. Do not copy all three into one installation.

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
Read its `VERSION` without executing anything, then run
`source_trust_preflight <scratch>/new <staged-version> || exit 2` and
`destination_root_preflight ~/.claude || exit 2`. A local tag or configured
`origin` is not a substitute for the canonical published tag. For an
owner-approved fork, pass the owner's full commit pin as the third argument.

**Step U2 — Check the local layer against the staged text.** From the staged
repository:

```sh
source_trust_preflight . "$(sed -n '1p' VERSION)" || exit 2
sh "$trust_root/scripts/check-local.sh" ~/.claude/rules "$trust_root/rules"
```

For an owner-approved fork, supply the same owner-provided full commit ID as
the third argument to this source preflight and every later one; never read a
pin from the staged checkout.

The first argument is where the user's `LOCAL.md` and `LOCAL_dev.md` live; the
second is the **staged** rules, not the installed ones. The script reads a live
Override's complete verifier: it extracts the anchored staged rule section,
checks its SHA-256 digest, and searches that section for the quoted words. It
writes nothing.

| Exit | Meaning | What you do |
|---|---|---|
| **0** | every quoted string and section digest is current, or the user has no local layer | Go on to step U3. |
| **1** | at least one **stale override** — its section digest changed or its quote disappeared | **Stop.** Show the user each reported line and ask what the override should become. Do not copy anything. |
| **2** | a usage error, unexpected Markdown or symlink anywhere in the recursively loaded rules tree, a missing file, a malformed or oversized verifier, an **Override** with no complete verifier, an ambiguous heading, a short or repeated quote, UTF-8 BOM or NUL bytes, a misplaced marker, an unclosed fence, an unreadable local file, or an unavailable check | **Stop.** Report exactly what the script said. An unreadable check is not a passed check, and a skipped entry is not a checked one. |

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
Re-run `source_trust_preflight`, `destination_root_preflight`, and the staged
`check-local.sh` immediately before the first copy; if any fails, keep the
backup and leave the current installation untouched. For an owner-pinned fork,
use the same approved pin on every invocation.

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
Before using this old checkout, run
`source_trust_preflight <scratch>/published <installed-version> '' baseline || exit 2`.
The baseline mode allows files that did not exist in that historical version,
but authenticates every listed file that does exist. Compare any additional
historical file from its authenticated Git blob, not an unverified worktree
copy. A fork baseline needs its own separately owner-approved full pin.

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
Run `source_trust_preflight <scratch>/new <new-version> || exit 2` before
reading its templates or running its checker, and
`destination_root_preflight ~/.claude || exit 2` before any backup or copy.

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
cd <scratch>/new && source_trust_preflight . "$(sed -n '1p' VERSION)" &&
    sh "$trust_root/scripts/check-local.sh" <scratch>/local "$trust_root/rules"
```

For an approved fork, add its owner-provided full commit ID as the third
argument to `source_trust_preflight` here and to both migration guards.

Exit 0 means every Override still bites against the text that is about to be
installed. Exit 1 or 2: fix the entries and run it again. Do not install a local
layer that has not passed this.

**Step M5 — Preflight both local paths, then install.** Before copying either
local file or changing any managed file, check **both** destinations together.
An existing path includes a directory or dangling symlink, not only a readable
file. The guard also refuses any other Markdown or symlink under the recursively
loaded rules directory that the new managed tree does not account for. Run this
read-only guard; exit 2 stops the migration:

```sh
migration_local_preflight() {
    if [ ! -f "$2/VERSION" ]; then
        printf 'Migration blocked: staged version unavailable.\n' >&2
        return 2
    fi
    migration_version=$(sed -n '1p' "$2/VERSION")
    if ! source_trust_preflight "$2" "$migration_version" "${3:-}" ||
       ! destination_root_preflight "${1%/*}"; then
        printf 'Migration blocked: source or destination trust preflight failed.\n' >&2
        return 2
    fi
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
    if ! sh "$trust_root/scripts/check-local.sh" "$1" "$trust_root/rules" "$trust_root/CLAUDE.md"; then
        printf 'Migration blocked: the recursively loaded rules tree is not accounted for.\n' >&2
        return 2
    fi
    return 0
}
migration_local_preflight ~/.claude/rules <scratch>/new || exit 2
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
Use the same owner-approved pin on every source preflight if migrating from a
fork. Re-run the source and destination guards before the first local or managed
copy, and stop if they no longer pass.

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

**Preflight before any restore or deletion.** From this repository's checkout
root, run the guard below. Claude Code recursively loads
local files from `rules/` even after the base rulebook is removed. An old backup
may also lack the local-layer boundary. A successful Override check says nothing
about a Fill or Add, so it cannot authorize leaving those files active without
their base. The guard also refuses unaccounted nested or extra Markdown or
symlinks, without moving or deleting them. Run it before changing anything:

```sh
uninstall_local_preflight() {
    if [ ! -f "$2/VERSION" ]; then
        printf 'Uninstall/restore blocked: staged version unavailable.\n' >&2
        return 2
    fi
    uninstall_version=$(sed -n '1p' "$2/VERSION")
    if ! source_trust_preflight "$2" "$uninstall_version" "${3:-}" ||
       ! destination_root_preflight "${1%/*}"; then
        printf 'Uninstall/restore blocked: source or destination trust preflight failed.\n' >&2
        return 2
    fi
    if [ -L "$1" ] || [ -L "${1%/*}" ] || [ -L "$1/platform" ]; then
        printf 'Uninstall/restore blocked: a configuration or rules directory is a symlink: %s\n' "$1" >&2
        return 2
    fi
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
    if ! sh "$trust_root/scripts/check-local.sh" "$1" "$trust_root/rules" "$trust_root/CLAUDE.md"; then
        printf 'Uninstall/restore blocked: the recursively loaded rules tree is not accounted for.\n' >&2
        return 2
    fi
    return 0
}
uninstall_local_preflight ~/.claude/rules /path/to/exact-installed-release-checkout || exit 2
```

For **both** restore-from-backup and no-backup uninstall, verify every current
managed path that would be overwritten or deleted
against an **authenticated checkout of the exact installed playbook version**.
If that checkout is unavailable, its version cannot be established, or any
installed bytes differ, do not overwrite or delete the file:
preserve the installation and ask the owner how to retain the changes. A
managed filename alone is not proof that its current content belongs to the
playbook. Run this read-only guard before the first mutation:

```sh
uninstall_managed_file_preflight() {
    if [ ! -d "$1/rules" ] || [ ! -f "$2/VERSION" ]; then
        printf 'Uninstall/restore blocked: installed rules or matching source unavailable.\n' >&2
        return 2
    fi
    if printf '%s' "$1$2" | LC_ALL=C grep -q '[[:cntrl:]]'; then
        printf 'Uninstall/restore blocked: ambiguous path encoding.\n' >&2
        return 2
    fi
    release_version=$(sed -n '1p' "$2/VERSION")
    if ! source_trust_preflight "$2" "$release_version" "${3:-}" ||
       ! destination_root_preflight "$1" ||
       ! grep -Fq "**This rulebook is version $release_version**" "$1/CLAUDE.md"; then
        printf 'Uninstall/restore blocked: source is not an authenticated copy of the installed version.\n' >&2
        return 2
    fi
    case $(uname -s) in
        Linux) platform=LINUX.md ;;
        Darwin) platform=MACOS.md ;;
        MINGW*|MSYS*|CYGWIN*) platform=WINDOWS.md ;;
        *) printf 'Uninstall/restore blocked: unsupported host platform.\n' >&2; return 2 ;;
    esac
    for relative in CLAUDE.md \
        rules/AUTHORITY.md rules/CODE.md rules/COLLABORATION.md \
        rules/DESTRUCTIVE.md rules/DOCS.md rules/ENVIRONMENT.md \
        rules/QUARANTINE.md rules/REPO.md rules/REVIEWS.md rules/ROSTER.md \
        rules/SUBAGENTS.md rules/TESTING.md rules/WORKFLOW.md \
        rules/WRITING.md "rules/platform/$platform"; do
        installed=$1/$relative
        source=$trust_root/$relative
        if [ -L "$installed" ] || [ -L "$source" ] ||
           [ ! -f "$installed" ] || [ ! -f "$source" ] ||
           ! cmp -s "$installed" "$source"; then
            printf 'Uninstall/restore blocked: not proven unchanged: %s\n' "$installed" >&2
            return 2
        fi
    done
    return 0
}
uninstall_managed_file_preflight ~/.claude /path/to/exact-installed-release-checkout || exit 2
```

**If either local path or unaccounted Markdown or a symlink exists, stop before
restoring or deleting managed files.**
This applies to Fill-only, Add-only, empty, unreadable, and dangling-link local
files as well as Overrides. Keep the installation and local files unchanged.
Explain that the owner must first decide how to preserve the local files outside
the recursively loaded `rules/` directory, or adapt their installation in a
separately approved operation. This procedure never moves, edits, or deletes
them. Re-run the guard after the owner has resolved the active local paths.

Only when both local paths are absent, the tree check passes, and every current
managed file is proven unchanged may the approved uninstall/restore continue.
Before overwriting or deleting any managed destination, take a **fresh,
verified snapshot of the current** `~/.claude/CLAUDE.md` and `~/.claude/rules/`
at unique timestamped sibling paths. This is separate from step 1's old
pre-install backups: those cannot contain changes made since installation.
Never place the snapshot under the recursively loaded rules directory or
overwrite an existing backup. Read it back and verify it is complete; if
copying or verification fails, stop with the current installation untouched.
Re-run **both** read-only guards immediately before the first mutation, using
the same exact installed release checkout as the source for both. Never treat a missing staged
`CLAUDE.md` as a passed preflight.
This manual procedure is not atomic: if another process is writing these
paths, stop until it is quiescent. Re-check the exact file against the
installed-release source immediately before overwriting or deleting that file;
if it changed after the earlier guard, preserve it and stop.

Restore the timestamped backups from step 1 over `~/.claude/CLAUDE.md` and the
rule files in `~/.claude/rules/` — **file by file, and never `LOCAL.md` or
`LOCAL_dev.md`.** Restoring a whole backup directory over `rules/` would put back
an old copy of a local file the user has changed since, and that is the one loss
this design exists to prevent. If there were no backups, the user had no previous
rulebook — **only after the exact-content and fresh-snapshot preflights pass**,
delete only the fourteen named managed rule files and the single
installed managed platform `.md` file, each by its exact path, then
`~/.claude/CLAUDE.md`. Remove `~/.claude/rules/platform/` with `rmdir` only
if it is empty. If any other content remains, preserve it and report it;
never recursively delete that directory or the rules directory.

If a local path appears during the operation, stop and report exactly what has
already changed. It is the user's own writing, not this bundle's — never restore
over it, delete it, or claim the uninstall completed safely.
