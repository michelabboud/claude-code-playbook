#!/bin/sh
# Execute INSTALL.md's read-only guards in disposable installations. In
# particular LOCAL_dev.md alone must stop migration before LOCAL.md is copied.
set -u
HERE=$(dirname -- "$0")
# shellcheck source=tests/lib.sh
. "$HERE/lib.sh"
ROOT=${1:-$HERE/..}
TMPROOT=$(make_tmpdir) || exit 2
trap 'cleanup_tmpdir "$TMPROOT"' EXIT INT TERM HUP

# All guards share a real, locally published source fixture. Only the
# canonical endpoint literal is replaced in the extracted source guard.
trust_fixture=$TMPROOT/source-trust
mkdir -p "$trust_fixture/published" || exit 2
cp "$ROOT/CLAUDE.md" "$ROOT/VERSION" "$ROOT/INSTALL.md" "$ROOT/CHANGELOG.md" \
    "$trust_fixture/published/" || exit 2
cp -R "$ROOT/rules" "$ROOT/scripts" "$ROOT/templates" "$trust_fixture/published/" || exit 2
release_version=$(sed -n '1p' "$trust_fixture/published/VERSION")
git -C "$trust_fixture/published" init -q || exit 2
git -C "$trust_fixture/published" config user.name Fixture || exit 2
git -C "$trust_fixture/published" config user.email fixture@example.invalid || exit 2
git -C "$trust_fixture/published" add -- . || exit 2
git -C "$trust_fixture/published" -c commit.gpgsign=false commit -qm 'published source' || exit 2
git -C "$trust_fixture/published" -c tag.gpgsign=false tag -a "checkpoint/$release_version" -m 'published release' || exit 2
git init --bare -q "$trust_fixture/remote.git" || exit 2
git -C "$trust_fixture/published" push -q "$trust_fixture/remote.git" HEAD:refs/heads/main "refs/tags/checkpoint/$release_version" || exit 2
fixture_pin=$(git -C "$trust_fixture/published" rev-parse HEAD) || exit 2
for helper in source_trust_preflight destination_root_preflight; do
    awk -v name="$helper" '
        $0 == name "() {" { copying = 1 }
        copying { print }
        copying && $0 == "}" { found = 1; exit }
        END { if (!found) exit 1 }
    ' "$ROOT/INSTALL.md" >"$TMPROOT/$helper-original.sh"
    assert_status "$helper exists as an executable preflight" 0 "$?"
    sed "s|https://github.com/michelabboud/claude-code-playbook.git|$trust_fixture/remote.git|g" \
        "$TMPROOT/$helper-original.sh" >"$TMPROOT/$helper.sh"
done
sed "s|https://github.com/michelabboud/claude-code-playbook.git|$trust_fixture/unreachable.git|g" \
    "$TMPROOT/source_trust_preflight-original.sh" >"$TMPROOT/source_trust_preflight-unreachable.sh"

