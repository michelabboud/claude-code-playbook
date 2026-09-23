#!/bin/sh
#
# check-local.sh — does every Override in the local layer still bite?
#
# The local layer (rules/LOCAL.md and rules/LOCAL_dev.md) belongs to the person
# who installed this playbook: the playbook never ships those two files, and an
# update never writes to, copies over or replaces them. This script reads them,
# and only to check them. An **Override** entry
# there changes a playbook rule and carries a three-line verifier: an Anchor
# naming one literal Markdown section, that normalized section's SHA-256 Rule
# digest, and — after a "**Dead words:**" line — an exact quote. If the
# playbook later rewrites that section or quote, the Override is STALE and its
# owner must be told before they rely on it.
#
# This script reads every live Override's verifier and searches the anchored
# section for each quoted string, as a fixed string. It never writes managed or
# local text; its private scratch directory is removed on exit.
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
#   0  every quoted string and section digest was current — or there is no local
#      layer at all
#   1  at least one stale override; each is reported with file:line, the words,
#      and the file it was sought in
#   2  usage error, a named file that does not exist, a "**Dead words:**" line
#      that does not parse or is longer than the byte bound below, an **Override**
#      entry with no complete Anchor, Rule digest, and "**Dead words:**" verifier,
#      a bare marker anywhere but the
#      start of a line, an unclosed fenced code block, a local file that exists
#      and cannot be read as a regular file, a UTF-8 BOM or NUL byte, or a failed search. An error
#      outranks a stale finding: if both happen, the status is 2.
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
#     may contain no whitespace, no "/" and no glob character ("*", "?", "[") —
#     no item may name a path outside the two directories given as arguments,
#     and no name's meaning may depend on the current directory
#   * the whole line may be at most MAX_LINE_BYTES bytes long
#
# **The line is scanned left to right over its code spans; it is never split on
# the separator.** A real entry quotes `### 11 · Your platform`, so " · ",
# "(in " and ")" all occur *inside* quoted words. Only a backtick ends a span,
# and the words between two backticks are taken verbatim — never trimmed, never
# re-split.
#
# Fail closed — four rules that make "skipped silently" impossible:
#
#   * a line that contains the bare marker **Dead words:** anywhere other than
#     its start is an ERROR, not a skipped entry. Prose that needs to name the
#     marker puts it inside a code span, and is then ignored.
#   * an **Override** entry with no complete Anchor, Rule digest, and valid
#     "**Dead words:**" line before the next
#     entry line, the next heading, or the end of the file is an ERROR. This is
#     what turns every mistyped marker — "**dead words:**", "**Dead words**:",
#     "Dead words:" — into a refusal instead of a silent pass. An *entry line* is
#     a line that, after optional indentation and an optional "- " or "* "
#     bullet, begins with **Fill, **Add or **Override; a *heading* is a line
#     whose first non-whitespace character is "#". A Dead-words line with no
#     Override above it is still parsed and searched: it is not the marker that
#     needs justifying, it is the Override that needs its words.
#   * lines inside a fenced code block are ignored, so a local file may quote
#     this grammar without the example being checked — an Override inside a fence
#     is an example, and owes no Dead-words line. A fence opens on a line whose
#     first non-whitespace is three or more backticks or tildes and closes on the
#     matching run of the same character; a fence left open at end of file is an
#     error.
#   * a local file that exists and cannot be read as a regular file — unreadable,
#     a directory, a dangling symlink, or inside a directory with no search
#     permission — is an ERROR, never "nothing is customized". A symlink to a
#     readable regular file IS read: dotfile managers install local files that
#     way.
#
# POSIX sh — note that POSIX sh has no `local`, so every helper's variables
# carry a prefix of their own and the parsers hand their results back in the
# globals SCAN_WORDS, ITEM_FILES and SCAN_REST.
#
# External utilities used: grep (-F, -q, -e, --), cat (for the usage heredoc),
# cmp, tr, awk, wc, find, mktemp, rm, and sha256sum, shasum, or openssl. Everything
# else is a shell builtin.

set -u

# No pathname expansion, anywhere. A file name inside an item is data read out
# of the user's file, and `$name` in a `for` list would otherwise be matched
# against the current directory — so the same local file would mean different
# things depending on where the script was run from. Names carrying a glob
# character are refused outright as well (parse_files); this is the second lock.
set -f

