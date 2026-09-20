#!/bin/sh
#
# check-local.sh — does every Override in the local layer still bite?
#
# The local layer (rules/LOCAL.md and rules/LOCAL_dev.md) belongs to the person
# who installed this playbook; an update never opens it. An **Override** entry
# there changes a playbook rule, and quotes — after a "**Dead words:**" line —
# the playbook's exact words that no longer apply. If the playbook later
# rewrites those words, the override is talking about text that is gone: it is
# STALE, and the person must be told before they rely on it.
#
# This script reads every "**Dead words:**" line and searches the named playbook
# file for each quoted string, as a fixed string. It never writes anything.
#
# Usage:
#   check-local.sh <local-dir> <rules-dir> [claude-md-path]
#
#   <local-dir>        directory holding LOCAL.md and/or LOCAL_dev.md
#                      (normally ~/.claude/rules)
#   <rules-dir>        directory holding the playbook rule files to check
#                      against. Point this at *staged* new text during an
#                      update, so staleness is known before anything is copied.
#   [claude-md-path]   optional. Where the item name `CLAUDE.md` resolves to.
#                      Default: CLAUDE.md in the parent of <rules-dir>, which is
#                      the layout both in this repository and under ~/.claude.
#
# Exit status:
#   0  every quoted string was found — or there is no local layer at all
#   1  at least one stale override; each is reported with file:line, the words,
#      and the file it was sought in
#   2  usage error, a named file that does not exist, a "**Dead words:**" line
#      that does not parse, a bare marker anywhere but the start of a line, an
#      unclosed fenced code block, or a failed search. An error outranks a stale
#      finding: if both happen, the status is 2.
#
# The last line of stdout is always a machine-readable count:
#
#   check-local.sh: <N> search(es), <S> stale, <E> error(s).
#
# ---------------------------------------------------------------------------
# The grammar of a "**Dead words:**" line — fixed, because this script reads it:
#
#   **Dead words:** `some words` (in `FILE.md`) · `other words` (in `A.md` and `B.md`)
#
#   * optional leading spaces or tabs, then the literal  **Dead words:**  , then
#     at least one space or tab, then the first item
#   * items are separated by  " · "  (space, U+00B7, space)
#   * each item is one code span of the quoted words, then  " (in ",
#     then one or more code spans naming files, then  ")"
#   * several file names are joined by ", ", " and ", or ", and "
#   * after the last item: one optional "." , then optional trailing whitespace
#     and an optional carriage return. Any other trailing text is an error.
#   * quoted words may not contain a backtick and may not be empty; file names
#     may contain no whitespace and no "/" — no item may name a path outside the
#     two directories given as arguments
#
# **The line is scanned left to right over its code spans; it is never split on
# the separator.** A real entry quotes `### 11 · Your platform`, so " · ",
# "(in " and ")" all occur *inside* quoted words. Only a backtick ends a span,
# and the words between two backticks are taken verbatim — never trimmed, never
# re-split.
#
# Fail closed — two rules that make "skipped silently" impossible:
#
#   * a line that contains the bare marker **Dead words:** anywhere other than
#     its start is an ERROR, not a skipped entry. Prose that needs to name the
#     marker puts it inside a code span, and is then ignored.
#   * lines inside a fenced code block are ignored, so a local file may quote
#     this grammar without the example being checked. A fence opens on a line
#     whose first non-whitespace is three or more backticks or tildes and closes
#     on the matching run of the same character; a fence left open at end of
#     file is an error.
#
# POSIX sh — note that POSIX sh has no `local`, so every helper's variables
# carry a prefix of their own and the parsers hand their results back in the
# globals SCAN_WORDS, ITEM_FILES and SCAN_REST.
#
# External utilities used, all POSIX: grep (-F, -q, -e, --), cat (for the usage
# heredoc), printf. Everything else is a shell builtin.

set -u
unset IFS

LC_ALL=C
export LC_ALL

