#!/bin/sh
#
# tests/rules_text_test.sh — the local layer's three hooks are in the rulebook,
# in exactly the files that should carry them and nowhere else; the shipped
# bundle holds nothing but rule files; and the templates match what they claim.
#
#   sh tests/rules_text_test.sh [repo-root]
#
# The optional argument exists so tests/rules_text_mutation_test.sh can point
# this suite at a copy of the repository with one thing broken, and prove the
# suite notices.
#
# Every required string is pinned so that it cannot be satisfied by another
# occurrence: each assertion checks the count in the file that should carry it
# AND the count in every file that should not. A wording test that passes
# because the string happens to appear somewhere else is not a test.
#
# The only temporary directory used is one this run creates and removes.

set -u

HERE=$(dirname -- "$0")
. "$HERE/lib.sh"

ROOT=${1:-$HERE/..}

SCOPED='CODE TESTING WORKFLOW SUBAGENTS REVIEWS ROSTER'
UNSCOPED='AUTHORITY COLLABORATION DESTRUCTIVE DOCS ENVIRONMENT REPO WRITING'
# Scoped to its trigger, not to source: the source-scoped invariants (hook 2,
# the shared frontmatter) do not apply to it (ADR 0011).
TRIGGER='QUARANTINE HYGIENE'
PLATFORM='LINUX MACOS WINDOWS'

HOOK2='*Local layer: if `~/.claude/rules/LOCAL_dev.md` exists, read it with this file — its entries for this section win over the wording here (section 0, "The local layer").*'
HOOK1='**The local layer:** `rules/LOCAL.md` (loads every session) and `rules/LOCAL_dev.md` (loads with the source-scoped sections) are mine, never the playbook'"'"'s'
HOOK3='*My own customizations live in `rules/LOCAL.md` and `rules/LOCAL_dev.md` — the local layer.'

# ---------------------------------------------------------------------------
# Hook 2 — the pointer line, in the six source-scoped files and nowhere else.
# ---------------------------------------------------------------------------
for f in $SCOPED; do
    assert_eq "hook 2 appears exactly once in rules/$f.md" \
        1 "$(count_in_file "$HOOK2" "$ROOT/rules/$f.md")"
done
for f in $UNSCOPED $TRIGGER; do
    assert_eq "hook 2 is absent from rules/$f.md" \
        0 "$(count_in_file "$HOOK2" "$ROOT/rules/$f.md")"
done
for f in $PLATFORM; do
    assert_eq "hook 2 is absent from rules/platform/$f.md" \
        0 "$(count_in_file "$HOOK2" "$ROOT/rules/platform/$f.md")"
done
assert_eq "hook 2 is absent from CLAUDE.md" \
    0 "$(count_in_file "$HOOK2" "$ROOT/CLAUDE.md")"

# It must sit in the header, right after the file's own "*Read …*" line, not
# buried in the body: line 18 in each file as the headers stand.
for f in $SCOPED; do
    line=$(grep -F -n -e "$HOOK2" -- "$ROOT/rules/$f.md" | cut -d: -f1)
    prev=$(sed -n "$((line - 2))p" "$ROOT/rules/$f.md")
    assert_contains "hook 2 in rules/$f.md follows the file's own Read line" \
        "$prev" '*Read '
done

# ---------------------------------------------------------------------------
# Hook 1 — the local-layer paragraph, in section 0 and nowhere else.
# ---------------------------------------------------------------------------
assert_eq "hook 1 appears exactly once in rules/AUTHORITY.md" \
    1 "$(count_in_file "$HOOK1" "$ROOT/rules/AUTHORITY.md")"
for f in $SCOPED $UNSCOPED $TRIGGER; do
    [ "$f" = AUTHORITY ] && continue
    assert_eq "hook 1 is absent from rules/$f.md" \
        0 "$(count_in_file "$HOOK1" "$ROOT/rules/$f.md")"
done
assert_eq "hook 1 is absent from CLAUDE.md" \
    0 "$(count_in_file "$HOOK1" "$ROOT/CLAUDE.md")"

# The paragraph says the things the decision requires it to say — and says them
# IN THE PARAGRAPH. Counting per file would pass just as happily with the
# sentence moved to the end of the file or into the approval table's region,
# where nobody reading the local layer's rule would ever see it.
A=$ROOT/rules/AUTHORITY.md
PARA=$(paragraph_with "$HOOK1" "$A")
assert_contains "the section-0 paragraph was found at all" "$PARA" 'The local layer:'
assert_eq "section 0's paragraph limits local entries to a safe boundary" \
    1 "$(count_in_text 'A local entry may never expand authority, remove an approval, relax a safety, destructive, security, or secret-handling constraint, change precedence, or override this paragraph.' "$PARA")"
assert_eq "section 0's paragraph defines a Fill" \
    1 "$(count_in_text 'A **Fill** supplies only a value a rule leaves open' "$PARA")"
assert_eq "section 0's paragraph defines an Add and reserves the L numbers" \
    1 "$(count_in_text 'non-authorizing guidance or a stricter constraint' "$PARA")"
assert_eq "section 0's paragraph defines an Override and its stale case" \
    1 "$(count_in_text 'A stale Override is **suspended**: tell me before relying on it' "$PARA")"
assert_eq "section 0's paragraph says an absent local file means nothing is customized" \
    1 "$(count_in_text 'A local file that is absent means nothing is customized.' "$PARA")"