unset IFS

LC_ALL=C
export LC_ALL

PROG=${0##*/}
SEP=' · '
MARKER='**Dead words:**'
ANCHOR_MARKER='**Anchor:**'
DIGEST_MARKER='**Rule digest:**'
CR=$(printf '\r')
TAB=$(printf '\t')
UTF8_BOM=$(printf '\357\273\277')

# The longest a **Dead words:** line may be, in bytes — a bound that fails
# closed rather than handing an unbounded quotation to grep. The longest real
# line measured is under 1 KB, so this is a runaway paste, not a quotation.
# LC_ALL=C above is what makes ${#line} a count of bytes rather than characters.
MAX_LINE_BYTES=4096

LOCAL_FILES='LOCAL.md LOCAL_dev.md'

errors=0
stale=0
checked=0

# Results handed back by the parsers (POSIX sh has no `local`, and a function
# called in $( ) would lose every counter it incremented).
SCAN_WORDS=''
SCAN_REST=''
ITEM_FILES=''
ENTRY_KIND=''

# A live Override is bound to one literal Markdown section, rather than merely
# to a phrase which might occur in several rules.  The verifier consists of an
# Anchor line naming that section, its normalized SHA-256 digest, and quoted
# words that occur exactly once inside it.
PENDING_ANCHOR_HEADING=''
PENDING_ANCHOR_NAME=''
PENDING_ANCHOR_PATH=''
PENDING_DIGEST=''
ACTIVE_ANCHOR_NAME=''
ACTIVE_ANCHOR_PATH=''
SCRATCH_DIR=''
SECTION_FILE=''
WORDS_FILE=''

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

cleanup_scratch() {
    if [ -n "$SCRATCH_DIR" ]; then
        rm -rf -- "$SCRATCH_DIR"
    fi
}

clear_verifier() {
    PENDING_ANCHOR_HEADING=''
    PENDING_ANCHOR_NAME=''
    PENDING_ANCHOR_PATH=''
    PENDING_DIGEST=''
    ACTIVE_ANCHOR_NAME=''
    ACTIVE_ANCHOR_PATH=''
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
            # A name is a name, never a pattern: `*.md` would otherwise mean
            # whatever the directory the script was run from happens to hold.
            *'*'*|*'?'*|*'['*)
                  parse_err "$_pf_src" "$_pf_ln" \
                     "file name may not contain a glob character (* ? [): $_pf_name"
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

# Parse `## A section` (in `FILE.md`), prove the heading is unambiguous, and
# write its normalized rule block into SECTION_FILE.  The actual heading is the
# anchor: a rule number alone can move or repeat, while this bounded section is
# the text an Override depends on.
parse_anchor() { # rest src ln
    _pa_rest=$1
    _pa_src=$2
    _pa_ln=$3
    parse_item "$_pa_rest" "$_pa_src" "$_pa_ln" || return 1
    PENDING_ANCHOR_HEADING=$SCAN_WORDS
    if [ -n "$SCAN_REST" ]; then
        parse_err "$_pa_src" "$_pa_ln" "trailing text after Anchor: $SCAN_REST"
        return 1
    fi
    case $PENDING_ANCHOR_HEADING in
        '# '*|'## '*|'### '*|'#### '*|'##### '*|'###### '*) ;;
        *) parse_err "$_pa_src" "$_pa_ln" "Anchor must name a Markdown heading, got: $PENDING_ANCHOR_HEADING"; return 1 ;;
    esac

    set -- $ITEM_FILES
    if [ "$#" -ne 1 ]; then
        parse_err "$_pa_src" "$_pa_ln" "Anchor must name exactly one file"
        return 1
    fi
    PENDING_ANCHOR_NAME=$1
    PENDING_ANCHOR_PATH=$(target_for "$PENDING_ANCHOR_NAME")
    if [ ! -f "$PENDING_ANCHOR_PATH" ]; then
        parse_err "$_pa_src" "$_pa_ln" \
            "Anchor names a file that does not exist: $PENDING_ANCHOR_NAME (looked in $PENDING_ANCHOR_PATH)"
        return 1
    fi

    printf '%s\n' "$PENDING_ANCHOR_HEADING" > "$SCRATCH_DIR/heading"
    # Count exactly the normalized heading that extraction compares below.
    # Counting raw bytes would reject CRLF and miss normalized duplicates.
    _pa_count=$(awk '
        NR == FNR { wanted = $0; next }
        { sub(/\r$/, ""); sub(/[ \t]+$/, ""); if ($0 == wanted) count++ }
        END { print count + 0 }
    ' "$SCRATCH_DIR/heading" "$PENDING_ANCHOR_PATH")
    _pa_status=$?
    if [ "$_pa_status" -ne 0 ]; then
        parse_err "$_pa_src" "$_pa_ln" "could not count the anchored heading in $PENDING_ANCHOR_NAME"
        return 1
    fi
    if [ "$_pa_count" -ne 1 ]; then
        parse_err "$_pa_src" "$_pa_ln" \
            "anchored heading must occur exactly once in $PENDING_ANCHOR_NAME; found $_pa_count"
        return 1
    fi

    awk '
        NR == FNR { wanted = $0; next }
        {
            line = $0
            sub(/\r$/, "", line)
            sub(/[ \t]+$/, "", line)
            plain = line
            sub(/^[ \t]*/, "", plain)
            if (!started && line == wanted) {
                started = 1
                level = 0
                while (substr(plain, level + 1, 1) == "#") level++
            }
            if (started) {
                if (line != wanted && plain ~ /^#+[ \t]/) {
                    next_level = 0
                    while (substr(plain, next_level + 1, 1) == "#") next_level++
                    if (next_level <= level) exit
                }
                sub(/[ \t]+$/, "", line)
                print line
            }
        }
        END { if (!started) exit 1 }
    ' "$SCRATCH_DIR/heading" "$PENDING_ANCHOR_PATH" > "$SECTION_FILE"
    _pa_status=$?
    if [ "$_pa_status" -ne 0 ] || [ ! -s "$SECTION_FILE" ]; then
        parse_err "$_pa_src" "$_pa_ln" "could not extract the anchored section from $PENDING_ANCHOR_NAME"
        return 1
    fi
    return 0
}

