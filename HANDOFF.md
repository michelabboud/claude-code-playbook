# Handoff

**Current:** v0.1.16 is **built, repaired and held**. The five tasks of the
local-layer plan are complete, the mechanical review's four blocking findings and
its eight minor ones are fixed, and the tests pass; nothing is published until the
batch's deep review is ruled, and the deep review of `scripts/check-local.sh` —
the risk-class task — is owed at task grain as well.

**What the fix round changed** (uncommitted in a worktree at the time of writing;
the report is `LANE-A3-REPORT.md`): an Override with no valid `**Dead words:**`
line is now exit 2, which is what makes a mistyped marker a refusal instead of a
silent pass; a local file that exists and cannot be read as a regular file is exit
2, not "nothing is customized"; a Dead-words line has a 4,096-byte bound; a file
name may carry no glob character and nothing is ever glob-expanded; the templates
ship no live entry; `INSTALL.md` asks before it copies, stages the new version
before the migration check, never copies a template over an existing local file,
and exempts the local files from the uninstall restore; and "never opens them" is
gone everywhere — the check script does open them, to read.

What 0.1.16 does: "make it yours" stopped meaning "edit the installed files".
Customizations live in `rules/LOCAL.md` and `rules/LOCAL_dev.md`, two files this
repository never ships, and that an update never writes to, copies over or
replaces. Section 0 says in one sentence
that an entry there wins over the playbook's wording — a sentence rather than a
reading order, because the harness loads `rules/` in no promised order. An entry
is a **Fill**, an **Add**, or an **Override** that quotes the dead words it
replaces, so `scripts/check-local.sh` can prove mechanically that it still bites
before an update copies anything. Decision: `docs/adr/0004-the-local-layer.md`;
guide: `docs/guides/local-layer.md`.

**Verify with:** `sh tests/run.sh` — five suites, 480 assertions, two of them
mutation harnesses over the other three.

**After publication**, the acceptance test is the script itself: run
`check-local.sh` against the owner's own local files and the published rules
(must exit 0), and confirm his installed playbook files are byte-identical to
the tag.

Where we are otherwise: the bundle is installable and swept clean of private
references. The macOS platform file is verified on real hardware; Linux and
Windows are written but unexecuted (see `BACKLOG.md`). No installed file needs
editing any more — the git identity is a Fill in the user's own `LOCAL.md`, and
the one file worth checking against their own setup is the model roster,
`rules/ROSTER.md`.

v0.1.13 made reviews non-blocking (rules 3.3 and 3.5, ADR 0001) and moved every
model name into `rules/ROSTER.md`. v0.1.14 corrected rule 3.5's accounting the
same day, after an independent review of the Codex port plan (ADR 0002); v0.1.15
corrected it again after the deep review of the finished port (ADR 0003).

**How this repository is worked (the owner's word, 2026-09-20):** every update
goes straight to `main` — no feature branches — and each task's commit gets a
`checkpoint/<VERSION>` tag, pushed. `checkpoint/0.1.13` is the first one.

The repository carries one branch, `main`, tracking `origin/main`. Before 0.1.9
the published branch was a local branch named `shipping` and the local `main`
was an unrelated abandoned root; they are now joined by a merge commit.
