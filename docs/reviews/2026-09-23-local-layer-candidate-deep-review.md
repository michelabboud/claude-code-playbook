# Local-layer candidate deep review — 2026-09-23

**Pinned candidate:** `a7e690e` (local main, not published). **Verdict:** FAIL. This is a focused repair review, not acceptance of the original risk-class tasks or batch.

The reviewer found the five earlier diagnostic items repaired in source, then found two blocking fail-open paths:

1. A valid Markdown `+ **Override ...**` list entry is not recognized as an Override and is not rejected as a malformed entry. An isolated archive fixture with a misspelled verifier reported zero searches and exited 0. The checker accepts `-` and `*` bullets and enumerates only selected alternate forms in its fail-closed guard (`scripts/check-local.sh`, `has_unrecognized_entry_marker` and `entry_kind`).
2. Claude recursively loads Markdown under its `rules/` directory, but the checker and uninstall guard inspect only top-level `LOCAL.md` and `LOCAL_dev.md`. A nested `backup/LOCAL.md` fixture reported no local layer and exited 0. Installation can therefore proceed while another active local file is unseen; the uninstall guard can remove managed base rules while leaving that file active. See `INSTALL.md`, "Where the files go" and "Uninstalling", and `scripts/check-local.sh`, `LOCAL_FILES`.

The reviewer also identified a copyable but fenced `templates/LOCAL_dev.md` example that moves security, concurrency, Rust, and unsafe development from Top to Strong. That contradicts rule 8.1 and the local-layer safety boundary. The template needs correction before publication.

**Verification at the pinned candidate:** six suites from an isolated archive exited 0 (195 checker, 93 shared-vector, 53 checker-mutation, 142 rule-text, 38 rule-text-mutation, 106 install-preflight assertions). `git diff --check 5296bc4..a7e690e` exited 0. No actual Claude loader or non-Linux platform was exercised. Green tests do not overrule the findings.
