---
name: dev-mode
description: Show or change this project's dev mode (spike, poc, mvp, production, sensitive), which sets how much code review runs and which security findings stop the line; start a hardening phase. Owner-invoked only.
argument-hint: "[status | spike | poc | mvp | production | sensitive | harden]"
disable-model-invocation: true
---

# /dev-mode — the project's dev mode

The rules are section 14, `~/.claude/rules/DEV_MODES.md`. **Read it by path
first, every time.** This skill only carries out what I asked for; it adds no
gate and no authority of its own. Only I invoke it, which is what makes a mode
change "my word" (rule 14.1).

The argument is: `$ARGUMENTS`

## No argument, or `status`

1. Find the project's `CLAUDE.md` (the repository root of the current working
   directory) and its `Dev mode:` line. Read-only.
2. Report, in plain words:
   - the mode, and whether it was declared or is the rule 14.1 default (say
     which default and why);
   - what that mode means here: its row of the review table (rule 14.2) and
     what stops the line;
   - whether the data minimum applies — if the project visibly holds real
     personal, financial or health data while its line says less than
     `sensitive`, say so plainly;
   - from `docs/security/backlog.md` and `docs/security/backlog.local.md`, if
     either exists: open entries by `due`, and how many are due at the next
     mode up.
3. Change nothing.

## A mode: `spike`, `poc`, `mvp`, `production`, `sensitive`

1. Reject anything else, naming the five modes.
2. **Lowering below the data minimum is refused** (rule 14.1): if the project
   holds real personal, financial or health data, a mode below `sensitive` is
   not set — say why, and stop. If you cannot tell, ask me that one question.
3. Write `Dev mode: <mode>` into the project's `CLAUDE.md`, replacing the
   existing line or adding one directly under its first heading; create the
   file with that line if it does not exist. Update the `Dev mode:` line of the
   running plan's header in `PLAN.md` (or the plan file it indexes) if there is
   one. Touch nothing else.
4. **Moving up** (rule 14.6): this is my go for the hardening plan. Hand it to
   the planner (rule 8.1): every backlog entry due at the new mode, plus any I
   named. Then say what the move costs: the entries due, and the review row
   that now applies.
5. **Moving down** within what the data allows: say which reviews stop running
   and which findings stop blocking from now on. Nothing already recorded in the
   backlog is removed.
6. Report the old mode, the new mode, and the files changed. The change lands
   in the next commit of the normal task chain (rule 6.1); it needs no version
   bump of its own.

## `harden`

Valid only in `production` or `sensitive`; otherwise say so and stop. This is my
go for the extra-hardening phase (rule 14.7): hand the planner every entry due at
`hardening`, to run as its own phase on its own line beside feature work, under
the production row's reviews. Report how many entries it covers.
