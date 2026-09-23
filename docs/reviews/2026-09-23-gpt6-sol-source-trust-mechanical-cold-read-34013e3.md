# Cold-read mechanical note — 34013e3b4a98b2509a42963c645f728ec4d0d447

Written before opening any prior review report. Source: pinned Git diff against b2fd2553d4bad4786d7e817c1c2c28a39cfae5bc, INSTALL.md and tests in a dedicated archive. This is an inherited child task, so it is cold in read order but not fully blind to the earlier issue summaries in the brief.

Initial findings: the Windows example now appends `/.claude` to `cygpath -u "$USERPROFILE"`, yielding the intended target directory for an ordinary Windows profile path. The prose makes an unset USERPROFILE or failed conversion a stop. The quiescence requirement appears in the shared preflight section, before Step 0, and explicitly names first install, update, migration, restore, and uninstall. The new wording tests pin both the example and section placement; their mutations remove the example and move the quiescence sentence out of the shared section. The install preflight test adds an existing destination with preserved owner bytes for unsupported `find -links`. `git diff --check` exited 0.

Open mechanical checks: run the six-suite archive tests and scratch-only adversarial mutations; check exact exits and whether the tests catch a regression that drops only `/.claude` while leaving the example line; inspect any changed report text for unexpected effects. No prior review report has been opened yet.
