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

# --- the context budget (ADR 0011) -----------------------------------------

check_mutation "the quarantine procedure losing its paths: scope is caught" \
    'drop_line "$M/rules/QUARANTINE.md" "**/.quarantine/**" && drop_line "$M/rules/QUARANTINE.md" "paths:"'

check_mutation "the quarantine scope pointing somewhere else is caught" \
    'replace_in_file "$M/rules/QUARANTINE.md" "**/.quarantine/**" "**/quarantine/**"'

check_mutation "an always-loaded file gaining a paths: scope is caught" \
    'printf -- "---\npaths:\n  - \"**/*.rs\"\n---\n" > "$M/rules/WRITING.md.new" && cat "$M/rules/WRITING.md" >> "$M/rules/WRITING.md.new" && mv -- "$M/rules/WRITING.md.new" "$M/rules/WRITING.md"'

check_mutation "a platform file gaining a paths: scope is caught" \
    'printf -- "---\npaths:\n  - \"**/*.sh\"\n---\n" > "$M/rules/platform/LINUX.md.new" && cat "$M/rules/platform/LINUX.md" >> "$M/rules/platform/LINUX.md.new" && mv -- "$M/rules/platform/LINUX.md.new" "$M/rules/platform/LINUX.md"'

check_mutation "DESTRUCTIVE.md no longer sending the agent to the procedure is caught" \
    'replace_in_file "$M/rules/DESTRUCTIVE.md" "so read it by path before your first quarantine of a session" "so see it when needed"'

check_mutation "section 0 summarising an always-loaded section again is caught" \
    'printf "%s\n" "### 9 · Environment & operations — \`rules/ENVIRONMENT.md\`" >> "$M/rules/AUTHORITY.md"'

check_mutation "section 0 summarising rule 10.1 again is caught" \
    'printf "%s\n" "| 10.1 | **Destructive actions need my OK.** |" >> "$M/rules/AUTHORITY.md"'

check_mutation "section 0 dropping a source-scoped summary is caught" \
    'replace_in_file "$M/rules/AUTHORITY.md" "### 6 · Task & phase workflow" "### Task & phase workflow"'

check_mutation "section 0 dropping the quarantine summary is caught" \
    'replace_in_file "$M/rules/AUTHORITY.md" "### 10.3 · Quarantine" "### Quarantine"'

check_mutation "section 0 no longer naming what it leaves out is caught" \
    'drop_line "$M/rules/AUTHORITY.md" "**Always in context, never summarised:**"'

check_mutation "the moved-past rule leaving COLLABORATION.md is caught" \
    'replace_in_file "$M/rules/COLLABORATION.md" "; a question I saw once and moved past is answered" ""'

check_mutation "the never-fix-during-review rule leaving COLLABORATION.md is caught" \
    'replace_in_file "$M/rules/COLLABORATION.md" "A defect found during a review is reported, never fixed there" "A defect found during a review is noted"'

check_mutation "a platform file losing the never-carry-across rule is caught" \
    'drop_line "$M/rules/platform/MACOS.md" "Never carry a command across from another platform file"'

check_mutation "section 0 losing the project boundary of path scopes is caught" \
    'replace_in_file "$M/rules/AUTHORITY.md" "only matches files inside the session'"'"'s project**" "matches files**"'

check_mutation "section 0 losing the read-by-path duty for outside code is caught" \
    'replace_in_file "$M/rules/AUTHORITY.md" "read \`CODE.md\` and \`TESTING.md\` by path" "consider \`CODE.md\` and \`TESTING.md\`"'

check_mutation "the boundary moving out of section 0's header is caught" \
    'l=$(grep -F -e "This file plus the Mantra" -- "$M/rules/AUTHORITY.md") && drop_line "$M/rules/AUTHORITY.md" "This file plus the Mantra" && printf "%s\n" "$l" | sed "s/This file plus the Mantra/The Mantra and this file/" >> "$M/rules/AUTHORITY.md" && printf "%s\n" "***This file plus the Mantra is the whole of what you must know before acting.***" > "$M/x" && cat "$M/x" "$M/rules/AUTHORITY.md" > "$M/y" && mv -- "$M/y" "$M/rules/AUTHORITY.md"'

check_mutation "CLAUDE.md losing the project boundary is caught" \
    'drop_line "$M/CLAUDE.md" "A \`paths:\` scope only matches files inside the session'"'"'s project, so for code outside it"'

check_mutation "economy mode losing the owner-only switch is caught" \
    'replace_in_file "$M/rules/REVIEWS.md" "you never switch it on yourself to save cost" "switch it on when cost matters"'

check_mutation "economy mode spreading to planning is caught" \
    'replace_in_file "$M/rules/REVIEWS.md" "planning and design stay on the Top tier" "planning and design follow it"'

check_mutation "economy mode losing its record is caught" \
    'replace_in_file "$M/rules/REVIEWS.md" "every review it runs says *economy mode* in its header" "reviews run normally"'

check_mutation "economy mode dropping dual-blind is caught" \
    'replace_in_file "$M/rules/REVIEWS.md" "the pair stays dual-blind and cross-family" "one reviewer is enough"'

check_mutation "the release gate hiding economy mode is caught" \
    'replace_in_file "$M/rules/REVIEWS.md" ", and its record says so." "."'

check_mutation "the roster's economy seat changing model is caught" \
    'replace_in_file "$M/rules/ROSTER.md" "**Claude Opus 5.5 at \`xhigh\` effort**" "**Claude Sonnet at \`high\` effort**"'

