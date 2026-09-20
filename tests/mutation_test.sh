#!/bin/sh
#
# tests/mutation_test.sh — does the test suite actually catch a broken script?
#
#   sh tests/mutation_test.sh
#
# A green suite proves nothing on its own: a test that asserts the wrong thing
# passes just as happily as one that asserts the right thing. So for every
# behaviour scripts/check-local.sh is supposed to have, this breaks that
# behaviour in a scratch copy and runs tests/check_local_test.sh against the
# mutant. The suite MUST fail. A mutation the suite survives is reported as
# SURVIVED — an assertion that is not really being made.
#
# Nothing outside a temporary directory this run creates is written, and the
# real scripts/check-local.sh is never modified.

set -u

HERE=$(dirname -- "$0")
. "$HERE/lib.sh"

SCRIPT=$HERE/../scripts/check-local.sh
SUITE=$HERE/check_local_test.sh

TMPROOT=$(make_tmpdir) || { printf 'cannot make a temp dir\n' >&2; exit 2; }
trap 'cleanup_tmpdir "$TMPROOT"' EXIT INT TERM HUP

seq_n=0

# Replace every line equal to $3 with $4, writing $1 -> $2.
# Fails if the anchor line is not there, so a mutation cannot silently no-op
# when the script is edited.
mutate() { # src dst old-line new-line
    _found=0
    : >"$2"
    while IFS= read -r _l || [ -n "$_l" ]; do
        if [ "$_l" = "$3" ]; then
            printf '%s\n' "$4" >>"$2"
            _found=$((_found + 1))
        else
            printf '%s\n' "$_l" >>"$2"
        fi
    done <"$1"
    [ "$_found" -gt 0 ]
}

# Break one behaviour; the suite must notice.
check_mutation() { # name old-line new-line
    seq_n=$((seq_n + 1))
    _mut=$TMPROOT/mutant-$seq_n.sh

    if ! mutate "$SCRIPT" "$_mut" "$2" "$3"; then
        _fail "$1" "anchor line not found in $SCRIPT — the mutation is stale: [$2]"
        return
    fi

    if ! sh -n "$_mut" 2>/dev/null; then
        _fail "$1" "the mutant does not parse; the mutation is malformed"
        return
    fi

    _out=$(sh "$SUITE" "$_mut" 2>&1)
    _st=$?
    if [ "$_st" -eq 0 ]; then
        _fail "$1" "SURVIVED — the suite passed against a broken script"
    else
        _pass "$1 (suite failed: $(printf '%s\n' "$_out" | grep -c '^not ok') assertion(s))"
    fi
}

# --- the search itself -----------------------------------------------------

check_mutation "a fixed-string search: dropping -F is caught" \
    '        grep -F -q -e "$_ci_words" -- "$_ci_target"' \
    '        grep -q -e "$_ci_words" -- "$_ci_target"'

check_mutation "a quoted string is data: dropping -e is caught" \
    '        grep -F -q -e "$_ci_words" -- "$_ci_target"' \
    '        grep -F -q "$_ci_words" -- "$_ci_target"'

check_mutation "not-found must mean stale: swallowing status 1 is caught" \
    '            0) ;;' \
    '            0|1) ;;'

# --- exit codes ------------------------------------------------------------

check_mutation "a stale override must exit 1, not 0" \
    '    exit 1' \
    '    exit 0'

check_mutation "an error must outrank a stale finding" \
    'if [ "$errors" -gt 0 ]; then' \
    'if [ "$errors" -gt 99 ]; then'

check_mutation "an unparsable line must be an error, never a pass" \
    '    errors=$((errors + 1))' \
    '    errors=$((errors + 0))'

# --- parsing ---------------------------------------------------------------

check_mutation "CRLF input must be handled" \
    '        _cf_line=${_cf_line%"$CR"}' \
    '        _cf_line=${_cf_line}'

check_mutation "leading whitespace must be trimmed" \
    "    printf '%s' \"\$_lt_s\"" \
    "    printf '%s' \"\$1\""

check_mutation "trailing whitespace must be trimmed" \
    "    printf '%s' \"\$_rt_s\"" \
    "    printf '%s' \"\$1\""

check_mutation "items separated by the middle dot must all be checked" \
    "SEP=' · '" \
    "SEP='@@a-separator-no-line-contains@@'"

check_mutation "a fenced code block must be skipped" \
    "            '\`\`\`'*) _cf_fence=\$((1 - _cf_fence)); continue ;;" \
    "            '\`\`\`'*) _cf_fence=0; continue ;;"

# --- targets ---------------------------------------------------------------

check_mutation "a named file that does not exist must say so" \
    '        if [ ! -f "$_ci_target" ]; then' \
    '        if [ -z "$_ci_target" ]; then'

check_mutation "no item may name a path outside the given directories" \
    '            */*|*\\*)' \
    '            @@no-file-name-looks-like-this@@)'

check_mutation "CLAUDE.md resolves to the parent of the rules directory" \
    '    claude_md=$rules_dir/../CLAUDE.md' \
    '    claude_md=$rules_dir/CLAUDE.md'

# --- which files are read --------------------------------------------------

check_mutation "LOCAL_dev.md must be read too" \
    "LOCAL_FILES='LOCAL.md LOCAL_dev.md'" \
    "LOCAL_FILES='LOCAL.md'"

check_mutation "no local layer must say nothing is customized" \
    "    printf '%s: no local layer in %s — nothing is customized.\\n' \"\$PROG\" \"\$local_dir\"" \
    "    printf '%s: no local layer in %s.\\n' \"\$PROG\" \"\$local_dir\""

finish
