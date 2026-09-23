# Plan — the local layer (0.1.16)

- **Status:** approved 2026-09-21 (the owner's word in conversation). Decision record: [`docs/adr/0004-the-local-layer.md`](../adr/0004-the-local-layer.md).
- **Goal:** a user installs and updates these rules from this repository *and* keeps their customizations, with no merge. Proven on the owner's own installation before this plan was written.
- **One batch, five tasks.** Task 2 is the risk-class one (a script that decides whether an update may proceed): deep review at task grain. The batch closes with a deep review on the Strong tier from the second model family; nothing is pushed before it is ruled.

| # | Task | Done when |
|---|---|---|
| 1 | **Rules text.** The "local layer" paragraph in `rules/AUTHORITY.md` after Precedence, including the reserved `L` numbers; one header line in each of the six source-scoped files; `CLAUDE.md` names the layer and its self-update paragraph no longer speaks of overwriting tailored files. Counts in `AUTHORITY.md`'s header stay true. | The three hooks are in; no other rule wording changes; `docs/index.html`'s dataset carries the section-0 paragraph if it carries section 0 at all. |
| 2 | **`scripts/check-local.sh`** — POSIX `sh`, no dependency. Arguments: the directory holding the local files, the directory holding the playbook's rule files to check against (so it can run against *staged* text). Exit 0 = every quoted string found; 1 = at least one stale override, each reported as `file:line`, the words, and the file they were sought in; 2 = usage error, a named file that does not exist, or a **Dead words:** line that does not parse. No local files = exit 0 with a message saying nothing is customized. Fixed-string search, with `-e` so a string that begins with a dash is data. | `tests/check_local_test.sh` passes, was seen to fail first, and each assertion was proven by mutation in a scratch copy: fresh, stale, unparsable, missing file, a string starting with `-`, a string with regex metacharacters, an item naming two files, no local files, CRLF input. |
| 3 | **`templates/LOCAL.md` and `templates/LOCAL_dev.md`** — the header, the three kinds, the grammar of a Dead-words line, one worked example of each kind, and the git-email Fill left blank. `LOCAL_dev.md` carries the same `paths:` block as the six scoped files; a test compares the blocks byte for byte. | Templates exist outside `rules/`; the frontmatter test passes. |
| 4 | **`INSTALL.md`** — never copy over, move or open a local file; on first install, offer the templates; the git email becomes a Fill (the old step 4 edit is gone); an **update** section: back up to a sibling of `rules/`, stage the new text, run `check-local.sh` against the staged text, stop on 1 or 2, list from `CHANGELOG.md` every rule the update touched that the user overrides, then copy; a **migration** section for an installation tailored the old way (compare with the published text of the version it records; each difference becomes an entry or an upstream candidate; ask before replacing). The file count in the verification step is corrected against reality. Nothing but rule files under `rules/`. | A cold reader can install, update and migrate from `INSTALL.md` alone. |
| 5 | **Propagation and close-out** — README "Make it yours" rewritten around entries; ARCHITECTURE; a guide `docs/guides/local-layer.md` with the owner's installation as the worked example (no private content); CHANGELOG 0.1.16; PROGRESS; BACKLOG (the section-11 numbering note; anything found and not done); PLAN, HANDOFF ("held" until published); `VERSION` 0.1.16; `docs/adr/README.md`. Older plans, reviews, ADRs and changelog entries untouched. | The repository describes itself truthfully at 0.1.16. |

**Reviews:** mechanical per task on the mechanical review lane; deep at the batch boundary (and on task 2 by itself) by Sol at its highest effort through a separate process, against pinned commits, cold-read note first; the coordinator validates every finding against source; blockers fixed and re-reviewed before publication.

**Publication:** `main` and `checkpoint/0.1.16`, after the deep review is ruled. Then the owner's installation is brought to the published text, and the acceptance test is the script itself: `check-local.sh` run against his local files and the published rules must exit 0, and his installed playbook files must be byte-identical to the tag.

**Sibling plan:** `codex-playbook` ports the same decision as 0.1.6 (one local file, because that harness has no path-scoped loading, kept outside the skill folders its installer swaps).

---

## Approved source-trust repair, 2026-09-23

The owner approved ADR 0010 after GPT-6 Sol deep and mechanical reviews found
that the earlier uninstall guard could trust a forged or hidden-edit checkout.
This is a focused amendment to task 4 and its publication gate, not permission
to mutate the owner's live installation during development.

1. Write and run red lifecycle tests in `tests/install_preflight_test.sh` for a
   forged local tag, unreachable canonical ref, hidden tracked source edits,
   staged-checker execution before authentication, an owner-pinned fork, and
   linked destination roots. Assert refusal before the continuation marker and
   unchanged external/installed bytes.
2. Add an inline read-only `source_trust_preflight` to `INSTALL.md`. Resolve a
   canonical published `checkpoint/<VERSION>` tag over HTTPS or match the full
   commit ID explicitly supplied by the owner; verify literal source bytes
   against authenticated Git blobs, including the checker. Call it before any
   staged script and re-run immediately before a managed mutation.
3. Add an inline destination-root preflight and use it for first install,
   update, migration, and uninstall. Keep backups, local files, and reports
   intact on every refusal. Document the fail-closed offline and fork behavior
   in README/guide and add any needed line-ending controls for Windows.
4. Run the focused tests, the six-suite test runner, shell syntax and lint,
   and a pinned GPT-6 Sol mechanical and deep re-review. A passing suite alone
   does not lift the hold. Publish Claude first, then Codex, only after review
   findings are ruled and the publication checklist is complete.

Each step starts the next once its gate is met. Disk capacity below 40 GB
stops dispatch and mutation; no unrelated repository or evidence cleanup is
authorized by this amendment.

### Review-found repair, 2026-09-23

The pinned `5441cd8` reviews failed on two independent source/destination
trust blockers: inherited Git repository state redirected the canonical URL,
and a hard-linked managed destination let a normal copy overwrite an external
file. Mechanical review also found newline-bearing paths accepted and missing
first-install prerequisites. Preserve both raw reports, add red regressions,
repair all four, run the full suite, then repeat pinned GPT-6 Sol review of the
affected trust boundary before any tag or push. The original publication order
remains Claude first, Codex second.

---

## Amendments after the batch's mechanical review, 2026-09-21

The five task rows above are the plan as approved and are left as they were. Three
of their done-when statements were overtaken by rulings made after the work was
built — recorded here rather than edited into the rows, so the plan still shows
what was approved and what changed:

- **Task 2's exit-2 list grows.** Beyond a usage error, a missing named file and a
  line that does not parse, exit 2 now also covers: an **Override** with no valid
  `**Dead words:**` line (which is what makes a mistyped marker a refusal instead
  of a silent pass — ADR 0004 decision 4, completed); a Dead-words line longer than
  4,096 bytes; a local file that exists and cannot be read as a regular file; a
  file name carrying a glob character; and a search that failed. "No local files =
  exit 0" still holds — but only when nothing is there at all.
- **Task 3 ships no live entry.** The git-identity Fill is a *fenced example*, not
  a blank live entry: a template copied as shipped would otherwise bind the agent
  to "commits use [nothing]". `INSTALL.md` step 4 writes the entry out of its fence
  once it has the address, and a test fails on any unfenced entry line in either
  template.
- **Task 4 gains four requirements.** The update asks the user before it copies;
  the migration stages the *new* version in a named directory and runs the check
  from it; migration copies only a local file that is not already there, and
  otherwise stops and shows the difference; and the uninstall restore exempts the
  two local files. `INSTALL.md` also states what it needs on the machine (`curl`
  and a POSIX `sh`).

Two wordings were corrected everywhere as part of the same round: "the playbook
never *opens* the local files" was never true — the check script reads both — so
the claim is now that the playbook never ships them and an update never writes to,
copies over or replaces them; and the suite counts stated in the records were
wrong and are now counted rather than copied.
