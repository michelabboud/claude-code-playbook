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
    sh -c '. "$1"; "$2" "$3"' sh "$TMPROOT/$guard.sh" "$guard" \
        "$TMPROOT/missing-rules" >"$TMPROOT/output" 2>&1
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
            sh -c '. "$1"; "$2" "$3" || exit 2; : >"$4"' sh \
                "$TMPROOT/$guard.sh" "$guard" "$case_dir/rules" "$case_dir/continued" \
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
done
finish
