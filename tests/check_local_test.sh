#!/bin/sh
#
# tests/check_local_test.sh — the behaviour of scripts/check-local.sh.
#
#   sh tests/check_local_test.sh [path-to-check-local.sh]
#
# The optional argument exists so tests/mutation_test.sh can point this suite at
# a deliberately broken scratch copy and prove each assertion catches the break.
#
# Every fixture lives in a temporary directory this run creates and removes.
# Nothing outside it is read or written; no real home directory is touched.

set -u

HERE=$(dirname -- "$0")
. "$HERE/lib.sh"

SCRIPT=${1:-$HERE/../scripts/check-local.sh}
if [ ! -f "$SCRIPT" ]; then
    printf 'no such script: %s\n' "$SCRIPT" >&2
    exit 2
fi

# One case runs the script from a different working directory, to prove a file
# name inside an item is never expanded against it. That needs an absolute path.
case $SCRIPT in
    /*) SCRIPT_ABS=$SCRIPT ;;
    *)  SCRIPT_ABS=$(cd -- "$(dirname -- "$SCRIPT")" && pwd)/$(basename -- "$SCRIPT") ;;
esac

TMPROOT=$(make_tmpdir) || { printf 'cannot make a temp dir\n' >&2; exit 2; }
trap 'cleanup_tmpdir "$TMPROOT"' EXIT INT TERM HUP

CASE=''
run_raw_check() { # args... -> OUT, ERRO, STATUS
    OUT=$(sh "$SCRIPT" "$@" 2>"$TMPROOT/stderr")
    STATUS=$?
    ERRO=$(cat "$TMPROOT/stderr")
}

# Most parser vectors deliberately exercise standalone Dead-words probes.  The
# few historical vectors that model a live Override predate the section
# verifier, so give only those otherwise-valid fixtures the exact metadata a
# person now has to write.  Dedicated vectors below invoke run_raw_check to
# prove the verifier itself refuses missing or bad metadata.
add_override_verifiers() { # local-dir rules-dir [claude-md]
    _av_local=$1
    _av_rules=$2
    _av_claude=${3:-$_av_rules/../CLAUDE.md}
    for _av_file in "$_av_local/LOCAL.md" "$_av_local/LOCAL_dev.md"; do
        [ -f "$_av_file" ] || continue
        [ -r "$_av_file" ] || continue
        if ! LC_ALL=C tr -d '\000' < "$_av_file" | cmp -s "$_av_file" -; then
            continue
        fi
        _av_out=$_av_file.verifier
        _av_wait=0
        : >"$_av_out"
        while IFS= read -r _av_line || [ -n "$_av_line" ]; do
            case $_av_line in
                *'**Override'*)
                    printf '%s\n' "$_av_line" >>"$_av_out"
                    _av_wait=1
                    continue
                    ;;
            esac
            if [ "$_av_wait" -ne 1 ]; then
                printf '%s\n' "$_av_line" >>"$_av_out"
                continue
            fi
            case $_av_line in *'**Dead words:** `'*'` (in `'*) ;; *)
                printf '%s\n' "$_av_line" >>"$_av_out"
                continue ;;
            esac
            _av_words=$(printf '%s\n' "$_av_line" | sed -n 's/.*\*\*Dead words:\*\* `\([^`]*\)` (in `\([^`]*\)`.*/\1/p')
            _av_name=$(printf '%s\n' "$_av_line" | sed -n 's/.*\*\*Dead words:\*\* `\([^`]*\)` (in `\([^`]*\)`.*/\2/p')
            case $_av_name in
                CLAUDE.md) _av_target=$_av_claude ;;
                *) _av_target=$_av_rules/$_av_name ;;
            esac
            _av_heading=$(grep -m 1 '^#' "$_av_target" 2>/dev/null || :)
            if [ -n "$_av_words" ] && [ -n "$_av_heading" ]; then
                printf '%s\n' "$_av_heading" >"$TMPROOT/heading"
                awk 'NR == FNR { wanted = $0; next }
                    { line = $0; sub(/\r$/, "", line); plain = line; sub(/^[ \t]*/, "", plain)
                      if (!started && line == wanted) { started = 1; level = 0; while (substr(plain, level + 1, 1) == "#") level++ }
                      if (started) { if (line != wanted && plain ~ /^#+[ \t]/) { next_level = 0; while (substr(plain, next_level + 1, 1) == "#") next_level++; if (next_level <= level) exit }
                                     sub(/[ \t]+$/, "", line); print line } }
                    END { if (!started) exit 1 }' "$TMPROOT/heading" "$_av_target" >"$TMPROOT/section"
                _av_digest=$(sha256sum "$TMPROOT/section" | awk '{print $1}')
                printf '  **Anchor:** `%s` (in `%s`)\n' "$_av_heading" "$_av_name" >>"$_av_out"
                printf '  **Rule digest:** `sha256:%s`\n' "$_av_digest" >>"$_av_out"
            fi
            printf '%s\n' "$_av_line" >>"$_av_out"
            _av_wait=0
        done <"$_av_file"
        mv -- "$_av_out" "$_av_file"
    done
}

run_check() { # args... -> OUT, ERRO, STATUS
    if [ "$#" -ge 2 ]; then
        add_override_verifiers "$1" "$2" "${3:-}"
    fi
    run_raw_check "$@"
}

