# 0010 — Authenticate playbook checkouts before mutation

## Context

The install guide treats a local tag and `git status --porcelain` as evidence
that a staged checkout is the release the owner installed. Neither is a trust
anchor: a local tag can be forged, and Git can hide tracked edits marked
`assume-unchanged` or `skip-worktree`. The uninstall procedure also executes
the checkout's checker before establishing the checkout's provenance. Update
and migration accept linked destination roots that uninstall refuses.

The owner approved a canonical published source as the default, with a fork
usable only when the owner explicitly supplies its full commit ID. An offline
or unverifiable source must not mutate the installation.

## Decision

Before running staged code, copying a managed file, restoring a backup, or
deleting a managed file, the guide authenticates the staged checkout. By
default, it resolves `checkpoint/<VERSION>` from the canonical public GitHub
repository over HTTPS, compares the remote tag object with the local tag
object, and requires the checkout's HEAD to be the tag's commit. The only
alternative is a full commit ID supplied explicitly by the owner in the
conversation; a checkout, its local tag, and its remote configuration cannot
nominate their own exception.

Every source file used by the procedure must be a regular, non-symlink file
whose literal working-tree bytes match the corresponding authenticated Git
blob. This includes the checker before it is executed and every managed file
before it is copied or used as a deletion baseline. Neither `git status` nor
index flags are proof of those bytes. The guide reruns the checks immediately
before mutation and refuses changes or unavailable verification without
modifying the destination. Existing owner files and backups remain preserved.

First install, update, migration, and both uninstall paths refuse a symlinked
configuration, rules, or platform root before any destination write or delete.
The guide also requires quiescence: these manual preflights do not make a
concurrent filesystem change atomic.

## Alternatives rejected (and why)

- Trust a clean local tag and status: both can be manufactured or can miss
  altered bytes, so they cannot prove the source of a destructive operation.
- Execute the checkout's verifier to verify itself: this runs attacker-controlled
  code before authentication.
- Accept any configured `origin`: a fork or rewritten remote would silently
  become authority without the owner's decision.
- Fetch individual files without commit binding: the bundle could mix versions
  or be incomplete.

## Consequences

Offline, unverifiable, or unpinned-fork operations refuse; the owner retains
the current installation and must provide a verifiable source or explicitly
approve a fork commit. Literal-byte comparison can reject a checkout whose
line endings were rewritten by local tooling; the safe recovery is to obtain
a clean checkout with the published line endings, not to waive the check.
The procedure trusts the canonical repository owner and HTTPS transport; it
does not claim signed-release verification or protection against a malicious
instruction file read before this preflight. Every actual copy/delete still
needs its existing backup, local-layer, and content checks.

## Status

Accepted 2026-09-23 by the owner; implementation and independent re-review
pending.
