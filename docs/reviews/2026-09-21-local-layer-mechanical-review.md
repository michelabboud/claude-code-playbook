# Mechanical review A — claude-code-playbook, the local layer (0.1.16, held)

- **Target:** `1b2ff2780a2d03e7f05e96150c6bb3f7f0dc1976`. **Base:** `0270322923cd15c8d792b0c1ef69280f6825e68d`.
- **Reviewer:** Sonnet 5 (dispatched as `sonnet`; the runtime does not confirm the model). Read-only: nothing tracked was edited, staged, committed, tagged or pushed. `git status --short` was empty before I began and shows only this report at the end. All fixtures and mutants lived under `/tmp/mrA/`. No home directory was read or written.
- **Method:** the change was read through the worktree, which is clean at the target, and a `git archive` copy in `/tmp/mrA/base` was used for everything that ran or was mutated.

## Verdict: **FAIL** — four blocking findings, all small to fix

The suite is green and the parser is much better than the first cut, but the checker still fails **open** in one class of input (an unreadable local file), and five ways of breaking it are invisible to the tests. The install guide can copy over a user's local file, and the `LOCAL.md` template ships a live entry, which the post-build ruling forbids.

| # | Severity | One line |
|---|---|---|
| B1 | Blocking | An unreadable or inaccessible local file exits 0 with "ok" — a stale entry passes |
| B2 | Blocking | `INSTALL.md` step M5 copies `LOCAL.md` / `LOCAL_dev.md` into place with no existing-file guard |
| B3 | Blocking | `templates/LOCAL.md` ships a live Fill (`` Commits use `` ``) — violates "no live entry" |
| B4 | Blocking | Five mutants of `check-local.sh` that turn a correct exit 1/2 into exit 0 survive all tests |
| m1–m8 | Minor | Wording tests not pinned where they claim; INSTALL ambiguities; glob names; stale counts; more |
| i1–i9 | Informational | |

---

## Blocking

### B1 — An unreadable or inaccessible local file exits 0, "ok"

`scripts/check-local.sh:404` (`while … read` loop), `:449` (`done < "$_cf_path"`), `:488-492` (presence scan with `[ -f ]`).

If the redirect `< "$_cf_path"` fails, the shell prints one line and carries on. Nothing counts it as an error, and the summary says `ok`. The same happens when the local directory has no search permission: `[ -f "$local_dir/LOCAL.md" ]` is false, so the script reports "nothing is customized". README:227 and `docs/guides/local-layer.md:162` both say "exit 2 is never a pass", so this contradicts a published claim.

Reproduction (uid 1000; a root-owned `LOCAL.md` copied in with `sudo cp` and mode 600 is the realistic way to get here):
```
d=/tmp/mrA/w/unread; mkdir -p $d
printf '%s\n' '**Dead words:** `zzz-not-there` (in `AUTHORITY.md`)' > $d/LOCAL.md
chmod 000 $d/LOCAL.md
sh scripts/check-local.sh $d /tmp/mrA/base/rules
```
```
scripts/check-local.sh: 404: cannot open /tmp/mrA/w/unread/LOCAL.md: Permission denied
check-local.sh: ok — 0 dead-words string(s) still present in /tmp/mrA/base/rules.
check-local.sh: 0 search(es), 0 stale, 0 error(s).        exit=0
```
Same exit 0 when the script is run by `bash`. Same for `LOCAL_dev.md`. With `chmod 600` on the *directory*, output is `no local layer … nothing is customized`, exit 0. The rules-directory side is handled correctly: an unreadable rule file exits 2 through the grep-status branch.

**Instead:** in `check_file`, `[ -r "$_cf_path" ] || { parse_err … "cannot read"; return; }`, and test the redirect's status. In the presence scan, treat an existing but unreadable or non-searchable entry as an error. `[ -e ]` true and `[ -f ]` false — a directory, or a dangling symlink — should also exit 2 rather than say "nothing is customized". Add assertions for each, skipped when `id -u` is 0.