check_mutation "a model named in REVIEWS.md is caught" \
    'replace_in_file "$M/rules/REVIEWS.md" "the roster'"'"'s economy configuration instead" "Opus 5.5 instead"'

check_mutation "rule 10.1 losing stop-means-stop is caught" \
    'replace_in_file "$M/rules/DESTRUCTIVE.md" "**A blocked command is a stop, not a spelling problem.**" "**Blocked commands can be retried.**"'

check_mutation "rule 10.1 allowing a re-spelled effect is caught" \
    'replace_in_file "$M/rules/DESTRUCTIVE.md" "never re-issue the same effect in another form" "try a gentler form"'

check_mutation "worktree removal allowing --force is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "Then run \`git worktree remove <path>\`, without \`--force\`, alone" "Then run \`git worktree remove --force <path>\`"'

check_mutation "worktree folder deletion stops being destructive is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "skips git'"'"'s checks and is a destructive act under rule 10.1" "is also fine"'

check_mutation "the worktree lock duty dropping is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "it locks it with \`git worktree lock\` while it is in use" "it may lock it"'

check_mutation "branch -D becoming allowed is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "Never use \`git branch -D\` on a branch with unique work" "Use \`git branch -D\` when convenient"'

check_mutation "the workflow checkpoint no longer running section 13 is caught" \
    'replace_in_file "$M/rules/WORKFLOW.md" "run the hygiene procedure (\`HYGIENE.md\`, section 13)" "tidy up"'

check_mutation "the ignored-files check dropping is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "\`git worktree remove\` deletes ignored files silently, so preserve or quarantine them first" "ignored files are disposable"'

check_mutation "the reachability check dropping is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "\`git -C <worktree> for-each-ref --contains HEAD refs/heads refs/tags\` must print a ref" "\`git -C <worktree> for-each-ref --contains HEAD\` must print a ref"'

check_mutation "the in-use check gaining an exception is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "no running process works in it, and no other lane has it locked" "no other lane has it locked"'

check_mutation "forcing past a git refusal is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "If git refuses, fix the cause it names instead of forcing" "If git refuses, add --force"'

check_mutation "branch -d being described as merged-into-main is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" ", which is not the same as merged into \`main\`" ""'

check_mutation "the owner declining no longer counting as a refusal is caught" \
    'replace_in_file "$M/rules/DESTRUCTIVE.md" "or I decline it, never re-issue" "never re-issue"'

check_mutation "rule 10.1 losing its cargo clean example is caught" \
    'replace_in_file "$M/rules/DESTRUCTIVE.md" "\`rm -r\` or \`cargo clean\` for" "\`rm -r\` for"'

check_mutation "rule 10.1 losing quarantine as the sanctioned move is caught" \
    'replace_in_file "$M/rules/DESTRUCTIVE.md" "rule 10.3 — the one sanctioned move" "rule 10.3"'

check_mutation "the hygiene section losing its paths: scope is caught" \
    'drop_line "$M/rules/HYGIENE.md" "**/.worktrees/**" && drop_line "$M/rules/HYGIENE.md" "paths:"'

check_mutation "a stash counting as reachable again is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "A stash or a remote-tracking ref alone is not enough" "Any ref is enough"'

check_mutation "the restore step for quarantined tracked files dropping is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "restore its committed version (\`git -C <worktree> restore <file>\`)" "leave it"'

check_mutation "reviewer worktrees losing their owner is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" " — including a detached one made for a reviewer" ""'

check_mutation "a name deciding the class is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "or a \`.gitignore\` entry never decides it" "or a \`.gitignore\` entry decides it"'

check_mutation "protected items losing the owner-only rule is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "anything I created | only on my word (rule 10.2) |" "anything I created | remove when stale |"'

check_mutation "unknown items no longer quarantined is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "| quarantine it (rule 10.3) |" "| remove it |"'

check_mutation "13.2 touching other lanes' items is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "and is not touched" "and may be removed"'

check_mutation "a foreign marker becoming permission is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "A marker you did not write is evidence, not permission" "Any marker is permission"'

check_mutation "the disk-floor default dropping is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" ", or 10 % free when it sets none" ""'

check_mutation "low space widening deletion is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "Low space calls for this procedure, never for broader deletion" "Low space justifies broader deletion"'

check_mutation "the report losing its candidate costs is caught" \
    'replace_in_file "$M/rules/HYGIENE.md" "each with what would be lost and whether it can be regenerated" "each listed"'

check_mutation "DESTRUCTIVE.md no longer sending cleanup to section 13 is caught" \
    'replace_in_file "$M/rules/DESTRUCTIVE.md" "read \`~/.claude/rules/HYGIENE.md\` by path before any cleanup" "tidy up as needed"'

check_mutation "a platform file losing its free-disk command is caught" \
    'drop_line "$M/rules/platform/WINDOWS.md" "| Free disk |"'

# --- INSTALL.md and the visual map -----------------------------------------

check_mutation "INSTALL.md stating the wrong file count is caught" \
    'drop_line "$M/INSTALL.md" "contains **15**" && printf "%s\n" "- \`~/.claude/rules/\` contains **14** \`.md\` files from this repository:" >> "$M/INSTALL.md"'

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

check_mutation "Windows target-directory example missing is caught" \
    'drop_line "$M/INSTALL.md" "windows_config="'

check_mutation "quiescence moved out of shared preflight is caught" \
    'move_to_end "$M/INSTALL.md" "Every procedure requires a quiescent source checkout and target configuration."'

check_mutation "a guide example missing its verifier is caught" \
    'drop_line "$M/docs/guides/local-layer.md" "  **Rule digest:**"'

finish