parse_digest() { # rest src ln
    _pd_rest=$1
    _pd_src=$2
    _pd_ln=$3
    case $_pd_rest in
        '`'*) ;;
        *) parse_err "$_pd_src" "$_pd_ln" "Rule digest must be one sha256 code span"; return 1 ;;
    esac
    _pd_after=${_pd_rest#'`'}
    case $_pd_after in
        *'`'*) ;;
        *) parse_err "$_pd_src" "$_pd_ln" "unterminated Rule digest code span"; return 1 ;;
    esac
    PENDING_DIGEST=${_pd_after%%'`'*}
    _pd_tail=${_pd_after#*'`'}
    if [ -n "$_pd_tail" ]; then
        parse_err "$_pd_src" "$_pd_ln" "trailing text after Rule digest: $_pd_tail"
        return 1
    fi
    case $PENDING_DIGEST in sha256:*) ;;
        *) parse_err "$_pd_src" "$_pd_ln" "Rule digest must be sha256 followed by 64 lowercase hexadecimal characters"; return 1 ;;
    esac
    _pd_hex=${PENDING_DIGEST#sha256:}
    case $_pd_hex in *[!0-9a-f]*|'')
        parse_err "$_pd_src" "$_pd_ln" "Rule digest must be sha256 followed by 64 lowercase hexadecimal characters"
        return 1 ;;
    esac
    if [ "${#_pd_hex}" -ne 64 ]; then
        parse_err "$_pd_src" "$_pd_ln" "Rule digest must be sha256 followed by 64 lowercase hexadecimal characters"
        return 1
    fi
    return 0
}

