#!/bin/sh
#
# tests/dead_words_vectors_test.sh — every shared conformance vector, plus the
# cases one line of a vectors file cannot express.
#
#   sh tests/dead_words_vectors_test.sh [path-to-check-local.sh]
#
# The optional argument exists so tests/mutation_test.sh can point this suite at
# a deliberately broken scratch copy and prove each assertion catches the break.
#
# tests/fixtures/dead-words-vectors.tsv is shared **byte for byte** with
# codex-playbook: the two editions implement the same grammar, and a vector file
# that drifted would let them diverge quietly. So this suite hashes it before it
# runs it — a local edit cannot pass unnoticed, and the fix for a vector that
# looks wrong is a conversation, not an edit.
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

VECTORS=$HERE/fixtures/dead-words-vectors.tsv
VECTORS_SHA256=644a4eb1215d06e7486f4b1b256098109d51b428c3130357c56d688e1c8d5765

# The two file names the vectors' @F1@ and @F2@ stand for in this edition: both
# are real rule-file names here, and both exist in the fixture rules directory.
F1=ENVIRONMENT.md
F2=SUBAGENTS.md

TAB=$(printf '\t')

TMPROOT=$(make_tmpdir) || { printf 'cannot make a temp dir\n' >&2; exit 2; }
trap 'cleanup_tmpdir "$TMPROOT"' EXIT INT TERM HUP

# ---------------------------------------------------------------------------
# 0. The vectors file is the shared one, byte for byte.
# ---------------------------------------------------------------------------
sha256_of() { # path -> hex digest on stdout, empty if no tool is available
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum -- "$1" | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 -- "$1" | cut -d' ' -f1
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$1" | sed 's/.*= *//'
    else
        printf ''
    fi
}

if [ ! -f "$VECTORS" ]; then
    _fail "the shared vectors file is present" "not found: $VECTORS"
    finish
fi

vectors_sha=$(sha256_of "$VECTORS")
if [ -z "$vectors_sha" ]; then
    # Fail closed: an unverified shared fixture is exactly what this guards.
    _fail "the vectors file is unedited" \
        "no sha256 tool (sha256sum, shasum, openssl) — the shared fixture could not be verified"
else
    assert_eq "the vectors file is byte-identical to the shared one" \
        "$VECTORS_SHA256" "$vectors_sha"
fi

# ---------------------------------------------------------------------------
# The fixture playbook the vectors are run against.
# Its two files deliberately contain none of the vectors' quoted words, so an
# "ok N" vector lands on N searches and a stale verdict (exit 1) rather than on
# an accidental match.
# ---------------------------------------------------------------------------
RULES=$TMPROOT/rules
LOCAL=$TMPROOT/local
mkdir -p -- "$RULES" "$LOCAL"
cat >"$RULES/$F1" <<'EOF'
# 9 · Environment & operations

Nothing in this fixture is one of the conformance vectors' quoted strings.
EOF
cat >"$RULES/$F2" <<'EOF'
# 8 · Subagents & model tiering

Nothing in this fixture is one of the conformance vectors' quoted strings.
EOF

LOCALF=$LOCAL/LOCAL.md

run_check() { # -> OUT, ERRO, STATUS
    OUT=$(sh "$SCRIPT" "$LOCAL" "$RULES" 2>"$TMPROOT/stderr")
    STATUS=$?
    ERRO=$(cat "$TMPROOT/stderr")
}

# How many fixed-string searches the run actually made, from the machine-readable
# last line of stdout. "?" when that line is absent — never a silent zero.
searches_made() { # output
    _sm=$(printf '%s\n' "$1" | sed -n 's/.*: \([0-9][0-9]*\) search(es).*/\1/p')
    printf '%s' "${_sm:-?}"
}

# POSIX sh has no global substitution in a parameter expansion.
REPL=''
replace_all() { # haystack needle replacement -> REPL
    _ra_out=''
    _ra_r=$1
    while :; do
        case $_ra_r in
            *"$2"*) _ra_out=$_ra_out${_ra_r%%"$2"*}$3
                    _ra_r=${_ra_r#*"$2"} ;;
            *)      break ;;
        esac
    done
    REPL=$_ra_out$_ra_r
}

