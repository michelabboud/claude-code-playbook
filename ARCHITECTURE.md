# Architecture

This is a documentation bundle, not a program. Its structure is the design.

## The layering, and the one property that matters

```
CLAUDE.md                 the Mantra + the section index        (always loaded)
  └── rules/AUTHORITY.md  §0 precedence · classification ·      (always loaded)
                             THE APPROVAL TABLE · critical rules
        └── rules/*.md    §1–§12 subject files                  (trigger-loaded)
              └── rules/platform/<os>.md   §11 OS specifics     (read by path)
```

**A subject file carries procedure, never new authority.** The approval table in
`AUTHORITY.md` is the complete list of things that need the owner's OK. Nothing
below it may add a gate — not a subject file, not a skill, not a harness default,
not a subagent.

That single property is load-bearing. Without it, every file added to the bundle
is a potential new reason to stop and ask, and a rulebook that grows new gates as
it grows pages becomes bureaucracy. With it, the bundle can be extended
indefinitely and the cost of asking stays fixed.

## Why the rules are split across files

The bundle started as one document and outgrew it. Splitting achieves two things
a single file cannot:

1. **Conditional loading.** Six files (`CODE`, `TESTING`, `REVIEWS`, `WORKFLOW`,
   `SUBAGENTS`, `ROSTER`) carry a `paths:` scope and enter context only when source files
   are touched. A session that never opens code shouldn't pay for development
   detail.
2. **Stable numbering.** Rules are numbered `<section>.<rule>`, so adding a rule
   never renumbers its neighbours and cross-references stay valid.

## Why the platform split exists

Rules state intent; platform files state commands. Listing a port, measuring host
load, hashing a file, and creating a private directory are spelled differently on
Linux, macOS and Windows — and several commands present on one are simply absent
on another.

Inlining one OS's command into a rule quietly makes the rule wrong on the other
two, and the failure is silent: a safety check that cannot run is a safety check
that stops checking. Keeping commands in one file per OS makes that impossible,
and makes it obvious which file a contributor must update.