for guard in migration_local_preflight uninstall_local_preflight; do
    {
    sed -n p "$TMPROOT/source_trust_preflight.sh" "$TMPROOT/destination_root_preflight.sh"
    awk -v name="$guard" '
        $0 == name "() {" { copying = 1 }
        copying { print }
        copying && $0 == "}" { found = 1; exit }
        END { if (!found) exit 1 }
    ' "$ROOT/INSTALL.md"
    } >"$TMPROOT/$guard.sh"
    status=$?
    assert_status "$guard exists as an executable preflight" 0 "$status"
    [ "$status" -eq 0 ] || continue
    sh -c '. "$1"; "$2" "$3" "$4"' sh "$TMPROOT/$guard.sh" "$guard" \
        "$TMPROOT/missing-rules" "$trust_fixture/published" >"$TMPROOT/output" 2>&1
    assert_status "$guard refuses an unavailable rules directory" 2 "$?"
    for state in absent fill add empty directory dangling; do
        for local_name in LOCAL.md LOCAL_dev.md; do
            case_dir=$TMPROOT/$guard-$state-$local_name
            mkdir -p "$case_dir/rules"
            printf 'managed rules stay intact\n' >"$case_dir/rules/AUTHORITY.md"
            cp "$case_dir/rules/AUTHORITY.md" "$case_dir/original-managed"
            local_path=$case_dir/rules/$local_name
            case $state in
                absent) ;;
                fill) printf '**Fill — identity.** Use owner@example.com.\n' >"$local_path" ;;
                add) printf '**Add — review.** Require a second review.\n' >"$local_path" ;;
                empty) : >"$local_path" ;;
                directory) mkdir "$local_path" ;;
                dangling) ln -s missing-target "$local_path" ;;
            esac
            if [ -f "$local_path" ]; then cp "$local_path" "$case_dir/original-local"; fi
            # The continuation marker stands for the first mutation in the
            # procedure; refusal must make that line unreachable.
            sh -c '. "$1"; "$2" "$3" "$4" || exit 2; : >"$5"' sh \
                "$TMPROOT/$guard.sh" "$guard" "$case_dir/rules" "$trust_fixture/published" "$case_dir/continued" \
                >"$case_dir/output" 2>&1
            status=$?
            if [ "$state" = absent ]; then
                assert_status "$guard with no local files allows continuation" 0 "$status"
                if [ -f "$case_dir/continued" ]; then
                    _pass "continuation was reached"
                else
                    _fail "continuation was reached" "missing marker"
                fi
            else
                assert_status "$guard refuses $state $local_name" 2 "$status"
                if [ ! -e "$case_dir/continued" ]; then
                    _pass "refusal precedes any mutation"
                else
                    _fail "refusal precedes any mutation" "continuation reached"
                fi
                if [ -f "$local_path" ]; then
                    assert_files_identical "user local content is preserved" "$local_path" "$case_dir/original-local"
                elif [ "$state" = directory ]; then
                    if [ -d "$local_path" ]; then
                        _pass "user directory is preserved"
                    else
                        _fail "user directory is preserved" "missing"
                    fi
                else
                    assert_eq "dangling user link is preserved" missing-target "$(readlink "$local_path")"
                fi
                if [ "$local_name" = LOCAL_dev.md ]; then
                    if [ ! -e "$case_dir/rules/LOCAL.md" ]; then
                        _pass "LOCAL.md was not partially installed"
                    else
                        _fail "LOCAL.md was not partially installed" "unexpected file"
                    fi
                fi
            fi
            assert_files_identical "managed rules are preserved" "$case_dir/rules/AUTHORITY.md" "$case_dir/original-managed"
        done
    done

    case_dir=$TMPROOT/$guard-nested-markdown
    mkdir -p "$case_dir/rules/backup"
    printf 'managed rules stay intact\n' > "$case_dir/rules/AUTHORITY.md"
    printf '%s\n' '**Override — nested and unchecked.**' > "$case_dir/rules/backup/LOCAL.md"
    cp "$case_dir/rules/backup/LOCAL.md" "$case_dir/original-nested"
    sh -c '. "$1"; "$2" "$3" "$4" || exit 2; : >"$5"' sh \
        "$TMPROOT/$guard.sh" "$guard" "$case_dir/rules" "$trust_fixture/published" "$case_dir/continued" \
        >"$case_dir/output" 2>&1
    assert_status "$guard refuses nested active Markdown before mutation" 2 "$?"
    if [ ! -e "$case_dir/continued" ]; then
        _pass "$guard leaves mutation unreachable for nested Markdown"
    else
        _fail "$guard leaves mutation unreachable for nested Markdown" "continuation reached"
    fi
    assert_files_identical "$guard preserves the nested user file" \
        "$case_dir/rules/backup/LOCAL.md" "$case_dir/original-nested"

    # A changed checker must never execute, even if it would report success.
    # An external marker distinguishes early refusal from refusal after code ran.
    case_dir=$TMPROOT/$guard-malicious-checker
    mkdir -p "$case_dir/rules" || exit 2
    git clone -q "$trust_fixture/published" "$case_dir/source" || exit 2
    printf '%s\n' '#!/bin/sh' ': >"$TEST_CHECKER_MARKER"' 'exit 0' \
        >"$case_dir/source/scripts/check-local.sh"
    TEST_CHECKER_MARKER=$case_dir/checker-executed \
        sh -c '. "$1"; "$2" "$3" "$4" || exit 2; : >"$5"' sh \
        "$TMPROOT/$guard.sh" "$guard" "$case_dir/rules" "$case_dir/source" "$case_dir/continued" \
        >"$case_dir/output" 2>&1
    assert_status "$guard rejects changed staged checker" 2 "$?"
    [ ! -e "$case_dir/continued" ] && _pass "$guard changed-checker continuation unreachable" || \
        _fail "$guard changed-checker continuation unreachable" "marker exists"
    [ ! -e "$case_dir/checker-executed" ] && _pass "$guard authenticates before executing checker" || \
        _fail "$guard authenticates before executing checker" "untrusted checker ran"