# ---------------------------------------------------------------------------
# 1. Every vector in the shared file.
# ---------------------------------------------------------------------------
vec_lineno=0
vec_ok=0
vec_error=0
vec_ignore=0

while IFS= read -r vline || [ -n "$vline" ]; do
    vec_lineno=$((vec_lineno + 1))
    case $vline in
        '#'*|'') continue ;;
    esac
    case $vline in
        *"$TAB"*) ;;
        *) _fail "vectors line $vec_lineno is well formed" \
              "no tab separator in: $vline"
           continue ;;
    esac

    expect=${vline%%"$TAB"*}
    body=${vline#*"$TAB"}
    replace_all "$body" '@F1@' "$F1"; body=$REPL
    replace_all "$body" '@F2@' "$F2"; body=$REPL

    # The vector line is the only Dead-words line in the file, on line 3.
    printf '# LOCAL\n\n' >"$LOCALF"
    printf '%s\n' "$body" >>"$LOCALF"
    run_check
    made=$(searches_made "$OUT")

    case $expect in
        'ok '*)
            want=${expect#'ok '}
            vec_ok=$((vec_ok + 1))
            case $STATUS in
                0|1) _pass "vector $vec_lineno parses (exit $STATUS): $body" ;;
                *)   _fail "vector $vec_lineno parses: $body" \
                        "expected exit 0 or 1, got $STATUS; stderr: $ERRO" ;;
            esac
            assert_eq "vector $vec_lineno makes $want search(es)" "$want" "$made"
            ;;
        error)
            vec_error=$((vec_error + 1))
            if [ "$STATUS" -eq 2 ]; then
                _pass "vector $vec_lineno is refused (exit 2): $body"
            else
                _fail "vector $vec_lineno is refused: $body" \
                    "expected exit 2, got $STATUS; stdout: $OUT"
            fi
            ;;
        ignore)
            vec_ignore=$((vec_ignore + 1))
            assert_status "vector $vec_lineno is ignored (exit 0): $body" 0 "$STATUS"
            assert_eq "vector $vec_lineno makes no search: $body" 0 "$made"
            ;;
        *)
            _fail "vectors line $vec_lineno has a known expectation" \
                "unknown expectation [$expect] in: $vline"
            ;;
    esac
done <"$VECTORS"

printf '# vectors run: %d ok, %d error, %d ignore (%d total)\n' \
    "$vec_ok" "$vec_error" "$vec_ignore" \
    "$((vec_ok + vec_error + vec_ignore))"

if [ "$((vec_ok + vec_error + vec_ignore))" -eq 0 ]; then
    _fail "the vectors file was actually read" "no vector line was run"
fi

# ---------------------------------------------------------------------------
# 2. What one line cannot express: a fenced block hides a whole entry.
# ---------------------------------------------------------------------------
cat >"$LOCALF" <<'EOF'
# LOCAL

The grammar, quoted so a reader can copy it:

```
**Dead words:** `words this playbook never had` (in `ENVIRONMENT.md`)
```

And prose that names the marker must put it in a code span: `**Dead words:**`.
EOF
run_check
assert_status "a fenced entry is ignored: exit 0" 0 "$STATUS"
assert_eq "a fenced entry makes no search" 0 "$(searches_made "$OUT")"

cat >"$LOCALF" <<'EOF'
# LOCAL

~~~
**Dead words:** `words this playbook never had` (in `ENVIRONMENT.md`)
~~~

**Dead words:** `Nothing in this fixture` (in `ENVIRONMENT.md`)
EOF
run_check
assert_status "a tilde fence hides its entry, the real one is checked: exit 0" 0 "$STATUS"
assert_eq "only the unfenced entry was searched" 1 "$(searches_made "$OUT")"

cat >"$LOCALF" <<'EOF'
# LOCAL

````
```
**Dead words:** `words this playbook never had` (in `ENVIRONMENT.md`)
```
````

**Dead words:** `Nothing in this fixture` (in `ENVIRONMENT.md`)
EOF
run_check
assert_status "a longer fence is closed only by a long-enough one: exit 0" 0 "$STATUS"
assert_eq "the nested fence did not reopen the block" 1 "$(searches_made "$OUT")"

# ---------------------------------------------------------------------------
# 3. A fence left open swallows every line after it — that is an error.
# ---------------------------------------------------------------------------
cat >"$LOCALF" <<'EOF'
# LOCAL

