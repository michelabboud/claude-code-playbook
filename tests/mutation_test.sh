#!/bin/sh
#
# tests/mutation_test.sh — does the test suite actually catch a broken script?
#
#   sh tests/mutation_test.sh
#
# A green suite proves nothing on its own: a test that asserts the wrong thing
# passes just as happily as one that asserts the right thing. So for every
# behaviour scripts/check-local.sh is supposed to have, this breaks that
# behaviour in a scratch copy and runs the suites against the mutant. They MUST
# fail, and this reports the first assertion that did. A mutation nothing
# catches is reported as SURVIVED — an assertion that is not really being made.
#
# Two suites are run, in order, and the first one to fail catches the mutation:
#
#   tests/check_local_test.sh          the script's behaviour, case by case
#   tests/dead_words_vectors_test.sh   the shared conformance vectors
#
# Nothing outside a temporary directory this run creates is written, and the
# real scripts/check-local.sh is never modified.

set -u

HERE=$(dirname -- "$0")
. "$HERE/lib.sh"

SCRIPT=$HERE/../scripts/check-local.sh
SUITES="$HERE/check_local_test.sh $HERE/dead_words_vectors_test.sh"

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

# The first failing assertion of a suite run — the evidence that the mutation
# was caught by something specific, not by a suite that merely went red.
first_not_ok() { # suite output
    printf '%s\n' "$1" | grep '^not ok' | head -n 1
}

# Break one behaviour; a suite must notice.
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

    for _suite in $SUITES; do
        _out=$(sh "$_suite" "$_mut" 2>&1)
        _st=$?
        if [ "$_st" -ne 0 ]; then
            _pass "$1 — caught by ${_suite##*/}: $(first_not_ok "$_out")"
            return
        fi
    done
    _fail "$1" "SURVIVED — every suite passed against a broken script"
}

# --- the search itself -----------------------------------------------------

check_mutation "a fixed-string search: dropping -F is caught" \
    '        grep -F -q -e "$_si_words" -- "$_si_target"' \
    '        grep -q -e "$_si_words" -- "$_si_target"'

check_mutation "a quoted string is data: dropping -e is caught" \
    '        grep -F -q -e "$_si_words" -- "$_si_target"' \
    '        grep -F -q "$_si_words" -- "$_si_target"'

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

# --- the scanner: the defect this parser was rewritten to fix ---------------
#
# Lane A's parser split the line on " · " before reading it, and refused eight
# of the ten entries in the author's real local files: a quotation may contain
# the separator. Splitting again must never pass unnoticed.

check_mutation "splitting the line on the separator is caught" \
    '        check_items "$_cf_rest" "$_cf_path" "$_cf_lineno"' \
    '        check_items "${_cf_rest%%"$SEP"*}" "$_cf_path" "$_cf_lineno"'

check_mutation "items separated by the middle dot must all be checked" \
    "SEP=' · '" \
    "SEP='@@a-separator-no-line-contains@@'"

check_mutation "the quoted words are exact bytes: trimming the end is caught" \
    "    SCAN_WORDS=\${_pi_after%%'\`'*}" \
    "    SCAN_WORDS=\$(rtrim \"\${_pi_after%%'\`'*}\")"

check_mutation "the quoted words are exact bytes: trimming the start is caught" \
    "    SCAN_WORDS=\${_pi_after%%'\`'*}" \
    "    SCAN_WORDS=\$(ltrim \"\${_pi_after%%'\`'*}\")"

check_mutation "empty quoted words must be refused" \
    '    if [ -z "$SCAN_WORDS" ]; then' \
    '    if [ -z "@@never-empty@@" ]; then'

check_mutation "an empty file span must be refused" \
    "            '')   parse_err \"\$_pf_src\" \"\$_pf_ln\" \"empty file name\"; return 1 ;;" \
    "            '')   : ;;"

check_mutation "trailing prose after an item must be refused" \
    '            *) parse_err "$_cl_src" "$_cl_ln" "trailing text after an item: $_cl_rest"; return ;;' \
    '            *) return ;;'

check_mutation "a closing period must still be allowed" \
    "            '.')      return ;;" \
    "            '.')      parse_err \"\$_cl_src\" \"\$_cl_ln\" \"period\"; return ;;"

check_mutation "an item must name a file" \
    '        *) parse_err "$_pi_src" "$_pi_ln" "expected \" (in \` after the quoted words, got: ${_pi_tail:-<end of line>}"; return 1 ;;' \
    '        *) ITEM_FILES=""; SCAN_REST=$_pi_tail; return 0 ;;'

check_mutation "the marker must be followed by a space or a tab" \
    "            ' '*|\"\$TAB\"*) ;;" \
    "            *) ;;"

# --- failing closed --------------------------------------------------------

check_mutation "a bare marker mid-line must be an error, not a skipped entry" \
    '               if has_bare_marker "$_cf_line"; then' \
    '               if false; then'

check_mutation "a marker inside a code span must stay prose" \
    "            *'\`'*'\`'*)" \
    "            *'@@no-line-contains-this@@'*)"

check_mutation "a fenced code block must be skipped" \
    '        if fence_opens "$_cf_trimmed" "$_cf_lineno"; then' \
    '        if false; then'

