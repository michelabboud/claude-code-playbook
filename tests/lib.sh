# tests/lib.sh — the small assertion harness the test scripts share.
#
# POSIX sh. Sourced, never executed. External utilities: cmp, grep, mkdir, rm,
# printf, and mktemp where it exists (with a portable fallback).
#
# Output is TAP-like: one "ok"/"not ok" line per assertion, a plan at the end.
# A test script exits 0 when every assertion passed, 1 otherwise.

tests_run=0
tests_failed=0

_pass() {
    tests_run=$((tests_run + 1))
    printf 'ok %d - %s\n' "$tests_run" "$1"
}

_fail() {
    tests_run=$((tests_run + 1))
    tests_failed=$((tests_failed + 1))
    printf 'not ok %d - %s\n' "$tests_run" "$1"
    printf '#   %s\n' "$2"
}

assert_status() { # name expected actual
    if [ "$2" -eq "$3" ]; then
        _pass "$1"
    else
        _fail "$1" "expected exit status $2, got $3"
    fi
}

assert_contains() { # name haystack needle
    case $2 in
        *"$3"*) _pass "$1" ;;
        *)      _fail "$1" "expected to find [$3] in: $2" ;;
    esac
}

assert_not_contains() { # name haystack needle
    case $2 in
        *"$3"*) _fail "$1" "did not expect [$3] in: $2" ;;
        *)      _pass "$1" ;;
    esac
}

assert_eq() { # name expected actual
    if [ "$2" = "$3" ]; then
        _pass "$1"
    else
        _fail "$1" "expected [$2], got [$3]"
    fi
}

assert_files_identical() { # name path-a path-b
    if cmp -s -- "$2" "$3"; then
        _pass "$1"
    else
        _fail "$1" "$2 and $3 differ"
    fi
}

# Count the lines of one file that contain a fixed string.
# A missing file is an error, not a zero: a wording test that silently passes
# because it looked in the wrong place is worse than no test.
count_in_file() { # fixed-string path
    if [ ! -f "$2" ]; then
        printf 'MISSING\n'
        return
    fi
    _c=$(grep -F -c -e "$1" -- "$2" 2>/dev/null) || _c=0
    printf '%s\n' "$_c"
}

# The YAML frontmatter of a Markdown file: line 1 through the closing "---".
frontmatter() { # path
    awk 'NR==1 { if ($0 != "---") exit 1; print; next }
         { print; if ($0 == "---") exit 0 }' "$1"
}

# A temporary directory this run creates, and removes on exit.
# mktemp is not in POSIX; fall back to a pid-named directory that mkdir
# refuses to create if it already exists.
make_tmpdir() {
    if command -v mktemp >/dev/null 2>&1; then
        mktemp -d 2>/dev/null || mktemp -d -t cclp.XXXXXX
    else
        _d=${TMPDIR:-/tmp}/cclp-test.$$
        mkdir -- "$_d" || return 1
        printf '%s\n' "$_d"
    fi
}

# Remove the temporary directory, and only that. Refuses anything else:
# a disposable fixture this run created is the only thing it may delete.
cleanup_tmpdir() { # path
    case ${1:-} in
        ''|/|.|..) return 0 ;;
    esac
    case $1 in
        */cclp-test.*|*/tmp.*|*/cclp.*) ;;
        *) printf 'refusing to remove an unexpected path: %s\n' "$1" >&2
           return 1 ;;
    esac
    [ -d "$1" ] || return 0
    rm -rf -- "$1"
}

finish() {
    printf '1..%d\n' "$tests_run"
    if [ "$tests_failed" -gt 0 ]; then
        printf '# FAILED %d of %d\n' "$tests_failed" "$tests_run"
        exit 1
    fi
    printf '# passed %d\n' "$tests_run"
    exit 0
}
