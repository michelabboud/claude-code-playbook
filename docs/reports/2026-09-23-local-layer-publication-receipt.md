# Local-layer source publication receipt — 2026-09-23

Claude Playbook 0.1.16 was published to the repository's source host after
focused mechanical and deep review passed. The final source commit was
`97938d0c874b651a7ab1b44b002b289c5c378caa`. A direct remote check after
push found `main` at that commit and the peeled annotated
`checkpoint/0.1.16` tag at that same commit. The tag object was
`dc6b06678a7d3c60e6ec9a2265bfd2831c369cf7`.

The tagged tree's `sh tests/run.sh` exited 0: its six suites passed 207, 93,
53, 147, 40, and 267 checks. Ignored raw output is preserved at
`logs/reviews/97938d0-full-tests.log`. The managed and executable source tree
at the tag is byte-identical to reviewed `34013e3`; the intervening commit
changed only status, report, and review documents. The pre-push diff check
exited 0. Review evidence and limits are in
`docs/reports/2026-09-23-local-layer-publication-readiness.md`.

This confirms source hosting, not a package release, live installation,
private-rule sync, native Windows/macOS acceptance, or concurrent-adversary
safety. No other repository, evidence log, worktree, or user file was cleaned
or modified as part of this publication receipt.
