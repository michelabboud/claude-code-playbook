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

for guard in migration_local_preflight uninstall_local_preflight; do
    awk -v name="$guard" '
        $0 == name "() {" { copying = 1 }
        copying { print }
        copying && $0 == "}" { found = 1; exit }
        END { if (!found) exit 1 }
    ' "$ROOT/INSTALL.md" >"$TMPROOT/$guard.sh"
    status=$?
    assert_status "$guard exists as an executable preflight" 0 "$status"
    [ "$status" -eq 0 ] || continue
    sh -c '. "$1"; "$2" "$3" "$4"' sh "$TMPROOT/$guard.sh" "$guard" \
        "$TMPROOT/missing-rules" "$ROOT" >"$TMPROOT/output" 2>&1
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
                "$TMPROOT/$guard.sh" "$guard" "$case_dir/rules" "$ROOT" "$case_dir/continued" \
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
        "$TMPROOT/$guard.sh" "$guard" "$case_dir/rules" "$ROOT" "$case_dir/continued" \
        >"$case_dir/output" 2>&1
    assert_status "$guard refuses nested active Markdown before mutation" 2 "$?"
    if [ ! -e "$case_dir/continued" ]; then
        _pass "$guard leaves mutation unreachable for nested Markdown"
    else
        _fail "$guard leaves mutation unreachable for nested Markdown" "continuation reached"
    fi
    assert_files_identical "$guard preserves the nested user file" \
        "$case_dir/rules/backup/LOCAL.md" "$case_dir/original-nested"
done

# A linked rules root or configuration parent may point outside the intended
# deletion scope. Uninstall must refuse before even considering exact files.
linked_case=$TMPROOT/linked-uninstall
mkdir -p "$linked_case/external/rules" "$linked_case/config"
printf 'external owner content\n' >"$linked_case/external/rules/notes.txt"
ln -s "$linked_case/external/rules" "$linked_case/config/rules"
sh -c '. "$1"; uninstall_local_preflight "$2" "$3" || exit 2; : > "$4"' sh \
    "$TMPROOT/uninstall_local_preflight.sh" "$linked_case/config/rules" "$ROOT" "$linked_case/continued" \
    >"$linked_case/output" 2>&1
assert_status "uninstall refuses a linked rules root" 2 "$?"
[ ! -e "$linked_case/continued" ] && _pass "linked-root continuation unreachable" || _fail "linked-root continuation unreachable" "marker exists"
[ -f "$linked_case/external/rules/notes.txt" ] && _pass "linked-root external bytes preserved" || _fail "linked-root external bytes preserved" "missing file"

parent_case=$TMPROOT/linked-parent-uninstall
mkdir -p "$parent_case/external/rules"
printf 'external owner content\n' >"$parent_case/external/rules/notes.txt"
ln -s "$parent_case/external" "$parent_case/config"
sh -c '. "$1"; uninstall_local_preflight "$2" "$3" || exit 2; : > "$4"' sh \
    "$TMPROOT/uninstall_local_preflight.sh" "$parent_case/config/rules" "$ROOT" "$parent_case/continued" \
    >"$parent_case/output" 2>&1
assert_status "uninstall refuses a linked configuration parent" 2 "$?"
[ ! -e "$parent_case/continued" ] && _pass "linked-parent continuation unreachable" || _fail "linked-parent continuation unreachable" "marker exists"
[ -f "$parent_case/external/rules/notes.txt" ] && _pass "linked-parent external bytes preserved" || _fail "linked-parent external bytes preserved" "missing file"

# A no-backup uninstall must not delete user edits merely because a pathname
# matches the managed inventory. Extract its separate content guard verbatim.
guard=uninstall_managed_file_preflight
awk -v name="$guard" '
    $0 == name "() {" { copying = 1 }
    copying { print }
    copying && $0 == "}" { found = 1; exit }
    END { if (!found) exit 1 }
' "$ROOT/INSTALL.md" >"$TMPROOT/$guard.sh"
assert_status "no-backup content guard exists" 0 "$?"
if [ -s "$TMPROOT/$guard.sh" ]; then
    case $(uname -s) in
        Linux) platform=LINUX.md ;;
        Darwin) platform=MACOS.md ;;
        MINGW*|MSYS*|CYGWIN*) platform=WINDOWS.md ;;
        *) platform=unsupported ;;
    esac
    source_checkout=$TMPROOT/exact-release-source
    mkdir -p "$source_checkout/rules/platform"
    cp "$ROOT/CLAUDE.md" "$ROOT/VERSION" "$source_checkout/"
    for managed in AUTHORITY CODE COLLABORATION DESTRUCTIVE DOCS ENVIRONMENT QUARANTINE REPO REVIEWS ROSTER SUBAGENTS TESTING WORKFLOW WRITING; do
        cp "$ROOT/rules/$managed.md" "$source_checkout/rules/$managed.md"
    done
    cp "$ROOT/rules/platform/$platform" "$source_checkout/rules/platform/$platform"
    git -C "$source_checkout" init -q
    git -C "$source_checkout" add -- .
    git -C "$source_checkout" -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm 'fixture release'
    git -C "$source_checkout" tag "checkpoint/$(sed -n '1p' "$ROOT/VERSION")"
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
    sh -c '. "$1"; uninstall_managed_file_preflight "$2" "$3" || exit 2; : > "$4"' sh \
        "$TMPROOT/$guard.sh" "$installed" "$source_checkout" "$TMPROOT/edited-continued" \
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
finish