mkcase() { # name
    CASE=$TMPROOT/$1
    mkdir -p -- "$CASE/local" "$CASE/rules"
    cat >"$CASE/rules/ENVIRONMENT.md" <<'EOF'
# 9 · Environment & operations

9.1 Ports: check the claims registry at `~/.config/agent-rules/` before
assigning. The exact phrase --force is not permission also lives here.
A line containing abc, which a regex would match but a fixed string must not.
Literal metacharacters: rm -rf $HOME/.config/*.bak [0-9]+ (kept as data).
EOF
    cat >"$CASE/rules/SUBAGENTS.md" <<'EOF'
# 8 · Subagents

8.1 Security, concurrency and unsafe code start on the Top tier.
EOF
    cat >"$CASE/rules/A.md" <<'EOF'
alpha lives here
shared phrase
EOF
    cat >"$CASE/rules/B.md" <<'EOF'
beta lives here
shared phrase
EOF
    cat >"$CASE/rules/C.md" <<'EOF'
gamma lives here
shared phrase
EOF
}

# ---------------------------------------------------------------------------
# 1. No local layer at all.
# ---------------------------------------------------------------------------
mkcase nolocal
run_check "$CASE/local" "$CASE/rules"
assert_status "no local files: exit 0" 0 "$STATUS"
assert_contains "no local files: says nothing is customized" "$OUT" "nothing is customized"

# ---------------------------------------------------------------------------
# 2. A fresh override — the quoted words are still in the playbook.
# ---------------------------------------------------------------------------
mkcase fresh
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1, the registry home.** Mine lives elsewhere.
  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "fresh override: exit 0" 0 "$STATUS"
assert_contains "fresh override: reports ok" "$OUT" "ok — 1 dead-words string(s) still present"
assert_not_contains "fresh override: says nothing about staleness" "$OUT" "STALE"

# ---------------------------------------------------------------------------
# 3. A stale override — the playbook rewrote that text.
# ---------------------------------------------------------------------------
mkcase stale
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1, the registry home.** Mine lives elsewhere.
  **Dead words:** `~/.config/gone-away/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "stale override: exit 1" 1 "$STATUS"
assert_contains "stale override: names file and line" "$OUT" "LOCAL.md:"
assert_contains "stale override: quotes the words" "$OUT" '`~/.config/gone-away/`'
assert_contains "stale override: names the file searched" "$OUT" "ENVIRONMENT.md"
assert_contains "stale override: says STALE" "$OUT" "STALE"

# ---------------------------------------------------------------------------
# 4. A **Dead words:** line that does not parse is an error, never a pass.
# ---------------------------------------------------------------------------
mkcase unparsable
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** the registry path, in ENVIRONMENT.md
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "unparsable line: exit 2" 2 "$STATUS"
assert_contains "unparsable line: reports an error" "$ERRO" "error:"
assert_contains "unparsable line: names file and line" "$ERRO" "LOCAL.md:3:"

mkcase emptyitems
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:**
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "empty dead-words line: exit 2" 2 "$STATUS"
assert_contains "empty dead-words line: says it names nothing" "$ERRO" "names nothing"

mkcase halfitem
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `no closing paren` (in `ENVIRONMENT.md`
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "malformed item: exit 2" 2 "$STATUS"

# ---------------------------------------------------------------------------
# 5. A named file that does not exist is an error, not a stale finding.
# ---------------------------------------------------------------------------
mkcase missingfile
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `anything at all` (in `NOPE.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "missing named file: exit 2" 2 "$STATUS"
assert_contains "missing named file: says so" "$ERRO" "named file does not exist"
assert_not_contains "missing named file: not reported as stale" "$OUT" "STALE"

# ---------------------------------------------------------------------------
# 6. A quoted string that begins with a dash is data, not an option.
# ---------------------------------------------------------------------------
mkcase dashstring
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `--force is not permission` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "leading-dash string: found, exit 0" 0 "$STATUS"
assert_contains "leading-dash string: counted as checked" "$OUT" "1 dead-words string(s)"

mkcase dashstringstale
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `--force was never written here` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "leading-dash string absent: exit 1, not an error" 1 "$STATUS"

# ---------------------------------------------------------------------------
# 7. Regex metacharacters are searched literally.
# ---------------------------------------------------------------------------
mkcase regexliteral
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `rm -rf $HOME/.config/*.bak [0-9]+` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "metacharacters present literally: exit 0" 0 "$STATUS"

# The discriminating case: `a.c` matches "abc" as a regex, but the file has no
# literal "a.c". A fixed-string search must call this stale.
mkcase regexnotmatched
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `a.c` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "regex metacharacter is not a wildcard: exit 1" 1 "$STATUS"
assert_contains "regex metacharacter: reported stale" "$OUT" "STALE"

# ---------------------------------------------------------------------------
# 8. One item naming several files.
# ---------------------------------------------------------------------------
mkcase twofiles
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `shared phrase` (in `A.md` and `B.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "two files, both fresh: exit 0" 0 "$STATUS"
assert_contains "two files: both counted" "$OUT" "ok — 2 dead-words string(s)"

mkcase twofilesonestale
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `alpha lives here` (in `A.md` and `B.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "two files, one stale: exit 1" 1 "$STATUS"
assert_contains "two files: the stale one is named" "$OUT" "no longer appears in B.md"
assert_not_contains "two files: the fresh one is not named" "$OUT" "appears in A.md"

mkcase threefiles
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `shared phrase` (in `A.md`, `B.md`, and `C.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "three files, comma-and: exit 0" 0 "$STATUS"
assert_contains "three files: all three counted" "$OUT" "ok — 3 dead-words string(s)"

mkcase badseparator
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `shared phrase` (in `A.md` plus `B.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "unknown file separator: exit 2" 2 "$STATUS"

# ---------------------------------------------------------------------------
# 9. Two items on one line, separated by " · ".
# ---------------------------------------------------------------------------
mkcase twoitems
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`) · `start on the Top tier` (in `SUBAGENTS.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "two items, both fresh: exit 0" 0 "$STATUS"
assert_contains "two items: both counted" "$OUT" "ok — 2 dead-words string(s)"

mkcase twoitemsonestale
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`) · `start on the Fast tier` (in `SUBAGENTS.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "two items, second stale: exit 1" 1 "$STATUS"
assert_contains "two items: the stale one named" "$OUT" "start on the Fast tier"

# ---------------------------------------------------------------------------
# 10. CRLF line endings.
# ---------------------------------------------------------------------------
mkcase crlf
printf '# LOCAL\r\n\r\n  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)\r\n' \
    >"$CASE/local/LOCAL.md"
run_check "$CASE/local" "$CASE/rules"
assert_status "CRLF input: exit 0" 0 "$STATUS"
assert_contains "CRLF input: the string was actually checked" "$OUT" "ok — 1 dead-words string(s)"

# ---------------------------------------------------------------------------
# 11. CLAUDE.md — the documented default, and the explicit override.
# ---------------------------------------------------------------------------
mkcase claudedefault
printf 'The rules live in ~/.claude/rules/, one file per section.\n' \
    >"$CASE/CLAUDE.md"
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `one file per section` (in `CLAUDE.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "CLAUDE.md resolves to the parent of the rules dir: exit 0" 0 "$STATUS"

mkcase claudeelsewhere
mkdir -p -- "$CASE/staged"
printf 'The rules live in ~/.claude/rules/, one file per section.\n' \
    >"$CASE/staged/CLAUDE.md"
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `one file per section` (in `CLAUDE.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "CLAUDE.md absent at the default place: exit 2" 2 "$STATUS"
run_check "$CASE/local" "$CASE/rules" "$CASE/staged/CLAUDE.md"
assert_status "CLAUDE.md given as the third argument: exit 0" 0 "$STATUS"

mkcase claudebadarg
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL
EOF
run_check "$CASE/local" "$CASE/rules" "$CASE/no-such-file.md"
assert_status "third argument is not a file: exit 2" 2 "$STATUS"

# ---------------------------------------------------------------------------
# 12. No item may name a path outside the two directories given.
# ---------------------------------------------------------------------------
mkcase pathescape
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `one file per section` (in `../CLAUDE.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "../CLAUDE.md is refused: exit 2" 2 "$STATUS"
assert_contains "../CLAUDE.md: says why" "$ERRO" "path separator"

mkcase pathescapeabs
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `root` (in `/etc/passwd`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "an absolute path is refused: exit 2" 2 "$STATUS"
assert_contains "absolute path: says why" "$ERRO" "path separator"

# ---------------------------------------------------------------------------
# 13. A fenced code block may quote the grammar without being checked.
# ---------------------------------------------------------------------------
mkcase fenced
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

The grammar of a dead-words line:

```
  **Dead words:** `words the playbook never had` (in `ENVIRONMENT.md`)
```

  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "fenced example is skipped: exit 0" 0 "$STATUS"
assert_contains "fenced example: only the real line was checked" "$OUT" "ok — 1 dead-words string(s)"

# ---------------------------------------------------------------------------
# 14. Both local files are read.
# ---------------------------------------------------------------------------
mkcase devonly
cat >"$CASE/local/LOCAL_dev.md" <<'EOF'
# LOCAL_dev

  **Dead words:** `start on the Bottom tier` (in `SUBAGENTS.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "LOCAL_dev.md alone is read: exit 1" 1 "$STATUS"
assert_contains "LOCAL_dev.md alone: named in the report" "$OUT" "LOCAL_dev.md:3:"

mkcase bothfiles
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
cat >"$CASE/local/LOCAL_dev.md" <<'EOF'
# LOCAL_dev

  **Dead words:** `start on the Bottom tier` (in `SUBAGENTS.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "both files read, one stale: exit 1" 1 "$STATUS"
assert_contains "both files: the stale one is in LOCAL_dev.md" "$OUT" "LOCAL_dev.md:3:"

# ---------------------------------------------------------------------------
# 15. An error outranks a stale finding.
# ---------------------------------------------------------------------------
mkcase errorwins
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `never written anywhere` (in `ENVIRONMENT.md`)
  **Dead words:** not a parsable item
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "one stale and one error: exit 2" 2 "$STATUS"
assert_contains "error wins: the stale one is still reported" "$OUT" "STALE"

# ---------------------------------------------------------------------------
# 16. Usage.
# ---------------------------------------------------------------------------
mkcase usage
run_check "$CASE/local"
assert_status "one argument: exit 2" 2 "$STATUS"
assert_contains "one argument: prints usage" "$ERRO" "usage:"

run_check "$CASE/local" "$CASE/rules" "$CASE/CLAUDE.md" extra
assert_status "four arguments: exit 2" 2 "$STATUS"

run_check "$CASE/no-such-dir" "$CASE/rules"
assert_status "local dir does not exist: exit 2" 2 "$STATUS"
assert_contains "local dir: says which" "$ERRO" "not a directory"

run_check "$CASE/local" "$CASE/no-such-dir"
assert_status "rules dir does not exist: exit 2" 2 "$STATUS"

OUT=$(sh "$SCRIPT" --help 2>&1); STATUS=$?
assert_status "--help: exit 0" 0 "$STATUS"
assert_contains "--help: prints usage" "$OUT" "usage:"

# ---------------------------------------------------------------------------
# 17. The indentation the templates actually use.
# ---------------------------------------------------------------------------
mkcase indented
printf '# LOCAL\n\n\t\t**Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)\n' \
    >"$CASE/local/LOCAL.md"
run_check "$CASE/local" "$CASE/rules"
assert_status "tab-indented dead-words line is found: exit 0" 0 "$STATUS"
assert_contains "tab-indented: actually checked something" "$OUT" "ok — 1 dead-words string(s)"

# ---------------------------------------------------------------------------
# 18. Trailing whitespace is invisible and must not halt an update.
# ---------------------------------------------------------------------------
mkcase trailingspace
printf '# LOCAL\n\n  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)   \n' \
    >"$CASE/local/LOCAL.md"
run_check "$CASE/local" "$CASE/rules"
assert_status "trailing spaces after the item: exit 0" 0 "$STATUS"
assert_contains "trailing spaces: the string was checked" "$OUT" "ok — 1 dead-words string(s)"

mkcase trailingtab
printf '# LOCAL\n\n  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)\t\n' \
    >"$CASE/local/LOCAL.md"
run_check "$CASE/local" "$CASE/rules"
assert_status "a trailing tab after the item: exit 0" 0 "$STATUS"

# The marker is followed by a space or a tab, and then the first item. Nothing
# abutting the marker is guessed at either.
mkcase nospaceaftermarker
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:**`~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "no space after the marker: exit 2" 2 "$STATUS"
assert_contains "no space after the marker: says what was expected" "$ERRO" "space or a tab"

# But whitespace inside the grammar is still an error, not something to guess at.
mkcase innerspace
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `some words`  (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a doubled space inside the item: exit 2" 2 "$STATUS"

# ---------------------------------------------------------------------------
# 19. Three items on one line search three strings.
#
# POSIX sh has no `local`: every helper writes into the one set of shell
# variables, and a parser that reused a name would lose an item somewhere in the
# middle of the line and report a smaller, quieter, wrong answer. The count is
# the assertion — not that the line "parses".
# ---------------------------------------------------------------------------
mkcase threeitems
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `alpha lives here` (in `A.md`) · `beta lives here` (in `B.md`) · `gamma lives here` (in `C.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "three items, all fresh: exit 0" 0 "$STATUS"
assert_contains "three items: three strings checked" "$OUT" "ok — 3 dead-words string(s)"
assert_contains "three items: the count line agrees" "$OUT" "3 search(es), 0 stale, 0 error(s)"

mkcase threeitemssixfiles
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `shared phrase` (in `A.md` and `B.md`) · `shared phrase` (in `B.md`, `C.md`) · `shared phrase` (in `A.md`, `B.md`, and `C.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "three items naming seven files: exit 0" 0 "$STATUS"
assert_contains "three items: every file was searched" "$OUT" "ok — 7 dead-words string(s)"

# The middle item is the one a lost variable would drop.
mkcase threeitemsmiddlestale
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `alpha lives here` (in `A.md`) · `never written anywhere` (in `B.md`) · `gamma lives here` (in `C.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "three items, the middle one stale: exit 1" 1 "$STATUS"
assert_contains "three items: the middle one is named" "$OUT" "never written anywhere"
assert_contains "three items: all three were still searched" "$OUT" "3 search(es), 1 stale"

# ---------------------------------------------------------------------------
# 20. Quoted words are scanned, not split: a quotation may contain " · ".
# ---------------------------------------------------------------------------
mkcase separatorinside
cat >"$CASE/rules/PLATFORM.md" <<'EOF'
# 11 · Your platform

### 11 · Your platform is a heading a real override quotes.
EOF
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `### 11 · Your platform` (in `PLATFORM.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a separator inside the quoted words: exit 0" 0 "$STATUS"
assert_contains "a separator inside the quoted words: one search, not two" \
    "$OUT" "1 search(es), 0 stale, 0 error(s)"

mkcase parensinside
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `a phrase with (in brackets) inside` (in `A.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "\" (in \" inside the quoted words: parses, exit 1" 1 "$STATUS"
assert_contains "\" (in \" inside the quoted words: searched whole" \
    "$OUT" 'a phrase with (in brackets) inside'

# ---------------------------------------------------------------------------
# 21. Fail closed: the bare marker anywhere but the start of a line.
# ---------------------------------------------------------------------------
mkcase midlinemarker
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1.** **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a marker mid-line is an error, not a skipped entry: exit 2" 2 "$STATUS"
assert_contains "a marker mid-line: names file and line" "$ERRO" "LOCAL.md:3:"
assert_contains "a marker mid-line: says what to do instead" "$ERRO" "code span"

mkcase markerinspan
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

An entry carries a `**Dead words:**` line; this sentence is prose, not an entry.

  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "the marker inside a code span is prose: exit 0" 0 "$STATUS"
assert_contains "the marker inside a code span: only the entry was searched" \
    "$OUT" "1 search(es), 0 stale, 0 error(s)"

# ---------------------------------------------------------------------------
# 22. The script writes nothing.
# ---------------------------------------------------------------------------
mkcase readonly
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
before=$(ls -a "$CASE/local" "$CASE/rules")
run_check "$CASE/local" "$CASE/rules"
after=$(ls -a "$CASE/local" "$CASE/rules")
assert_eq "the check creates and removes nothing" "$before" "$after"

# ---------------------------------------------------------------------------
# 23. An Override must carry its Dead words.
#
# This is what makes a mistyped marker an error instead of a silent pass: the
# words are the only thing that can ever go stale, so an Override without them
# is not a smaller check, it is no check. Six cases, each a whole local file.
# ---------------------------------------------------------------------------
mkcase overridewithwords
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1, the registry home.** Mine lives elsewhere.
  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "Override then a valid Dead-words line: exit 0" 0 "$STATUS"
assert_contains "Override then a valid line: the words were searched" \
    "$OUT" "1 search(es), 0 stale, 0 error(s)"

# A mistyped marker is not the marker. Before this rule it exited 0 with no
# searches at all, which is the one failure a staleness check may never have.
mkcase overridelowercasemarker
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1, the registry home.** Mine lives elsewhere.
  **dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "Override with a lower-case marker: exit 2" 2 "$STATUS"
assert_contains "Override with a lower-case marker: reported at the Override's line" \
    "$ERRO" "LOCAL.md:3:"
assert_contains "Override with a lower-case marker: says what is missing" \
    "$ERRO" "no complete verifier"

mkcase overridecolonoutside
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1, the registry home.** Mine lives elsewhere.
  **Dead words**: `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "Override with the colon outside the bold: exit 2" 2 "$STATUS"
assert_contains "Override with the colon outside the bold: names the Override's line" \
    "$ERRO" "LOCAL.md:3:"

mkcase overridenolineatall
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1, the registry home.** Mine lives elsewhere, and this
  entry ends the file without ever quoting a dead word.
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "Override with no following line at all: exit 2" 2 "$STATUS"
assert_contains "Override at end of file: names the Override's line" \
    "$ERRO" "LOCAL.md:3:"

# The same, with the Override as the very last line of the file and no newline
# after it: end of file is end of file.
mkcase overridelastline
printf '# LOCAL\n\n- **Override — rule 9.1.** Mine lives elsewhere.' \
    >"$CASE/local/LOCAL.md"
run_check "$CASE/local" "$CASE/rules"
assert_status "an Override as the unterminated last line: exit 2" 2 "$STATUS"
assert_contains "an Override as the last line: names its line" "$ERRO" "LOCAL.md:3:"

# A blank line between an entry and its words is not a boundary — only another
# entry, a heading, or the end of the file is. This layout is the common one.
mkcase overrideblankline
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1, the registry home.** Mine lives elsewhere.

  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a blank line between the Override and its words: exit 0" 0 "$STATUS"
assert_contains "a blank line does not orphan the words" "$OUT" "1 search(es), 0 stale, 0 error(s)"

mkcase overridethenheading
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1, the registry home.** Mine lives elsewhere.

## 10 · Destructive actions

  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a Dead-words line after a heading belongs to nothing: exit 2" 2 "$STATUS"
assert_contains "Override then a heading: names the Override's line" \
    "$ERRO" "LOCAL.md:3:"
assert_contains "Override then a heading: the orphaned line is still searched" \
    "$OUT" "1 search(es)"

mkcase overridethenfill
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1, the registry home.** Mine lives elsewhere.
- **Fill — rule 9.1, the registry home.** Mine is `~/.config/fleet/ports/`.
  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "the next entry ends the Override: exit 2" 2 "$STATUS"
assert_contains "Override then a Fill: names the Override's line, not the Fill's" \
    "$ERRO" "LOCAL.md:3:"

mkcase overrideinfence
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

An Override looks like this:

```
- **Override — rule 9.1, the registry home.** Mine lives elsewhere.
  **Dead words:** `words this playbook never had` (in `ENVIRONMENT.md`)
```
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "an Override inside a fence is an example, not an entry: exit 0" 0 "$STATUS"
assert_contains "a fenced Override: nothing was searched" "$OUT" "0 search(es), 0 stale, 0 error(s)"

# Two Overrides, each with its own line, and a Fill with none: all fine.
mkcase twooverrides
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Fill — rule 9.1, the registry home.** Mine is `~/.config/fleet/ports/`.
- **Override — rule 9.1, the registry home.** Mine lives elsewhere.
  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
- **Add — a note the playbook lacks.** Nothing to quote here.
- **Override — rule 8.1, the tiers.** Mine start higher.
  **Dead words:** `start on the Top tier` (in `SUBAGENTS.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "two Overrides each with its own line, plus a Fill and an Add: exit 0" 0 "$STATUS"
assert_contains "two Overrides: both lines were searched" "$OUT" "2 search(es), 0 stale, 0 error(s)"

# An entry written without a list bullet is an entry too, and a bullet is not
# what makes one: the pattern that strips "- " must not turn "* " into a wildcard
# that swallows every line with a space in it.
mkcase overridenobullet
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

**Override — rule 9.1, written with no list bullet.** Mine lives elsewhere.
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "an Override with no list bullet still owes its words: exit 2" 2 "$STATUS"

mkcase prosewithstar
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

Some prose with spaces and a * star in it, which is not an entry at all.
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "prose containing a star is not an entry: exit 0" 0 "$STATUS"

# A Dead-words line with no Override above it is still parsed and searched:
# it is the Override that owes words, never the words that owe an Override.
mkcase wordswithoutoverride
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `~/.config/gone-away/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a Dead-words line with no Override above it is still checked: exit 1" 1 "$STATUS"
assert_contains "a Dead-words line with no Override: reported stale" "$OUT" "STALE"

# ---------------------------------------------------------------------------
# 24. The line bound, measured in bytes.
# ---------------------------------------------------------------------------
BOUND=4096

# N bytes of 'x' on stdout, built by doubling so the loop is logarithmic.
xbytes() { # n
    _xb=x
    while [ "${#_xb}" -lt "$1" ]; do _xb=$_xb$_xb; done
    printf '%s' "$_xb" | cut -b "1-$1"
}

# The fixed parts of the line are 30 bytes: the marker and a space (16), the two
# backticks around the words (2), and " (in `A.md`)" (12).
mkcase atbound
words=$(xbytes $((BOUND - 30)))
printf '# LOCAL\n\n**Dead words:** `%s` (in `A.md`)\n' "$words" >"$CASE/local/LOCAL.md"
assert_eq "the at-the-bound fixture really is $BOUND bytes" \
    "$BOUND" "$(sed -n 3p "$CASE/local/LOCAL.md" | tr -d '\n' | wc -c | tr -d ' ')"
run_check "$CASE/local" "$CASE/rules"
assert_status "a line of exactly $BOUND bytes is accepted and searched: exit 1" 1 "$STATUS"
assert_not_contains "a line of exactly $BOUND bytes: no bound error" "$ERRO" "the bound is"

mkcase overbound
words=$(xbytes $((BOUND - 29)))
printf '# LOCAL\n\n**Dead words:** `%s` (in `A.md`)\n' "$words" >"$CASE/local/LOCAL.md"
assert_eq "the over-the-bound fixture really is $((BOUND + 1)) bytes" \
    "$((BOUND + 1))" "$(sed -n 3p "$CASE/local/LOCAL.md" | tr -d '\n' | wc -c | tr -d ' ')"
run_check "$CASE/local" "$CASE/rules"
assert_status "one byte over the bound: exit 2" 2 "$STATUS"
assert_contains "over the bound: the message names the bound" "$ERRO" "the bound is $BOUND bytes"
assert_contains "over the bound: nothing was searched" "$OUT" "0 search(es)"

# ---------------------------------------------------------------------------
# 25. A local file that exists and cannot be read as a regular file.
#
# The failure this closes: the redirect fails, the shell prints one line and
# carries on, and the summary says "ok — 0 strings checked". A stale override
# passed an update that way.
# ---------------------------------------------------------------------------
mkcase localisdir
mkdir -p -- "$CASE/local/LOCAL.md"
run_check "$CASE/local" "$CASE/rules"
assert_status "a directory named LOCAL.md: exit 2" 2 "$STATUS"
assert_contains "a directory named LOCAL.md: says it is not a regular file" \
    "$ERRO" "not a regular file"
assert_not_contains "a directory named LOCAL.md: never 'nothing is customized'" \
    "$OUT" "nothing is customized"

mkcase localdangling
ln -s -- "$CASE/local/no-such-target.md" "$CASE/local/LOCAL_dev.md"
run_check "$CASE/local" "$CASE/rules"
assert_status "a dangling symlink named LOCAL_dev.md: exit 2" 2 "$STATUS"
assert_not_contains "a dangling symlink: never 'nothing is customized'" \
    "$OUT" "nothing is customized"

mkcase localsymlink
cat >"$CASE/real-local.md" <<'EOF'
# LOCAL

  **Dead words:** `~/.config/gone-away/` (in `ENVIRONMENT.md`)
EOF
ln -s -- "$CASE/real-local.md" "$CASE/local/LOCAL.md"
run_check "$CASE/local" "$CASE/rules"
assert_status "a symlink to a readable regular file is read: exit 1" 1 "$STATUS"
assert_contains "a symlink to a regular file: its entry was checked" "$OUT" "STALE"

if [ "$(id -u)" -eq 0 ]; then
    _pass "an unreadable local file is an error (skipped: running as root, which can read anything)"
    _pass "an unsearchable local directory is an error (skipped: running as root)"
    _pass "an unreadable playbook file is an error (skipped: running as root)"
else
    mkcase localunreadable
    cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `~/.config/gone-away/` (in `ENVIRONMENT.md`)
EOF
    chmod 000 -- "$CASE/local/LOCAL.md"
    run_check "$CASE/local" "$CASE/rules"
    chmod 644 -- "$CASE/local/LOCAL.md"
    assert_status "an unreadable LOCAL.md: exit 2" 2 "$STATUS"
    assert_not_contains "an unreadable LOCAL.md: never reported ok" "$OUT" "ok — "
    assert_contains "an unreadable LOCAL.md: says it could not be read" "$ERRO" "cannot be read"

    mkcase localdirnosearch
    cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `~/.config/gone-away/` (in `ENVIRONMENT.md`)
EOF
    chmod 600 -- "$CASE/local"
    run_check "$CASE/local" "$CASE/rules"
    chmod 700 -- "$CASE/local"
    assert_status "a local directory with no search permission: exit 2" 2 "$STATUS"
    assert_not_contains "an unsearchable local directory: never 'nothing is customized'" \
        "$OUT" "nothing is customized"

    # A failed search is not a found string. grep exits 2, and swallowing that
    # reported the override as still biting.
    mkcase rulesunreadable
    cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
    chmod 000 -- "$CASE/rules/ENVIRONMENT.md"
    run_check "$CASE/local" "$CASE/rules"
    chmod 644 -- "$CASE/rules/ENVIRONMENT.md"
    assert_status "an unreadable playbook file: exit 2" 2 "$STATUS"
    assert_contains "an unreadable playbook file: says the search failed" "$ERRO" "search failed"
fi

# ---------------------------------------------------------------------------
# 26. A file name is a name, not a pattern.
#
# Without this the same local file means different things depending on the
# directory the check happened to be run from.
# ---------------------------------------------------------------------------
mkcase globname
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `alpha lives here` (in `[A].md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a bracket glob in a file name: exit 2" 2 "$STATUS"
assert_contains "a bracket glob in a file name: says why" "$ERRO" "glob character"

mkcase globstar
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `alpha lives here` (in `*.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a star glob in a file name: exit 2" 2 "$STATUS"

# The same input, run from a directory that contains a matching file, must give
# the same answer: the name was never expanded.
mkcase globcwd
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `alpha lives here` (in `[A].md`)
EOF
OUT=$(cd "$CASE/rules" && sh "$SCRIPT_ABS" "$CASE/local" "$CASE/rules" 2>"$TMPROOT/stderr")
STATUS=$?
ERRO=$(cat "$TMPROOT/stderr")
assert_status "a glob name run from a directory holding A.md: still exit 2" 2 "$STATUS"
assert_contains "a glob name is never expanded against the current directory" \
    "$ERRO" "glob character"

# ---------------------------------------------------------------------------
# 27. A final line with no newline is still a line.
# ---------------------------------------------------------------------------
mkcase unterminated
printf '# LOCAL\n\n  **Dead words:** `~/.config/gone-away/` (in `ENVIRONMENT.md`)' \
    >"$CASE/local/LOCAL.md"
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "a stale entry on a final line with no newline: exit 1" 1 "$STATUS"
assert_contains "an unterminated final line: it was actually searched" "$OUT" "1 search(es), 1 stale"

# ---------------------------------------------------------------------------
# 28. The quoted words are searched whole, never as a prefix.
#
# A parser that cut the quotation at the first " · " would find the prefix and
# report the override fresh — the playbook heading it quotes starts the same way.
# ---------------------------------------------------------------------------
mkcase prefixonly
cat >"$CASE/rules/PLAT.md" <<'EOF'
# 11 · Your platform

### 11 · Your platform — the OS-specific commands.
EOF
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `### 11 · Your operating system` (in `PLAT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "only the text after the separator is absent: exit 1, not 0" 1 "$STATUS"
assert_contains "the whole quotation was searched, not its prefix" \
    "$OUT" '### 11 · Your operating system'

# ---------------------------------------------------------------------------
# 29. A bare marker AFTER a code span on the same line is still an error.
# ---------------------------------------------------------------------------
mkcase markerafterspan
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1.** See `the registry` **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a marker after a code span: exit 2" 2 "$STATUS"
assert_contains "a marker after a code span: names file and line" "$ERRO" "LOCAL.md:3:"
assert_contains "a marker after a code span: says it is not at the start of the line" \
    "$ERRO" "not at the start of the line"
assert_contains "a marker after a code span: nothing was searched" "$OUT" "0 search(es)"

# ---------------------------------------------------------------------------
# 30. A backslash inside the quoted words is one of the bytes searched for.
# ---------------------------------------------------------------------------
mkcase backslashwords
# The word the second case searches for must appear NOWHERE in this file
# except with the backslash in the middle of it.
cat >"$CASE/rules/BS.md" <<'EOF'
# 11 · a file that quotes an escape

The pattern *\\* in a case arm, and the words back\slash here.
EOF
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `back\slash` (in `BS.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a backslash in the quoted words is kept: exit 0" 0 "$STATUS"
assert_contains "a backslash in the quoted words: one search, found" \
    "$OUT" "1 search(es), 0 stale, 0 error(s)"

# The same fixture, so the only thing that changed is the backslash.
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `backslash` (in `BS.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "the same words without the backslash are absent: exit 1" 1 "$STATUS"

# ---------------------------------------------------------------------------
# 31. Fences: what closes one, and what never opened one.
# ---------------------------------------------------------------------------
mkcase fencetrailingtext
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

```
``` and then some prose
  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
```
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a closing run followed by prose does not close a fence: exit 0" 0 "$STATUS"
assert_contains "a run with trailing text left the fence open: nothing searched" \
    "$OUT" "0 search(es), 0 stale, 0 error(s)"

mkcase fenceinfobacktick
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

```see `this` for the grammar
  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "a backtick in the info string means no fence opened: exit 0" 0 "$STATUS"
assert_contains "no fence opened: the entry below it was checked" \
    "$OUT" "1 search(es), 0 stale, 0 error(s)"

# ---------------------------------------------------------------------------
# 32. -h on its own prints usage, like --help.
# ---------------------------------------------------------------------------
OUT=$(sh "$SCRIPT" -h 2>&1); STATUS=$?
assert_status "-h: exit 0" 0 "$STATUS"
assert_contains "-h: prints usage" "$OUT" "usage:"

# ---------------------------------------------------------------------------
# 33. A named file that does not exist is not a search.
#
# The count is what the vectors suite reads; counting a file that was never
# opened would make every "ok N" vector agree with a check that did less.
# ---------------------------------------------------------------------------
mkcase missingnotasearch
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

  **Dead words:** `shared phrase` (in `A.md` and `NOPE.md`)
EOF
run_check "$CASE/local" "$CASE/rules"
assert_status "one file present, one missing: exit 2" 2 "$STATUS"
assert_contains "a missing named file is not counted as a search" \
    "$OUT" "1 search(es), 0 stale, 1 error(s)"

# ---------------------------------------------------------------------------
# 34. Binary, option-shaped, and almost-Markdown inputs are refusals.
#
# These are all inputs a human or an editor can produce.  An exit 0 would let
# an Override bypass the only freshness proof it has.
# ---------------------------------------------------------------------------
mkcase nulbyte
printf '# LOCAL\n\n**Override — binary words.**\n**Dead words:** `prefix\000suffix` (in `A.md`)\n' \
    >"$CASE/local/LOCAL.md"
printf 'prefixsuffix\n' >"$CASE/rules/A.md"
run_check "$CASE/local" "$CASE/rules"
assert_status "a NUL byte in a local file: exit 2" 2 "$STATUS"
assert_contains "a NUL byte: says why" "$ERRO" "NUL"

mkcase optionpath
mkdir -- "$CASE/local/-h"
OUT=$(cd "$CASE/local" && sh "$SCRIPT_ABS" -h "$CASE/rules" "$CASE/CLAUDE.md" 2>&1)
STATUS=$?
assert_status "a local directory literally named -h is a path, not help: exit 2" 2 "$STATUS"

for shape in numbered blockquote heading italicbold plusbullet splitbold unicode_lookalike; do
    mkcase "unrecognized-$shape"
    case $shape in
        numbered)   line='1. **Override — numbered list.**' ;;
        blockquote) line='> **Override — block quote.**' ;;
        heading)    line='## **Override — heading.**' ;;
        italicbold) line='***Override — italic bold.***' ;;
        plusbullet) line='+ **Override — plus list.**' ;;
        splitbold) line='- **Over**ride — split emphasis.' ;;
        unicode_lookalike) line='- **Оverride — confusable first letter.**' ;;
    esac
    printf '# LOCAL\n\n%s\n' "$line" >"$CASE/local/LOCAL.md"
    run_check "$CASE/local" "$CASE/rules"
    assert_status "an unrecognized $shape Override is refused: exit 2" 2 "$STATUS"
done

mkcase overlongprose
xbytes $((BOUND + 1)) >"$CASE/local/LOCAL.md"
run_check "$CASE/local" "$CASE/rules"
assert_status "an overlong prose line is refused: exit 2" 2 "$STATUS"

# ---------------------------------------------------------------------------
# 35. A live Override has one unambiguous section, its current digest, and one
# unique substantial quotation inside that section.  These run raw: the helper
# above exists solely for legacy parser vectors and must not mask this contract.
# ---------------------------------------------------------------------------
mkcase verifiermissing
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1.** Mine lives elsewhere.
  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "a live Override without an Anchor and digest is refused: exit 2" 2 "$STATUS"
assert_contains "missing verifier: says which fields are required" "$ERRO" "**Anchor:** and **Rule digest:**"

mkcase verifierfresh
digest=$(sha256sum "$CASE/rules/ENVIRONMENT.md" | awk '{print $1}')
cat >"$CASE/local/LOCAL.md" <<EOF
# LOCAL

- **Override — rule 9.1.** Mine lives elsewhere.
  **Anchor:** \`# 9 · Environment & operations\` (in \`ENVIRONMENT.md\`)
  **Rule digest:** \`sha256:$digest\`
  **Dead words:** \`~/.config/agent-rules/\` (in \`ENVIRONMENT.md\`)
EOF
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "a matching section verifier is accepted: exit 0" 0 "$STATUS"
assert_contains "matching verifier: one anchored phrase was checked" "$OUT" "1 search(es), 0 stale, 0 error(s)"

mkcase verifieranchortrailing
digest=$(sha256sum "$CASE/rules/ENVIRONMENT.md" | awk '{print $1}')
cat >"$CASE/local/LOCAL.md" <<EOF
# LOCAL

- **Override — rule 9.1.** Mine lives elsewhere.
  **Anchor:** \`# 9 · Environment & operations\` (in \`ENVIRONMENT.md\`).
  **Rule digest:** \`sha256:$digest\`
  **Dead words:** \`~/.config/agent-rules/\` (in \`ENVIRONMENT.md\`)
EOF
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "an Anchor with trailing text is refused: exit 2" 2 "$STATUS"
assert_contains "trailing Anchor text: says it is not parsed" "$ERRO" "trailing text after Anchor"

mkcase verifierstaledigest
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — rule 9.1.** Mine lives elsewhere.
  **Anchor:** `# 9 · Environment & operations` (in `ENVIRONMENT.md`)
  **Rule digest:** `sha256:0000000000000000000000000000000000000000000000000000000000000000`
  **Dead words:** `~/.config/agent-rules/` (in `ENVIRONMENT.md`)
EOF
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "a changed section digest is stale: exit 1" 1 "$STATUS"
assert_contains "changed digest: reports the current digest" "$OUT" "current sha256:"

mkcase verifierduplicatequote
cat >"$CASE/rules/DUP.md" <<'EOF'
# Duplicate

the unique text is not unique after all
the unique text is not unique after all
EOF
digest=$(sha256sum "$CASE/rules/DUP.md" | awk '{print $1}')
cat >"$CASE/local/LOCAL.md" <<EOF
# LOCAL

- **Override — duplicate quotation.** Mine differs.
  **Anchor:** \`# Duplicate\` (in \`DUP.md\`)
  **Rule digest:** \`sha256:$digest\`
  **Dead words:** \`the unique text is not unique after all\` (in \`DUP.md\`)
EOF
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "a quotation occurring twice in its section is refused: exit 2" 2 "$STATUS"
assert_contains "duplicate quotation: says it must occur exactly once" "$ERRO" "must occur exactly once"

mkcase verifiershortquote
cat >"$CASE/rules/SHORT.md" <<'EOF'
# Short

tiny
EOF
digest=$(sha256sum "$CASE/rules/SHORT.md" | awk '{print $1}')
cat >"$CASE/local/LOCAL.md" <<EOF
# LOCAL

- **Override — short quotation.** Mine differs.
  **Anchor:** \`# Short\` (in \`SHORT.md\`)
  **Rule digest:** \`sha256:$digest\`
  **Dead words:** \`tiny\` (in \`SHORT.md\`)
EOF
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "a quotation below sixteen non-whitespace bytes is refused: exit 2" 2 "$STATUS"
assert_contains "short quotation: reports the minimum" "$ERRO" "minimum anchor is 16"

mkcase verifierduplicateheading
cat >"$CASE/rules/DUPHEADING.md" <<'EOF'
# Repeated heading

first section

# Repeated heading

second section
EOF
cat >"$CASE/local/LOCAL.md" <<'EOF'
# LOCAL

- **Override — ambiguous anchor.** Mine differs.
  **Anchor:** `# Repeated heading` (in `DUPHEADING.md`)
  **Rule digest:** `sha256:0000000000000000000000000000000000000000000000000000000000000000`
  **Dead words:** `first section is long enough` (in `DUPHEADING.md`)
EOF
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "a repeated anchored heading is refused: exit 2" 2 "$STATUS"
assert_contains "repeated heading: says it is ambiguous" "$ERRO" "must occur exactly once"

# Editor encodings must not hide an Override or change its anchored section.
for local_name in LOCAL.md LOCAL_dev.md; do
    mkcase "bom-$local_name"
    printf '\357\273\277**Override — missing verifier.**\n' >"$CASE/local/$local_name"
    run_raw_check "$CASE/local" "$CASE/rules"
    assert_status "a BOM-prefixed $local_name is refused: exit 2" 2 "$STATUS"
    assert_contains "BOM refusal names the encoding problem" "$ERRO" "BOM"
    printf '# LOCAL\n  \357\273\277**Override — missing verifier.**\n' >"$CASE/local/$local_name"
    run_raw_check "$CASE/local" "$CASE/rules"
    assert_status "an indented BOM on a later line in $local_name is refused" 2 "$STATUS"
    assert_contains "later BOM refusal identifies its line" "$ERRO" "$local_name:2:"
done

mkcase normalizedheading
printf '# Normalized\n\nA uniquely quoted requirement lives here.\n' >"$CASE/normalized"
digest=$(sha256sum "$CASE/normalized" | awk '{print $1}')
printf '%s\n' '**Override — require additional review.**' \
    '**Anchor:** `# Normalized` (in `NORMALIZED.md`)' \
    "**Rule digest:** \`sha256:$digest\`" \
    '**Dead words:** `A uniquely quoted requirement lives here.` (in `NORMALIZED.md`)' \
    >"$CASE/local/LOCAL.md"
awk '{ printf "%s\r\n", $0 }' "$CASE/normalized" >"$CASE/rules/NORMALIZED.md"
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "CRLF managed headings use the normalized digest: exit 0" 0 "$STATUS"
assert_contains "CRLF verifier actually checked the quote" "$OUT" "1 search(es), 0 stale, 0 error(s)"
printf '# Normalized \t\r\n\nA uniquely quoted requirement lives here.\r\n' >"$CASE/rules/NORMALIZED.md"
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "heading trailing blanks use the normalized digest: exit 0" 0 "$STATUS"
printf '\n# Normalized\nsecond occurrence\n' >>"$CASE/rules/NORMALIZED.md"
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "normalized duplicate headings are refused: exit 2" 2 "$STATUS"
assert_contains "normalized duplicate count includes both forms" "$ERRO" "found 2"

# Claude loads this directory recursively. A file outside the managed names
# and two local names cannot be silently declared "no local layer".
mkcase nestedrule
mkdir -p "$CASE/local/backup"
printf '%s\n' '**Override — hidden nested rule.**' > "$CASE/local/backup/LOCAL.md"
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "nested Markdown outside the staged rule tree is refused: exit 2" 2 "$STATUS"
assert_contains "nested Markdown refusal names the active path" "$ERRO" 'backup/LOCAL.md'

mkcase unknownrule
printf '%s\n' '# A user-created active rule' > "$CASE/local/notes.md"
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "an extra top-level Markdown rule is refused: exit 2" 2 "$STATUS"

mkcase uppercaseunknownrule
printf '%s\n' '# A user-created active rule' > "$CASE/local/NOTES.MD"
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "an extra uppercase Markdown rule is refused: exit 2" 2 "$STATUS"

mkcase linkedrule
mkdir -p "$CASE/elsewhere"
printf '%s\n' '# Hidden active rule' > "$CASE/elsewhere/note.md"
ln -s "$CASE/elsewhere" "$CASE/local/linked"
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "an uninspected linked rules directory is refused: exit 2" 2 "$STATUS"

mkcase knownrule
cp "$CASE/rules/ENVIRONMENT.md" "$CASE/local/ENVIRONMENT.md"
run_raw_check "$CASE/local" "$CASE/rules"
assert_status "a known staged managed rule remains allowed: exit 0" 0 "$STATUS"

finish
