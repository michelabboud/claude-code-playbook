# Visual rule map alignment — 2026-09-23

This is a documentation correction to the published 0.1.16 rule text. It does not change managed rules, the installer, or `checkpoint/0.1.16`.

The map now distinguishes leaving uncertain user material alone from quarantining it when it blocks work; states the plan's task and communication records; describes post-close-out context hygiene and next-task continuity; and shows the approved-plan subagent mode with a link to the conditional communication and Herdr guide.

Read-only mechanical review of the four changed entries against `checkpoint/0.1.16`: **PASS**, no blocking findings. The reviewer checked `rules/AUTHORITY.md`, `rules/COLLABORATION.md`, `rules/SUBAGENTS.md`, `CLAUDE.md`, and the communication guide. Inline JavaScript syntax and `git diff --check` passed. `bash tests/run.sh` exited 0 with all six suites passing (207, 93, 53, 147, 40, and 267 assertions).
