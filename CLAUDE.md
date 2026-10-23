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
  the most specific wins. The paths below are where each scope lives on
  a real machine; by default every scope is read from inside `.skogai`.
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
  a point in time: the last clone, update, or sync of that repo. It lives
  in `.skogai/base/`, which holds defaults only, never runtime values.

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

### phase 0 decisions

Agreed overall, from claude's first assumptions and the user's answers.

- tooling - arch, git, pacman/makepkg; scripts in bash, not fish, so they
  run anywhere; shellcheck.
- language - bash.
- format - git-config format, read with `git config --file`. Worked fine
  in the last test version. Line-based, so the git diff is the state diff.
- types - int, bool, path, string; enough for settings. Richer types come
  at the command-runner stage.
- keys - lowercase, dotted (`section.key`). Env is `SKOGAI_` + uppercase
  with `.` as `_`. Watch: clashes if `_` is also a relation in names.
- locations are settings - where each scope is read from is itself a
  setting with a default inside the repo's `.skogai`; the machine
  overrides it via env, e.g. `SKOGAI_SYSTEM_CONFIG_DIR=/etc/skogai`.
  Location keys can only come from env or their default, since a file
  cannot say where files are.
- tests run against a real setup - point the location settings at a
  local folder and the whole layered setup runs there. No mocks; the test
  setup is the real one, relocated.
- done - tests that run with only the repo (bats, against a relocated
  setup), help text, and a line in this file.

### config as markdown frontmatter? (user's experiment, not decided)

The user tried `tmp/frontmatter/argc.sh` against
`.skogai/base/global.config.md`. It is extracted from the old runner, so
only its intents are recorded here, not its code.

- one file is both docs and settings: yaml frontmatter holds the keys, the
  markdown body explains them.
- a module describes itself the same way: `type`, `name`, `description`,
  `command`, `tools`, `requires`.
- each `x.md` layer has an `x.local.md` applied after it; writes go to the
  `.local.md`, never the committed file. A candidate answer to where
  runtime values live.
- a null removes a key an earlier layer set, so a layer can delete as well
  as override; a full diff, not only overrides.
- lists are one value; nested maps flatten to dotted keys.
- env names: `.` becomes `_`, `-` is dropped, `_` in a key reads as `-`.
  This answers the `_` clash noted under keys.
- every value knows which layer it came from (`--show-origin`).
- argc as the command runner, yq as the parser.

Against the git-config decision: frontmatter needs yq in the sandbox and
has richer types; git config needs only git. Not decided.

### how does `.skogai/base` track its point in time?

First assumption: a plain copy of `/etc/skogai` plus the package version
it came from. User's idea, not yet thought through: make it a git-native
reference to a SHA instead (submodule, sparse checkout, or similar), so
"base state at a point in time" is literally a commit.

- pro: the point in time is a SHA, not a version string we maintain.
- pro: upgrade = move the reference; the diff to review comes from git.
- pro: trust existing systems; git already does this.
- con: a submodule is empty unless cloned with submodules and the sandbox
  can reach the base repo. That works against the core question.
- con: the base then comes from a git repo, not from the pacman package;
  how the two relate needs an answer.
- to check: subtree-style approaches copy the content into the repo while
  still recording the SHA, which may get both.

## roadmap

Each phase lists the intent it serves and how we know it is done.

### phase 0 - foundation

- [x] empty repo, clean-room rule written down
- [x] intentions above described and agreed (broad basics)
- [x] general tooling and preferences written down
- [x] language/runtime: bash
- [x] settings file format: git config
- [x] key naming, and how a key maps to an env variable
- [ ] how `.skogai/base` tracks its point in time (can wait; see phase 1)
- [x] what "done" means

### phase 1 - settings

Settings alone are a starting point on their own. Starting with config
only is deliberate: it forces the questions about how things are applied
to be answered before commands or bigger ideas are built on top. See open
questions.

Plan, in build order:

1. [ ] skeleton - one bash entry point that answers "what is the value of
       this key", typed (int, bool, path, string). shellcheck clean.
2. [ ] location settings - one per scope, env or default only. Every
       default points inside the repo's `.skogai`, so each new setup is
       complete on the local repo side. Real machine paths are opt-in:
       on the user's machine, env overrides them (e.g.
       `SKOGAI_SYSTEM_CONFIG_DIR=/etc/skogai`) where needed.
3. [ ] layered lookup - env, then local, then global, then system; first
       hit wins. A key with no value anywhere is an error, since every key
       must have a default.
4. [ ] test setup - bats; each test points the location settings at a
       fresh local folder and runs the real lookup there.
5. [ ] package - a PKGBUILD that installs the entry point and owns
       `/etc/skogai` as config, so local edits survive upgrades.
6. [ ] base snapshot - only once the open question on tracking is
       answered; steps 1-5 do not depend on it.

Decided: all default locations are local, by necessity; a sandbox has
only the repo. In a repo the system layer is the repo's own copy.

Default locations all live under one subfolder, `.skogai/base/`. It holds
the defaults, not runtime values; everything related to defaults goes
there. Each scope is a folder holding a git-config file `config`:

- system - `.skogai/base/system`
- global - `.skogai/base/global`
- local - `.skogai/base/local`

Where runtime values live is not decided yet; see the `.local.md`
idea under open questions.

#### first milestone: simple install with tests and a few settings

Claude's draft plan, not agreed. Steps 1-5 above, made concrete.

Layout:

- `lib/settings.sh` - the lookup, as a function other bash can source.
- `bin/skogai` - thin entry point: `skogai get|set|list` (user writes
  this). The command runner replaces this dispatch later.
- `.skogai/base/{system,global,local}/config` - this repo's own defaults,
  so the repo uses itself from day one.
- `test/*.bats` - the tests.
- `PKGBUILD` (done) - builds from committed HEAD only; version is
  `r<commit count>.<short sha>`. Installs `bin/*` to `/usr/bin`, `lib/*`
  to `/usr/lib/skogai/`, and the system defaults as `/etc/skogai/config`,
  listed as backup so edits survive. Note: `bin/skogai` must find its lib
  both in the repo (`../lib`) and installed (`../lib/skogai`). No
  `check()` yet: bats and shellcheck come from mise, not pacman, so
  makepkg cannot depend on them.

Locations (env only, never from a file):

- `SKOGAI_ROOT` - the project root; default: the git top level.
- `SKOGAI_SYSTEM_CONFIG_DIR`, `SKOGAI_GLOBAL_CONFIG_DIR`,
  `SKOGAI_LOCAL_CONFIG_DIR` - default `$SKOGAI_ROOT/.skogai/base/<scope>`.

A few settings, one per type, as placeholders to exercise the lookup:

- `core.name` (string) = `skogai`
- `core.debug` (bool) = `false`
- `core.retries` (int) = `3`
- `core.logdir` (path) = `.skogai/logs`

Tests, each in a fresh relocated setup:

- a key set only in system returns the system default.
- global overrides system; local overrides global; env overrides all.
- relocating any scope via its location env is honoured.
- an unknown key fails with a clear error and non-zero exit.
- `--type` rejects a bad int or bool, and normalises a path.
- the lookup works with only the repo present (no `/etc/skogai`, no xdg).
- `shellcheck` passes on `bin/` and `lib/`.

Done when: all tests pass, `makepkg` builds the package, and installing it
gives a working `skogai get` that reads `/etc/skogai` when told to via env.

### later

- _(captured as intentions surface; not planned until phase 1 is done)_
