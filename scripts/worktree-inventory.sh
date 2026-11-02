#!/bin/sh
#
# worktree-inventory.sh — rule 13.7's inventory, mechanically.
#
# Lists every worktree of one repository, reads its lock reason (the
# `key=value` marker rule 13.7 asks every creator to write), measures what git
# can prove about it, and sorts it into the five groups of rule 13.7's
# inventory: running, ready to merge, paused or not ready, merged or empty,
# unclaimed or orphaned. It also flags a worktree that lives outside the
# repository's one home, `<repo>_lanes/`, and a pause past its `until=` date.
#
# It is READ-ONLY toward every worktree: it never removes, moves, locks,
# unlocks, commits, stashes or fetches anything. The one thing it may write is
# the status page `<repo>_lanes/README.md`, and only with --write; that page is
# generated, so rerunning the script replaces it.
#
# What it cannot decide, and says so: whether an ignored file is regenerable
# build output or something to keep (a `.env`, a database). It counts ignored
# entries and leaves that judgement to rule 13.1. "Empty" here therefore means
# "pushed, no modified or untracked files, no stash" — the reader still checks
# the ignored count before removing.
#
# Usage:
#   worktree-inventory.sh [--repo <path>] [--target <ref>] [--write] [--today <YYYY-MM-DD>]
#
#   --repo <path>    the repository (any of its worktrees). Default: the
#                    current directory.
#   --target <ref>   the line a worktree counts as merged into. Default: the
#                    remote's default branch (origin/HEAD), else origin/main,
#                    else main.
#   --write          also write the page to <repo>_lanes/README.md, creating
#                    the folder if needed.
#   --today <date>   the date to judge `until=` against (tests use it).
#                    Default: today, UTC.
#
# Exit status: 0 on success, 2 on a usage error or a path that is not a git
# repository.

set -u
LC_ALL=C
export LC_ALL

repo=.
target=
write=0
today=$(date -u +%Y-%m-%d)

usage() {
    printf 'usage: %s [--repo <path>] [--target <ref>] [--write] [--today <YYYY-MM-DD>]\n' "$0" >&2
    exit 2
}

while [ $# -gt 0 ]; do
    case $1 in
        --repo) [ $# -ge 2 ] || usage; repo=$2; shift 2 ;;
        --target) [ $# -ge 2 ] || usage; target=$2; shift 2 ;;
        --write) write=1; shift ;;
        --today) [ $# -ge 2 ] || usage; today=$2; shift 2 ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
done

case $today in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) printf 'worktree-inventory: --today must be YYYY-MM-DD\n' >&2; exit 2 ;;
esac

if ! common=$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
    printf 'worktree-inventory: not a git repository: %s\n' "$repo" >&2
    exit 2
fi
# The main worktree is the parent of the common .git directory.
main=$(dirname -- "$common")
name=$(basename -- "$main")
home="$(dirname -- "$main")/${name}_lanes"

if [ -z "$target" ]; then
    if t=$(git -C "$main" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null); then
        target=$t
    elif git -C "$main" rev-parse --verify --quiet refs/remotes/origin/main >/dev/null; then
        target=origin/main
    else
        target=main
    fi
fi
if ! git -C "$main" rev-parse --verify --quiet "$target^{commit}" >/dev/null; then
    printf 'worktree-inventory: target %s does not resolve\n' "$target" >&2
    exit 2
fi

# A value from a `key=value; key=value` lock reason. Empty when absent.
reason_value() {
    printf '%s\n' "$1" | tr ';' '\n' | sed -n "s/^[[:space:]]*$2=//p" | sed 's/[[:space:]]*$//' | head -n 1
}