check_section_digest() { # src override-line
    _sd_src=$1
    _sd_ln=$2
    if command -v sha256sum >/dev/null 2>&1; then
        _sd_actual=$(sha256sum "$SECTION_FILE" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        _sd_actual=$(shasum -a 256 "$SECTION_FILE" | awk '{print $1}')
    elif command -v openssl >/dev/null 2>&1; then
        _sd_actual=$(openssl dgst -sha256 "$SECTION_FILE" | awk '{print $NF}')
    else
        parse_err "$_sd_src" "$_sd_ln" "cannot calculate the required SHA-256 Rule digest (need sha256sum, shasum, or openssl)"
        return 1
    fi
    case $_sd_actual in *[!0-9a-f]*|'')
        parse_err "$_sd_src" "$_sd_ln" "could not calculate a SHA-256 Rule digest"
        return 1 ;;
    esac
    if [ "${#_sd_actual}" -ne 64 ]; then
        parse_err "$_sd_src" "$_sd_ln" "could not calculate a SHA-256 Rule digest"
        return 1
    fi
    if [ "sha256:$_sd_actual" != "$PENDING_DIGEST" ]; then
        report_stale \
          "$_sd_src:$_sd_ln: STALE — section digest $PENDING_DIGEST (current sha256:$_sd_actual) no longer matches $PENDING_ANCHOR_NAME ($PENDING_ANCHOR_PATH)"
    fi
    return 0
}

# Search one item's quoted words in each file it names.
search_item() { # words files src ln
    _si_words=$1
    _si_files=$2
    _si_src=$3
    _si_ln=$4

    for _si_name in $_si_files; do
        if [ -n "$ACTIVE_ANCHOR_NAME" ]; then
            if [ "$_si_name" != "$ACTIVE_ANCHOR_NAME" ]; then
                parse_err "$_si_src" "$_si_ln" \
                    "an Override's Dead words must name its anchored file $ACTIVE_ANCHOR_NAME, not $_si_name"
                continue
            fi
            _si_nonblank=$(printf '%s' "$_si_words" | tr -d '[:space:]' | wc -c | tr -d ' ')
            if [ "$_si_nonblank" -lt 16 ]; then
                parse_err "$_si_src" "$_si_ln" \
                    "an Override's quoted words have $_si_nonblank non-whitespace bytes; the minimum anchor is 16"
                continue
            fi
            printf '%s\n' "$_si_words" > "$WORDS_FILE"
            _si_count=$(awk 'NR == FNR { needle = $0; next }
                { rest = $0; while ((at = index(rest, needle)) != 0) { count++; rest = substr(rest, at + length(needle)) } }
                END { print count + 0 }' "$WORDS_FILE" "$SECTION_FILE")
            _si_status=$?
            if [ "$_si_status" -ne 0 ]; then
                parse_err "$_si_src" "$_si_ln" "could not search the anchored section in $ACTIVE_ANCHOR_NAME"
                continue
            fi
            checked=$((checked + 1))
            case $_si_count in
                0) report_stale \
                   "$_si_src:$_si_ln: STALE — \`$_si_words\` no longer appears in the anchored section of $ACTIVE_ANCHOR_NAME ($ACTIVE_ANCHOR_PATH)" ;;
                1) ;;
                *) parse_err "$_si_src" "$_si_ln" \
                   "an Override's quoted words occur $_si_count times in the anchored section; they must occur exactly once" ;;
            esac
            continue
        fi
        _si_target=$(target_for "$_si_name")
        if [ ! -f "$_si_target" ]; then
            parse_err "$_si_src" "$_si_ln" \
               "named file does not exist: $_si_name (looked in $_si_target)"
            continue  # a file that was never opened is not a search
        fi
        checked=$((checked + 1))
        grep -F -q -e "$_si_words" -- "$_si_target"
        _si_gs=$?
        case $_si_gs in
            0) ;;
            1) report_stale \
                 "$_si_src:$_si_ln: STALE — \`$_si_words\` no longer appears in $_si_name ($_si_target)" ;;
            # grep says 2 or more: it could not read the file, or the pattern
            # defeated it. A search that did not happen is never a match.
            *) parse_err "$_si_src" "$_si_ln" "search failed (grep status $_si_gs) on $_si_target" ;;
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

