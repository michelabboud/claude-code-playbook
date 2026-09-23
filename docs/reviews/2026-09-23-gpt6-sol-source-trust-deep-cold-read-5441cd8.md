# Independent cold read — 5441cd8542fb2ac7c90f7e0c35aea3a1ded8915f

Context: child reviewer in a shared parent conversation; no claim of process or history blindness. Input was the pinned Git archive and diff from a20bca7bf363b60c7ff48a2bed7cdb07e4941442. Excluded docs/reviews/* from initial reading; no prior review opened at the time of this note.

Initial observations and hypotheses, before adversarial testing:

1. The default tag decision compares canonical HTTPS `ls-remote` tag object, local tag object, and HEAD commit. The owner-pin route matches full lowercase hex length to HEAD. The code validates literal bytes of the listed managed files and staged checker, including Git blob mode regularity. This appears to cover forged local tags and status-hidden edits for files on the list.
2. The bootstrap remains a trust boundary: `INSTALL.md` supplies the inline verification function and is read before the checkout is verified. If an attacker edits that file and an operator evaluates its altered guard, arbitrary shell may run or verification may be skipped. ADR 0010 names malicious instruction text as a limitation. Determine whether the review should classify this as an accepted trust assumption or a blocking gap in the desired workflow.
3. Confirm exact call paths across first install, update, migration, uninstall and restore. Check whether the required preflight is repeated at every managed mutation and whether staged local drafts and backup sources can change after verification.
4. Check destination component symlink rejection, quoted shell paths, Git environment/config behavior, line ending portability, and source/installation compare semantics. In particular, inspect behavior for unusual filenames or externally supplied environment variables.
5. Backup verification describes non-empty readback rather than exact byte and tree equivalence; assess whether partial backup could be accepted before overwrites. Restore source identity also needs close inspection.

No verdict yet. No tests run as of this note.