# One record per worktree, fields separated by a tab:
# path, head, branch, locked(0/1), reason, prunable(0/1). The separator is
# the ASCII unit separator, not a tab: `read` collapses runs of a whitespace
# separator, so an empty lock reason would shift every later field.
records=$(git -C "$main" worktree list --porcelain | awk '
    function flush() {
        if (path != "") printf "%s\037%s\037%s\037%s\037%s\037%s\n", path, head, branch, locked, reason, prunable
        path = ""; head = ""; branch = "(detached)"; locked = 0; reason = ""; prunable = 0
    }
    BEGIN { path = ""; branch = "(detached)"; locked = 0; prunable = 0 }
    /^worktree / { flush(); path = substr($0, 10); next }
    /^HEAD / { head = substr($0, 6); next }
    /^branch / { branch = substr($0, 8); sub(/^refs\/heads\//, "", branch); next }
    /^locked/ { locked = 1; reason = substr($0, 8); next }
    /^prunable/ { prunable = 1; next }
    END { flush() }
')

sep=$(printf '\037')
out_running=; out_ready=; out_paused=; out_done=; out_unclaimed=
n_total=0; n_outside=0

row() {
    # path | branch | state | HEAD | pushed | merged | modified | untracked | ignored | stash | notes
    printf '| `%s` | `%s` | %s | `%s` | %s | %s | %s | %s | %s | %s | %s |\n' "$@"
}

first=1
while IFS=$sep read -r path head branch locked reason prunable; do
    [ -n "$path" ] || continue
    if [ "$first" = 1 ]; then first=0; continue; fi    # the main worktree
    n_total=$((n_total + 1))
    short=$(printf '%.8s' "$head")
    notes=

    case $path in
        "$home"/*) ;;
        *) notes="outside \`${name}_lanes/\`"; n_outside=$((n_outside + 1)) ;;
    esac

    if [ "$prunable" = 1 ] || [ ! -d "$path" ]; then
        notes="${notes:+$notes; }folder missing: \`git worktree prune\` clears it"
        out_unclaimed="$out_unclaimed$(row "$path" "$branch" "gone" "$short" "-" "-" "-" "-" "-" "-" "$notes")
"
        continue
    fi

    if git -C "$main" branch -r --contains "$head" 2>/dev/null | grep -q .; then pushed=yes; else pushed=no; fi
    if git -C "$main" merge-base --is-ancestor "$head" "$target" 2>/dev/null; then merged=yes; else merged=no; fi
    st=$(git -C "$path" status --porcelain --ignored --untracked-files=all 2>/dev/null)
    modified=$(printf '%s' "$st" | grep -c '^[^?!]' || true)
    untracked=$(printf '%s' "$st" | grep -c '^?? ' || true)
    ignored=$(printf '%s' "$st" | grep -c '^!! ' || true)
    stash=$(git -C "$main" stash list --format='%gs' 2>/dev/null | grep -c " on $branch:" || true)
    [ "$branch" = "(detached)" ] && stash=0

    state=
    if [ "$locked" = 1 ]; then
        state=$(reason_value "$reason" state)
        owner=$(reason_value "$reason" owner)
        [ -n "$owner" ] && notes="${notes:+$notes; }owner $owner"
        [ -z "$state" ] && notes="${notes:+$notes; }lock reason has no state="
    fi
    [ -n "$state" ] || state=unclaimed

    clean=no
    if [ "$pushed" = yes ] && [ "$modified" = 0 ] && [ "$untracked" = 0 ] && [ "$stash" = 0 ]; then clean=yes; fi
    [ "$ignored" != 0 ] && notes="${notes:+$notes; }check ignored files (rule 13.1)"

    line=$(row "$path" "$branch" "$state" "$short" "$pushed" "$merged" "$modified" "$untracked" "$ignored" "$stash" "${notes:--}")

    if [ "$merged" = yes ] && [ "$clean" = yes ]; then
        out_done="$out_done$line
"
        continue
    fi
    case $state in
        running)
            out_running="$out_running$line
" ;;
        ready-to-merge)
            out_ready="$out_ready$line
" ;;
        paused|not-ready)
            until=$(reason_value "$reason" until)
            why=$(reason_value "$reason" why)
            flag=
            if [ -z "$until" ]; then flag="no until="
            elif [ "$until" \< "$today" ]; then flag="past until=$until"
            fi
            [ -z "$why" ] && flag="${flag:+$flag; }no why="
            [ -n "$flag" ] && line=$(row "$path" "$branch" "$state" "$short" "$pushed" "$merged" "$modified" "$untracked" "$ignored" "$stash" "${notes:+$notes; }**$flag**")
            out_paused="$out_paused$line
" ;;
        *)
            if [ "$clean" = yes ]; then
                line=$(row "$path" "$branch" "$state" "$short" "$pushed" "$merged" "$modified" "$untracked" "$ignored" "$stash" "${notes:+$notes; }empty")
            fi
            out_unclaimed="$out_unclaimed$line
" ;;
    esac
done <<EOF
$records
EOF

section() {
    printf '\n## %s\n\n' "$1"
    if [ -z "$2" ]; then
        printf 'None.\n'
    else
        printf '| Worktree | Branch | State | HEAD | Pushed | Merged | Modified | Untracked | Ignored | Stash | Notes |\n'
        printf '|---|---|---|---|---|---|---|---|---|---|---|\n'
        printf '%s' "$2"
    fi
}

page() {
    printf '# Worktrees of `%s`\n\n' "$name"
    printf 'Generated by `worktree-inventory.sh` on %s against `%s`. Read-only: it removed nothing. ' "$today" "$target"
    printf 'Rule 13.7 decides what happens to each group; this page only reports.\n\n'
    printf '%s worktrees besides the main checkout; %s outside `%s_lanes/`.\n' "$n_total" "$n_outside" "$name"
    section 'Running' "$out_running"
    section 'Ready to merge' "$out_ready"
    section 'Paused or not ready' "$out_paused"
    section 'Merged or empty (pushed, merged, nothing modified or untracked, no stash)' "$out_done"
    section 'Unclaimed or orphaned' "$out_unclaimed"
}

if [ "$write" = 1 ]; then
    mkdir -p -- "$home" || exit 2
    tmp="$home/.README.md.$$"
    page >"$tmp" && mv -f -- "$tmp" "$home/README.md" || { rm -f -- "$tmp"; exit 2; }
    printf 'wrote %s/README.md\n' "$home"
fi
page
