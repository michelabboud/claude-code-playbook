# Cold read — 5441cd8542fb2ac7c90f7e0c35aea3a1ded8915f

Read the pinned diff and archived INSTALL.md, test script, and ADR 0010 before opening any `docs/reviews/*` or sibling review output. This is a same-session child review with a scoped brief, not a separate fresh process; independence is limited accordingly.

Initial observations to test:

- The inline source guard binds a canonical HTTPS tag object (or owner pin) to HEAD, then hashes named working-tree source files as literal blobs. This directly addresses forged local tags and hidden tracked edits.
- The guard enumerates `rules/` by a fixed entry count and verifies each named managed file. Need check whether an extra active file can evade that count, and whether baseline mode accepts missing historical files safely.
- The destination guard checks absolute path components, managed paths, and root symlinks. Need test alternate spellings, intermediate links, and unlisted paths used in backup/restore.
- In update U2, `source_trust_preflight .` uses current directory. `cd` is not shown in that snippet, although text says run from the staged repository; likely clear enough, but verify fork invocation and failure exits.
- Migration M4 uses `&&` before the checker but has no explicit `|| exit 2`; need check whether prose makes failure handling unambiguous.
- Manual copy and uninstall remain multi-step procedures; check each recheck point for source/destination drift or unauthenticated script execution.

No verdict yet. No prior review read.