# A Markdown-looking entry outside this small documented grammar must not be
# silently ignored. Complete code spans are removed so prose can name the
# grammar without becoming an entry.
has_unrecognized_entry_marker() { # raw line
    _he_out=''
    _he_r=$1
    while :; do
        case $_he_r in
            *'`'*'`'*)
                _he_out=$_he_out${_he_r%%'`'*}
                _he_r=${_he_r#*'`'}
                _he_r=${_he_r#*'`'}
                ;;
            *) break ;;
        esac
    done
    _he_out=$_he_out$_he_r
    _he_out=$(ltrim "$_he_out")
    case $_he_out in
        [0-9]*.\ \*\*Override*|[0-9]*.\ \*\*Fill*|[0-9]*.\ \*\*Add*|\
        \>\ \*\*Override*|\>\ \*\*Fill*|\>\ \*\*Add*|\
        \#*\ \*\*Override*|\#*\ \*\*Fill*|\#*\ \*\*Add*|\
        \*\*\*Override*|\*\*\*Fill*|\*\*\*Add*|\
        +\ \*\*Override*|+\ \*\*Fill*|+\ \*\*Add*) return 0 ;;
    esac
    # Reserve a bold lead-in with an em dash for canonical entries. This also
    # catches + list bullets, split emphasis, and Unicode lookalike letters.
    _he_candidate=$_he_out
    _he_entry_context=0
    case $_he_candidate in
        '- '*|'* '*|'+ '*|'> '*) _he_entry_context=1; _he_candidate=${_he_candidate#??} ;;
        [0-9]*'. '*) _he_entry_context=1; _he_candidate=${_he_candidate#*. } ;;
        '#'* ) _he_entry_context=1 ;;
    esac
    while :; do
        case $_he_candidate in
            '# '*) _he_candidate=${_he_candidate#??}; break ;;
            '#'* ) _he_candidate=${_he_candidate#?} ;;
            *) break ;;
        esac
    done
    _he_candidate=$(ltrim "$_he_candidate")
    case $_he_candidate in
        '**Fill'*|'**Add'*|'**Override'*) return 1 ;;
        '**'*' — '*) [ "$_he_entry_context" -eq 1 ] && return 0 ;;
    esac
    return 1
}

# Which kind of entry does this line open, if any? Sets ENTRY_KIND to
# "override", "other" (a Fill or an Add) or "" (not an entry line at all).
# The caller passes the already-ltrimmed line; a "- " or "* " list bullet is
# stripped, because section 0's entries are written both ways.
entry_kind() { # already-ltrimmed line
    ENTRY_KIND=''
    _ek_s=$1
    case $_ek_s in
        '- '*|'* '*) _ek_s=$(ltrim "${_ek_s#??}") ;;
    esac
    case $_ek_s in
        '**Override'*)      ENTRY_KIND=override ;;
        '**Fill'*|'**Add'*) ENTRY_KIND=other ;;
    esac
}

# An Override that never quoted its dead words. Reported at the Override's own
# line, because that is the line the user has to fix.
err_no_dead_words() { # path lineno
    parse_err "$1" "$2" \
       "an **Override** entry with no complete verifier before the next entry, the next heading, or the end of the file — it must carry $ANCHOR_MARKER, $DIGEST_MARKER, and a valid $MARKER line"
}

