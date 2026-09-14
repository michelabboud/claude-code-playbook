# Optional tools

**No rule in this bundle depends on any tool listed here.** The rule is the law,
a tool is an accelerator, and the hand procedure in the rule file is always
present and always sufficient. Install none of these and nothing breaks.

They are listed because a procedure done by hand a hundred times is a procedure
that eventually gets done wrong, and because you should know these exist before
you build your own.

---

## A quarantine helper

**What it would do:** the file half of `rules/QUARANTINE.md` §2 — validate first
and alone, move by rename, write the manifest in the documented format, append
the index line under a lock.

**Why it helps:** the procedure is five steps that must happen in a specific
order, two of which must be their own isolated operation. That is exactly the
kind of sequence a tool should own so judgment doesn't have to compete with
bookkeeping.

**What stays yours either way:** WHETHER to quarantine, and the honest one-line
`reason`. A tool that decides those for you is the wrong tool.

**The contract if you build or adopt one:** a manifest it writes and a manifest
written by hand must be interchangeable, and a hand move between the state
directories must remain a first-class way to drive it. Final deletion must still
refuse without explicit approval. If it can't honor those, use the hand
procedure.

---

## A dispatcher for coding CLIs

**What it would do:** run a configured coding CLI under a named profile that
declares what the run is allowed to do — model or tier, permission mode, budget
ceilings, data-handling policy — and refuse any shape it cannot enforce.

**Why it helps:** rule 8.1 asks you to pick a tier, cap concurrency by measured
host load, and keep a model floor. Done by hand that is a convention; done by a
dispatcher that enforces a declared policy, it is a control. The difference
shows up the first time a subagent is dispatched with a wider permission set
than anyone intended.

**The distinction that matters, and it catches people out:** an isolated working
directory is not a sandbox. A worktree isolates *files in one repository*. A
process sandbox limits *what the process can do*. A policy limits *the shape of
the run*. They are three different controls and only the ones actually
implemented for your setup are real. Never describe one as another.

**If you use one:** discovery commands that list profiles and check health must
not submit a prompt. A refusal before dispatch is the tool working, not an error
to route around — inspect the profile and change the configuration deliberately,
never copy a profile name from another machine and hope.

---

## The general rule for adding one

Rule 1.5 applies to a tool you adopt exactly as it applies to a dependency you
add: confirm the current stable version, check advisories and real maintenance,
compare alternatives, prefer free and open source, and write down why this one
won. A tool that silently becomes load-bearing is a dependency nobody vetted.
