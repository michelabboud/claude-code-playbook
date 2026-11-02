#!/bin/sh
#
# tests/worktree_inventory_test.sh — scripts/worktree-inventory.sh sorts every
# worktree into rule 13.7's groups, reads key=value lock reasons, flags stale
# pauses and worktrees outside <repo>_lanes/, and never changes a worktree.
#
#   sh tests/worktree_inventory_test.sh
#
# Every fixture is a throwaway repository under this suite's own temporary
# directory, with a bare repository as its remote.

set -u
HERE=$(dirname -- "$0")
. "$HERE/lib.sh"
ROOT=${1:-$HERE/..}
SCRIPT=$ROOT/scripts/worktree-inventory.sh
TMPROOT=$(make_tmpdir) || exit 2
trap 'cleanup_tmpdir "$TMPROOT"' EXIT INT TERM HUP

g() { git -c user.name=Fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false "$@"; }

W=$TMPROOT/work
mkdir -p "$W" || exit 2
g init -q --bare "$W/remote.git" || exit 2
g init -q -b main "$W/proj" || exit 2
printf 'one\n' >"$W/proj/file.txt"
g -C "$W/proj" add file.txt && g -C "$W/proj" commit -qm one || exit 2
g -C "$W/proj" remote add origin "$W/remote.git" && g -C "$W/proj" push -q origin main 2>/dev/null || exit 2
g -C "$W/proj" remote set-head origin main >/dev/null 2>&1 || true
L=$W/proj_lanes

# running: locked, unmerged commit, pushed.
g -C "$W/proj" worktree add -q -b lane-run "$L/run" main || exit 2
printf 'run\n' >>"$L/run/file.txt"; g -C "$L/run" commit -qam run && g -C "$L/run" push -q origin lane-run 2>/dev/null
g -C "$W/proj" worktree lock --reason "owner=lane-a; task=T1; created=2026-10-01; state=running" "$L/run"

# ready to merge: unmerged, pushed.
g -C "$W/proj" worktree add -q -b lane-ready "$L/ready" main || exit 2
printf 'ready\n' >>"$L/ready/file.txt"; g -C "$L/ready" commit -qam ready && g -C "$L/ready" push -q origin lane-ready 2>/dev/null
g -C "$W/proj" worktree lock --reason "owner=lane-b; task=T2; created=2026-10-01; state=ready-to-merge" "$L/ready"

# paused past its until date, with uncommitted work.
g -C "$W/proj" worktree add -q -b lane-paused "$L/paused" main || exit 2
printf 'wip\n' >>"$L/paused/file.txt"; g -C "$L/paused" commit -qam wip && g -C "$L/paused" push -q origin lane-paused 2>/dev/null
printf 'more wip\n' >>"$L/paused/file.txt"
g -C "$W/proj" worktree lock --reason "owner=lane-c; task=T3; created=2026-10-01; state=paused; since=2026-10-02; until=2026-10-10; why=budget" "$L/paused"

# paused with no until= and no why=.
g -C "$W/proj" worktree add -q -b lane-paused2 "$L/paused2" main || exit 2
printf 'p2\n' >>"$L/paused2/file.txt"; g -C "$L/paused2" commit -qam p2 && g -C "$L/paused2" push -q origin lane-paused2 2>/dev/null
g -C "$W/proj" worktree lock --reason "owner=lane-d; task=T4; created=2026-10-01; state=paused" "$L/paused2"

# merged: a branch at main's own commit, pushed, clean, unlocked.
g -C "$W/proj" worktree add -q -b lane-merged "$L/merged" main || exit 2
g -C "$L/merged" push -q origin lane-merged 2>/dev/null

# unclaimed with an untracked file, outside the home.
g -C "$W/proj" worktree add -q -b stray "$W/stray" main || exit 2
printf 'x\n' >"$W/stray/new.txt"
printf 'y\n' >>"$W/stray/file.txt"; g -C "$W/stray" commit -qam stray

# a worktree whose folder is gone.
g -C "$W/proj" worktree add -q -b lane-gone "$L/gone" main || exit 2

locks_before=$(g -C "$W/proj" worktree list --porcelain | grep -c '^locked')

rm -r "$L/gone"
before=$(cd "$W" && find . -path ./remote.git -prune -o -type f -print | sort | while read -r f; do cksum "$f"; done)

out=$(sh "$SCRIPT" --repo "$W/proj" --today 2026-10-26 2>&1)
assert_status "the inventory exits 0" 0 $?

sect() { printf '%s\n' "$out" | awk -v h="## $1" '$0 == h {on=1; next} /^## / {on=0} on'; }

assert_contains "a running worktree is in Running" "$(sect 'Running')" "$L/run"
assert_contains "a running worktree's owner is read from its lock reason" "$(sect 'Running')" 'owner lane-a'
assert_contains "a ready worktree is in Ready to merge" "$(sect 'Ready to merge')" "$L/ready"
assert_contains "a paused worktree is in Paused" "$(sect 'Paused or not ready')" "$L/paused\`"
assert_contains "a pause past its until= date is flagged" "$(sect 'Paused or not ready')" '**past until=2026-10-10**'
assert_contains "a pause with no until= and no why= is flagged" "$(sect 'Paused or not ready')" '**no until=; no why=**'
assert_contains "a merged, pushed, clean worktree is in Merged or empty" "$(sect 'Merged or empty (pushed, merged, nothing modified or untracked, no stash)')" "$L/merged"
assert_not_contains "a paused worktree with uncommitted work is never in Merged or empty" "$(sect 'Merged or empty (pushed, merged, nothing modified or untracked, no stash)')" "$L/paused\`"
assert_contains "an unlocked worktree is Unclaimed" "$(sect 'Unclaimed or orphaned')" "$W/stray"
assert_contains "a worktree outside <repo>_lanes/ is flagged" "$(sect 'Unclaimed or orphaned')" 'outside `proj_lanes/`'
assert_contains "a worktree whose folder is gone is reported, with the prune hint" "$(sect 'Unclaimed or orphaned')" 'git worktree prune'
assert_contains "the header counts worktrees and those outside the home" "$out" '7 worktrees besides the main checkout; 1 outside `proj_lanes/`.'
assert_contains "the stray worktree's untracked file is counted" "$(sect 'Unclaimed or orphaned' | grep "$W/stray")" '| no | no | 0 | 1 | 0 | 0 |'

after=$(cd "$W" && find . -path ./remote.git -prune -o -type f -print | sort | while read -r f; do cksum "$f"; done)
assert_eq "without --write the inventory changes no file" "$before" "$after"
assert_eq "the inventory leaves every lock in place" "$locks_before" "$(g -C "$W/proj" worktree list --porcelain | grep -c '^locked')"

sh "$SCRIPT" --repo "$L/run" --today 2026-10-26 --write >/dev/null 2>&1
assert_status "--write exits 0, run from inside a lane's worktree" 0 $?
assert_eq "--write writes <repo>_lanes/README.md" 1 "$( [ -f "$L/README.md" ] && echo 1 || echo 0)"
assert_contains "the page names the repository" "$(cat "$L/README.md" 2>/dev/null)" '# Worktrees of `proj`'

sh "$SCRIPT" --repo "$TMPROOT" >/dev/null 2>&1
assert_status "a path that is not a repository is exit 2" 2 $?
sh "$SCRIPT" --repo "$W/proj" --today 26-10-2026 >/dev/null 2>&1
assert_status "a malformed --today is exit 2" 2 $?
sh "$SCRIPT" --repo "$W/proj" --target no-such-ref >/dev/null 2>&1
assert_status "a target that does not resolve is exit 2" 2 $?

finish
