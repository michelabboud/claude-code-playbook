# Local-layer candidate mechanical re-check — 2026-09-23

**Pinned candidate:** `a7e690e`. **Mechanical verdict:** PASS for the five prior diagnostic gaps; the separate deep review of the same candidate returned FAIL and controls the publication gate.

The reviewer found the earlier uninstall/restore guard, authority guide and index, BOM rejection, migration preflight, and CRLF heading normalization repairs present. From a Git-archive snapshot, `sh tests/run.sh`, selected shell syntax checks, and `git diff --check a7e690e^ a7e690e` exited 0. No real Claude runtime or actual installation was exercised.

The reviewer additionally claimed a non-blocking restore/checker wording mismatch at `rules/AUTHORITY.md:42-43`. A direct check of that file at the pinned commit found no restore or `check-local.sh` statement there; the claim is not reproduced and no text change is warranted on that basis. This mechanical pass does not overrule the deep review's recursive-file and `+`-bullet findings.