# Read one local file and check every **Dead words:** line in it.
check_file() {
    _cf_path=$1
    _cf_lineno=0
    _cf_override_line=0
    clear_verifier
    FENCE_CHAR=''
    FENCE_LEN=0
    FENCE_LINE=0

    # An existing file the shell cannot open would otherwise make the redirect
    # below fail while the summary still said "ok" — a check that silently
    # checked nothing. Never a pass.
    if [ ! -r "$_cf_path" ]; then
        parse_err "$_cf_path" 0 "cannot read this file — the check cannot pass on a file it could not open"
        return
    fi

    # A shell variable cannot carry NUL. Compare the original byte stream to a
    # NUL-free stream before line parsing; an unavailable scan is unsafe too.
    if ! LC_ALL=C tr -d '\000' < "$_cf_path" | cmp -s "$_cf_path" -; then
        parse_err "$_cf_path" 0 "contains a NUL byte, or its binary-safety scan failed — a local layer must be text"
        return
    fi

    while IFS= read -r _cf_line || [ -n "$_cf_line" ]; do
        _cf_lineno=$((_cf_lineno + 1))
        case $_cf_line in
            *"$UTF8_BOM"*)
                parse_err "$_cf_path" "$_cf_lineno" "UTF-8 BOM is not supported — save the local file as UTF-8 without BOM"
                return ;;
        esac
        _cf_line=${_cf_line%"$CR"}
        if [ "${#_cf_line}" -gt "$MAX_LINE_BYTES" ]; then
            parse_err "$_cf_path" "$_cf_lineno" \
               "local-layer line is ${#_cf_line} bytes long; the bound is $MAX_LINE_BYTES bytes"
            continue
        fi
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
            "$ANCHOR_MARKER"*)
               if [ "$_cf_override_line" -eq 0 ] || [ -n "$PENDING_ANCHOR_PATH" ]; then
                   parse_err "$_cf_path" "$_cf_lineno" "$ANCHOR_MARKER is valid only once inside the Override it verifies"
                   continue
               fi
               _cf_anchor=${_cf_trimmed#"$ANCHOR_MARKER"}
               case $_cf_anchor in
                   ' '*|"$TAB"*) _cf_anchor=$(ltrim "$_cf_anchor") ;;
                   *) parse_err "$_cf_path" "$_cf_lineno" "$ANCHOR_MARKER must continue with an anchored Markdown heading"; continue ;;
               esac
               parse_anchor "$_cf_anchor" "$_cf_path" "$_cf_lineno" || :
               continue
               ;;
            "$DIGEST_MARKER"*)
               if [ "$_cf_override_line" -eq 0 ] || [ -z "$PENDING_ANCHOR_PATH" ] || [ -n "$PENDING_DIGEST" ]; then
                   parse_err "$_cf_path" "$_cf_lineno" "$DIGEST_MARKER is valid once after a valid $ANCHOR_MARKER inside the Override it verifies"
                   continue
               fi
               _cf_digest=${_cf_trimmed#"$DIGEST_MARKER"}
               case $_cf_digest in
                   ' '*|"$TAB"*) _cf_digest=$(ltrim "$_cf_digest") ;;
                   *) parse_err "$_cf_path" "$_cf_lineno" "$DIGEST_MARKER must continue with a sha256 code span"; continue ;;
               esac
               parse_digest "$_cf_digest" "$_cf_path" "$_cf_lineno" || :
               continue
               ;;
            "$MARKER"*) ;;
            *) # Not a Dead-words line. A bare marker anywhere else is an error,
               # never a silently skipped entry; inside a code span it is prose.
               # The marker IS on this line, misplaced, so it neither satisfies
               # an Override above nor opens a new one — the error is enough.
               if has_bare_marker "$_cf_line"; then
                   parse_err "$_cf_path" "$_cf_lineno" \
                      "the $MARKER marker is not at the start of the line — an entry here would be skipped. Give the entry a line of its own, or, if this is prose about the marker, put it inside a code span"
                   _cf_override_line=0
                   continue
               fi
               # A heading, or the next entry, ends whatever entry came before:
               # a Dead-words line further down would belong to neither.
               case $_cf_trimmed in
                   '#'*) ENTRY_KIND=heading ;;
                   *)    entry_kind "$_cf_trimmed" ;;
               esac
               if { [ -z "$ENTRY_KIND" ] || [ "$ENTRY_KIND" = heading ]; } && has_unrecognized_entry_marker "$_cf_line"; then
                   parse_err "$_cf_path" "$_cf_lineno" \
                      "looks like a Fill, Add, or Override but is not in the canonical entry shape (optional - or * bullet, then **Override**, **Fill**, or **Add**) — refusing a silently ignored entry"
                   _cf_override_line=0
                   continue
               fi
               if [ -n "$ENTRY_KIND" ]; then
                   if [ "$_cf_override_line" -ne 0 ]; then
                       err_no_dead_words "$_cf_path" "$_cf_override_line"
                       _cf_override_line=0
                       clear_verifier
                   fi
                   if [ "$ENTRY_KIND" = override ]; then
                       _cf_override_line=$_cf_lineno
                       clear_verifier
                   fi
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

        if [ "$_cf_override_line" -ne 0 ]; then
            if [ -z "$PENDING_ANCHOR_PATH" ] || [ -z "$PENDING_DIGEST" ]; then
                parse_err "$_cf_path" "$_cf_override_line" \
                    "this Override's $MARKER line has no complete verifier: add $ANCHOR_MARKER and $DIGEST_MARKER before it"
            else
                ACTIVE_ANCHOR_NAME=$PENDING_ANCHOR_NAME
                ACTIVE_ANCHOR_PATH=$PENDING_ANCHOR_PATH
                check_section_digest "$_cf_path" "$_cf_override_line" || :
                check_items "$_cf_rest" "$_cf_path" "$_cf_lineno"
            fi
            _cf_override_line=0
            clear_verifier
        else
            check_items "$_cf_rest" "$_cf_path" "$_cf_lineno"
        fi
    done < "$_cf_path"

    # The redirect above can still fail on a file that passed [ -r ] a moment
    # ago, or on something that is readable but yields nothing — a directory, a
    # device. A file with bytes in it that produced no lines was not read.
    if [ "$_cf_lineno" -eq 0 ] && [ -s "$_cf_path" ]; then
        parse_err "$_cf_path" 0 \
           "this file has contents but not one line could be read from it — the check cannot pass on a file it could not read"
    fi

    if [ -n "$FENCE_CHAR" ]; then
        parse_err "$_cf_path" "$FENCE_LINE" \
           "fenced code block opened here is never closed — every line after it was ignored"
    fi

    # An Override still waiting for its words at the end of the file.
    if [ "$_cf_override_line" -ne 0 ]; then
        err_no_dead_words "$_cf_path" "$_cf_override_line"
        clear_verifier
    fi
}

