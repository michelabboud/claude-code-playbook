# Local-layer publication readiness — 2026-09-23

The Claude playbook source at `34013e3b4a98b2509a42963c645f728ec4d0d447`
cleared its focused mechanical and deep review gate. This is source-publication
readiness, not a claim of native Windows/macOS acceptance or a live install.
Remote `main` and `checkpoint/0.1.16` still require direct verification after
publication; this record does not infer them from a local commit.

## Review disposition

| Pinned source | Mechanical | Deep | Result |
|---|---|---|---|
| `5441cd8` | FAIL | FAIL | Inherited Git state and hard-linked destination; newline and prerequisite gaps |
| `c0bd879` | FAIL | PASS | Empty first install did not probe `find -links` support |
| `b2fd255` | PASS | FAIL | Windows example dropped `/.claude`; quiescence missed update/migration |
| `34013e3` | PASS | PASS | No new blocker in the focused changed trust boundary |

The review reports and their cold-read notes are under `docs/reviews/`. Each
reviewer used a pinned archive and disposable scratch; none operated on the
live Claude installation. Review assignments requested GPT-6 Sol at xhigh,
but the child runtime did not expose an independently verifiable model ID or
effort level. No stronger attestation is claimed.

## Verification and limits

- `sh tests/run.sh` on the committed `34013e3` tree: direct exit 0; suites
  passed 207, 93, 53, 147, 40, and 267 assertions. The coordinator's full
  output is preserved in ignored `logs/reviews/34013e3-full-tests.log`.
- `git diff --check b2fd255 34013e3`: direct exit 0. Shell syntax and focused
  warning-level ShellCheck for both inline guards: exit 0. Whole-test
  ShellCheck still reports the existing `HOOK2` unused-variable warning; it
  was reproduced at the base, not introduced by this repair.
- Adversarial regressions refused inherited Git URL rewrites, managed hard
  links, newline paths, unsupported hard-link inspection on empty and
  populated destinations, and the two unsafe wording variants. Failed
  mutations were exercised only in disposable fixtures.
- Native Windows/macOS execution, NTFS hard-link accounting, the live
  canonical tag before publication, and the owner's installed files were not
  exercised. Manual preflights need a quiescent source and destination and are
  not atomic. ADR 0010 records the accepted bootstrap trust limit.

## Publication boundary and hygiene

The final administrative commit may contain only this report, review records,
and status documents. Before tagging, compare `VERSION`, `CLAUDE.md`,
`INSTALL.md`, `CHANGELOG.md`, `rules/`, `scripts/`, and `templates/` against
`34013e3`; any difference reopens source review. Confirm remote `main` has
not advanced and `checkpoint/0.1.16` does not exist, then tag and push only
this repository. Publish the Codex sibling only after the Claude remote tag
is confirmed.

Disk had over 100 GB free at the review closeout, above the 40 GB dispatch
floor. Reviewer scratch fixtures and ignored logs were retained as evidence;
reports and documents were committed. No unrelated worktree, branch, log,
backup, private installation, or other repository was cleaned or modified by
this Claude review task.
