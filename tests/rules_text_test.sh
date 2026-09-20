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
UNSCOPED='AUTHORITY COLLABORATION DESTRUCTIVE DOCS ENVIRONMENT QUARANTINE REPO WRITING'
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
for f in $UNSCOPED; do
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
for f in $SCOPED $UNSCOPED; do
    [ "$f" = AUTHORITY ] && continue
    assert_eq "hook 1 is absent from rules/$f.md" \
        0 "$(count_in_file "$HOOK1" "$ROOT/rules/$f.md")"
done
assert_eq "hook 1 is absent from CLAUDE.md" \
    0 "$(count_in_file "$HOOK1" "$ROOT/CLAUDE.md")"

# The paragraph says the things the decision requires it to say.
A=$ROOT/rules/AUTHORITY.md
assert_eq "section 0 states that a local entry wins over the playbook's wording" \
    1 "$(count_in_file 'where an entry there changes a rule, the entry wins over the playbook'"'"'s wording' "$A")"
assert_eq "section 0 defines a Fill" \
    1 "$(count_in_file 'a **Fill** supplies a value a rule leaves open' "$A")"
assert_eq "section 0 defines an Add and reserves the L numbers" \
    1 "$(count_in_file 'an **Add** is a rule or note the playbook lacks, its sections numbered `L1`, `L2`, … — numbers the playbook never uses' "$A")"
assert_eq "section 0 defines an Override and its stale case" \
    1 "$(count_in_file 'the override is stale and you tell me before relying on it' "$A")"
assert_eq "section 0 says an absent local file means nothing is customized" \
    1 "$(count_in_file 'A local file that is absent means nothing is customized.' "$A")"
assert_eq "section 0 denies the local layer any new authority" \
    1 "$(count_in_file 'it never adds authority the approval table doesn'"'"'t have, except by adding a row in so many words' "$A")"

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
    13 "$subject"
assert_eq "section 0's header says thirteen subject files" \
    1 "$(count_in_file 'thirteen subject files' "$A")"

# ---------------------------------------------------------------------------
# Hook 3 — CLAUDE.md names the layer, and its self-update paragraph is rewritten.
# ---------------------------------------------------------------------------
C=$ROOT/CLAUDE.md
assert_eq "hook 3 appears exactly once in CLAUDE.md" \
    1 "$(count_in_file "$HOOK3" "$C")"
for f in $SCOPED $UNSCOPED; do
    assert_eq "hook 3 is absent from rules/$f.md" \
        0 "$(count_in_file "$HOOK3" "$ROOT/rules/$f.md")"
done

assert_eq "the self-update paragraph no longer claims an update overwrites tailored files" \
    0 "$(count_in_file 'Updating overwrites files I may have tailored' "$C")"
assert_eq "the self-update paragraph no longer names four tailorable places" \
    0 "$(count_in_file 'four places are explicitly meant to be tailored' "$C")"
assert_eq "the self-update paragraph still stops and asks before replacing" \
    1 "$(count_in_file 'stop and ask before replacing anything.' "$C")"
assert_eq "the self-update paragraph still calls an update a rule 10.2 action" \
    1 "$(count_in_file 'it is a rule 10.2 action: back up first, verify the backup, and only then copy' "$C")"
assert_eq "the self-update paragraph says customizations survive an update" \
    1 "$(count_in_file 'they live in the local layer, which an update never opens' "$C")"
assert_eq "the self-update paragraph runs the check against the new text first" \
    1 "$(count_in_file 'scripts/check-local.sh` is run against the new text before anything is copied' "$C")"
assert_eq "the self-update paragraph still points at INSTALL.md" \
    1 "$(count_in_file 'The full procedure is `INSTALL.md` in the repo' "$C")"
assert_eq "CLAUDE.md still reads VERSION as the source of truth" \
    1 "$(count_in_file 'The `VERSION` file is the single source of truth' "$C")"

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
expected='AUTHORITY.md CODE.md COLLABORATION.md DESTRUCTIVE.md DOCS.md ENVIRONMENT.md QUARANTINE.md REPO.md REVIEWS.md ROSTER.md SUBAGENTS.md TESTING.md WORKFLOW.md WRITING.md'
assert_eq "rules/ holds exactly the playbook's rule files" "$expected" "$rulenames"

assert_eq "the templates live outside rules/" \
    0 "$(find "$ROOT/rules" -type d -name templates | wc -l)"
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
# The visual map's dataset carries the section-0 paragraph.
# ---------------------------------------------------------------------------
assert_eq "docs/index.html describes the local layer" \
    1 "$(count_in_file 'The local layer — customizations the playbook never touches' "$ROOT/docs/index.html")"

# ---------------------------------------------------------------------------
# End to end, against the real playbook text: a fresh override and a stale one.
# ---------------------------------------------------------------------------
mkdir -p -- "$TMPROOT/local"
printf '# LOCAL\n\n  **Dead words:** `%s` (in `%s`)\n' \
    'thirteen subject files' 'AUTHORITY.md' >"$TMPROOT/local/LOCAL.md"
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

finish