PROG=${0##*/}
SEP=' · '
MARKER='**Dead words:**'
CR=$(printf '\r')
TAB=$(printf '\t')

LOCAL_FILES='LOCAL.md LOCAL_dev.md'

errors=0
stale=0
checked=0

# Results handed back by the parsers (POSIX sh has no `local`, and a function
# called in $( ) would lose every counter it incremented).
SCAN_WORDS=''
SCAN_REST=''
ITEM_FILES=''

# Fence state while one file is being read.
FENCE_CHAR=''
FENCE_LEN=0
FENCE_LINE=0

usage() {
    cat <<EOF
usage: $PROG <local-dir> <rules-dir> [claude-md-path]

  <local-dir>       directory holding LOCAL.md and/or LOCAL_dev.md
  <rules-dir>       directory holding the playbook rule files to check against
  [claude-md-path]  where the name \`CLAUDE.md\` resolves to
                    (default: CLAUDE.md in the parent of <rules-dir>)

exit 0 = every quoted string found, or nothing is customized
exit 1 = at least one stale override
exit 2 = usage error, missing named file, or an unparsable **Dead words:** line
EOF
}

die_usage() {
    printf '%s: %s\n' "$PROG" "$1" >&2
    usage >&2
    exit 2
}

# A hard error. Never a pass: it forces exit 2.
err() {
    printf '%s\n' "$1" >&2
    errors=$((errors + 1))
}

parse_err() {
    err "$1:$2: error: $3"
}

report_stale() {
    printf '%s\n' "$1"
    stale=$((stale + 1))
}

# Strip leading spaces and tabs.
ltrim() {
    _lt_s=$1
    while :; do
        case $_lt_s in
            ' '*)    _lt_s=${_lt_s#' '} ;;
            "$TAB"*) _lt_s=${_lt_s#"$TAB"} ;;
            *)       break ;;
        esac
    done
    printf '%s' "$_lt_s"
}

# Strip trailing spaces and tabs. An editor's stray trailing space is invisible,
# and halting an update with "does not parse" over one would be a bad failure
# for a real cause; whitespace at the end of a line carries no meaning here.
rtrim() {
    _rt_s=$1
    while :; do
        case $_rt_s in
            *' ')    _rt_s=${_rt_s%' '} ;;
            *"$TAB") _rt_s=${_rt_s%"$TAB"} ;;
            *)       break ;;
        esac
    done
    printf '%s' "$_rt_s"
}

# Where a file name in an item resolves to on disk.
target_for() {
    case $1 in
        CLAUDE.md) printf '%s' "$claude_md" ;;
        *)         printf '%s' "$rules_dir/$1" ;;
    esac
}

# ------------------------------------------------------------------ the scanner

# The file-name list of one item, starting just after " (in ".
# On success: ITEM_FILES holds the names, SCAN_REST the text after the ")".
# Returns 1 and reports if the list does not parse.
parse_files() {
    _pf_rest=$1
    _pf_src=$2
    _pf_ln=$3
    ITEM_FILES=''

    while :; do
        case $_pf_rest in
            '`'*) ;;
            *) parse_err "$_pf_src" "$_pf_ln" \
                  "expected a \`file\` code span, got: ${_pf_rest:-<end of line>}"
               return 1 ;;
        esac
        _pf_r=${_pf_rest#'`'}
        case $_pf_r in
            *'`'*) ;;
            *) parse_err "$_pf_src" "$_pf_ln" \
                  "unterminated file code span: \`$_pf_r"
               return 1 ;;
        esac
        _pf_name=${_pf_r%%'`'*}
        _pf_rest=${_pf_r#*'`'}

        case $_pf_name in
            '')   parse_err "$_pf_src" "$_pf_ln" "empty file name"; return 1 ;;
            .|..) parse_err "$_pf_src" "$_pf_ln" "not a file name: $_pf_name"
                  return 1 ;;
            */*|*\\*)
                  parse_err "$_pf_src" "$_pf_ln" \
                     "file name may not contain a path separator: $_pf_name"
                  return 1 ;;
            *' '*|*"$TAB"*)
                  parse_err "$_pf_src" "$_pf_ln" \
                     "file name may not contain whitespace: $_pf_name"
                  return 1 ;;
        esac

        ITEM_FILES="$ITEM_FILES $_pf_name"

        case $_pf_rest in
            ')'*)      SCAN_REST=${_pf_rest#')'}; return 0 ;;
            ', and '*) _pf_rest=${_pf_rest#', and '} ;;
            ' and '*)  _pf_rest=${_pf_rest#' and '} ;;
            ', '*)     _pf_rest=${_pf_rest#', '} ;;
            *) parse_err "$_pf_src" "$_pf_ln" \
                  "expected \", \", \" and \" or \")\" after a file name, got: ${_pf_rest:-<end of line>}"
               return 1 ;;
        esac
    done
}

# One item:  `words` (in `FILE.md` and `OTHER.md`)
# On success: SCAN_WORDS holds the quoted words verbatim, ITEM_FILES the file
# names, SCAN_REST whatever follows the item on the line.
parse_item() {
    _pi_rest=$1
    _pi_src=$2
    _pi_ln=$3

    case $_pi_rest in
        '`'*) ;;
        *) parse_err "$_pi_src" "$_pi_ln" \
              "item does not begin with a backtick: $_pi_rest"
           return 1 ;;
    esac
    _pi_after=${_pi_rest#'`'}
    case $_pi_after in
        *'`'*) ;;
        *) parse_err "$_pi_src" "$_pi_ln" \
              "unterminated quoted words: \`$_pi_after"
           return 1 ;;
    esac
    SCAN_WORDS=${_pi_after%%'`'*}
    _pi_tail=${_pi_after#*'`'}

    if [ -z "$SCAN_WORDS" ]; then
        parse_err "$_pi_src" "$_pi_ln" "empty quoted words: \`\`"
        return 1
    fi

    # Every item names the file its words are in. An item without one is an
    # error, not a guess at which file was meant.
    case $_pi_tail in
        ' (in '*) ;;
        *) parse_err "$_pi_src" "$_pi_ln" "expected \" (in \` after the quoted words, got: ${_pi_tail:-<end of line>}"; return 1 ;;
    esac

    parse_files "${_pi_tail#' (in '}" "$_pi_src" "$_pi_ln" || return 1
    return 0
}

# Search one item's quoted words in each file it names.
search_item() { # words files src ln
    _si_words=$1
    _si_files=$2
    _si_src=$3
    _si_ln=$4

    for _si_name in $_si_files; do
        _si_target=$(target_for "$_si_name")
        if [ ! -f "$_si_target" ]; then
            parse_err "$_si_src" "$_si_ln" \
               "named file does not exist: $_si_name (looked in $_si_target)"
            continue
        fi
        checked=$((checked + 1))
        grep -F -q -e "$_si_words" -- "$_si_target"
        _si_gs=$?
        case $_si_gs in
            0) ;;
            1) report_stale \
                 "$_si_src:$_si_ln: STALE — \`$_si_words\` no longer appears in $_si_name ($_si_target)" ;;
            *) parse_err "$_si_src" "$_si_ln" \
                 "search failed (grep status $_si_gs) on $_si_target" ;;
        esac
    done
}

# The item list of one **Dead words:** line: item (SEP item)* "."? — already
# stripped of leading and trailing whitespace by the caller.
check_items() { # rest src ln
    _cl_rest=$1
    _cl_src=$2
    _cl_ln=$3

    while :; do
        parse_item "$_cl_rest" "$_cl_src" "$_cl_ln" || return
        _cl_words=$SCAN_WORDS
        _cl_files=$ITEM_FILES
        _cl_rest=$SCAN_REST
        search_item "$_cl_words" "$_cl_files" "$_cl_src" "$_cl_ln"

        # One closing "." is allowed after the last item — a sentence may end
        # normally. Anything else after an item is trailing prose, and an entry
        # whose tail was not understood is an error, never a half-read entry.
        case $_cl_rest in
            '')       return ;;
            '.')      return ;;
            "$SEP"*)  _cl_rest=${_cl_rest#"$SEP"} ;;
            *) parse_err "$_cl_src" "$_cl_ln" "trailing text after an item: $_cl_rest"; return ;;
        esac
    done
}

# ------------------------------------------------------------------ the lines

# Does this line open a fenced code block? Sets FENCE_CHAR/FENCE_LEN on yes.
fence_opens() { # already-ltrimmed line, lineno
    case $1 in
        '```'*) _fo_ch='`' ;;
        '~~~'*) _fo_ch='~' ;;
        *)      return 1 ;;
    esac
    _fo_n=0
    _fo_r=$1
    while :; do
        case $_fo_r in
            "$_fo_ch"*) _fo_n=$((_fo_n + 1)); _fo_r=${_fo_r#"$_fo_ch"} ;;
            *)          break ;;
        esac
    done
    # A backtick fence's info string may not itself contain a backtick.
    if [ "$_fo_ch" = '`' ]; then
        case $_fo_r in *'`'*) return 1 ;; esac
    fi
    FENCE_CHAR=$_fo_ch
    FENCE_LEN=$_fo_n
    FENCE_LINE=$2
    return 0
}

# Does this line close the open fence? The run must be of the same character,
# at least as long as the opening one, and followed by nothing but whitespace.
fence_closes() { # already-ltrimmed line
    _fc_n=0
    _fc_r=$1
    while :; do
        case $_fc_r in
            "$FENCE_CHAR"*) _fc_n=$((_fc_n + 1)); _fc_r=${_fc_r#"$FENCE_CHAR"} ;;
            *)              break ;;
        esac
    done
    [ "$_fc_n" -ge "$FENCE_LEN" ] || return 1
    [ -z "$(rtrim "$_fc_r")" ]
}

# Is the bare marker present outside every code span on this line? Complete
# `code spans` are removed first; an unterminated backtick leaves its text in
# place, so a marker after one still counts — fail closed.
has_bare_marker() { # raw line
    _hb_out=''
    _hb_r=$1
    while :; do
        case $_hb_r in
            *'`'*'`'*)
                _hb_out=$_hb_out${_hb_r%%'`'*}
                _hb_r=${_hb_r#*'`'}
                _hb_r=${_hb_r#*'`'}
                ;;
            *) break ;;
        esac
    done
    _hb_out=$_hb_out$_hb_r
    case $_hb_out in
        *"$MARKER"*) return 0 ;;
    esac
    return 1
}

# Read one local file and check every **Dead words:** line in it.
check_file() {
    _cf_path=$1
    _cf_lineno=0
    FENCE_CHAR=''
    FENCE_LEN=0
    FENCE_LINE=0

    while IFS= read -r _cf_line || [ -n "$_cf_line" ]; do
        _cf_lineno=$((_cf_lineno + 1))
        _cf_line=${_cf_line%"$CR"}
        _cf_trimmed=$(ltrim "$_cf_line")

        if [ -n "$FENCE_CHAR" ]; then
            if fence_closes "$_cf_trimmed"; then
                FENCE_CHAR=''
            fi
            continue
        fi
        if fence_opens "$_cf_trimmed" "$_cf_lineno"; then
            continue
        fi

        case $_cf_trimmed in
            "$MARKER"*) ;;
            *) # Not an entry. A bare marker anywhere else is an error, never a
               # silently skipped entry; inside a code span it is prose.
               if has_bare_marker "$_cf_line"; then
                   parse_err "$_cf_path" "$_cf_lineno" \
                      "the $MARKER marker is not at the start of the line — an entry here would be skipped. Give the entry a line of its own, or, if this is prose about the marker, put it inside a code span"
               fi
               continue ;;
        esac

        _cf_rest=${_cf_trimmed#"$MARKER"}
        case $_cf_rest in
            '') parse_err "$_cf_path" "$_cf_lineno" "$MARKER line names nothing"
                continue ;;
            ' '*|"$TAB"*) ;;
            *)  parse_err "$_cf_path" "$_cf_lineno" \
                   "expected a space or a tab after the marker, got: $_cf_rest"
                continue ;;
        esac

        _cf_rest=$(ltrim "$_cf_rest")
        _cf_rest=$(rtrim "$_cf_rest")

        if [ -z "$_cf_rest" ]; then
            parse_err "$_cf_path" "$_cf_lineno" "$MARKER line names nothing"
            continue
        fi

        check_items "$_cf_rest" "$_cf_path" "$_cf_lineno"
    done < "$_cf_path"

    if [ -n "$FENCE_CHAR" ]; then
        parse_err "$_cf_path" "$FENCE_LINE" \
           "fenced code block opened here is never closed — every line after it was ignored"
    fi
}

# ---------------------------------------------------------------- arguments

case ${1:-} in
    -h|--help) usage; exit 0 ;;
esac

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    die_usage "expected 2 or 3 arguments, got $#"
fi

local_dir=$1
rules_dir=$2

[ -d "$local_dir" ] || die_usage "not a directory: $local_dir"
[ -d "$rules_dir" ] || die_usage "not a directory: $rules_dir"

if [ $# -eq 3 ]; then
    claude_md=$3
    [ -f "$claude_md" ] || die_usage "not a file: $claude_md"
else
    claude_md=$rules_dir/../CLAUDE.md
fi

# ---------------------------------------------------------------- the check

counts() {
    printf '%s: %d search(es), %d stale, %d error(s).\n' \
        "$PROG" "$checked" "$stale" "$errors"
}

present=''
for name in $LOCAL_FILES; do
    if [ -f "$local_dir/$name" ]; then
        present="$present $name"
    fi
done

if [ -z "$present" ]; then
    printf '%s: no local layer in %s — nothing is customized.\n' "$PROG" "$local_dir"
    counts
    exit 0
fi

for name in $present; do
    check_file "$local_dir/$name"
done

if [ "$errors" -gt 0 ]; then
    printf '%s: %d error(s) and %d stale override(s); %d string(s) checked.\n' \
        "$PROG" "$errors" "$stale" "$checked" >&2
    counts
    exit 2
fi

if [ "$stale" -gt 0 ]; then
    printf '%s: %d stale override(s) of %d string(s) checked — the playbook rewrote that text.\n' \
        "$PROG" "$stale" "$checked"
    counts
    exit 1
fi

printf '%s: ok — %d dead-words string(s) still present in %s.\n' \
    "$PROG" "$checked" "$rules_dir"
counts
exit 0
