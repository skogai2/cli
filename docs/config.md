# config

Read and write key-value settings across layers. This spec covers the
commands, their inputs and their expected outputs. It holds current
decisions only; see `CLAUDE.md` for the goals behind them.

## model

A setting is a key with a value. Keys are lowercase and dotted
(`config.local.dir`). Values are strings, bools, ints, or lists.

Settings live in the yaml frontmatter of markdown files. Nested maps
flatten to dotted keys; `_` in a key reads as `-`.

Layers are applied in fold order, later wins:

1. module defaults - the frontmatter of `.skogai/base/config.md`
2. system - its default file, then its override
3. global - its default file, then its override
4. local - its default file, then its override
5. env - `SKOGAI_*` variables

Every file layer has two parts:

- default - `.skogai/base/<path>`, committed, never written by a command.
- override - `.skogai/<path>`, the same path minus `base/`. All writes
  go here.

Where each scope's files live is itself a setting (from `config.md`):

| key                       | default            |
|---------------------------|--------------------|
| `config.base.dot.dir`     | `.skogai`          |
| `config.base.defaults.dir`| `base`             |
| `config.<scope>.dir`      | `config`           |
| `config.<scope>.file`     | `config.<scope>.md`|
| `config.<scope>.file.override` | null          |
| `config.base.module.dir`  | `module`           |

Modules live in `.skogai/base/<module.dir>/<name>/`; the config module's
command is `.skogai/base/module/config/argc.sh`.

`config.<scope>.file.override` is how a machine points a scope at an
absolute file, e.g. `config.system.file.override: /etc/skogai/config.md`
set in the local override. Null by default, so it does nothing in a
sandbox.

So the local layer is `.skogai/base/config/config.local.md`, then
`.skogai/config/config.local.md`. The two `config.base.*` keys can only
be changed from env, since they say where `config.md` itself is.

A null value removes a key that an earlier layer set.

### env names

`SKOGAI_` + the key in uppercase, `.` as `_`, `-` dropped:

| key                   | env                          |
|-----------------------|------------------------------|
| `config.local.dir`    | `SKOGAI_CONFIG_LOCAL_DIR`    |
| `stage.on-stop`       | `SKOGAI_STAGE_ONSTOP`        |

Env only overrides keys that some file layer defines.

## commands

All output goes to stdout, errors to stderr. Exit codes:

| code | meaning                                  |
|------|------------------------------------------|
| 0    | ok                                       |
| 1    | key not set / nothing to remove          |
| 2    | bad input: unknown command, bad key, unreadable file |

Examples below assume this state:

```
.skogai/base/config.md            core.name: skogai, core.debug: false,
                                  core.retries: 3, core.tools: [git, yq]
.skogai/config/config.local.md    core.debug: true
env                               SKOGAI_CORE_RETRIES=5
```

### get

```
skogai config get <key> [--show-origin]
```

Prints the resolved value of one key. A list prints one item per line.

```
$ skogai config get core.name
skogai
$ skogai config get core.tools
git
yq
$ skogai config get core.debug --show-origin
file:.skogai/config/config.local.md	true
$ skogai config get core.retries --show-origin
env:SKOGAI_CORE_RETRIES	5
$ skogai config get core.missing
error: core.missing is not set                           (exit 1)
```

With `--show-origin` the line is `<origin><TAB><value>`; a list's items
are joined by spaces. Origin is `file:<path>` or `env:<NAME>`. A value
only shows `env:` if the env variable was actually set by the caller, not
when it is a default the command filled in itself.

### set

```
skogai config set <key> <value> [--scope system|global|local]
```

Writes the key to the override file of a scope, default `local`. Creates
the file if missing. Never touches `.skogai/base/`. The value is read as
yaml, so `true`, `52`, `[a, b]` and `null` keep their type. Prints
nothing.

```
$ skogai config set core.retries 7
$ skogai config set core.tools '[git]' --scope global
$ skogai config set core.debug null
$ skogai config get core.debug
error: core.debug is not set                             (exit 1)
$ skogai config set 'bad..key' 1
error: bad key: bad..key                                 (exit 2)
```

### unset

```
skogai config unset <key> [--scope system|global|local]
```

Removes the key from a scope's override file, default `local`, so the
value beneath shows through again. Unlike `set <key> null`, it removes
the change instead of adding a deletion.

```
$ skogai config unset core.debug
$ skogai config get core.debug
false
$ skogai config unset core.debug
error: core.debug is not in .skogai/config/config.local.md   (exit 1)
```

### list

```
skogai config list [--show-origin]
```

Prints every resolved key as `key=value`, sorted by key. A list prints one
line per item. Nothing set prints nothing, exit 0.

```
$ skogai config list
core.debug=true
core.name=skogai
core.retries=5
core.tools=git
core.tools=yq
$ skogai config list --show-origin
file:.skogai/config/config.local.md	core.debug=true
file:.skogai/base/config.md	core.name=skogai
env:SKOGAI_CORE_RETRIES	core.retries=5
file:.skogai/base/config.md	core.tools=git
file:.skogai/base/config.md	core.tools=yq
```

### env

```
skogai config env
```

Prints the resolved config as shell `export` lines, values shell-quoted,
sorted by key. A list's items are separated by newlines inside the value.

```
$ skogai config env
export SKOGAI_CORE_DEBUG=true
export SKOGAI_CORE_NAME=skogai
export SKOGAI_CORE_RETRIES=5
export SKOGAI_CORE_TOOLS=$'git\nyq'
```

### files

```
skogai config files
```

Prints each layer file in fold order, and whether it exists.

```
$ skogai config files
.skogai/base/config.md	present
.skogai/base/config/config.system.md	missing
.skogai/config/config.system.md	missing
.skogai/base/config/config.global.md	missing
.skogai/config/config.global.md	missing
.skogai/base/config/config.local.md	missing
.skogai/config/config.local.md	present
```

## edge cases

- metadata keys (`type`, `name`, `tools`, ...) are keys like any other and
  show in `list`.
- an empty value or empty list is a value: `get` prints an empty line,
  `list` prints `key=`. It is never shown as its origin.
- a missing layer file is skipped, not an error.
- a file without frontmatter is an empty layer.
- a file with broken frontmatter is exit 2, naming the file.

## open

- whether `config.<scope>.file.override` replaces the scope's override
  file or adds a layer after it.
- `--file` extra layers, and keys mounted under a module's name, from the
  example script: not in this spec yet.
- path as a type: a convention for now, no checking.
