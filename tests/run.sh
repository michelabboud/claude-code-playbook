#!/bin/sh
#
# tests/run.sh — every test in this repository.
#
#   sh tests/run.sh
#
# Four suites, in the order that makes a failure easiest to read:
#
#   check_local_test         what scripts/check-local.sh does
#   mutation_test            proof that the suite above catches a broken script
#   rules_text_test          the local layer's hooks, the bundle's shape,
#                            the templates, INSTALL.md's counts
#   rules_text_mutation_test proof that the suite above catches a broken rulebook
#
# Exits 0 only if all four pass. Each suite creates and removes its own
# temporary directory; no real home directory is read or written.

set -u

HERE=$(dirname -- "$0")
failed=0

for suite in check_local_test mutation_test rules_text_test rules_text_mutation_test; do
    printf '\n=== %s ===\n' "$suite"
    if sh "$HERE/$suite.sh"; then
        :
    else
        failed=$((failed + 1))
    fi
done

printf '\n'
if [ "$failed" -gt 0 ]; then
    printf '%d suite(s) FAILED\n' "$failed"
    exit 1
fi
printf 'all suites passed\n'
exit 0
