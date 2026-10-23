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

- _(to be described)_

## concepts

The ideas the cli is built around. One line each: name - what it means.

- _(to be described)_

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
