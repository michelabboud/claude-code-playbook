# Independent cold-read note — 2026-09-23

Input: frozen commit `b2fd2553d4bad4786d7e817c1c2c28a39cfae5bc`, parent `c0bd8795aaffc4d790025dab76e5d1c5bbd8da27`, in `/home/michel/projects/claude-code-playbook`. I read the pinned Git diff and `INSTALL.md` and test code from Git objects. I have not read `docs/reviews/*` or a prior adjudication. This process is a child of the coordinator and is not blind to the task brief; runtime model identity is not exposed here.

Initial assessment:

- `destination_root_preflight` at `INSTALL.md:263-333` now runs `find / -prune -links +1 -print` before walking components or inspecting managed paths. Standard `find` evaluates the predicate on `/` and `-prune` prevents descent, so an unsupported `-links` should return nonzero for both empty and existing destinations. The command itself is read-only.
- The new regression at `tests/install_preflight_test.sh:482-497` simulates unsupported `-links` for a nonexistent configuration root and verifies guard exit 2 and absence of a continuation marker. It does not directly exercise unsupported `-links` with an existing destination, record whether `/` was traversed, or check bytes in that new case. Existing linked-file cases separately check preserved external bytes.
- Windows prose at `INSTALL.md:36-45` distinguishes Git Bash or MSYS2 from WSL and tells the operator to resolve the Windows profile to a POSIX absolute path. Step 0 names the target OS; the copy step uses that selected OS. I noticed the uninstall guard at `INSTALL.md:838-842` still selects from `uname`; this predates this commit and may refuse a Windows target from WSL. Need assess whether that is only a documented unsupported workflow.
- The guide asks for quiescent source and destination at `INSTALL.md:361-364`, with rechecks before copy. This is a manual requirement, not a lock. I will test the predicate behavior and suite from an archived snapshot, then compare prior reviews.
