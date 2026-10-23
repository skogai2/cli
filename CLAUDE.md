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
  - system - machine-wide, `/etc/skogai`.
  - global - per user, the xdg layer (`$XDG_CONFIG_HOME/skogai`).
  - local - per project, `.skogai` in the project.
  - env - the current process, environment variables.

## tools

What the cli uses or works with, and why. One line each: tool - its role.

- _(to be described)_

## roadmap

Each phase lists the intent it serves and how we know it is done.

### phase 0 - foundation

- [x] empty repo, clean-room rule written down
- [ ] intentions above described and agreed
- [ ] choose language/runtime from the intentions, not from habit
- [ ] decide what "done" means for a command (tests, docs, help text)

### phase 1 - first command

- [ ] _(the smallest command that proves the core intent)_

### later

- _(captured as intentions surface; not planned until phase 1 is done)_
