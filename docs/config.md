# config

Read and write key-value settings across layers. mise holds the values;
`skogai-config` is the interface to them. This file holds current
decisions only; see `CLAUDE.md` for the goals behind them.

## model

A setting is a key with a string value. Keys are lowercase and dotted
(`core.debug`). Each is a `SKOGAI_*` variable in the `[env]` of mise's
`skogai` env: `SKOGAI_` + the key in uppercase, `.` as `_`.

Layers, later wins:

1. system - `/etc/mise/config.skogai.toml`
2. global - `~/.config/mise/config.skogai.toml`
3. base - the project's `mise.skogai.toml`, committed, never written by
   a command
4. local - the project's `mise.skogai.local.toml`

mise's own rules apply on top (`MISE_SYSTEM_CONFIG_DIR`,
`MISE_CONFIG_DIR`, parent directories, `config.override.toml`). The
project is the nearest directory up holding `mise.skogai.toml`.

A `SKOGAI_*` value already in the calling shell is ignored: a shell with
mise activated outside the `skogai` env carries its own, and it cannot
be told apart from a deliberate one.

A key exists only if some layer sets it. New keys are declared by adding
them to the base.

## commands

The command is `bin/config` in the repo, installed as `skogai-config`.
Exit codes: 0 ok, 1 expected no (unknown key, nothing to remove, bad
input; the possible values go to stderr), 2 unexpected.

Examples assume `mise.skogai.toml` sets `core.name=skogai`,
`core.debug=false`, `core.retries=3`, and `mise.skogai.local.toml` sets
`core.debug=true`.

### get

```
$ skogai-config get core.name
skogai
$ skogai-config get core.debug --show-origin
file:/path/to/proj/mise.skogai.local.toml	true
$ skogai-config get core.missing
error: invalid value `core.missing` for `<KEY>`           (exit 1)
  [possible values: core.debug, core.name, core.retries]
```

### set

```
skogai-config set <key> <value> [--scope system|global|local]
```

Writes a declared key to a scope's file, default `local`. Creates the
file if missing. Prints nothing.

### unset

```
skogai-config unset <key> [--scope system|global|local]
```

Removes the key from a scope's file, so the value beneath shows again.
A key not set in that file is exit 1.

### list

```
$ skogai-config list
core.debug=true
core.name=skogai
core.retries=3
```

`--show-origin` prefixes each line like `get`. A value mise marks with
`redact = true` shows as `[redacted]`.

### env

```
$ skogai-config env
export SKOGAI_CORE_DEBUG=true
export SKOGAI_CORE_NAME=skogai
export SKOGAI_CORE_RETRIES=3
```

### files

```
$ skogai-config files
/etc/mise/config.skogai.toml	missing
/home/me/.config/mise/config.skogai.toml	missing
mise.skogai.toml	present
mise.skogai.local.toml	present
```

## the same with mise directly

`mise set`, `mise unset --file <file>`, `mise env` and `mise config ls`
with `MISE_ENV=skogai` do the same jobs; `skogai-config` adds keys
instead of env names, completion, the base/local split, and origin.

## tests

`test/config.bats` is this spec as tests; each runs in a fresh project
with its own system and global mise config. `test/install.sh` runs the
same tests against the installed `skogai-config`.
