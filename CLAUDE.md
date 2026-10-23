# skogai2/cli

A ground-up rework of the skogai cli. Nothing here is carried over; every
piece is rebuilt from its intent.

## the clean-room rule

Do not read, search, or copy the old implementation. That includes its
source, its docs, its tests, and its git history. The old version was the
result of copying forward; this repo exists to stop doing that.

If you think you need something from the old version, stop and ask. The
answer is almost always to describe the *intent* behind it together, write
that down here, and build from the description.

Allowed sources of truth, in order:

1. what the user says in conversation
2. this file and the documents it points to
3. the code in this repo

## how we work

- Intentions before implementation. A feature is not built until its
  intent is written in the roadmap below and agreed on.
- Describe concepts, not mechanisms. An intent says *what* and *why*, not
  which tool, file layout, or library does it.
- Trust existing systems. Where a system already solves something
  (pacman for installs and versions, git for history), use it instead of
  reinventing the wheel.
- Small steps. Each roadmap item should be buildable and checkable on its
  own.
- `tmp/` is throwaway scratch space and is gitignored.

- Write it down as we talk. Whatever we settle in conversation goes into
  the sections below right away, in short form, so the broad basics can be
  reviewed at a glance.

## intentions

What the cli is for, in the user's words. Filled in together; empty until
agreed.

- A modular framework, combined mainly from two parts: a command runner
  and settings via key-value lookups.

## the core question

What this project tries to answer that most similar solutions do not:

> How do we manage ai agents working in sandboxes with only a project repo
> checked out, and the problems that come with it?

Problems as first described (a starting list, not yet agreed):

- Only the local scope exists. A sandbox has no `/etc/skogai` and no
  user xdg config, so system and global settings are missing.
  Partly answered: the repo carries a snapshot of the base state (see
  concepts), so defaults are always present.
- Env is the only way in from outside. Anything not in the repo has to
  arrive through environment variables.
- Secrets cannot live in the repo, yet the repo is all the agent has.
- Tools the user has installed may not exist in the sandbox.
- Work done in the sandbox, beyond commits, is lost when it ends.
- The same repo should behave the same on the user's machine and in a
  sandbox, even though the layers around it differ.

## concepts

The ideas the cli is built around. One line each: name - what it means.

- skogai - the project name; used for every settings location below.
- modular - the framework is made of separate parts that combine, not one
  monolith.
- command runner - the part that runs commands.
- settings - configuration, read through key-value lookups.
- scopes - settings come in layers following classic linux rules:
  system, global, local, env. Each layer overrides the one before it, so
  the most specific wins.
  - system - machine-wide, `/etc/skogai`. The base case: the default
    values everything else is applied on top of.
  - global - per user, the xdg layer (`$XDG_CONFIG_HOME/skogai`).
  - local - per project, `.skogai` in the project.
  - env - the current process, environment variables.
- state as diff - state is thought of functionally, like a git diff that
  gets applied. Each scope is a diff applied on top of the one before it.
- every key has a default - no key-value exists without a base value, so
  a lookup always has an answer.
- base snapshot - each repo carries a copy of the base state as it was at
  a point in time: the last clone, update, or sync of that repo.

## tools

What the cli uses or works with, and why. One line each: tool - its role.

- pacman - installs skogai as a versioned package, to try a more versioned
  workflow. New to the user; an experiment. The package owns
  `/etc/skogai`, so the base case (system defaults) arrives and updates
  as a package version.

Open thought (not agreed): a repo's base snapshot could record which
package version it was taken from, so "base state at a point in time" has
a name.

## open questions

Questions config-first forces us to answer. Pros and cons are a first
take, not agreed.

### should `.skogai/src` apply the install on a repo level?

That is, the repo carries skogai itself, not only settings.

- pro: answers the core question directly; a sandbox with only the repo
  still has skogai.
- pro: the version is pinned per repo, so the repo behaves the same
  everywhere.
- pro: fits the base snapshot; the install becomes part of the state at
  a point in time.
- con: every repo carries a copy; duplication and repo size.
- con: repos drift from the pacman-installed version; which one runs when
  both exist?
- con: updates happen per repo instead of once per machine.

Leaning (agreed in direction): the repo-level install is the local layer
of the install, applied over the system install like any other scope, so
the scope rule decides which runs. How pacman handles this is to be found
out, not reinvented. Known so far: pacman installs to one root with one
database by default, but can target another root and database, which
could make a repo-level install a pacman install too.

### upgrades are manual and local (decided, for now)

Upgrading a repo's install is done by hand, on the user's machine or an
arch base, never inside a sandbox.

- why: modules (see modular) can be one-time per repo, and each update
  likely carries choices that should be looked over anyway.
- consequence: a sandbox never needs pacman. It only uses what the last
  upgrade committed into the repo, which is the base snapshot.
- not ideal: in a perfect world upgrades would not need a human. Accepted
  to start; to be revisited later.

### first assumptions for phase 0 (claude's, not agreed)

- tooling - arch, git, pacman/makepkg; scripts in bash, not fish, so they
  run anywhere; shellcheck.
- language - bash for phase 1: the only runtime a bare sandbox is sure to
  have. Revisit if settings outgrow it.
- format - git-config format, read with `git config --file`: an existing,
  tested key-value lookup available wherever git is. Line-based, so the
  git diff is the state diff.
- keys - lowercase, dotted (`section.key`). Env is `SKOGAI_` + uppercase
  with `.` as `_`. Watch: clashes if `_` is also a relation in names.
- base snapshot - `.skogai/base/`, a frozen copy of `/etc/skogai` plus
  the package version it came from. Upgrade = refresh it and commit; the
  diff is what gets reviewed.
- done - tests that run with only the repo (bats, against a fake root),
  help text, and a line in this file.

## roadmap

Each phase lists the intent it serves and how we know it is done.

### phase 0 - foundation

- [x] empty repo, clean-room rule written down
- [x] intentions above described and agreed (broad basics)
- [ ] general tooling and preferences written down
- [ ] choose language/runtime from the intentions, not from habit
- [ ] settings file format (prefer an existing one)
- [ ] key naming, and how a key maps to an env variable
- [ ] where the base snapshot lives in `.skogai`
- [ ] decide what "done" means (tests, docs, help text)

### phase 1 - settings

Settings alone are a starting point on their own. Starting with config
only is deliberate: it forces the questions about how things are applied
to be answered before commands or bigger ideas are built on top. See open
questions.

- [ ] key-value lookup across system, global, local, env
- [ ] every key has a default from the system layer
- [ ] a repo carries its base snapshot
- [ ] installed as a pacman package that owns `/etc/skogai`

### later

- _(captured as intentions surface; not planned until phase 1 is done)_