assert_eq "section 0's paragraph denies the local layer any new authority" \
    1 "$(count_in_text 'Its authority comes only from this paragraph and never extends beyond it.' "$PARA")"

# The claim the mechanical review corrected: the check script reads both local
# files, so "never opens them" was never true. What the paragraph may say is
# that nothing writes to them.
assert_eq "section 0's paragraph says an update never writes to, copies over or replaces the local files" \
    1 "$(count_in_text 'an update replaces the playbook'"'"'s files and never writes to, copies over or replaces these two' "$PARA")"
for f in $SCOPED $UNSCOPED $TRIGGER; do
    assert_eq "rules/$f.md never claims the playbook does not open the local files" \
        0 "$(count_in_file 'without opening these two' "$ROOT/rules/$f.md")"
done

# The paragraph goes after Precedence, which is where the decision put it.
prec=$(grep -F -n -e '**Precedence:**' -- "$A" | head -1 | cut -d: -f1)
loc=$(grep -F -n -e "$HOOK1" -- "$A" | head -1 | cut -d: -f1)
if [ "$loc" -gt "$prec" ] && [ "$((loc - prec))" -le 3 ]; then
    _pass "the local-layer paragraph directly follows Precedence"
else
    _fail "the local-layer paragraph directly follows Precedence" \
        "Precedence at line $prec, local layer at line $loc"
fi

# The header's count of subject files is still true.
rulecount=0
rulenames=''
for p in "$ROOT"/rules/*.md; do
    rulecount=$((rulecount + 1))
    rulenames="$rulenames ${p##*/}"
