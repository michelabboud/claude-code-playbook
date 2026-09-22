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
for f in $SCOPED $UNSCOPED; do
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
expected='AUTHORITY.md CODE.md COLLABORATION.md DESTRUCTIVE.md DOCS.md ENVIRONMENT.md QUARANTINE.md REPO.md REVIEWS.md ROSTER.md SUBAGENTS.md TESTING.md WORKFLOW.md WRITING.md'
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
    1 "$(count_in_file 'sh scripts/check-local.sh ~/.claude/rules ./rules' "$I")"
assert_eq "the update says which argument is the staged one" \
    1 "$(count_in_file 'second is the **staged** rules, not the installed ones' "$I")"
assert_eq "the update stages the new text before anything is copied" \
    1 "$(count_in_file 'Everything below runs' "$I")"
assert_eq "the migration stages the new version too, and names the directory" \
    1 "$(count_in_file '**Step M1b — Stage the new version too.**' "$I")"
assert_eq "the migration check runs from the new checkout" \
    1 "$(count_in_file 'cd <scratch>/new && sh scripts/check-local.sh <scratch>/local ./rules' "$I")"
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
    1 "$(count_in_file 'it needs `sh` — on Windows' "$I")"

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