# ---------------------------------------------------------------- arguments

if [ "$#" -eq 1 ]; then
    case ${1:-} in
        -h|--help) usage; exit 0 ;;
    esac
fi

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

# A directory that cannot be searched answers "no such file" to every question
# asked of its contents. Reporting that as "nothing is customized" would turn a
# permission problem into a clean bill of health.
if [ ! -x "$local_dir" ]; then
    err "$PROG: cannot search $local_dir — a local file inside it could not be seen, so this is not a pass"
fi

# Claude loads Markdown recursively. Only the two named local files and files
# present in the staged managed tree are accounted for by this check/update.
# A symlink anywhere else may hide a subtree from find, so refuse it too.
# -exec passes each pathname as an argument, including spaces and newlines;
# parsing a line-oriented find listing here would fail open on unusual names.
unexpected_tree_entries=$(
    find "$local_dir" -mindepth 1 \( -name '*.[mM][dD]' -o -type l \) \
        -exec sh -c '
            staged=$1; installed=$2; shift 2
            for path do
                relative=${path#"$installed"/}
                case $relative in LOCAL.md|LOCAL_dev.md) continue ;; esac
                if [ -L "$path" ] || [ ! -f "$path" ] ||
                   [ ! -f "$staged/$relative" ] || [ -L "$staged/$relative" ]; then
                    printf "unexpected active Markdown or symlink: %s\n" "$path"
                fi
            done
        ' sh "$rules_dir" "$local_dir" {} + 2>&1
)
tree_scan_status=$?
if [ "$tree_scan_status" -ne 0 ]; then
    err "$PROG: cannot enumerate the recursively loaded rules tree: $unexpected_tree_entries"
elif [ -n "$unexpected_tree_entries" ]; then
    err "$PROG: refusing unaccounted content in the recursively loaded rules tree: $unexpected_tree_entries"
fi

present=''
for name in $LOCAL_FILES; do
    path=$local_dir/$name
    # -e is false for a dangling symlink, so -L is asked as well: something is
    # there under that name either way, and the harness would try to load it.
    if [ -e "$path" ] || [ -L "$path" ]; then
        if [ ! -f "$path" ]; then
            err "$path: error: exists but is not a regular file (a directory, a dangling symlink, or a special file) — never read as 'nothing is customized'"
            continue
        fi
        if [ ! -r "$path" ]; then
            err "$path: error: exists and cannot be read — an unreadable local file is not an absent one"
            continue
        fi
        present="$present $name"
    fi
done

if [ -z "$present" ] && [ "$errors" -eq 0 ]; then
    printf '%s: no local layer in %s — nothing is customized.\n' "$PROG" "$local_dir"
    counts
    exit 0
fi

SCRATCH_DIR=$(mktemp -d "${TMPDIR:-/tmp}/claude-code-playbook-check-local.XXXXXX") || {
    err "$PROG: cannot create private scratch space for local-layer verification"
    counts
    exit 2
}
SECTION_FILE=$SCRATCH_DIR/section
WORDS_FILE=$SCRATCH_DIR/words
trap cleanup_scratch EXIT HUP INT TERM

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