done

# A linked rules root or configuration parent may point outside the intended
# deletion scope. Uninstall must refuse before even considering exact files.
linked_case=$TMPROOT/linked-uninstall
mkdir -p "$linked_case/external/rules" "$linked_case/config"
printf 'external owner content\n' >"$linked_case/external/rules/notes.txt"
ln -s "$linked_case/external/rules" "$linked_case/config/rules"
sh -c '. "$1"; uninstall_local_preflight "$2" "$3" || exit 2; : > "$4"' sh \
    "$TMPROOT/uninstall_local_preflight.sh" "$linked_case/config/rules" "$trust_fixture/published" "$linked_case/continued" \
    >"$linked_case/output" 2>&1
assert_status "uninstall refuses a linked rules root" 2 "$?"
[ ! -e "$linked_case/continued" ] && _pass "linked-root continuation unreachable" || _fail "linked-root continuation unreachable" "marker exists"
[ -f "$linked_case/external/rules/notes.txt" ] && _pass "linked-root external bytes preserved" || _fail "linked-root external bytes preserved" "missing file"

parent_case=$TMPROOT/linked-parent-uninstall
mkdir -p "$parent_case/external/rules"
printf 'external owner content\n' >"$parent_case/external/rules/notes.txt"
ln -s "$parent_case/external" "$parent_case/config"
sh -c '. "$1"; uninstall_local_preflight "$2" "$3" || exit 2; : > "$4"' sh \
    "$TMPROOT/uninstall_local_preflight.sh" "$parent_case/config/rules" "$trust_fixture/published" "$parent_case/continued" \
    >"$parent_case/output" 2>&1
assert_status "uninstall refuses a linked configuration parent" 2 "$?"
[ ! -e "$parent_case/continued" ] && _pass "linked-parent continuation unreachable" || _fail "linked-parent continuation unreachable" "marker exists"
[ -f "$parent_case/external/rules/notes.txt" ] && _pass "linked-parent external bytes preserved" || _fail "linked-parent external bytes preserved" "missing file"

