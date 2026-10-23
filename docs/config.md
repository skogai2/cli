# config

A setting is an argc option bound to a `SKOGAI_*` environment variable.
mise holds its value in layers. skogai adds no store and no command of
its own for settings. This file holds current decisions only; see
`CLAUDE.md` for the goals behind them. The 0.0.1 store is tagged
`v0.0.1`.

## a setting

Every command declares the settings it reads, in its own comments:

```sh
# @option --greeting=hello $SKOGAI_GREETING  What to say
# @option --mode[=dev|prod] $SKOGAI_MODE     How to say it
```

- the default is the one in the comment, so the command describes it.
- the env name is `SKOGAI_` + the name in uppercase.
- choices, required and types come from argc and are checked on every run.
- `-h` lists each setting with its default and env name:

```
--greeting <GREETING>  What to say [default: hello] [env: SKOGAI_GREETING]
--mode <MODE>          How to say it [possible values: dev, prod] [default: dev] [env: SKOGAI_MODE]
```

## layers

Later wins:

1. the command's default
2. system - `/etc/mise/config.toml`, `config.skogai.toml`
3. global - `~/.config/mise/config.toml`, `config.skogai.toml`
4. every directory up to the current one, nearest wins
5. project - `mise.skogai.toml`, committed
6. local - `mise.skogai.local.toml`, personal, not committed
7. the flag on the command line

Values live in `[env]`. They are in the `skogai` mise env
(`MISE_ENV=skogai`), so they stay apart from a project's own `mise.toml`.
A command runs under mise (`mise x -- <cmd>`, or the runner) to see them.

Files hold changes only. Removing a change shows the value beneath.

## operations

| need                         | how                                              |
|------------------------------|--------------------------------------------------|
| set                          | `mise set --file mise.skogai.local.toml KEY=VALUE` |
| remove a change              | `mise unset --file mise.skogai.local.toml KEY`   |
| every value and its file     | `mise set`                                       |
| the resolved environment     | `mise env`                                       |
| which files, in what order   | `mise config ls`                                 |
| what a setting means         | `<cmd> -h`                                       |

`--global` and `--system` pick those layers instead of `--file`.

## edge cases

- a value outside a setting's choices fails the command, listing them.
- a value already in the calling shell loses to mise's files under
  `mise x`; the flag is the way to set one for a single run.

## tests

`test/config.bats` is this file as tests: a sample command, a temp
project, and its own system and global mise config.
