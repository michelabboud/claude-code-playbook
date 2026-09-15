# Announcing it to a team

A message you can paste into Slack, Teams or email. Edit the first line so it
sounds like you — the rest is deliberately plain.

---

**A rulebook for working with Claude Code — take it or leave it**

I've been keeping a written set of rules for how I work with Claude Code: what it
may do without asking, what it must bring to me, how code and tests are held to a
standard, when a review happens. I've cleaned it up so anyone can install it.

**Look before you install:** https://nice-michel.github.io/claude-code-playbook/
Thirteen sections, forty-nine rules, click through them. Two minutes tells you
whether you want it.

**Repo:** https://github.com/nice-michel/claude-code-playbook

**The easy way** — open the repo in Claude Code and say *"install this"*. It reads
`INSTALL.md`, which is written to be executed: it backs up anything you already
have, copies only the platform file for your OS, and asks you for your git email.

**By hand**, if you prefer (swap `MACOS.md` for `LINUX.md` or `WINDOWS.md`):

```bash
git clone https://github.com/nice-michel/claude-code-playbook.git
cd claude-code-playbook
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.backup-$(date +%F)   # if you already have one
cp CLAUDE.md ~/.claude/
mkdir -p ~/.claude/rules/platform
cp rules/*.md ~/.claude/rules/
cp rules/platform/MACOS.md ~/.claude/rules/platform/
```

**Three things to know:**

1. **It replaces `~/.claude/CLAUDE.md`.** If you have one, back it up — the first
   command above does that.
2. **Edit one line:** `~/.claude/rules/WORKFLOW.md` has a placeholder for your git
   email. It is the only required edit, and it is yours, not shared.
3. **Start a fresh session afterwards.** An open session has already loaded the
   old file.

**It is a resource, not a policy.** Nothing here is mandated by anyone. Take it
whole, take one section, or take the idea and write your own — the approval
table, the review cadence and the close-out chain each stand alone. It is written
in the first person and *you* are the "I", so it only works if you actually agree
with it. Disagree with a rule? Change it; it is yours once installed.

---

## Two notes for whoever sends it

**Lead with the visual map, not the repo.** Most people will not clone something
to evaluate it. The hosted page renders in a browser in seconds and shows the
whole shape.

**Say the bit about platform files.** The commands for checking a port or
measuring host load genuinely differ per operating system, which is why only one
file is installed. Someone who copies all three "to be safe" ends up with a
rulebook carrying three contradictory answers — the exact thing the split exists
to prevent.

**Send it to one person first** and watch where they get stuck. That is the
cheapest way to find the next gap in `INSTALL.md` — installing it on a real
machine is what found the platform-index defect fixed in v0.1.7.