# A no-backup uninstall must not delete user edits merely because a pathname
# matches the managed inventory. Extract its separate content guard verbatim.
guard=uninstall_managed_file_preflight
{
sed -n p "$TMPROOT/source_trust_preflight.sh" "$TMPROOT/destination_root_preflight.sh"
awk -v name="$guard" '
    $0 == name "() {" { copying = 1 }
    copying { print }
    copying && $0 == "}" { found = 1; exit }
    END { if (!found) exit 1 }
' "$ROOT/INSTALL.md"
} >"$TMPROOT/$guard.sh"
assert_status "no-backup content guard exists" 0 "$?"
if [ -s "$TMPROOT/$guard.sh" ]; then
    case $(uname -s) in
        Linux) platform=LINUX.md ;;
        Darwin) platform=MACOS.md ;;
        MINGW*|MSYS*|CYGWIN*) platform=WINDOWS.md ;;
        *) platform=unsupported ;;
    esac
    source_checkout=$TMPROOT/exact-release-source
    git clone -q "$trust_fixture/published" "$source_checkout" || exit 2
    installed=$TMPROOT/no-backup-install
    mkdir -p "$installed/rules/platform"
    cp "$ROOT/CLAUDE.md" "$installed/CLAUDE.md"
    for managed in AUTHORITY CODE COLLABORATION DESTRUCTIVE DOCS ENVIRONMENT QUARANTINE REPO REVIEWS ROSTER SUBAGENTS TESTING WORKFLOW WRITING; do
        cp "$ROOT/rules/$managed.md" "$installed/rules/$managed.md"
    done
    cp "$ROOT/rules/platform/$platform" "$installed/rules/platform/$platform"
    sh -c '. "$1"; uninstall_managed_file_preflight "$2" "$3" || exit 2; : > "$4"' sh \
        "$TMPROOT/$guard.sh" "$installed" "$source_checkout" "$TMPROOT/clean-continued" \
        >"$TMPROOT/content-output" 2>&1
    assert_status "unchanged managed files may continue" 0 "$?"
    [ -f "$TMPROOT/clean-continued" ] && _pass "clean continuation reached" || _fail "clean continuation reached" "missing marker"

    printf '\nowner edit\n' >>"$installed/rules/AUTHORITY.md"
    cp "$installed/rules/AUTHORITY.md" "$TMPROOT/owner-edit-original"
    sh -c '. "$1"; uninstall_managed_file_preflight "$2" "$3" "$5" || exit 2; : > "$4"' sh \
        "$TMPROOT/$guard.sh" "$installed" "$source_checkout" "$TMPROOT/edited-continued" "$fixture_pin" \
        >"$TMPROOT/content-output" 2>&1
    assert_status "edited managed filename refuses before deletion" 2 "$?"
    [ ! -e "$TMPROOT/edited-continued" ] && _pass "edited continuation unreachable" || _fail "edited continuation unreachable" "marker exists"
    assert_files_identical "edited managed bytes preserved" "$installed/rules/AUTHORITY.md" "$TMPROOT/owner-edit-original"
    cp "$ROOT/rules/AUTHORITY.md" "$installed/rules/AUTHORITY.md"

    printf '\nowner platform edit\n' >>"$installed/rules/platform/$platform"
    sh -c '. "$1"; uninstall_managed_file_preflight "$2" "$3" || exit 2; : > "$4"' sh \
        "$TMPROOT/$guard.sh" "$installed" "$source_checkout" "$TMPROOT/platform-continued" \
        >"$TMPROOT/content-output" 2>&1
    assert_status "edited platform file refuses before deletion" 2 "$?"
    [ ! -e "$TMPROOT/platform-continued" ] && _pass "platform continuation unreachable" || _fail "platform continuation unreachable" "marker exists"

    cp "$ROOT/rules/platform/$platform" "$installed/rules/platform/$platform"
    printf '9.9.9\n' >"$source_checkout/VERSION"
    sh -c '. "$1"; uninstall_managed_file_preflight "$2" "$3" || exit 2; : > "$4"' sh \
        "$TMPROOT/$guard.sh" "$installed" "$source_checkout" "$TMPROOT/wrong-version-continued" \
        >"$TMPROOT/content-output" 2>&1
    assert_status "wrong source VERSION refuses before deletion" 2 "$?"
    [ ! -e "$TMPROOT/wrong-version-continued" ] && _pass "wrong-version continuation unreachable" || _fail "wrong-version continuation unreachable" "marker exists"
    cp "$ROOT/VERSION" "$source_checkout/VERSION"

    printf '\nowner matched edit\n' >>"$source_checkout/rules/AUTHORITY.md"
    printf '\nowner matched edit\n' >>"$installed/rules/AUTHORITY.md"
    sh -c '. "$1"; uninstall_managed_file_preflight "$2" "$3" || exit 2; : > "$4"' sh \
        "$TMPROOT/$guard.sh" "$installed" "$source_checkout" "$TMPROOT/dirty-source-continued" \
        >"$TMPROOT/content-output" 2>&1
    assert_status "dirty matching source refuses before deletion" 2 "$?"
    [ ! -e "$TMPROOT/dirty-source-continued" ] && _pass "dirty-source continuation unreachable" || _fail "dirty-source continuation unreachable" "marker exists"
fi

