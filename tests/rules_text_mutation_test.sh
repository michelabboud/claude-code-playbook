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
    mkdir -p -- "$1/docs/guides"
    cp -- "$SRC/docs/guides/local-layer.md" "$1/docs/guides/local-layer.md"
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

# Replace a fixed string wherever it occurs, once per line. Fails if there was
# none, so a mutation cannot silently no-op when the text is rewritten.
replace_in_file() { # path fixed-old fixed-new
    _n=0
    : >"$1.new"
    while IFS= read -r _l || [ -n "$_l" ]; do
        case $_l in
            *"$2"*) printf '%s%s%s\n' "${_l%%"$2"*}" "$3" "${_l#*"$2"}"
                    _n=$((_n + 1)) ;;
            *)      printf '%s\n' "$_l" ;;
        esac >>"$1.new"
    done <"$1"
    mv -- "$1.new" "$1"
    [ "$_n" -gt 0 ]
}

# Move a sentence out of its paragraph and state it at the end of the file
# instead. Every wording assertion that counts per FILE survives this; the ones
# that count inside the paragraph do not. It is the commonest way a wording test
# turns into decoration.
move_to_end() { # path fixed-sentence
    replace_in_file "$1" "$2" '' && printf '\n%s\n' "$2" >>"$1"
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
        # Name the first failing assertion, not just the count: the evidence
        # that something specific caught it, rather than a suite that went red.
        _pass "$1 — caught by $(printf '%s\n' "$_out" | grep '^not ok' | head -n 1) (of $(printf '%s\n' "$_out" | grep -c '^not ok'))"
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

# --- a sentence that leaves its paragraph -----------------------------------
#
# Five mutants that survived the whole suite once, because every wording
# assertion counted per file. A rule read out of its paragraph is a different
# rule: the sentence is still in the file and nobody reading the local layer's
# rule will ever meet it.

check_mutation "the absent-local-file sentence moved out of the paragraph is caught" \
    'move_to_end "$M/rules/AUTHORITY.md" "A local file that is absent means nothing is customized."'

check_mutation "the never-adds-authority sentence moved out of the paragraph is caught" \
    'move_to_end "$M/rules/AUTHORITY.md" "A local entry may never expand authority, remove an approval, relax a safety, destructive, security, or secret-handling constraint, change precedence, or override this paragraph."'

check_mutation "hook 3 moved to the end of CLAUDE.md is caught" \
    'l=$(grep -F -e "My own customizations live in" -- "$M/CLAUDE.md") && drop_line "$M/CLAUDE.md" "My own customizations live in" && printf "\n%s\n" "$l" >> "$M/CLAUDE.md"'

check_mutation "the Fill definition restated only at the end of the file is caught" \
    'move_to_end "$M/rules/AUTHORITY.md" "A **Fill** supplies only a value a rule leaves open"'

check_mutation "the map's entry renamed with its title left in a comment is caught" \
    'replace_in_file "$M/docs/index.html" "{t:\"The local layer — customizations the playbook never touches\",c:\"" "{t:\"Local customizations\",c:\"" && printf "%s\n" "<!-- The local layer — customizations the playbook never touches -->" >> "$M/docs/index.html"'

# --- the wording the mechanical review corrected -----------------------------

check_mutation "section 0 going back to 'without opening these two' is caught" \
    'replace_in_file "$M/rules/AUTHORITY.md" "an update replaces the playbook'"'"'s files and never writes to, copies over or replaces these two" "an update replaces the playbook'"'"'s files without opening these two"'

check_mutation "CLAUDE.md going back to 'never ships or touches' is caught" \
    'replace_in_file "$M/CLAUDE.md" "The playbook never ships them, and an update never writes to, copies over or replaces them" "The playbook never ships or touches those two files"'

# --- a template shipping a live entry ----------------------------------------

check_mutation "an unfenced Override in a template is caught" \
    'printf -- "\n- **Override — rule 3.2, risk classes.** Mine are different.\n" >> "$M/templates/LOCAL_dev.md"'

check_mutation "the git-identity Fill shipped live again is caught" \
    'printf -- "\n- **Fill — git identity (section 6).** Commits use \`\`.\n" >> "$M/templates/LOCAL.md"'

# --- INSTALL.md as a procedure ----------------------------------------------
#
# Each of these was a mutant that survived: the guide said the opposite of what
# the design requires, and nothing noticed.

check_mutation "the update checking installed rules against installed rules is caught" \
    'replace_in_file "$M/INSTALL.md" "sh \"\$trust_root/scripts/check-local.sh\" ~/.claude/rules \"\$trust_root/rules\"" "sh \"\$trust_root/scripts/check-local.sh\" ~/.claude/rules ~/.claude/rules"'

check_mutation "the update dropping its ask-before-copy is caught" \
    'drop_line "$M/INSTALL.md" "ask whether to proceed, and stop until they answer."'

check_mutation "the update dropping its backup is caught" \
    'drop_line "$M/INSTALL.md" "Back up, then copy.** Only after the user has said yes."'

check_mutation "step 2 replacing the whole rules directory is caught" \
    'replace_in_file "$M/INSTALL.md" "**Copy file by file. Never replace the whole directory**" "**Copy the whole directory over**"'

check_mutation "step 4 copying a template over an existing local file is caught" \
    'replace_in_file "$M/INSTALL.md" "not copy the template over it and do not merge into it" "copy both templates into place"'

check_mutation "U2's exit-1 row saying Continue instead of Stop is caught" \
    'replace_in_file "$M/INSTALL.md" "| **Stop.** Show the user each reported line" "| **Continue.** Show the user each reported line"'

check_mutation "migration copying over an existing local file is caught" \
    'drop_line "$M/INSTALL.md" "**Stop this migration and do not copy.**"'

check_mutation "migration not staging the new version is caught" \
    'drop_line "$M/INSTALL.md" "**Step M1b — Stage the new version too.**"'

check_mutation "migration checking against the old checkout is caught" \
    'replace_in_file "$M/INSTALL.md" "sh \"\$trust_root/scripts/check-local.sh\" <scratch>/local \"\$trust_root/rules\"" "sh \"\$trust_root/scripts/check-local.sh\" <scratch>/local <scratch>/published/rules"'

check_mutation "uninstall restoring over the local files is caught" \
    'replace_in_file "$M/INSTALL.md" "and never \`LOCAL.md\` or" "including"'

check_mutation "INSTALL.md not saying it needs sh is caught" \
    'drop_line "$M/INSTALL.md" "update, migration, restore, and uninstall needs \`sh\` and Git"'

check_mutation "a guide example missing its verifier is caught" \
    'drop_line "$M/docs/guides/local-layer.md" "  **Rule digest:**"'

finish