check_mutation "a fence must be closed by its own character and length" \
    '    [ "$_fc_n" -ge "$FENCE_LEN" ] || return 1' \
    '    [ "$_fc_n" -ge 1 ] || return 1'

check_mutation "a fence left open at end of file must be an error" \
    '    if [ -n "$FENCE_CHAR" ]; then' \
    '    if false; then'

check_mutation "lines inside a fence must be skipped, not read" \
    '        if [ -n "$FENCE_CHAR" ]; then' \
    '        if false; then'

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

# --- targets ---------------------------------------------------------------

check_mutation "a named file that does not exist must say so" \
    '        if [ ! -f "$_si_target" ]; then' \
    '        if [ -z "$_si_target" ]; then'

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

# --- the count the vector suite reads --------------------------------------

check_mutation "the reported count must be the searches actually made" \
    '        checked=$((checked + 1))' \
    '        checked=$((checked + 2))'

check_mutation "a named file that was never opened must not count as a search" \
    '            continue  # a file that was never opened is not a search' \
    '            checked=$((checked + 1))'

# --- an Override must carry its dead words ---------------------------------
#
# Every mutant below turns a mistyped or missing marker back into a silent pass,
# which is the one failure a staleness check may never have.

check_mutation "an Override with no Dead-words line must be an error" \
    "        '**Override'*)      ENTRY_KIND=override ;;" \
    "        '@@no-entry-starts-like-this@@'*)      ENTRY_KIND=override ;;"

check_mutation "a heading must end the entry above it" \
    "                   '#'*) ENTRY_KIND=heading ;;" \
    "                   '@@no-line-starts-like-this@@'*) ENTRY_KIND=heading ;;"

check_mutation "the next entry must end the Override above it" \
    "        '**Fill'*|'**Add'*) ENTRY_KIND=other ;;" \
    "        '@@nor-this@@'*) ENTRY_KIND=other ;;"

check_mutation "an Override still owing its words at end of file must be an error" \
    '    if [ "$_cf_override_line" -ne 0 ]; then' \
    '    if false; then'

check_mutation "a list bullet must not hide an entry" \
    "        '- '*|'* '*) _ek_s=\$(ltrim \"\${_ek_s#??}\") ;;" \
    "        '@@not-a-bullet@@'*) _ek_s=\$(ltrim \"\${_ek_s#??}\") ;;"

# --- the line bound --------------------------------------------------------

check_mutation "a Dead-words line longer than the bound must be refused" \
    'MAX_LINE_BYTES=4096' \
    'MAX_LINE_BYTES=999999'

# --- a local file that cannot be read --------------------------------------

check_mutation "a local file that is not a regular file must be an error" \
    '        if [ ! -f "$path" ]; then' \
    '        if [ ! -e "$path" ]; then'

check_mutation "a dangling symlink must not read as 'nothing is customized'" \
    '    if [ -e "$path" ] || [ -L "$path" ]; then' \
    '    if [ -e "$path" ]; then'

# Three more depend on a file the current user cannot read, which root can.
if [ "$(id -u)" -eq 0 ]; then
    _pass "an unreadable local file must be an error (skipped: running as root)"
    _pass "an unsearchable local directory must be an error (skipped: running as root)"
    _pass "a failed search must not be reported as found (skipped: running as root)"
else
    check_mutation "an unreadable local file must be an error" \
        '        if [ ! -r "$path" ]; then' \
        '        if false; then'

    check_mutation "an unsearchable local directory must be an error" \
        'if [ ! -x "$local_dir" ]; then' \
        'if false; then'

    check_mutation "a failed search must not be reported as found" \
        '            *) parse_err "$_si_src" "$_si_ln" "search failed (grep status $_si_gs) on $_si_target" ;;' \
        '            *) : ;;'
fi

# --- a file name is a name, not a pattern ----------------------------------

check_mutation "a glob character in a file name must be refused" \
    "            *'*'*|*'?'*|*'['*)" \
    "            @@no-file-name-looks-like-this@@)"

# --- the lines of a file ---------------------------------------------------

check_mutation "a final line with no newline must still be read" \
    '    while IFS= read -r _cf_line || [ -n "$_cf_line" ]; do' \
    '    while IFS= read -r _cf_line; do'

check_mutation "read must not eat a backslash in the quoted words" \
    '    while IFS= read -r _cf_line || [ -n "$_cf_line" ]; do' \
    '    while IFS= read _cf_line || [ -n "$_cf_line" ]; do'

check_mutation "the quoted words must be searched whole, never as a prefix" \
    '        _cl_words=$SCAN_WORDS' \
    '        _cl_words=${SCAN_WORDS%%"$SEP"*}'

check_mutation "a bare marker after a code span must still be seen" \
    "                _hb_out=\$_hb_out\${_hb_r%%'\`'*}" \
    "                _hb_out=\${_hb_r%%'\`'*}"

# --- fences ----------------------------------------------------------------

check_mutation "a closing run followed by prose must not close a fence" \
    '    [ -z "$(rtrim "$_fc_r")" ]' \
    '    :'

check_mutation "a backtick in a fence's info string must mean no fence" \
    "        case \$_fo_r in *'\`'*) return 1 ;; esac" \
    '        :'

# --- usage -----------------------------------------------------------------

check_mutation "-h alone must print usage" \
    '    -h|--help) usage; exit 0 ;;' \
    '    --help) usage; exit 0 ;;'

finish