# Source trust must come from a published commit (or an explicit full owner
# pin), never from tags or clean-status claims controlled by the checkout.
guard=source_trust_preflight
if [ -s "$TMPROOT/$guard-original.sh" ]; then
    run_source_trust() { # label expected guard checkout version [owner pin] [mode]
        trust_label=$1
        trust_expected=$2
        trust_marker=$TMPROOT/trust-$trust_label-continued
        sh -c '. "$1"; source_trust_preflight "$2" "$3" "$4" "$6" || exit 2; : >"$5"' sh \
            "$3" "$4" "$5" "${6:-}" "$trust_marker" "${7:-current}" \
            >"$TMPROOT/trust-$trust_label-output" 2>&1
        trust_status=$?
        assert_status "source trust: $trust_label" "$trust_expected" "$trust_status"
        if [ "$trust_expected" -eq 0 ]; then
            [ -f "$trust_marker" ] && _pass "$trust_label reaches continuation" || \
                _fail "$trust_label reaches continuation" "missing marker"
        else
            [ ! -e "$trust_marker" ] && _pass "$trust_label stops before continuation" || \
                _fail "$trust_label stops before continuation" "marker exists"
        fi
        if [ "$trust_status" -ne "$trust_expected" ]; then
            sed 's/^/# guard: /' "$TMPROOT/trust-$trust_label-output"
        fi
    }

    run_source_trust matching-published-annotated-tag 0 "$TMPROOT/$guard.sh" \
        "$trust_fixture/published" "$release_version"
    run_source_trust unreachable-remote 2 "$TMPROOT/$guard-unreachable.sh" \
        "$trust_fixture/published" "$release_version"
    run_source_trust wrong-expected-version 2 "$TMPROOT/$guard.sh" \
        "$trust_fixture/published" 9.9.9
    newline_checkout=$trust_fixture/line$(printf '\nx')checkout
    git clone -q "$trust_fixture/published" "$newline_checkout" || exit 2
    run_source_trust newline-checkout-path 2 "$TMPROOT/$guard.sh" \
        "$newline_checkout" "$release_version"

    # Historical releases predate the checker and local-layer templates. Use
    # a separate published tag so baseline mode still exercises provenance.
    historical_checkout=$trust_fixture/historical
    mkdir -p "$historical_checkout" || exit 2
    cp "$trust_fixture/published/CLAUDE.md" "$trust_fixture/published/VERSION" \
        "$trust_fixture/published/INSTALL.md" "$trust_fixture/published/CHANGELOG.md" \
        "$historical_checkout/" || exit 2
    cp -R "$trust_fixture/published/rules" "$historical_checkout/" || exit 2
    git -C "$historical_checkout" init -q || exit 2
    git -C "$historical_checkout" add -- . || exit 2
    git -C "$historical_checkout" -c user.name=Fixture -c user.email=fixture@example.invalid \
        -c commit.gpgsign=false commit -qm 'historical release without newer files' || exit 2
    git -C "$historical_checkout" -c user.name=Fixture -c user.email=fixture@example.invalid \
        -c tag.gpgsign=false tag -a "checkpoint/$release_version" -m 'historical release' || exit 2
    git init --bare -q "$trust_fixture/historical-remote.git" || exit 2
    git -C "$historical_checkout" push -q "$trust_fixture/historical-remote.git" \
        HEAD:refs/heads/main "refs/tags/checkpoint/$release_version" || exit 2
    sed "s|https://github.com/michelabboud/claude-code-playbook.git|$trust_fixture/historical-remote.git|g" \
        "$TMPROOT/$guard-original.sh" >"$TMPROOT/$guard-historical.sh"
    run_source_trust baseline-missing-newer-files 0 "$TMPROOT/$guard-historical.sh" \
        "$historical_checkout" "$release_version" '' baseline

    git -C "$historical_checkout" update-index --assume-unchanged -- rules/AUTHORITY.md || exit 2
    printf '\nhidden historical source edit\n' >>"$historical_checkout/rules/AUTHORITY.md"
    cp "$historical_checkout/rules/AUTHORITY.md" "$trust_fixture/historical-edited-original" || exit 2
    assert_eq "historical source edit really evades ordinary status" '' \
        "$(git -C "$historical_checkout" status --porcelain --untracked-files=all)"
    run_source_trust baseline-hidden-present-rule-edit 2 "$TMPROOT/$guard-historical.sh" \
        "$historical_checkout" "$release_version" '' baseline
    assert_files_identical "baseline refusal preserves hidden historical edit" \
        "$historical_checkout/rules/AUTHORITY.md" "$trust_fixture/historical-edited-original"

    for extra in markdown symlink; do
        checkout=$trust_fixture/extra-$extra
        git clone -q "$trust_fixture/published" "$checkout" || exit 2
        if [ "$extra" = markdown ]; then
            printf 'unpublished active rules\n' >"$checkout/rules/EVIL.md"
        else
            ln -s ../CLAUDE.md "$checkout/rules/EVIL.md" || exit 2
        fi
        run_source_trust "untracked-extra-$extra" 2 "$TMPROOT/$guard.sh" \
            "$checkout" "$release_version"
    done

    for flag in assume-unchanged skip-worktree; do
        for relative in rules/AUTHORITY.md scripts/check-local.sh; do
            case_name=$flag-$(basename "$relative")
            checkout=$trust_fixture/$case_name
            git clone -q "$trust_fixture/published" "$checkout" || exit 2
            git -C "$checkout" update-index "--$flag" -- "$relative" || exit 2
            printf '\nhidden source edit\n' >>"$checkout/$relative"
            cp "$checkout/$relative" "$trust_fixture/$case_name-original" || exit 2
            assert_eq "$case_name really evades ordinary status" '' \
                "$(git -C "$checkout" status --porcelain --untracked-files=all)"
            run_source_trust "$case_name" 2 "$TMPROOT/$guard.sh" "$checkout" "$release_version"
            assert_files_identical "$case_name preserves source bytes" \
                "$checkout/$relative" "$trust_fixture/$case_name-original"
        done
    done

    checkout=$trust_fixture/forged
    git clone -q "$trust_fixture/published" "$checkout" || exit 2
    printf '\nforged local authority\n' >>"$checkout/rules/AUTHORITY.md"
    git -C "$checkout" add -- rules/AUTHORITY.md || exit 2
    git -C "$checkout" -c user.name=Fixture -c user.email=fixture@example.invalid \
        -c commit.gpgsign=false commit -qm 'unpublished fork' || exit 2
    git -C "$checkout" -c tag.gpgsign=false tag -f "checkpoint/$release_version" >/dev/null || exit 2
    fork_pin=$(git -C "$checkout" rev-parse HEAD) || exit 2
    run_source_trust forged-local-tag 2 "$TMPROOT/$guard.sh" "$checkout" "$release_version"
    # The canonical lookup must not inherit the checkout's Git environment:
    # its local config can rewrite even a literal remote URL to a forged repo.
    false_remote=$trust_fixture/false-canonical.git
    git init --bare -q "$false_remote" || exit 2
    git -C "$checkout" push -q "$false_remote" "refs/tags/checkpoint/$release_version" || exit 2
    git -C "$checkout" config --local "url.$false_remote.insteadOf" \
        "$trust_fixture/remote.git" || exit 2
    trust_marker=$TMPROOT/trust-inherited-git-dir-continued
    GIT_DIR="$checkout/.git" GIT_WORK_TREE="$checkout" sh -c \
        '. "$1"; source_trust_preflight "$2" "$3" || exit 2; : >"$4"' sh \
        "$TMPROOT/$guard.sh" "$checkout" "$release_version" "$trust_marker" \
        >"$TMPROOT/trust-inherited-git-dir-output" 2>&1
    assert_status "source trust refuses inherited Git directory URL rewrite" 2 "$?"
    [ ! -e "$trust_marker" ] && _pass "inherited Git directory stops before continuation" || \
        _fail "inherited Git directory stops before continuation" "marker exists"
    run_source_trust owner-approved-full-fork-pin 0 "$TMPROOT/$guard-unreachable.sh" \
        "$checkout" "$release_version" "$fork_pin"
    short_pin=$(git -C "$checkout" rev-parse --short HEAD) || exit 2
    run_source_trust abbreviated-owner-pin 2 "$TMPROOT/$guard-unreachable.sh" \
        "$checkout" "$release_version" "$short_pin"

    # Keep each mismatch clean and explicitly pinned so rejection must check
    # release metadata even after commit provenance has been established.
    for mismatch in VERSION CLAUDE.md; do
        checkout=$trust_fixture/wrong-$mismatch
        git clone -q "$trust_fixture/published" "$checkout" || exit 2
        if [ "$mismatch" = VERSION ]; then
            printf '9.9.9\n' >"$checkout/VERSION"
        else
            printf '**This rulebook is version 9.9.9**\n' >"$checkout/CLAUDE.md"
        fi
        git -C "$checkout" add -- "$mismatch" || exit 2
        git -C "$checkout" -c user.name=Fixture -c user.email=fixture@example.invalid \
            -c commit.gpgsign=false commit -qm 'mismatched metadata' || exit 2
        mismatch_pin=$(git -C "$checkout" rev-parse HEAD) || exit 2
        run_source_trust "wrong-$mismatch" 2 "$TMPROOT/$guard.sh" \
            "$checkout" "$release_version" "$mismatch_pin"
    done

    # Git stores symlink targets as blobs too. A regular checkout file with
    # the same bytes must not pass as an authenticated managed regular file.
    checkout=$trust_fixture/committed-symlink
    git clone -q "$trust_fixture/published" "$checkout" || exit 2
    symlink_blob=$(printf 'target.md' | git -C "$checkout" hash-object -w --stdin) || exit 2
    git -C "$checkout" update-index --cacheinfo "120000,$symlink_blob,rules/AUTHORITY.md" || exit 2
    git -C "$checkout" -c user.name=Fixture -c user.email=fixture@example.invalid \
        -c commit.gpgsign=false commit -qm 'committed symlink mode' || exit 2
    printf 'target.md' >"$checkout/rules/AUTHORITY.md"
    symlink_pin=$(git -C "$checkout" rev-parse HEAD) || exit 2
    run_source_trust committed-symlink-disguised-as-regular 2 "$TMPROOT/$guard.sh" \
        "$checkout" "$release_version" "$symlink_pin"