done
rulenames=${rulenames# }
subject=$((rulecount - 1))
assert_eq "section 0's header still says the right number of subject files" \
    14 "$subject"
assert_eq "section 0's header says fourteen subject files" \
    1 "$(count_in_file 'fourteen subject files' "$A")"

# ---------------------------------------------------------------------------
# Hook 3 — CLAUDE.md names the layer, and its self-update paragraph is rewritten.
# ---------------------------------------------------------------------------
C=$ROOT/CLAUDE.md
assert_eq "hook 3 appears exactly once in CLAUDE.md" \
    1 "$(count_in_file "$HOOK3" "$C")"
for f in $SCOPED $UNSCOPED $TRIGGER; do
    assert_eq "hook 3 is absent from rules/$f.md" \
        0 "$(count_in_file "$HOOK3" "$ROOT/rules/$f.md")"
done

# Hook 3 belongs to the front page's preamble, beside the self-update paragraph
# it depends on — not parked at the end of the file, where a reader who has
# already reached the section index will never meet it.
h3=$(grep -F -n -e "$HOOK3" -- "$C" | head -1 | cut -d: -f1)
ver=$(grep -F -n -e 'This rulebook is version' -- "$C" | head -1 | cut -d: -f1)
index=$(grep -F -n -e '## The rulebook' -- "$C" | head -1 | cut -d: -f1)
if [ "$h3" -gt "$ver" ] && [ "$h3" -lt "$index" ]; then
    _pass "hook 3 sits in CLAUDE.md's preamble, before the section index"
else
    _fail "hook 3 sits in CLAUDE.md's preamble, before the section index" \
        "version line $ver, hook 3 line $h3, section index line $index"
fi

# The self-update paragraph, asserted inside the paragraph.
SELF=$(paragraph_with 'stop and ask before replacing anything.' "$C")
assert_contains "the self-update paragraph was found at all" "$SELF" 'rule 10.2 action'
assert_eq "the self-update paragraph no longer claims an update overwrites tailored files" \
    0 "$(count_in_file 'Updating overwrites files I may have tailored' "$C")"
assert_eq "the self-update paragraph no longer names four tailorable places" \
    0 "$(count_in_file 'four places are explicitly meant to be tailored' "$C")"
assert_eq "the self-update paragraph still stops and asks before replacing" \
    1 "$(count_in_text 'stop and ask before replacing anything.' "$SELF")"
assert_eq "the self-update paragraph still calls an update a rule 10.2 action" \
    1 "$(count_in_text 'it is a rule 10.2 action: back up first, verify the backup, and only then copy' "$SELF")"
assert_eq "the self-update paragraph says customizations survive an update" \
    1 "$(count_in_text 'they live in the local layer, which an update never writes to, copies over or replaces' "$SELF")"
assert_eq "the self-update paragraph runs the check against the new text first" \
    1 "$(count_in_text 'scripts/check-local.sh` is run against the new text before anything is copied' "$SELF")"
assert_eq "the self-update paragraph still points at INSTALL.md" \
    1 "$(count_in_text 'The full procedure is `INSTALL.md` in the repo' "$SELF")"
assert_eq "CLAUDE.md still reads VERSION as the source of truth" \
    1 "$(count_in_file 'The `VERSION` file is the single source of truth' "$C")"

# Hook 3's own paragraph carries the two things it exists to say.
H3PARA=$(paragraph_with "$HOOK3" "$C")
assert_eq "hook 3's paragraph says the playbook never ships the local files" \
    1 "$(count_in_text 'The playbook never ships them' "$H3PARA")"
assert_eq "hook 3's paragraph states the local boundary" \
    1 "$(count_in_text 'They may fill open values, add non-authorizing guidance, or tighten a constraint' "$H3PARA")"
assert_eq "CLAUDE.md never claims the playbook does not touch the local files" \
    0 "$(count_in_file 'never ships or touches' "$C")"

# ---------------------------------------------------------------------------
# The bundle ships no local file, and nothing but rule files.
# ---------------------------------------------------------------------------
if [ -e "$ROOT/rules/LOCAL.md" ] || [ -e "$ROOT/rules/LOCAL_dev.md" ]; then
    _fail "the playbook ships no local file" "found one under rules/"
else
    _pass "the playbook ships no local file"
fi

nonmd=$(find "$ROOT/rules" -type f ! -name '*.md' | head -5)
assert_eq "every file under rules/ is a Markdown rule file" "" "$nonmd"

# The rules directory holds exactly the files it is supposed to hold.
expected='AUTHORITY.md CODE.md COLLABORATION.md DESTRUCTIVE.md DOCS.md ENVIRONMENT.md HYGIENE.md QUARANTINE.md REPO.md REVIEWS.md ROSTER.md SUBAGENTS.md TESTING.md WORKFLOW.md WRITING.md'
assert_eq "rules/ holds exactly the playbook's rule files" "$expected" "$rulenames"

assert_eq "the templates live outside rules/" \
    0 "$(find "$ROOT/rules" -type d -name templates | wc -l | tr -d ' ')"
for t in LOCAL.md LOCAL_dev.md; do
    if [ -f "$ROOT/templates/$t" ]; then
        _pass "templates/$t exists"
    else
        _fail "templates/$t exists" "not found"
    fi
done

# ---------------------------------------------------------------------------
# The LOCAL_dev template's frontmatter is byte-identical to the six scoped files.
# ---------------------------------------------------------------------------
TMPROOT=$(make_tmpdir) || { printf 'cannot make a temp dir\n' >&2; exit 2; }
trap 'cleanup_tmpdir "$TMPROOT"' EXIT INT TERM HUP

frontmatter "$ROOT/templates/LOCAL_dev.md" >"$TMPROOT/tmpl.fm"
if [ ! -s "$TMPROOT/tmpl.fm" ]; then
    _fail "templates/LOCAL_dev.md carries YAML frontmatter" "none found"
else
    _pass "templates/LOCAL_dev.md carries YAML frontmatter"
fi
for f in $SCOPED; do
    frontmatter "$ROOT/rules/$f.md" >"$TMPROOT/$f.fm"
    assert_files_identical \
        "templates/LOCAL_dev.md's paths: block is byte-identical to rules/$f.md's" \
        "$TMPROOT/tmpl.fm" "$TMPROOT/$f.fm"
done
assert_contains "the shared frontmatter really is a paths: scope" \
    "$(cat "$TMPROOT/tmpl.fm")" 'paths:'

# The always-loaded template must NOT carry a paths: scope — it loads always.
assert_eq "templates/LOCAL.md carries no paths: scope" \
    0 "$(count_in_file 'paths:' "$ROOT/templates/LOCAL.md")"

# ---------------------------------------------------------------------------
# The context budget (ADR 0011): what loads every session, and what section 0
# summarises.
# ---------------------------------------------------------------------------
for f in $UNSCOPED; do
    assert_eq "rules/$f.md carries no paths: scope — it loads every session" \
        0 "$(frontmatter "$ROOT/rules/$f.md" | grep -c 'paths:')"
done
for f in $PLATFORM; do
    assert_eq "rules/platform/$f.md carries no paths: scope" \
        0 "$(frontmatter "$ROOT/rules/platform/$f.md" | grep -c 'paths:')"
done
frontmatter "$ROOT/rules/QUARANTINE.md" >"$TMPROOT/quarantine.fm"
assert_contains "rules/QUARANTINE.md carries a paths: scope" \
    "$(cat "$TMPROOT/quarantine.fm")" 'paths:'
assert_contains "rules/QUARANTINE.md is scoped to the quarantine vault" \
    "$(cat "$TMPROOT/quarantine.fm")" '"**/.quarantine/**"'
# The safety net for a scoped procedure: the always-loaded file sends the agent
# to it by path.
assert_eq "DESTRUCTIVE.md tells the agent to read the quarantine procedure by path" \
    1 "$(count_in_file 'it does not load every session, so read it by path before your first quarantine of a session' "$ROOT/rules/DESTRUCTIVE.md")"

# Section 0 summarises only sections whose file may be absent from context.
for n in 4 5 7 9 11 12; do
    assert_eq "section 0 does not summarise always-loaded section $n" \
        0 "$(grep -c "^### $n · " "$A")"
done
assert_eq "section 0 does not summarise rules 10.1–10.2, which are always loaded" \
    0 "$(grep -c '^| 10\.[12] |' "$A")"
for n in 1 2 3 6 8 10.3 13; do
    assert_eq "section 0 summarises section $n" \
        1 "$(grep -c "^### $n · " "$A")"
done
assert_eq "section 0 says which sections it does not summarise" \
    1 "$(count_in_file '**Always in context, never summarised:**' "$A")"

# Path scopes stop at the project (ADR 0012): section 0's header and the front
# page make reading the dev files by path a duty for code outside it.
HDR=$(paragraph_with 'This file plus the Mantra is the whole of what you must know' "$A")
assert_eq "section 0's header says a paths: scope only matches inside the project" \
    1 "$(count_in_text "**A \`paths:\` scope only matches files inside the session's project**" "$HDR")"
assert_eq "section 0's header makes CODE.md and TESTING.md a read-by-path duty outside the project" \
    1 "$(count_in_text 'read `CODE.md` and `TESTING.md` by path, and `LOCAL_dev.md` if it exists' "$HDR")"
assert_eq "CLAUDE.md states the project boundary of path scopes" \
    1 "$(count_in_file "A \`paths:\` scope only matches files inside the session's project, so for code outside it" "$ROOT/CLAUDE.md")"

# Economy mode: switched on by the owner only, code review only, recorded, and
# its models named only in the roster.
R=$ROOT/rules/REVIEWS.md
ECO=$(paragraph_with '**Economy mode — on my word only.**' "$R")
assert_contains "REVIEWS.md carries the economy-mode rule" "$ECO" 'Economy mode'
assert_eq "economy mode is never switched on by the agent to save cost" \
    1 "$(count_in_text 'you never switch it on yourself to save cost' "$ECO")"
assert_eq "economy mode covers code review only; planning stays on Top" \
    1 "$(count_in_text 'planning and design stay on the Top tier' "$ECO")"
assert_eq "economy mode keeps the pair dual-blind and cross-family" \
    1 "$(count_in_text 'the pair stays dual-blind and cross-family' "$ECO")"
assert_eq "economy mode is recorded in every review it runs" \
    1 "$(count_in_text 'every review it runs says *economy mode* in its header' "$ECO")"
assert_eq "the release gate says so in economy mode" \
    1 "$(count_in_file 'In economy mode (rule 3.1) it runs on the economy configuration, and its record says so.' "$R")"
RO=$ROOT/rules/ROSTER.md
assert_eq "the roster seats economy's Claude reviewer on Opus 5.5 at xhigh" \
    1 "$(count_in_file '| **Top**, Claude | **Claude Fable** | **Claude Opus 5.5 at `xhigh` effort** |' "$RO")"
assert_eq "the roster seats economy's second-family reviewer on GPT-6 Sol at xhigh" \
    1 "$(count_in_file '| **Top**, second family | GPT-6 Astra | **GPT-6 Sol at `xhigh` effort** |' "$RO")"
assert_eq "REVIEWS.md names no model for economy mode — the roster does" \
    0 "$(grep -c 'Opus 5.5\|GPT-6 Sol' "$R")"
assert_eq "section 0's review summary mentions economy mode" \
    1 "$(count_in_file 'except in **economy mode**, on my word only' "$A")"

# Refused means stop, and worktrees go through git (0.1.20).
DS=$ROOT/rules/DESTRUCTIVE.md
R101=$(paragraph_with '10.1 **Destructive actions need my OK**' "$DS")
assert_eq "rule 10.1 says a blocked command is a stop, not a spelling problem" \
    1 "$(count_in_text '**A blocked command is a stop, not a spelling problem.**' "$R101")"
assert_eq "rule 10.1 forbids re-issuing a refused effect in another form" \
    1 "$(count_in_text 'never re-issue the same effect in another form' "$R101")"
# Section 13, hygiene (0.1.21): the worktree procedure moved here from 10.2.
H=$ROOT/rules/HYGIENE.md
frontmatter "$H" >"$TMPROOT/hygiene.fm"
assert_contains "rules/HYGIENE.md carries a paths: scope" "$(cat "$TMPROOT/hygiene.fm")" 'paths:'
assert_contains "rules/HYGIENE.md is scoped to worktree folders" "$(cat "$TMPROOT/hygiene.fm")" '"**/.worktrees/**"'
WT=$(paragraph_with '13.3 **Worktrees are removed through git, never by deleting their folder, and only after three read-only checks.**' "$H")
WT2=$(paragraph_with 'Then run `git worktree remove <path>`, without `--force`, alone' "$H")
assert_contains "HYGIENE.md carries the worktree checks" "$WT" 'Worktrees are removed through git'
assert_eq "check 1: ignored files are inspected, since remove deletes them silently" \
    1 "$(count_in_text '`git worktree remove` deletes ignored files silently, so preserve or quarantine them first' "$WT")"
assert_eq "check 1: a quarantined tracked file is restored so git allows removal" \
    1 "$(count_in_text 'restore its committed version (`git -C <worktree> restore <file>`)' "$WT")"
assert_eq "check 2: commits must be reachable from a branch or tag" \
    1 "$(count_in_text '`git -C <worktree> for-each-ref --contains HEAD refs/heads refs/tags` must print a ref' "$WT")"
assert_eq "check 2: a stash alone does not count" \
    1 "$(count_in_text 'A stash or a remote-tracking ref alone is not enough' "$WT")"
assert_eq "check 3: not in use, not locked by another lane" \
    1 "$(count_in_text 'no running process works in it, and no other lane has it locked' "$WT")"
assert_eq "a refused removal is fixed, not forced" \
    1 "$(count_in_text 'If git refuses, fix the cause it names instead of forcing' "$WT2")"
assert_eq "deleting a worktree folder with rm is a destructive act" \
    1 "$(count_in_text 'Deleting a worktree'"'"'s folder with `rm`, or passing `--force`, skips git'"'"'s checks and is a destructive act under rule 10.1' "$WT2")"
assert_eq "the creating lane owns worktrees, a reviewer's detached one included" \
    1 "$(count_in_text 'including a detached one made for a reviewer' "$WT2")"
assert_eq "the owning lane locks its worktree" \
    1 "$(count_in_text 'it locks it with `git worktree lock` while it is in use, and unlocks and removes it at close-out' "$WT2")"
assert_eq "branch -d is described as no proof on its own" \
    1 "$(count_in_text 'deletes a pushed branch that the default branch never merged' "$WT2")"
assert_eq "branch deletion needs another ref holding its commits" \
    1 "$(count_in_text 'prints a ref other than `refs/heads/<branch>` itself' "$WT2")"
assert_eq "the branch check names the default branch, not main alone" \
    1 "$(count_in_text 'where `<default>` is the repository'"'"'s default branch' "$WT2")"
assert_eq "13.1: the session row excludes anything used since" \
    1 "$(count_in_file 'fixtures it built — nothing anyone has used since' "$H")"
assert_eq "13.1: the git row covers only branches another ref holds" \
    1 "$(count_in_file 'local branches whose commits another branch or tag holds' "$H")"
assert_eq "13.2: build output membership is decided by 13.1's row" \
    1 "$(count_in_file '13.1'"'"'s row, not a folder name, decides membership' "$H")"
assert_eq "branch deletion names the ancestor check against main" \
    1 "$(count_in_text '`git merge-base --is-ancestor <branch> <default>` succeeds' "$WT2")"
assert_eq "worktree prune skips locked worktrees" \
    1 "$(count_in_text 'and skips locked ones' "$WT2")"
assert_eq "a worktree another lane has locked is never removed" \
    1 "$(count_in_text 'Never remove a worktree another lane has locked' "$WT2")"
assert_eq "check 1 lists files inside ignored folders" \
    1 "$(count_in_text 'status --short --ignored --untracked-files=all' "$WT")"
assert_eq "check 2 says the exit status is not the signal" \
    1 "$(count_in_text 'its exit status is 0 either way, so the printed ref is the signal' "$WT")"
assert_eq "check 2 branches or tags a detached worktree's commits" \
    1 "$(count_in_text 'so branch or tag them first' "$WT")"
assert_eq "check 2 covers the worktree's own HEAD log" \
    1 "$(count_in_text 'if `git -C <worktree> reflog` shows commits you moved away from' "$WT")"
assert_eq "branches go with git branch -d, never -D on unique work" \
    1 "$(count_in_text 'Never use `git branch -D` on a branch with unique work' "$WT2")"
assert_eq "rule 10.1 names cargo clean as a same-effect example" \
    1 "$(count_in_text '`rm -r` or `cargo clean` for a refused `rm -rf target/`' "$R101")"
assert_eq "rule 10.1 names quarantine as the one sanctioned move" \
    1 "$(count_in_text 'rule 10.3 — the one sanctioned move' "$R101")"
assert_eq "rule 10.1 counts the owner declining as a refusal" \
    1 "$(count_in_text 'or I decline it, never re-issue' "$R101")"
H131=$(paragraph_with '13.1 **Classify before you remove.**' "$H")
assert_eq "13.1: a name or a .gitignore entry never decides the class" \
    1 "$(count_in_text 'A name (`tmp`, `old`, `backup`) or a `.gitignore` entry never decides it' "$H131")"
assert_eq "13.1: a session may remove its own temporary files" \
    1 "$(count_in_file 'including a read-only inventory'"'"'s own temporary files' "$H")"
assert_eq "13.1: protected items only on the owner's word" \
    1 "$(count_in_file '| **Protected** | `.env`, credentials, keys, databases, state files, backups, anything I created | only on my word (rule 10.2) |' "$H")"
assert_eq "13.1: unknown items are quarantined" \
    1 "$(count_in_file '| **Unknown** | anything that fits none of the above | quarantine it (rule 10.3) — unless' "$H")"
assert_eq "13.1: an in-use or live-database unknown is reported, not moved" \
    1 "$(count_in_file 'which the quarantine procedure forbids moving: list it in the report instead' "$H")"
assert_eq "13.1: overlapping classes resolve to the most protective" \
    1 "$(count_in_text 'the most protective one applies: protected, then evidence, then unknown, then the rest' "$H131")"
assert_eq "13.1: the session row covers disposable items only" \
    1 "$(count_in_file '| **Disposable, created by this session** |' "$H")"
assert_eq "13.1: evidence is kept" \
    1 "$(count_in_file 'debug dumps a document refers to | keep; compress rotated logs (rule 9.4)' "$H")"
assert_eq "13.1: regenerable means rebuilt by a manifest or build command" \
    1 "$(count_in_file 'untracked or git-ignored toolchain output that a manifest or build command beside it rebuilds' "$H")"
assert_eq "13.1: regenerable output is removed only when idle" \
    1 "$(count_in_file 'after checking no process uses it' "$H")"
assert_eq "13.1: a tracked folder with a build name is not regenerable" \
    1 "$(count_in_file 'a tracked or hand-made folder of the same name is not in this class' "$H")"
assert_eq "13.1: remote branches and tracked files are not cleanup" \
    1 "$(count_in_file 'a remote branch is outward-facing and not cleanup, and a tracked file is not cleaned up at all' "$H")"
assert_eq "13.2: only what is provably yours" \
    1 "$(count_in_text 'goes in the report (rule 13.5) and is not touched' "$(paragraph_with '13.2 **Remove only what is provably yours.**' "$H")")"
assert_eq "13.4: the marker file and its fields" \
    1 "$(count_in_file '`.hygiene.json`, recording `owner`, `task`, `created`, `disposable` (`true` or `false`) and `regenerate`' "$H")"
assert_eq "13.4: a marker you did not write is not permission" \
    1 "$(count_in_file 'A marker you did not write, or cannot show you wrote, is evidence, not permission' "$H")"
assert_eq "13.4: a marker never leaves the protected or evidence class" \
    1 "$(count_in_file 'A marker never moves an item out of the protected or evidence class' "$H")"
assert_eq "13.4: the marker starts classification, never ends it" \
    1 "$(count_in_file 'as the starting point of classification, not as its result' "$H")"
assert_eq "13.2: a marker proves ownership only with the task record" \
    1 "$(count_in_file '*and* your task'"'"'s own record — its close-out report or handoff — lists the same path' "$H")"
assert_eq "13.2: build output follows rule 10.2's carve-out" \
    1 "$(count_in_file 'rule 10.2'"'"'s build-output carve-out lets it go without an owner' "$H")"
assert_eq "13.6: never re-issue the same effect" \
    1 "$(count_in_file 'do not re-issue the same effect in another form' "$H")"
H135=$(paragraph_with '13.5 **When hygiene runs, and what it reports.**' "$H")
assert_eq "13.5: the disk floor is the local layer's, else 10 % free" \
    1 "$(count_in_text 'the one your local layer sets, or 10 % free when it sets none' "$H135")"
assert_eq "13.5: low space never widens deletion" \
    1 "$(count_in_text 'Low space calls for this procedure, never for broader deletion' "$H135")"
assert_eq "13.5: the report lists candidates with their cost" \
    1 "$(count_in_text 'the next candidates for me, largest first, each with what would be lost and whether it can be regenerated' "$H135")"
assert_eq "13.6: a refusal ends the attempt" \
    1 "$(count_in_file '13.6 **A refusal ends the attempt.**' "$H")"
assert_eq "the Windows free-disk row notes UNC paths" \
    1 "$(count_in_file 'drive-letter paths only — for a network (UNC) path' "$ROOT/rules/platform/WINDOWS.md")"
assert_eq "DESTRUCTIVE.md sends cleanup to section 13 by path" \
    1 "$(count_in_file '**Cleanup follows section 13: read `~/.claude/rules/HYGIENE.md` by path before any cleanup**' "$DS")"
assert_eq "DESTRUCTIVE.md keeps the worktree law" \
    1 "$(count_in_file 'deleting a worktree'"'"'s folder, or `git worktree remove --force`, is a destructive act under rule 10.1' "$DS")"
assert_eq "the workflow hygiene checkpoint runs section 13" \
    1 "$(count_in_file 'run the hygiene procedure (`HYGIENE.md`, section 13)' "$ROOT/rules/WORKFLOW.md")"
for f in $PLATFORM; do
    assert_eq "rules/platform/$f.md gives the free-disk command" \
        1 "$(grep -c '^| Free disk |' "$ROOT/rules/platform/$f.md")"
    assert_eq "rules/platform/$f.md says how to find a process using a directory" \
        1 "$(grep -c '^4\. Is a process using a directory' "$ROOT/rules/platform/$f.md")"
done
assert_eq "LINUX.md: lsof +D finds a process under a directory" \
    1 "$(count_in_file '`lsof +D <dir>` lists every process with a file open anywhere under it' "$ROOT/rules/platform/LINUX.md")"
assert_eq "MACOS.md: lsof +D finds a process under a directory" \
    1 "$(count_in_file '`lsof +D <dir>` lists every process with a file open anywhere under it' "$ROOT/rules/platform/MACOS.md")"
assert_eq "WINDOWS.md: an unrun idle check is said to be unrun" \
    1 "$(count_in_file 'the check was not run, and the folder is not proven idle' "$ROOT/rules/platform/WINDOWS.md")"

# Rule 7.1: tasks run back to back, and every plan says so.
C71="$ROOT/rules/COLLABORATION.md"
assert_eq "7.1: tasks run back to back and every plan says so" \
    1 "$(count_in_file '**Tasks run back to back — every plan says so in its header.**' "$C71")"
assert_eq "7.1: whoever runs the plan starts the next task at once" \
    1 "$(count_in_file 'whoever runs the plan — the coordinator, or a solo session running it — starts the next approved task at once, in the same turn' "$C71")"
assert_eq "7.1: a lane returns its close-out and never admits the next task" \
    1 "$(count_in_file 'and never admits the next task itself (rule 3.5: one coordinator admits work)' "$C71")"
assert_eq "7.1: the stops include rule 3.5's ceiling and its waits" \
    1 "$(count_in_file 'rule 3.5'"'"'s ceiling and its waits' "$C71")"
assert_eq "7.1: the stops include a review's blocking finding" \
    1 "$(count_in_file 'a review'"'"'s blocking finding (rule 3.3'"'"'s stop-the-line)' "$C71")"
assert_eq "7.1: a close-out report is a record, not a stopping point" \
    1 "$(count_in_file 'A close-out report is a record, not a stopping point' "$C71")"
assert_eq "7.1: never ask whether to continue" \
    1 "$(count_in_file 'never asks "shall I continue?"' "$C71")"
assert_eq "7.1: the stops include an unfixable-advisory release block" \
    1 "$(count_in_file 'a release blocked by an unfixable advisory (rule 6.3)' "$C71")"
assert_eq "7.1: the stops are the gates this rulebook keeps" \
    1 "$(count_in_file 'The only stops are the gates this rulebook keeps: a high deep review' "$C71")"
assert_eq "6.2: the hygiene checkpoint hands on to the next task" \
    1 "$(count_in_file 'then whoever runs the plan starts the next approved task at once (rule 7.1)' "$ROOT/rules/WORKFLOW.md")"

# The statements that once lived only in a summary now live in their files.
assert_eq "COLLABORATION.md: a question seen once and moved past is answered" \
    1 "$(count_in_file 'a question I saw once and moved past is answered' "$ROOT/rules/COLLABORATION.md")"
assert_eq "COLLABORATION.md: a defect found during a review is reported, never fixed there" \
    1 "$(count_in_file 'A defect found during a review is reported, never fixed there' "$ROOT/rules/COLLABORATION.md")"
for f in $PLATFORM; do
    assert_eq "rules/platform/$f.md forbids carrying a command across platforms" \
        1 "$(count_in_file 'Never carry a command across from another platform file' "$ROOT/rules/platform/$f.md")"
done

# ---------------------------------------------------------------------------
# INSTALL.md's verification counts match the repository.
# ---------------------------------------------------------------------------
stated=$(grep -F -e 'contains **' -- "$ROOT/INSTALL.md" \
    | grep -F -e '.md` files' \
    | sed 's/.*contains \*\*\([0-9][0-9]*\)\*\*.*/\1/')
assert_eq "INSTALL.md states the real number of rule files" "$rulecount" "$stated"

platcount=0
for p in "$ROOT"/rules/platform/*.md; do platcount=$((platcount + 1)); done
assert_eq "there are three platform files" 3 "$platcount"

# ---------------------------------------------------------------------------
# A template ships no LIVE entry.
#
# A user who copies a template as shipped must not be handed an entry that is
# already law — the git-identity Fill shipped with an empty value once, which
# bound the agent to "commits use [nothing]". Every example is fenced instead,
# which is also what makes the templates pass the staleness check unedited.
# ---------------------------------------------------------------------------
unfenced_entries() { # path -> the offending "line: text" lines, or nothing
    awk '
        { line = $0
          sub(/^[ \t]+/, "", line)
          if (line ~ /^(```|~~~)/) { if (fence) fence = 0; else fence = 1; next }
          if (fence) next
          probe = line
          sub(/^[-*][ \t]+/, "", probe)
          if (probe ~ /^\*\*(Fill|Add|Override)/) printf "%d: %s\n", NR, $0
        }' "$1"
}
for t in LOCAL.md LOCAL_dev.md; do
    assert_eq "templates/$t ships no unfenced entry" \
        "" "$(unfenced_entries "$ROOT/templates/$t")"
done
assert_not_contains "LOCAL_dev example does not lower the Top safety floor" \
    "$(cat "$ROOT/templates/LOCAL_dev.md")" 'unsafe code — start on the **Strong** tier'
# The finder itself must be able to see one, or the two assertions above are
# satisfied by a finder that never matches anything.
TMPPROBE=${TMPDIR:-/tmp}/cclp-probe.$$
{
    printf '# probe\n\n'
    printf '```\n- **Override — fenced, so invisible.**\n```\n\n'
    printf -- '- **Override — rule 9.1.** Live, so the finder must see it.\n'
} >"$TMPPROBE"
assert_contains "the unfenced-entry finder can actually find one" \
    "$(unfenced_entries "$TMPPROBE")" '**Override — rule 9.1.**'
assert_not_contains "the unfenced-entry finder ignores a fenced one" \
    "$(unfenced_entries "$TMPPROBE")" 'fenced, so invisible'
rm -f -- "$TMPPROBE"

# ---------------------------------------------------------------------------
# The visual map's dataset carries the section-0 paragraph.
#
# Pinned as a dataset entry — title AND the start of its body — so that renaming
# the entry and leaving the old title in an HTML comment does not pass.
# ---------------------------------------------------------------------------
assert_eq "docs/index.html carries the local layer as a dataset entry" \
    1 "$(count_in_file '{t:"The local layer — customizations the playbook never touches",c:"' "$ROOT/docs/index.html")"
assert_eq "the map's entry no longer says the playbook never opens the local files" \
    0 "$(count_in_file 'never ships, copies over, or opens them' "$ROOT/docs/index.html")"
assert_eq "the map's entry says what an update actually does" \
    1 "$(count_in_file 'an update never writes to, copies over or replaces them' "$ROOT/docs/index.html")"

# ---------------------------------------------------------------------------
# INSTALL.md's load-bearing sentences.
#
# Most of INSTALL.md is prose the rules deprecate testing. These five sentences
# are not prose: each is a property the whole design rests on, and each was a
# mutant that survived the suite. A procedure that says the opposite installs
# over somebody's file.
# ---------------------------------------------------------------------------
I=$ROOT/INSTALL.md
assert_eq "the update checks the local layer against the STAGED rules, not the installed ones" \
    1 "$(count_in_file 'sh "$trust_root/scripts/check-local.sh" ~/.claude/rules "$trust_root/rules"' "$I")"
assert_eq "the update says which argument is the staged one" \
    1 "$(count_in_file 'second is the **staged** rules, not the installed ones' "$I")"
assert_eq "the update stages the new text before anything is copied" \
    1 "$(count_in_file 'Everything below runs' "$I")"
assert_eq "the migration stages the new version too, and names the directory" \
    1 "$(count_in_file '**Step M1b — Stage the new version too.**' "$I")"
assert_eq "the migration check runs from the new checkout" \
    1 "$(count_in_file 'sh "$trust_root/scripts/check-local.sh" <scratch>/local "$trust_root/rules"' "$I")"
assert_eq "the update asks before it copies" \
    1 "$(count_in_file '**ask whether to proceed, and stop until they answer.**' "$I")"
assert_eq "the backup comes before the copy" \
    1 "$(count_in_file 'Back up, then copy.** Only after the user has said yes.' "$I")"
assert_eq "the copy is file by file and never replaces the rules directory" \
    1 "$(count_in_file '**Copy file by file. Never replace the whole directory**' "$I")"
assert_eq "a template is never copied over an existing local file" \
    1 "$(count_in_file 'not copy the template over it and do not merge into it' "$I")"
assert_eq "migration copies only a local file that is not already there" \
    1 "$(count_in_file '**Stop this migration and do not copy.**' "$I")"
assert_eq "the uninstall restore exempts the local files" \
    1 "$(count_in_file 'and never `LOCAL.md` or' "$I")"
for code in 1 2; do
    row=$(grep -F -e "| **$code** |" -- "$I")
    assert_contains "the check's exit-$code row exists at all" "$row" "| **$code** |"
    assert_contains "exit $code from the check stops the update" "$row" '**Stop.**'
    assert_not_contains "exit $code from the check never says carry on" "$row" 'Continue'
done
assert_eq "the procedures state what they need on the machine" \
    1 "$(count_in_file 'update, migration, restore, and uninstall needs `sh` and Git' "$I")"
assert_eq "the Windows first-install shell is named" \
    1 "$(count_in_file 'On Windows, run the POSIX-shell guards in Git Bash or MSYS2' "$I")"
assert_eq "the Windows example targets the configuration directory" \
    1 "$(count_in_file 'windows_config="$(cygpath -u "$USERPROFILE")/.claude"' "$I")"
assert_eq "quiescence applies to every install and removal procedure" \
    1 "$(count_in_file 'Every procedure requires a quiescent source checkout and target configuration.' "$I")"
assert_eq "quiescence is in the shared preflight, before first-install-only steps" \
    1 "$(awk '
        /^## Source and destination preflights/ { shared = 1; next }
        /^## Step 0/ { shared = 0 }
        shared && /^Every procedure requires a quiescent source checkout and target configuration[.]$/ { count++ }
        END { print count + 0 }
    ' "$I")"

# ---------------------------------------------------------------------------
# End to end, against the real playbook text: a fresh override and a stale one.
# ---------------------------------------------------------------------------
mkdir -p -- "$TMPROOT/local"
printf '# LOCAL\n\n  **Dead words:** `%s` (in `%s`)\n' \
    'fourteen subject files' 'AUTHORITY.md' >"$TMPROOT/local/LOCAL.md"
out=$(sh "$ROOT/scripts/check-local.sh" "$TMPROOT/local" "$ROOT/rules" 2>&1); st=$?
assert_status "a real override against the real rules: exit 0" 0 "$st"
assert_contains "a real override against the real rules: reports ok" "$out" "ok — 1"

printf '# LOCAL\n\n  **Dead words:** `%s` (in `%s`)\n' \
    'a sentence this playbook has never contained' 'AUTHORITY.md' \
    >"$TMPROOT/local/LOCAL.md"
out=$(sh "$ROOT/scripts/check-local.sh" "$TMPROOT/local" "$ROOT/rules" 2>&1); st=$?
assert_status "a stale override against the real rules: exit 1" 1 "$st"
assert_contains "a stale override against the real rules: says STALE" "$out" "STALE"

# CLAUDE.md resolves through the documented default, in this repository's layout.
printf '# LOCAL\n\n  **Dead words:** `%s` (in `%s`)\n' \
    'This rulebook is version' 'CLAUDE.md' >"$TMPROOT/local/LOCAL.md"
out=$(sh "$ROOT/scripts/check-local.sh" "$TMPROOT/local" "$ROOT/rules" 2>&1); st=$?
assert_status "CLAUDE.md resolves in this repository's layout: exit 0" 0 "$st"

# The guide's copyable Override must actually satisfy the current checker;
# naming the verifier in surrounding prose is not enough.
awk '
    /^- \*\*Override/ { example = 1 }
    example && /^```/ { exit }
    example { print }
' "$ROOT/docs/guides/local-layer.md" >"$TMPROOT/local/LOCAL.md"
assert_eq "the guide provides a complete live Override example" 1 \
    "$(count_in_file '**Rule digest:**' "$TMPROOT/local/LOCAL.md")"
out=$(sh "$ROOT/scripts/check-local.sh" "$TMPROOT/local" "$ROOT/rules" 2>&1); st=$?
assert_status "the guide Override verifies against the shipped rules" 0 "$st"
assert_contains "the guide example checks one anchored quotation" "$out" "1 search(es), 0 stale, 0 error(s)"

finish
