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
#      that does not parse, or a failed search. An error outranks a stale
#      finding: if both happen, the status is 2.
#
# The grammar of a "**Dead words:**" line — fixed, because this script reads it:
#
#   **Dead words:** `some words` (in `FILE.md`) · `other words` (in `A.md` and `B.md`)
#
#   * optional leading whitespace, then the literal  **Dead words:**
#   * items separated by  " · "  (space, U+00B7, space)
#   * each item is one code span of the quoted words, then  " (in ",
#     then one or more code spans naming files, then  ")"
#   * several file names are joined by ", ", " and ", or ", and "
#   * quoted words may not contain a backtick; file names may contain no
#     whitespace and no "/" — no item may name a path outside the two
#     directories given as arguments
#   * lines inside a ``` fenced code block are skipped, so a local file may
#     quote this grammar without the example being checked
#   * whitespace at the start of the line and after the last item is ignored;
#     whitespace inside the grammar is not
#
# POSIX sh. External utilities used, all POSIX: grep (-F, -q, -e, --), cat
# (for the usage heredoc), printf. Everything else is a shell builtin.

set -u
unset IFS

LC_ALL=C
export LC_ALL

PROG=${0##*/}
SEP=' · '
CR=$(printf '\r')
TAB=$(printf '\t')

LOCAL_FILES='LOCAL.md LOCAL_dev.md'

errors=0
stale=0
checked=0
ITEM_FILES=''

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

# Validate the file-name list of one item and leave it in ITEM_FILES.
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
                  "expected a \`file\` code span, got: $_pf_rest"
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
            '')        break ;;
            ', and '*) _pf_rest=${_pf_rest#', and '} ;;
            ' and '*)  _pf_rest=${_pf_rest#' and '} ;;
            ', '*)     _pf_rest=${_pf_rest#', '} ;;
            *) parse_err "$_pf_src" "$_pf_ln" \
                  "expected \", \", \" and \" or \", and \" between file names, got: $_pf_rest"
               return 1 ;;
        esac
    done
    return 0
}

# Check one item:  `words` (in `FILE.md` and `OTHER.md`)
check_item() {
    _ci_item=$1
    _ci_src=$2
    _ci_ln=$3

    case $_ci_item in
        '`'*) ;;
        *) parse_err "$_ci_src" "$_ci_ln" \
              "item does not begin with a backtick: $_ci_item"
           return ;;
    esac
    _ci_after=${_ci_item#'`'}
    case $_ci_after in
        *'`'*) ;;
        *) parse_err "$_ci_src" "$_ci_ln" \
              "unterminated quoted words: $_ci_item"
           return ;;
    esac
    _ci_words=${_ci_after%%'`'*}
    _ci_tail=${_ci_after#*'`'}

    if [ -z "$_ci_words" ]; then
        parse_err "$_ci_src" "$_ci_ln" "empty quoted words: $_ci_item"
        return
    fi

    case $_ci_tail in
        ' (in '*')') ;;
        *) parse_err "$_ci_src" "$_ci_ln" \
              "item is not \`words\` (in \`FILE.md\`): $_ci_item"
           return ;;
    esac
    _ci_files=${_ci_tail#' (in '}
    _ci_files=${_ci_files%')'}

    parse_files "$_ci_files" "$_ci_src" "$_ci_ln" || return

    for _ci_name in $ITEM_FILES; do
        _ci_target=$(target_for "$_ci_name")
        if [ ! -f "$_ci_target" ]; then
            parse_err "$_ci_src" "$_ci_ln" \
               "named file does not exist: $_ci_name (looked in $_ci_target)"
            continue
        fi
        checked=$((checked + 1))
        grep -F -q -e "$_ci_words" -- "$_ci_target"
        _ci_gs=$?
        case $_ci_gs in
            0) ;;
            1) report_stale \
                 "$_ci_src:$_ci_ln: STALE — \`$_ci_words\` no longer appears in $_ci_name ($_ci_target)" ;;
            *) parse_err "$_ci_src" "$_ci_ln" \
                 "search failed (grep status $_ci_gs) on $_ci_target" ;;
        esac
    done
}

# Read one local file and check every **Dead words:** line in it.
check_file() {
    _cf_path=$1
    _cf_lineno=0
    _cf_fence=0

    while IFS= read -r _cf_line || [ -n "$_cf_line" ]; do
        _cf_lineno=$((_cf_lineno + 1))
        _cf_line=${_cf_line%"$CR"}
        _cf_trimmed=$(ltrim "$_cf_line")

        case $_cf_trimmed in
            '```'*) _cf_fence=$((1 - _cf_fence)); continue ;;
        esac
        [ "$_cf_fence" -eq 0 ] || continue

        case $_cf_trimmed in
            '**Dead words:**'*) ;;
            *) continue ;;
        esac

        _cf_rest=${_cf_trimmed#'**Dead words:**'}
        _cf_rest=$(ltrim "$_cf_rest")
        _cf_rest=$(rtrim "$_cf_rest")

        if [ -z "$_cf_rest" ]; then
            parse_err "$_cf_path" "$_cf_lineno" "**Dead words:** line names nothing"
            continue
        fi

        while [ -n "$_cf_rest" ]; do
            case $_cf_rest in
                *"$SEP"*) _cf_item=${_cf_rest%%"$SEP"*}
                          _cf_rest=${_cf_rest#*"$SEP"} ;;
                *)        _cf_item=$_cf_rest
                          _cf_rest='' ;;
            esac
            check_item "$_cf_item" "$_cf_path" "$_cf_lineno"
        done
    done < "$_cf_path"
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

present=''
for name in $LOCAL_FILES; do
    if [ -f "$local_dir/$name" ]; then
        present="$present $name"
    fi
done

if [ -z "$present" ]; then
    printf '%s: no local layer in %s — nothing is customized.\n' "$PROG" "$local_dir"
    exit 0
fi

for name in $present; do
    check_file "$local_dir/$name"
done

if [ "$errors" -gt 0 ]; then
    printf '%s: %d error(s) and %d stale override(s); %d string(s) checked.\n' \
        "$PROG" "$errors" "$stale" "$checked" >&2
    exit 2
fi

if [ "$stale" -gt 0 ]; then
    printf '%s: %d stale override(s) of %d string(s) checked — the playbook rewrote that text.\n' \
        "$PROG" "$stale" "$checked"
    exit 1
fi

printf '%s: ok — %d dead-words string(s) still present in %s.\n' \
    "$PROG" "$checked" "$rules_dir"
exit 0
