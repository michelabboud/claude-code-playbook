# Focused diagnostic — local-layer repair at `5491f39`

**Status:** FAIL, read-only pinned-object diagnostic; not a completed release gate.
**Target:** `5491f39e56a1e2e877ff17ca6257d9a428200e9d`.
**Reviewer:** requested GPT-6 Sol; actual effort and token use were not exposed by the runner. The review used a fresh child context, not a separate-process dual-blind gate. The reviewer ran no suites under the pinned-object/read-only brief.

## Findings and coordinator disposition

| Finding | Severity | Disposition |
|---|---|---|
| `INSTALL.md` can remove or restore managed base rules while leaving a Fill/Add-only local file recursively loadable. The checker sees no quoted Override to verify and can return 0. | Blocking | Confirmed against the documented uninstall path; refuse uninstall/restore while any local path remains active. |
| `docs/guides/local-layer.md` and `docs/index.html` still say a local entry may expand authority by adding an approval-table row, contrary to the repaired section 0 boundary. The guide's Override example also omits its required section verifier. | Blocking | Confirmed. Correct the guide and visual map, and test a complete example. |
| A UTF-8 BOM before an Override bypasses the recognized and unrecognized entry shapes, producing a zero-search exit 0. | Blocking | Confirmed against the scanner. Reject BOM bytes in the local layer. |
| Migration checks and copies `LOCAL.md` before discovering that `LOCAL_dev.md` already exists, creating a partial installation before its stated refusal. | Major | Confirmed. Preflight both destinations before copying either. |
| Anchor counting compares raw CRLF headings before the section extractor normalizes them. | Moderate | Confirmed. Normalize before uniqueness count and extraction. |

The reviewer observed source-level repairs for the earlier NUL, help-path, line-bound, and minimum-anchor findings, but this diagnostic is not a PASS on the full batch. The original deep review and these repairs still need a pinned focused review at the required depth; mechanical and task-grain review obligations also remain.

## Evidence boundary

The reviewer used Git-object inspection, shell syntax checks, and `git diff --check`; no executable reproductions or test suites were run by that reviewer. Coordinator/worker tests are recorded with the separate fix commit and do not retroactively change this verdict.