```
**Dead words:** `Nothing in this fixture` (in `ENVIRONMENT.md`)
EOF
run_check
assert_status "an unclosed fence: exit 2" 2 "$STATUS"
assert_contains "an unclosed fence: says where it was opened" "$ERRO" "LOCAL.md:3:"
assert_contains "an unclosed fence: says what it cost" "$ERRO" "never closed"

# ---------------------------------------------------------------------------
# 4. The quoted words are the exact bytes between the backticks.
# ---------------------------------------------------------------------------
cat >"$RULES/DOCS.md" <<'EOF'
# 4 · Documentation

A gap:  two spaces sit before "two", and one space before "sit".
EOF

cat >"$LOCALF" <<'EOF'
# LOCAL

**Dead words:** `gap:  two spaces` (in `DOCS.md`)
EOF
run_check
assert_status "two inner spaces are searched as two: exit 0" 0 "$STATUS"
assert_eq "two inner spaces: one search was made" 1 "$(searches_made "$OUT")"

cat >"$LOCALF" <<'EOF'
# LOCAL

**Dead words:** `gap: two spaces` (in `DOCS.md`)
EOF
run_check
assert_status "the same words with one space are not there: exit 1" 1 "$STATUS"
assert_contains "one space: reported stale" "$OUT" "STALE"

# The discriminating pair: the fixture line ENDS with the period, so the span
# with a trailing space is absent and its trimmed form is present. A parser that
# trimmed the quoted words would report this one found.
cat >"$LOCALF" <<'EOF'
# LOCAL

**Dead words:** `one space before "sit". ` (in `DOCS.md`)
EOF
run_check
assert_status "a trailing space inside the span is kept, so it is absent: exit 1" 1 "$STATUS"
assert_contains "trailing space inside the span: reported stale" "$OUT" "STALE"

cat >"$LOCALF" <<'EOF'
# LOCAL

**Dead words:** `one space before "sit".` (in `DOCS.md`)
EOF
run_check
assert_status "the same span without that space is present: exit 0" 0 "$STATUS"

# The same, at the other end: the fixture line starts at column 1.
cat >"$LOCALF" <<'EOF'
# LOCAL

**Dead words:** ` A gap:` (in `DOCS.md`)
EOF
run_check
assert_status "a leading space inside the span is kept, so it is absent: exit 1" 1 "$STATUS"

cat >"$LOCALF" <<'EOF'
# LOCAL

**Dead words:** `A gap:` (in `DOCS.md`)
EOF
run_check
assert_status "the same span without that leading space is present: exit 0" 0 "$STATUS"

# ---------------------------------------------------------------------------
# 5. The templates pass the check as shipped.
#    They are what a user copies; if they do not check clean, the first thing
#    the local layer does to a new installation is fail its own check.
# ---------------------------------------------------------------------------
TPL=$HERE/../templates
REPO_RULES=$HERE/../rules
REPO_CLAUDE=$HERE/../CLAUDE.md
TPLLOCAL=$TMPROOT/tpl
mkdir -p -- "$TPLLOCAL"
if [ -f "$TPL/LOCAL.md" ] && [ -f "$TPL/LOCAL_dev.md" ]; then
    cp -- "$TPL/LOCAL.md" "$TPL/LOCAL_dev.md" "$TPLLOCAL/"
    OUT=$(sh "$SCRIPT" "$TPLLOCAL" "$REPO_RULES" "$REPO_CLAUDE" 2>"$TMPROOT/stderr")
    STATUS=$?
    ERRO=$(cat "$TMPROOT/stderr")
    assert_status "both templates, unedited, pass the check: exit 0" 0 "$STATUS"
    assert_eq "the templates' examples are all fenced: no search" 0 "$(searches_made "$OUT")"

    rm -f -- "$TPLLOCAL/LOCAL_dev.md"
    OUT=$(sh "$SCRIPT" "$TPLLOCAL" "$REPO_RULES" "$REPO_CLAUDE" 2>"$TMPROOT/stderr")
    STATUS=$?
    assert_status "the always-loaded template alone passes: exit 0" 0 "$STATUS"
else
    _fail "the templates are where the tests expect them" "not found under $TPL"
fi

finish