fi

# Every path that receives installed files must be a real directory. A linked
# root, rules directory, or platform directory could overwrite external data.
guard=destination_root_preflight
awk -v name="$guard" '
    $0 == name "() {" { copying = 1 }
    copying { print }
    copying && $0 == "}" { found = 1; exit }
    END { if (!found) exit 1 }
' "$ROOT/INSTALL.md" >"$TMPROOT/$guard.sh"
assert_status "destination root guard exists as an executable preflight" 0 "$?"
if [ -s "$TMPROOT/$guard.sh" ]; then
    for state in absent directory ancestor-link config-link rules-link platform-link claude-link managed-link claude-hardlink managed-hardlink newline-root config-dangling rules-dangling platform-dangling claude-dangling; do
        case_dir=$TMPROOT/destination-$state
        config_dir=$case_dir/config
        mkdir -p "$case_dir/external/rules/platform" || exit 2
        printf 'external owner content\n' >"$case_dir/external/owner.txt"
        cp "$case_dir/external/owner.txt" "$case_dir/external/rules/owner.txt" || exit 2
        cp "$case_dir/external/owner.txt" "$case_dir/external/rules/platform/owner.txt" || exit 2
        cp "$case_dir/external/owner.txt" "$case_dir/original-owner" || exit 2
        case $state in
            absent) ;;
            directory) mkdir -p "$config_dir/rules/platform" ;;
            ancestor-link)
                mkdir -p "$case_dir/external/config/rules/platform"
                ln -s "$case_dir/external" "$case_dir/linked-parent"
                config_dir=$case_dir/linked-parent/config ;;
            config-link) ln -s "$case_dir/external" "$config_dir" ;;
            rules-link)
                mkdir -p "$config_dir"
                ln -s "$case_dir/external/rules" "$config_dir/rules" ;;
            platform-link)
                mkdir -p "$config_dir/rules"
                ln -s "$case_dir/external/rules/platform" "$config_dir/rules/platform" ;;
            claude-link)
                mkdir -p "$config_dir"
                ln -s "$case_dir/external/owner.txt" "$config_dir/CLAUDE.md" ;;
            managed-link)
                mkdir -p "$config_dir/rules"
                ln -s "$case_dir/external/rules/owner.txt" "$config_dir/rules/AUTHORITY.md" ;;
            claude-hardlink)
                mkdir -p "$config_dir"
                ln "$case_dir/external/owner.txt" "$config_dir/CLAUDE.md" ;;
            managed-hardlink)
                mkdir -p "$config_dir/rules"
                ln "$case_dir/external/rules/owner.txt" "$config_dir/rules/AUTHORITY.md" ;;
            newline-root)
                config_dir=$case_dir/line$(printf '\nx')break
                mkdir -p "$config_dir/rules/platform" ;;
            config-dangling) ln -s "$case_dir/missing" "$config_dir" ;;
            rules-dangling)
                mkdir -p "$config_dir"
                ln -s "$case_dir/missing" "$config_dir/rules" ;;
            platform-dangling)
                mkdir -p "$config_dir/rules"
                ln -s "$case_dir/missing" "$config_dir/rules/platform" ;;
            claude-dangling)
                mkdir -p "$config_dir"
                ln -s "$case_dir/missing" "$config_dir/CLAUDE.md" ;;
        esac
        sh -c '. "$1"; destination_root_preflight "$2" || exit 2; : >"$3"' sh \
            "$TMPROOT/$guard.sh" "$config_dir" "$case_dir/continued" >"$case_dir/output" 2>&1
        status=$?
        case $state in
            absent|directory)
                assert_status "destination guard allows $state root" 0 "$status"
                [ -f "$case_dir/continued" ] && _pass "$state destination continuation reached" || \
                    _fail "$state destination continuation reached" "missing marker" ;;
            *)
                assert_status "destination guard refuses $state" 2 "$status"
                [ ! -e "$case_dir/continued" ] && _pass "$state destination continuation unreachable" || \
                    _fail "$state destination continuation unreachable" "marker exists" ;;
        esac
        for relative in owner.txt rules/owner.txt rules/platform/owner.txt; do
            assert_files_identical "$state preserves external $relative" \
                "$case_dir/external/$relative" "$case_dir/original-owner"
        done
    done
    # The documented hard-link check is required even on a fresh install
    # where no managed destination file exists yet.
    find_case=$TMPROOT/destination-unsupported-find
    mkdir -p "$find_case/bin" || exit 2
    real_find=$(command -v find) || exit 2
    printf '%s\n' '#!/bin/sh' \
        'case " $* " in *" -links "*) exit 1 ;; esac' \
        "exec \"$real_find\" \"\$@\"" >"$find_case/bin/find"
    chmod +x "$find_case/bin/find" || exit 2
    PATH="$find_case/bin:$PATH" sh -c \
        '. "$1"; destination_root_preflight "$2" || exit 2; : >"$3"' sh \
        "$TMPROOT/$guard.sh" "$find_case/new-config" "$find_case/continued" \
        >"$find_case/output" 2>&1
    assert_status "destination guard refuses unavailable hard-link check on first install" 2 "$?"
    [ ! -e "$find_case/continued" ] && _pass "unavailable hard-link check stops before first copy" || \
        _fail "unavailable hard-link check stops before first copy" "marker exists"
    mkdir -p "$find_case/existing/rules" || exit 2
    printf 'existing owner bytes\n' >"$find_case/existing/rules/AUTHORITY.md"
    cp "$find_case/existing/rules/AUTHORITY.md" "$find_case/existing-original" || exit 2
    PATH="$find_case/bin:$PATH" sh -c \
        '. "$1"; destination_root_preflight "$2" || exit 2; : >"$3"' sh \
        "$TMPROOT/$guard.sh" "$find_case/existing" "$find_case/existing-continued" \
        >"$find_case/existing-output" 2>&1
    assert_status "destination guard refuses unavailable hard-link check on update" 2 "$?"
    [ ! -e "$find_case/existing-continued" ] && _pass "unavailable hard-link check stops before update" || \
        _fail "unavailable hard-link check stops before update" "marker exists"
    assert_files_identical "unavailable hard-link check preserves existing owner bytes" \
        "$find_case/existing/rules/AUTHORITY.md" "$find_case/existing-original"
fi
finish
