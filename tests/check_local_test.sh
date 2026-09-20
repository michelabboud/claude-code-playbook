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

TMPROOT=$(make_tmpdir) || { printf 'cannot make a temp dir\n' >&2; exit 2; }
trap 'cleanup_tmpdir "$TMPROOT"' EXIT INT TERM HUP

CASE=''
run_check() { # args... -> OUT, ERRO, STATUS
    OUT=$(sh "$SCRIPT" "$@" 2>"$TMPROOT/stderr")
    STATUS=$?
    ERRO=$(cat "$TMPROOT/stderr")
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
assert_contains "stale override: names file and line" "$OUT" "LOCAL.md:4:"
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

finish
