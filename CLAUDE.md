# skogai2/cli

A ground-up rework of the skogai cli: a modular framework built from a
command runner and layered key-value settings. Nothing is carried over;
every piece is rebuilt from its intent.

## the clean-room rule

Do not read, search, or copy the old implementation: its source, docs,
tests, or git history. The old version was the result of copying forward;
this repo exists to stop doing that.

If you think you need something from it, stop and ask. The answer is
almost always to describe the intent together, write it down, and build
from the description.

Sources of truth, in order:

1. what the user says in conversation
2. this file and `docs/`
3. the code in this repo

## how we work

- Intent before implementation. Nothing is built until its intent is
  written down and agreed.
- Describe concepts, not mechanisms.
- Use what exists (pacman, git, argc, mise, yq) instead of reinventing it.
- Small steps, each buildable and checkable on its own.
- Write it down as we talk: settled decisions go into this file or
  `docs/` right away.
- `tmp/` is throwaway scratch space and is gitignored.

## goals

What skogai is meant to be when it is done. Concepts only.

1. A repo is enough. Everything an agent needs travels with the repo. A
   sandbox with only the repo checked out behaves the same as the user's
   machine.
2. State is a diff on a base. Every setting has a default; every change
   is applied on top of it and can be removed again.
3. Layers, most specific wins. System, global, local, then the running
   process. It is always possible to tell which layer a value came from.
4. Defaults stay apart from changes. Use never edits the base; changes
   live beside it.
5. The base has a point in time. A repo knows which version of the base
   it carries, and moving it forward is a deliberate, reviewed step.
6. Everything describes itself. Modules and commands carry their own
   description, needs, dependencies and defaults. Docs and behaviour live
   together.
7. Modular. Small parts that combine; a repo takes only what it needs.
8. Nothing is fixed but the starting point. Even where things live is a
   setting.
9. Use what exists. Build on established systems.
10. Tested as real. A test is the real setup, moved somewhere else.
11. Installed as a version. skogai is installed and upgraded as a
    versioned package.

The core question behind them: how do we manage ai agents working in
sandboxes with only a project repo checked out?

## how it is built

- bash, argc as the command runner, mise for settings, yq for markdown
  frontmatter.
- argc first: whatever argc comments can express (usage, help,
  validation, defaults, choices, env, completion, required tools) is
  written as comments, never as bash.
- A setting is an argc option bound to a `SKOGAI_*` env var, its
  default in the comment; mise layers its value in the `skogai` env.
  See `docs/config.md`.
- A command is an argc script that describes its own interface in
  comments. Shared helpers live in `lib/`; argc needs `_choice_*`
  functions in the script itself, so those stay in `bin/`.
- A module is a markdown file: frontmatter says what it is (`type`,
  `name`, `description`, `command`, `tools`, `requires`); the body is
  its docs.
- `.skogai/base/<path>` is a default, `.skogai/<path>` its override.
  `base/` is committed and never written by a command.
- Upgrades are manual and local, on the user's machine, never inside a
  sandbox. Each update may carry choices worth reviewing.
- `.skogai/base/mise.toml` lists the tools a sandbox needs.

## layout

| repo | installed as | what |
|---|---|---|
| `bin/<name>` | `/usr/bin/skogai-<name>` | commands |
| `lib/<name>.sh` | `/usr/lib/skogai/<name>.sh` | their helpers |
| `.skogai/base/` | `/usr/share/skogai/base/` | the base a repo copies |
| `docs/<name>.md` | | specs: inputs and expected outputs |
| `test/` | | bats tests, and `install.sh` for the package |

## modules

- config - settings: argc options bound to env, layered by mise. Spec:
  `docs/config.md`.

## testing

- `bats test/` - every spec against the repo.
- `test/install.sh` - builds the package from HEAD, unpacks it into a
  temp root, and checks it holds the repo's base and commands.
- `shellcheck -x bin/* lib/*.sh test/*.sh` - clean.

A thing is done when its spec, tests and help text agree.

## roadmap

### 0.0.1 - config (released, tag `v0.0.1`)

- [x] layered lookup: module defaults, system, global, local, env
- [x] every location is a setting with a local default
- [x] get, set, unset, list, env, files
- [x] tests in a relocated `.skogai`, against repo and package
- [x] pacman package

### 0.0.2 - config on mise

- [x] a setting is an argc option bound to env, default in the comment
- [x] layers, set, unset and origin from mise's `skogai` env
- [x] the 0.0.1 store and `bin/config` removed

### next

- the runner: a `skogai` command that runs a module's `command`
- how a repo copies the installed base and records its version
- a type module (path, ...) using argc's runtime validation
