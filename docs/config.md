# config

Read and write key-value settings across layers. mise holds the values;
`skogai-config` is the interface to them. This file holds current
decisions only; see `CLAUDE.md` for the goals behind them.

## model

A setting is a key with a string value. Keys are lowercase and dotted
(`core.debug`). Each is a variable in the `[env]` of a mise env: the prefix + the key
in uppercase, `.` as `_`. With the defaults, `core.debug` is
`SKOGAI_CORE_DEBUG` in the `skogai` env.

Layers, later wins:

1. system - `$SKOGAI_CONFIG_SYSTEM_FILE`
2. global - `$SKOGAI_CONFIG_GLOBAL_FILE`
3. base - `$SKOGAI_CONFIG_BASE_FILE`, the project's, committed, never
   written by a command
4. local - `$SKOGAI_CONFIG_LOCAL_FILE`, beside the base

The project is the nearest directory up holding the base file.

Every location is a setting, read from the environment, with a default
that follows mise's own variables. `skogai-config -h` lists them:

| variable                    | default                                        |
|-----------------------------|------------------------------------------------|
| `MISE_ENV`                  | `skogai`                                       |
| `SKOGAI_CONFIG_PREFIX`      | `SKOGAI_`                                      |
| `SKOGAI_CONFIG_SYSTEM_FILE` | `$MISE_SYSTEM_CONFIG_DIR/config.$MISE_ENV.toml` (`/etc/mise`) |
| `SKOGAI_CONFIG_GLOBAL_FILE` | `$MISE_CONFIG_DIR/config.$MISE_ENV.toml` (`~/.config/mise`) |
| `SKOGAI_CONFIG_BASE_FILE`   | `mise.$MISE_ENV.toml`                          |
| `SKOGAI_CONFIG_LOCAL_FILE`  | `mise.$MISE_ENV.local.toml`                    |

A location only counts if mise loads that file; the defaults are the
names mise loads for that env.

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
