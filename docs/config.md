# config

Settings belong to mise. skogai does not keep its own layered store; it
uses mise's and describes its keys through argc. This file holds current
decisions only; see `CLAUDE.md` for the goals behind them. The 0.0.1
implementation (yaml frontmatter, `bin/config`) is tagged `v0.0.1` and
is to be replaced by this.

## decided

- **mise holds the values.** Layers, precedence, and where files live
  are mise's: system (`/etc/mise/`), global (`~/.config/mise/`), every
  directory up to the project, nearest wins; `config.override.toml` beats
  project config; `*.local.toml` is personal and not committed.
- **skogai is a mise env.** Its settings live in the `skogai` profile
  (`-E skogai` / `MISE_ENV=skogai`), so in `mise.skogai.toml`,
  `mise.skogai.local.toml`, `config.skogai.toml` and so on, apart from
  a project's own `mise.toml`.
- **argc is the interface.** Everything a command can do with argc
  comments, it does with them, before any bash is written: usage, help,
  validation, defaults, choices, completion, required tools.

## mise commands that already cover the old spec

| need                         | mise                                   |
|------------------------------|----------------------------------------|
| set a value                  | `mise set -E skogai KEY=VALUE`         |
| remove a change              | `mise unset -E skogai KEY`             |
| list values with their file  | `mise set -E skogai`                   |
| resolved environment         | `mise env -E skogai`                   |
| read one file                | `mise config get -E skogai -f <file> <key>` |
| which files, in what order   | `mise config ls -E skogai`             |
| what a key means             | `mise config explain`                  |

## open

- **`[env]` or a `[skogai]` table.** `[env]` keys (`SKOGAI_*`) get
  set, unset, list-with-source and a resolved view from mise, and reach
  argc as environment variables with no glue. A `[skogai]` table is
  read per file only, and mise warns about it as an unknown field.
  Leaning `[env]`.
- **Where the default lives.** Candidates: the command's own
  `@env SKOGAI_X=default` (goal 6, the command describes itself), the
  committed `mise.skogai.toml` as base with `mise.skogai.local.toml` as
  the change (goal 4), or both, argc's default being the last resort.
- **Which layer won.** `mise set` lists the source file; check whether
  that answers goal 3 fully or a small helper is still needed.
- **Is `bin/config` still needed**, or only as a thin wrapper, or not
  at all.