### B2 — `INSTALL.md` step M5 can copy over a user's local file

`INSTALL.md:320-323`: "Back up (step 1), copy the approved `LOCAL.md` and `LOCAL_dev.md` into `~/.claude/rules/`". Nothing checks whether those files already exist. M3 says the entries are written into *copies of the templates*, not into the user's existing local files, so an installation that already has a `LOCAL.md` (a half-migrated one, or the owner's own) has it replaced. This contradicts `INSTALL.md:43` ("Never copy over them") and step 4's own guard at `:148-150`. The step-1 backup makes it recoverable, but the guide's own rule is never, not "recoverably".

**Instead:** M5 should say: if either file exists, stop, show the user the diff between it and the approved one, and let them merge by hand; copy only what does not exist.

### B3 — `templates/LOCAL.md` ships a live entry

`templates/LOCAL.md:112-114`, under `# The entries` / `## Who and where`, sits outside every fence:
```
- **Fill — git identity (section 6, "Git identity, every repo").** Commits use
  `` — use your provider's noreply address if your real one is push-blocked.
  The trailer stays as the rule gives it.
```
A user who copies the template as shipped binds the agent to "Commits use [nothing]". The ruling is that a template carries no live entry.

What the tests do and do not show. Checker over both templates as shipped: `0 search(es), 0 stale, 0 error(s)`, exit 0 — so no *Dead-words* line is live, which is what `tests/dead_words_vectors_test.sh` "the templates' examples are all fenced: no search" checks. `templates/LOCAL_dev.md` has no live entry. `templates/LOCAL_dev.md`'s `paths:` block is byte-identical to the six scoped files: all six `md5` to `eacdaa7432dc`, and the template matches.

The live Fill is invisible to every test. Mutant T2 (add an unfenced `- **Override — rule 3.2 …**` with no Dead-words line to `LOCAL_dev.md`) **survived the whole suite**. An unfenced-entry finder over the templates finds exactly one hit: `templates/LOCAL.md:112`.

**Instead:** put that Fill inside a fenced example, and have `INSTALL.md` step 4 tell the agent to *write* the entry from the example once it has the user's email. That is also what step 4 already implies when the user declines the template copy. Add a test that fails on any line matching `^\s*[-*] \*\*(Fill|Add|Override)` outside a fence in either template.

### B4 — Tests pass while the checker is broken in five fail-open ways

Each mutant below was applied to a scratch copy of `scripts/check-local.sh` and run against `tests/check_local_test.sh` then `tests/dead_words_vectors_test.sh`, the way `tests/mutation_test.sh` does. **Every one survived both suites, and each changes a correct exit 1 or 2 into 0** (or a wrong one — M26):

| Mutant | What breaks | Hand case, original → mutant | Assertion that should exist |
|---|---|---|---|
| **M25** `read -r … \|\| [ -n … ]` → drop the `\|\| [ -n … ]` | a final line with no newline is never read | stale entry on unterminated last line: exit **1 → 0**, `0 search(es)` | a stale entry on a final line with no newline → exit 1 |
| **M31** truncate `SCAN_WORDS` at the first ` · ` | quotation cut short; still found as a prefix | playbook heading rewritten `# 11 · Your platform` → `# 11 · Your OS`: exit **1 → 0** | tests 80–83 use words whose prefix is present; add a case where only the part after the separator is absent |
| **M15** `has_bare_marker`: an odd backtick swallows the rest of the line | marker after a code span is hidden | `see \`x\` **Dead words:** \`zzz\` (in \`AUTHORITY.md\`)`: exit **2 → 0**, entry silently skipped | tests 84–88 only put the marker before any backtick; add marker-after-a-span → exit 2 |
| **M26** `read -r` → `read` | backslash eaten in quoted words | words `` `back\slash` `` present in file: exit **0 → 1**, reported stale as `backslash` | a quotation containing a backslash |
| **M1** the `*)` grep-status branch → `*) : ;;` | a failed search is swallowed | unreadable rule file: exit **2 → 0**, `ok` | an unreadable rules file → exit 2 (skip as root) |

