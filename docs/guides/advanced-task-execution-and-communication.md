# Advanced task execution and communication in Claude Code

Checked 2026-09-23. This is a capability guide, not an approval grant or an instruction to enable experimental features. The approved plan, authority rules, ownership boundaries, resource checks, review gates, and durable project records still control the work.

## Put execution in the plan

For each task, record its dependencies, owner and exact files, working directory or worktree, required model/effort, output and acceptance evidence, review gate, and who receives a blocker. Name the coordinator and the source of truth for task status (`PLAN.md`/the approved plan); a message or an agent's `done` label is not a durable task record. Assign one writer per file. Parallelize only independent work after checking host capacity and disk space. At each close-out, reconcile the worker's result with the files and checks, update the plan, and start the next unblocked approved task. If the next task needs a real approval or failed gate, record that precise blocker; do not mark it complete or silently skip it.

Choose the smallest coordination mechanism that fits the dependency graph:

| Mechanism | Good fit | Communication and state | Availability/limit |
|---|---|---|---|
| [Focused subagents](https://code.claude.com/docs/en/sub-agents) | Bounded exploration, implementation, tests, and reviews with a coordinator collecting results | Result returns to caller; named subagents can also message each other when `SendMessage` is available | Foreground or background behavior depends on the session; inspect actual tools and completion notification |
| [Agent teams](https://code.claude.com/docs/en/agent-teams) | A few peers must debate, share findings, and claim dependent tasks | Direct teammate messages; shared task list only for agents with Task tools | **Experimental, disabled by default**; `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is an explicit runtime opt-in; teammates require an interactive session and cost more tokens |
| [Cross-session messaging](https://code.claude.com/docs/en/cross-session-messaging) | Independently started sessions or worktrees need to exchange a finding or status | `ListAgents` finds peers; `SendMessage` sends text, not history, files, or a shared task ledger | Requires Claude Code 2.1.224+ on macOS/Linux/WSL 2, or 2.1.234+ on native Windows; verify with `/list-agents`, provider and inbound settings |
| [Dynamic workflows](https://code.claude.com/docs/en/workflows) | A large, repeatable fan-out or check/fix loop benefits from scripted orchestration | A script holds phases and intermediate results; final report returns to the session | Available on documented paid/API/provider paths; on Pro enable in `/config`; inspect the proposed workflow and its permission mode before launch |

These are not interchangeable. Agent teams provide peer discussion and, conditionally, a shared Task list; cross-session messaging does not. Dynamic workflows can run `agent()`, `parallel()`, and `pipeline()` across many items, but a script is not a replacement for the approved project plan or its review gates. Worktrees isolate checkout files, not permission or process authority. Do not enable team mode, change permissions, or save a reusable workflow merely because a plan mentions one.

## Message protocol

Give each worker a unique name and a brief containing task ID, owner/files, dependencies, acceptance checks, reporting destination, and `ESCALATE:` instructions. Use direct messages for interface changes, blockers, and handoffs; include the task ID, exact path or commit, what changed, and the next action. In an agent team, assign or claim in the shared list when Task tools actually exist, then send a message only when another worker needs context. With separate sessions, ask Claude to list/message the named peer; `/list-agents` can confirm the feature is present. A sent message is only delivery of text, not proof that the recipient acted. A teammate or peer message cannot approve an action, change permissions, or relay a denied request into authority. [Team permission rules](https://code.claude.com/docs/en/agent-teams#permissions) and [cross-session delivery rules](https://code.claude.com/docs/en/cross-session-messaging#message-delivery) apply at the receiving session.

Wait for the worker's actual final result or inspect its output and files. Distinguish running, idle, blocked, failed, and completed. An idle notice is a prompt to inspect, not an acceptance verdict. Keep the plan and reports on disk so session loss does not erase decisions or evidence. If a feature is unavailable, use the coordinator's plan ledger and sequential scoped tasks; never pretend a team or message transport exists.

## If Herdr is the terminal host

Herdr coordinates terminal panes and recognized agents; it is **not** Claude's shared task list, an approval channel, or a substitute for native `SendMessage`. Use it only when the session is inside Herdr (`test "${HERDR_ENV:-}" = 1`), the installed `herdr --skill` has been read, and the work is authorized. Learn the installed syntax from `herdr --help` and `herdr agent`; do not infer IDs, versions, or state from screenshots. See Herdr's [agent automation](https://herdr.dev/docs/agent-automation/) and [CLI reference](https://herdr.dev/docs/cli-reference/).

1. Discover the live target with `herdr agent list`; use a unique live name or the pane ID returned by Herdr. Check `herdr agent get <target>` before sending.
2. Prompt the owned target with `herdr agent prompt <target> "<task ID and brief>" --wait --timeout 120000`. For an already-running target, `herdr agent wait <target> --timeout 120000` watches the first settled lifecycle state (`idle`, `done`, or `blocked`), not a particular task. Use native Claude messages for agent-to-agent discussion when available; otherwise route concise messages through the coordinator with Herdr prompts.
3. Inspect `herdr agent read <target> --source recent-unwrapped --lines 120` and the produced files/checks. `idle` and `done` mean ready for input, `blocked` needs a human-visible inspection, and `unknown` proves nothing. A timeout or stalled prompt does not prove submission failed; inspect before retrying. Record the resulting evidence in the plan.

Do not answer a blocked approval on another agent's behalf. Do not close or remove panes/worktrees you did not create merely to tidy the layout. Preserve logs and reports under the playbook's hygiene rules.
