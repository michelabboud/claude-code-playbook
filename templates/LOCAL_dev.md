---
paths:
  - "**/*.{rs,py,ts,tsx,js,jsx,mjs,cjs,go,java,kt,swift,c,cc,cpp,h,hpp,cs,rb,php,sh,bash,sql}"
  - "**/Cargo.toml"
  - "**/package.json"
  - "**/pyproject.toml"
  - "**/go.mod"
  - "**/Dockerfile"
  - "**/Makefile"
  - "**/VERSION"
  - "**/CHANGELOG.md"
  - ".github/workflows/**"
---
# LOCAL_dev · my local layer for the source-scoped sections — loads with them

*This file is mine, not the playbook's: the playbook never ships it, and an update never writes to, copies over or replaces it — it is read only to check it. It carries my entries for sections 1, 2, 3, 6, 8 and the roster, and it has the same `paths:` scope as those files, so it arrives when they do. When you read one of them by path, read this file too.*

*The three kinds of entry — **Fill**, **Add**, **Override** with its `**Dead words:**` line — and the force they have are defined at the top of `LOCAL.md` and in section 0 ("The local layer"). Read that file first; this one does not repeat the grammar. Note how the marker is written here: **inside a code span**, because the bare marker anywhere but the start of a line is an error rather than a silently skipped entry.*

*Written against **playbook <VERSION>** — fill in the number on the `This rulebook is version` line of `CLAUDE.md`, so a later reader knows what this file was checked against.*

---

## Why this file is separate

The playbook scopes six of its files — `CODE`, `TESTING`, `REVIEWS`,
`WORKFLOW`, `SUBAGENTS`, `ROSTER` — to source work, so a session that never
opens a source file does not pay for development and review detail. Most of a
heavy customizer's entries are about exactly those sections. Putting them in
`LOCAL.md` would load all of it in every session and throw that property away.

**The frontmatter above must stay byte-identical to the `paths:` block in those
six files.** If it drifts, this file arrives at different moments than the rules
it modifies, and an entry can be missing precisely when its rule is being read.
The playbook's `tests/rules_text_test.sh` checks that.

If you have no entries for these sections, delete this file. A local file that
is absent means nothing is customized.

## Worked example — delete it once you have your own

An **Override** of a scoped rule, with the line `scripts/check-local.sh` reads:

```
- **Override — rule 8.1, the Top tier never runs a dev lane.** The Top tier is
  reserved for planning and review, so the hard domains — security, concurrency,
  Rust, unsafe code — start on the **Strong** tier, and the dev escalation ladder
  is Fast → Standard → Strong and ends there. Written against 0.1.16.
  **Dead words:** `start on the Top tier` (in `SUBAGENTS.md`)
```

---

# The entries

## 1 · Code

## 2 · Testing & verification

## 3 · Code reviews

## 6 · Task & phase workflow

## 8 · Subagents & model tiering

## The roster
