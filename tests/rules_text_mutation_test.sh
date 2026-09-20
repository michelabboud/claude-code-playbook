#!/bin/sh
#
# tests/rules_text_mutation_test.sh — does the wording suite catch a broken
# rulebook?
#
#   sh tests/rules_text_mutation_test.sh
#
# A wording test is the easiest kind to write so that it can never fail: pin a
# string that is already everywhere, or look in a file that cannot not contain
# it. So for every property tests/rules_text_test.sh claims to check, this
# copies the repository into a temporary directory, breaks that one property,
# and runs the suite against the copy. The suite MUST fail.
#
# The real repository is only ever read. Everything written lives in a
# temporary directory this run creates and removes.

set -u

HERE=$(dirname -- "$0")
. "$HERE/lib.sh"

SRC=$HERE/..
SUITE=$HERE/rules_text_test.sh

TMPROOT=$(make_tmpdir) || { printf 'cannot make a temp dir\n' >&2; exit 2; }
trap 'cleanup_tmpdir "$TMPROOT"' EXIT INT TERM HUP

seq_n=0

# A fresh copy of everything the wording suite reads.
fresh_copy() { # dest
    mkdir -p -- "$1"
    cp -R -- "$SRC/rules" "$1/rules"
    cp -R -- "$SRC/templates" "$1/templates"
    cp -R -- "$SRC/scripts" "$1/scripts"
    mkdir -p -- "$1/docs"
    cp -- "$SRC/docs/index.html" "$1/docs/index.html"
    cp -- "$SRC/CLAUDE.md" "$1/CLAUDE.md"
    cp -- "$SRC/INSTALL.md" "$1/INSTALL.md"
}

# Delete every line containing a fixed string. Fails if there was none.
drop_line() { # path fixed-string
    _n=0
    : >"$1.new"
    while IFS= read -r _l || [ -n "$_l" ]; do
        case $_l in
            *"$2"*) _n=$((_n + 1)) ;;
            *) printf '%s\n' "$_l" >>"$1.new" ;;
        esac
    done <"$1"
    mv -- "$1.new" "$1"
    [ "$_n" -gt 0 ]
}

# Break one property; the suite must notice.
check_mutation() { # name shell-command-operating-on $M
    seq_n=$((seq_n + 1))
    M=$TMPROOT/repo-$seq_n
    fresh_copy "$M"

    if ! ( eval "$2" ); then
        _fail "$1" "the mutation itself failed to apply"
        return
    fi

    _out=$(sh "$SUITE" "$M" 2>&1)
    _st=$?
    if [ "$_st" -eq 0 ]; then
        _fail "$1" "SURVIVED — the suite passed against a broken rulebook"
    else
        _pass "$1 (suite failed: $(printf '%s\n' "$_out" | grep -c '^not ok') assertion(s))"
    fi
}

HOOK2='*Local layer: if `~/.claude/rules/LOCAL_dev.md` exists'

# --- hook 2: present in the six, absent everywhere else --------------------

check_mutation "a scoped file missing the pointer line is caught" \
    'drop_line "$M/rules/REVIEWS.md" "$HOOK2"'

check_mutation "the pointer line leaking into an unscoped file is caught" \
    'grep -F -e "$HOOK2" -- "$M/rules/CODE.md" >> "$M/rules/WRITING.md"'

check_mutation "a pointer line buried in the body instead of the header is caught" \
    'l=$(grep -F -e "$HOOK2" -- "$M/rules/CODE.md") && drop_line "$M/rules/CODE.md" "$HOOK2" && printf "%s\n" "$l" >> "$M/rules/CODE.md"'

# --- hook 1: the section-0 paragraph ---------------------------------------

check_mutation "section 0 losing the local-layer paragraph is caught" \
    'drop_line "$M/rules/AUTHORITY.md" "**The local layer:**"'

check_mutation "section 0 losing the reserved L numbers is caught" \
    'drop_line "$M/rules/AUTHORITY.md" "numbers the playbook never uses"'

check_mutation "the local-layer paragraph moved away from Precedence is caught" \
    'l=$(grep -F -e "**The local layer:**" -- "$M/rules/AUTHORITY.md") && drop_line "$M/rules/AUTHORITY.md" "**The local layer:**" && printf "%s\n" "$l" >> "$M/rules/AUTHORITY.md"'

# --- hook 3 and the self-update paragraph ----------------------------------

check_mutation "CLAUDE.md losing the local-layer line is caught" \
    'drop_line "$M/CLAUDE.md" "My own customizations live in"'

check_mutation "the old overwrites-your-tailoring sentence coming back is caught" \
    'printf "%s\n" "Updating overwrites files I may have tailored — four places are explicitly meant to be tailored." >> "$M/CLAUDE.md"'

check_mutation "CLAUDE.md dropping the staged check is caught" \
    'drop_line "$M/CLAUDE.md" "scripts/check-local.sh"'

# --- what the bundle ships -------------------------------------------------

check_mutation "a local file shipped under rules/ is caught" \
    'cp -- "$M/templates/LOCAL.md" "$M/rules/LOCAL.md"'

check_mutation "a non-rule file under rules/ is caught" \
    'printf "notes\n" > "$M/rules/scratch.txt"'

check_mutation "a stray rule file under rules/ is caught" \
    'printf "# extra\n" > "$M/rules/EXTRA.md"'

check_mutation "templates moved under rules/ is caught" \
    'mkdir -p -- "$M/rules/templates" && cp -- "$M/templates/LOCAL.md" "$M/rules/templates/LOCAL.md"'

# --- the shared frontmatter ------------------------------------------------

check_mutation "the template's paths: block drifting from the scoped files is caught" \
    'drop_line "$M/templates/LOCAL_dev.md" "**/go.mod"'

check_mutation "the always-loaded template gaining a paths: scope is caught" \
    'printf -- "---\npaths:\n  - \"**/*.rs\"\n---\n" > "$M/templates/LOCAL.md.new" && cat "$M/templates/LOCAL.md" >> "$M/templates/LOCAL.md.new" && mv -- "$M/templates/LOCAL.md.new" "$M/templates/LOCAL.md"'

# --- INSTALL.md and the visual map -----------------------------------------

check_mutation "INSTALL.md stating the wrong file count is caught" \
    'drop_line "$M/INSTALL.md" "contains **14**" && printf "%s\n" "- \`~/.claude/rules/\` contains **13** \`.md\` files from this repository:" >> "$M/INSTALL.md"'

check_mutation "the visual map losing the local layer is caught" \
    'drop_line "$M/docs/index.html" "The local layer — customizations the playbook never touches"'

finish