M25, M31 and M15 are exactly the property the ADR calls the point of the check: nothing may be skipped silently.

**Other real survivors**, lower stakes (mutant → what a test should assert): M3 `fence_closes` accepts trailing text (`` ``` text `` must not close a fence); M5 the "info string may not contain a backtick" rule; M9 `-h` alone; M14 `LC_ALL=C` removal (needs a non-UTF-8 byte run under a UTF-8 locale); M16 a missing named file must not count as a search; M33 `[ -f ]` → `[ -e ]` for the local files.

Mutation totals, 36 new mutants of `check-local.sh`: 17 caught, 19 survived. Of the survivors 8 are equivalent or mutants I built badly (M11, M12, M13, M23, M24, M27, M34, M35), and 11 are real (M1, M3, M5, M9, M14, M15, M16, M25, M26, M31, M33). The mutants are in `/tmp/mrA/mut/run.py`.

---

## Minor

**m1 — The wording tests do not pin the strings where they claim to.** `tests/rules_text_test.sh:13-17` says "each assertion … cannot be satisfied by another occurrence". The six section-0 phrases (lines 77–90) and hook 3 are counted per *file*, not per paragraph, and the `docs/index.html` string is counted anywhere in the file. Five mutants **survived the whole suite** (`/tmp/mrA/mut/repo_mut2.py`):
- W1 `A local file that is absent means nothing is customized.` moved to the end of `AUTHORITY.md`
- W2 the "never adds authority" sentence moved into the approval-table region
- W3 hook 3 moved to the end of `CLAUDE.md`
- W4 the Fill definition replaced in the paragraph and stated only in a stray line at the end of the file
- W5 the index.html dataset entry renamed, its title left in an HTML comment — the map no longer shows it and the test passes

**m2 — Other repo-level survivors.** Of 18 mutants of rules text, templates and `INSTALL.md` run through the whole `sh tests/run.sh`, 7 were caught (T1, T9, T10, T11, T12, T14, T18) and 11 survived: T2 (above); T3 the update checks *installed* rules against installed rules instead of staged; T4 the update drops its backup; T5 step 2 says replace the whole directory; T15 step 4 says copy both templates, overwriting; T16 U2's exit-1 row says "Continue"; T6 the `docs/index.html` version drifts; T7 the changelog says 40 vectors; T8 a real email in `WORKFLOW.md`'s placeholder; T13 the README says thirteen files; T17 a broken shebang. Most are prose the rules deprecate testing (rule 2.1), and T6/T7/T13 are known (BACKLOG "version carriers"). **T3 and T4 guard the property the ADR is built on** — the check runs against staged text before anything is copied, and a backup precedes the copy — and only `CLAUDE.md`'s wording is pinned, not `INSTALL.md`'s.

**m3 — `INSTALL.md` as a procedure.** Followed on paper against a scratch stand-in for `~/.claude`:
- **The update never asks before copying.** The section opens "asks before replacing" (`:198`) and `CLAUDE.md` says "stop and ask before replacing anything", but U2→U3→U4 (`:215-249`) only *show* the user things; U4 says "Back up, then copy". Add an explicit ask between U3 and U4.
- **Migration M4 is ambiguous about the checkout** (`:274-318`). M1 checks out the *old* tag into a scratch directory; that tree has no `scripts/check-local.sh`. M4 says "the new version staged" and runs `sh scripts/check-local.sh <scratch-dir> ./rules`, but no step stages the new version. From the M1 checkout the command does not exist; if an agent points `./rules` at the old text the check passes by construction. Add an M-step that stages the new version (as U1 does) and name the directory.
- **Step 4 vs an existing `LOCAL.md`** (`:148-150` "do not merge into it" against `:159-163` "write it into `~/.claude/rules/LOCAL.md` as a Fill"). For a user with a `LOCAL.md` and no git Fill, both cannot be followed. Say: show the user the entry to add.
- **Uninstall** (`:345`): "Restore the timestamped backups … over `~/.claude/rules/`". Restoring a backup directory over `rules/` overwrites a `LOCAL.md` that has changed since. The next paragraph says leave them alone, but the restore sentence needs the same exemption.
- **Windows:** `:30` names `%USERPROFILE%` but U2/M4 need `sh` and `curl`, and no fallback or requirement is stated.
- **`docs/ANNOUNCE.md:34`** `cp templates/LOCAL.md ~/.claude/rules/LOCAL.md` has no `-n`, so it overwrites an existing local file. It is labelled "optional, and yours", but it is a bare overwrite. It also copies the template with the live Fill (B3).

What holds: U2 runs the check against `./rules` of the *staged* clone, and `CLAUDE.md` resolves to the staged `../CLAUDE.md` before U4. Counts are right: `ls rules/*.md | wc -l` = **14**, `rules/platform/*.md` = 3, and INSTALL states 14 at `:175`, "fourteen" at `:329` and `:347`. Nothing except rule files, the one platform file, and the user's own `LOCAL*.md` is ever placed under `rules/`; backups go to a sibling.

**m4 — File names are glob-expanded, so a name's meaning depends on the current directory.** `scripts/check-local.sh:285` (`for _si_name in $_si_files`) with no `set -f`. Entry `(in \`[A]UTHORITY.md\`)`: from a directory with no such file → `error: named file does not exist`, exit 2; from a directory that contains `AUTHORITY.md` → **exit 0**, one search made. The grammar does not forbid glob characters in names. It cannot make a stale entry pass, but it is cwd-dependent parsing. Add `set -f`, or reject glob characters like whitespace.

**m5 — An Override with no Dead-words line, or with a mistyped marker, exits 0 and says `0 search(es)`.** `**dead words:**`, `**Dead words**:`, `Dead words:`, `**Dead  words:**`, `__Dead words:__`, and an `**Override — …**` entry with no line at all all give exit 0, `0 search(es), 0 stale, 0 error(s)`. Section 0, the ADR and the templates say an Override quotes dead words, and nothing checks that it does. A user who mistypes the marker silently loses the check. Suggest: warn (exit 2) on a line outside a fence and code span that matches `dead words` case-insensitively but is not the exact marker; and have INSTALL U2's exit-0 row say "compare the number of searches with the number of Overrides".

**m6 — Wrong counts and one stale entry.**
- `HANDOFF.md:18` and `PROGRESS.md:30`: "four suites, 197 assertions". Actual: five suites; 89 + 88 + 31 + 94 + 17 = **319**, which the changelog states correctly.
- `ARCHITECTURE.md:93`: "two mutation harnesses as well as two suites" — there are three suites.
- `docs/adr/0004-the-local-layer.md:10`: "Five files differed substantially" against 3 + 7 + 5 = 15 ≠ 14. `CHANGELOG.md:16` and `docs/guides/local-layer.md:18` say four (3 + 7 + 4 = 14).
- `BACKLOG.md:38-43` says fence detection "does not understand tildes, indented fences, or a fence opened inside a list item" and that examples would be checked. At the target the script handles tildes, indentation and runs of any length (`:333-371`), and tests exist (`dead_words_vectors_test.sh` "a tilde fence…"). The entry is stale from before the last commit.
- Words in `README.md:227` ("never treated as a pass") and guide `:162` are wrong until B1 is fixed.

**m7 — "Never opens them" against a script that opens them.** `README.md:96,193`, `ARCHITECTURE.md`, `rules/AUTHORITY.md:9` ("an update replaces the playbook's files without opening these two"), `templates/LOCAL.md:3` and ADR decision 1. The update procedure runs a script over both files (U2) and tells the agent to read them (U3). It only reads; the wording should say "never writes, copies over or replaces".

**m8 — A test that fails on macOS/BSD (unverified here).** `tests/rules_text_test.sh:159` compares `0` with `$(find … | wc -l)`; BSD `wc -l` pads with spaces, so `assert_eq` fails. Piping through `tr -d ' '` fixes it. Not run: no macOS available; GNU `wc` here prints `1` unpadded.

---

## Informational

- i1. Symlinked local files are followed, which is right for dotfile managers, but it means the script reads outside `local-dir`. Read-only. A symlink inside the rules dir pointing outside is followed the same way. The default `CLAUDE.md` path `<rules-dir>/..` is resolved physically, so a symlinked rules directory reads the physical parent's `CLAUDE.md` (a scratch case found a different file, no damage).
- i2. `LOCAL.md` as a directory or a dangling symlink → "nothing is customized", exit 0 (the harness would not load either). Covered by the fix in B1.
- i3. A named file that is a directory reports "does not exist" (misleading wording, exit 2 correct).
- i4. Platform files cannot be named in a Dead-words item (`/` is rejected), so an override of a platform rule cannot be staleness-checked; naming `LINUX.md` gives exit 2 forever.
- i5. Quoted words of one space, or one common letter, match nearly any file and never go stale. The grammar allows it.
- i6. A 300 KB quotation exits 2 (`grep: Argument list too long`, status 126): fail-closed. A line of 3,001 items ran in 10.1 s (quadratic), irrelevant in practice.
- i7. The `, and ` joiner is accepted without a shared vector (already in BACKLOG). The vectors test hashes the fixture against a constant in the test; it cannot compare with the sibling repo's copy.
- i8. `docs/ANNOUNCE.md` changed although the plan's task list does not name it; the commit message does, and the old text ("edit one line in WORKFLOW.md") would now be wrong. ADR 0004 was edited in place after acceptance in `e5c4f85`; acceptable while held. `docs/plans/2026-09-21-local-layer-plan.md:15` names a model; not a rules file.
- i9. `check-local.sh -h` exits 0 and `--` is not accepted as an option terminator (`-- a b` → exit 2 "not a directory: --"). Harmless.

---

## What I ran, exact results

1. **`sh tests/run.sh`** (`/bin/sh` is dash): exit **0**.
   `# passed 89` (check_local_test) · `# passed 88` (dead_words_vectors_test; `# vectors run: 20 ok, 22 error, 2 ignore (44 total)`) · `# passed 31` (mutation_test) · `# passed 94` (rules_text_test) · `# passed 17` (rules_text_mutation_test) · `all suites passed`. `bash tests/run.sh` also 0 with the same counts, but `run.sh` calls each suite through `sh`, so that was dash again. Separately, `bash --posix tests/{check_local,dead_words_vectors,rules_text}_test.sh`: 89 / 88 / 94 passed.
2. **About 130 hand inputs to `check-local.sh`** in `/tmp/mrA/w/`. Everything below exited as it should (stale → 1, malformed → 2, good → 0) **except** the rows in B1, m4 and m5:
   - **Local files:** empty `LOCAL.md` → 0; only `LOCAL_dev.md`, stale → 1; both files with errors in each → 2 (stale also reported); a symlink to a stale file → 1; a directory → "nothing customized"; a dangling symlink → same; a FIFO → 0 without hanging; unreadable → **0 (B1)**.
   - **Named files:** directory → 2; a symlink to a real playbook file → 0; missing → 2; a dangling symlink → 2; an empty file → 1; `CLAUDE.md` with and without the third argument → 0; a missing third argument → 2; missing at the default place → 2.
   - **Names:** with `/`, `\`, `..`, `.`, a leading `-`, a space → 2; glob characters `*.md`, `?`, `[A]` → 2 in a directory without a matching file, **0 when the current directory has a matching file (m4)**.
   - **Quoted words:** `*`, `[`, `\`, `$HOME`, `"`, a leading `-`, `-e`, `--`, a tab, a non-UTF-8 byte, `.` → literal (fixed string), correct; empty span → 2.
   - **Format:** a final line with no newline; CRLF throughout (1 and 0 correctly); nested fences (4-tick around 3-tick, tilde around backtick, backtick around tilde, trailing spaces, an info string, indentation) → correct; an unclosed fence → 2; a fence indented 7 spaces → 2 (fails closed).
   - **Marker in context:** in a code span → prose; mid-line, after `- `, after `> `, in a single-line HTML comment, after a numbered-list prefix, after a BOM, after a non-breaking space → 2; inside a multi-line HTML comment → checked, 1; two marker lines → two reports; trailing prose, `..`, a trailing ` ·` → 2; a single closing `.` → allowed.
   - **Arguments:** rules dir with a trailing slash, relative paths, `./`, a local dir starting with `-` → all work; `--` → 2; 0, 1, 4 arguments → 2; `-h` → 0; an empty-string directory → 2; both directories the same → 0 "nothing customized".
3. **36 mutants of `check-local.sh`** (B4). **18 mutants of the repo** run through the whole `sh tests/run.sh`, and 5 wording mutants (W1–W5) (m1, m2).
4. **Templates** (item 5 of the brief): checker over a directory holding both templates as shipped → `0 search(es), 0 stale, 0 error(s)`, exit 0. The `paths:` blocks are byte-identical (see B3). **The ruling is met for Dead-words lines and not met for the Fill (B3).**
5. **Propagation** (item 7). Against the base, `git diff --numstat` shows **0 deleted lines** in `CHANGELOG.md`, and nothing changed in ADRs 0001–0003, `docs/guides/non-blocking-review-pipeline.md`, `docs/reports/*` or `docs/assets/*`. Files outside the plan's task list that changed: `docs/ANNOUNCE.md`, `docs/index.html` (task 1 allows the dataset; its eyebrow also moved to v0.1.16) and `docs/adr/0004…` (new). Version string 0.1.16 is correct in `VERSION`, `CLAUDE.md:13`, `README.md:282-286`, `docs/index.html:290`; templates carry the `<VERSION>` placeholder. Markdown link check over the whole tree: **0 broken**. `docs/index.html`'s script extracted and `node --check` → parses. Changelog arithmetic 89+88+94+31+17 = 319 ✓; 44 vectors ✓ (`grep -vc '^#\|^$'`). Plan tasks 1, 2 and 5 meet their done-when, except the stale numbers in m6; task 3 fails on B3; task 4 on B2 and m3.
6. **Portability** (item 8). No `[[`, `local`, `echo -e`, `==`, arrays, `$'…'`, `sed -i` or GNU-only flag in `scripts/check-local.sh`; it runs under dash and bash. Tests use `find`, `awk`, `sed`, `cut`, `cmp`, `head -5` (all POSIX) plus `sha256sum` with `shasum` and `openssl` fallbacks and `mktemp` with a fallback. The exception is `wc -l` padding (m8).

## What I could not verify

- That each assertion "was seen to fail first": no history of the red runs exists in the repository.
- macOS/BSD `grep`, BSD `wc`, and `busybox ash`: not available here (BACKLOG says the same).
- B1 with `id -u` = 0: root can read a mode-000 file, so the fixture needs a non-root user; I ran as uid 1000.
- Whether the owner's real `~/.claude/rules/LOCAL.md` passes: I did not read it (the brief forbids it). The BACKLOG claim of nine searches and two refusals is unchecked.
- That the vectors file is byte-identical to `codex-playbook`'s copy: that repository is not here.
- How GitHub renders `&lt;VERSION&gt;` in `BACKLOG.md:46-47`, and how `docs/index.html` looks in a browser (syntax only).
