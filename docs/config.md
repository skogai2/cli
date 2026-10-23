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

Where each scope's files live is itself a setting:

| key                       | default            | set in |
|---------------------------|--------------------|--------|
| `config.base.dot.dir`     | `.skogai`          | env only |
| `config.base.defaults.dir`| `base`             | env only |
| `config.<scope>.dir`      | `config`           | `config.md` |
| `config.<scope>.file`     | `config.<scope>.md`| `config.md` |

So the local layer is `.skogai/base/config/config.local.md`, then
`.skogai/config/config.local.md`. The two `config.base.*` keys say where
`config.md` itself is, so only env can change them; their defaults are
listed under ENVIRONMENT VARIABLES in every command's help. The dot dir
is found by walking up from the current directory.

A key exists only if some default file declares it. A key declared as
null shows up nowhere until a layer sets it, but `set` can use it.

A null value removes a key that an earlier layer set.

### env names

`SKOGAI_` + the key in uppercase, `.` as `_`, `-` dropped:

| key                   | env                          |
|-----------------------|------------------------------|
| `config.local.dir`    | `SKOGAI_CONFIG_LOCAL_DIR`    |
| `stage.on-stop`       | `SKOGAI_STAGE_ONSTOP`        |

Env only overrides keys that some file layer defines.

## commands

The command is `bin/config` in the repo, installed as `skogai-config`.
All output goes to stdout, errors to stderr. Exit codes:

| code | meaning                                  |
|------|------------------------------------------|
| 0    | ok                                       |
| 1    | expected no: key not set, nothing to remove, bad input; the possible values go to stderr |
| 2    | unexpected: broken frontmatter, unreadable file |

Examples below assume this state:

```
.skogai/base/config/config.system.md   core.name: skogai, core.debug: false,
                                       core.retries: 3, core.tools: [git, yq]
.skogai/config/config.local.md         core.debug: true
env                                    SKOGAI_CORE_RETRIES=5
```

`list` and `env` output below leaves out the keys of `config.md` itself
(`type`, `name`, `config.*`, ...), which show like any other.

### get

```
skogai-config get <key> [--show-origin]
```

Prints the resolved value of one key. A list prints one item per line.

```
$ skogai-config get core.name
skogai
$ skogai-config get core.tools
git
yq
$ skogai-config get core.debug --show-origin
file:.skogai/config/config.local.md	true
$ skogai-config get core.retries --show-origin
env:SKOGAI_CORE_RETRIES	5
$ skogai-config get core.missing
error: invalid value `core.missing` for `<KEY>`           (exit 1)
  [possible values: core.debug, core.name, ...]
```

With `--show-origin` the line is `<origin><TAB><value>`; a list's items
are joined by spaces. Origin is `file:<path>` or `env:<NAME>`.

### set

```
skogai-config set <key> <value> [--scope system|global|local]
```

Writes a declared key to the override file of a scope, default `local`.
An undeclared key is exit 1, listing the declared keys. Creates
the file if missing. Never touches `.skogai/base/`. The value is read as
yaml, so `true`, `52`, `[a, b]` and `null` keep their type. Prints
nothing.

```
$ skogai-config set core.retries 7
$ skogai-config set core.tools '[git]' --scope global
$ skogai-config set core.debug null
$ skogai-config get core.debug                           (exit 1)
$ skogai-config set 'bad..key' 1
error: invalid value `bad..key` for `<KEY>`               (exit 1)
  [possible values: ...]
```

### unset

```
skogai-config unset <key> [--scope system|global|local]
```

Removes the key from a scope's override file, default `local`, so the
value beneath shows through again. Unlike `set <key> null`, it removes
the change instead of adding a deletion.

```
$ skogai-config unset core.debug
$ skogai-config get core.debug
false
$ skogai-config unset core.debug
error: invalid value `core.debug` for `<KEY>`             (exit 1)
  [possible values: ...keys set in that override]
```

### list

```
skogai-config list [--show-origin]
```

Prints every resolved key as `key=value`, sorted by key. A list prints one
line per item. Nothing set prints nothing, exit 0.

```
$ skogai-config list
core.debug=true
core.name=skogai
core.retries=5
core.tools=git
core.tools=yq
$ skogai-config list --show-origin
file:.skogai/config/config.local.md	core.debug=true
file:.skogai/base/config/config.system.md	core.name=skogai
env:SKOGAI_CORE_RETRIES	core.retries=5
file:.skogai/base/config/config.system.md	core.tools=git
file:.skogai/base/config/config.system.md	core.tools=yq
```

### env

```
skogai-config env
```

Prints the resolved config as shell `export` lines, values shell-quoted,
sorted by key. A list's items are separated by newlines inside the value.

```
$ skogai-config env
export SKOGAI_CORE_DEBUG=true
export SKOGAI_CORE_NAME=skogai
export SKOGAI_CORE_RETRIES=5
export SKOGAI_CORE_TOOLS=$'git\nyq'
```

### files

```
skogai-config files
```

Prints each layer file in fold order, and whether it exists.

```
$ skogai-config files
.skogai/base/config.md	present
.skogai/base/config/config.system.md	present
.skogai/config/config.system.md	missing
.skogai/base/config/config.global.md	missing
.skogai/config/config.global.md	missing
.skogai/base/config/config.local.md	missing
.skogai/config/config.local.md	present
```

## edge cases

- metadata keys (`type`, `name`, `tools`, ...) are keys like any other.
- an empty value or empty list is a value: `get` prints an empty line,
  `list` prints `key=`. It is never shown as its origin.
- a missing layer file is skipped, not an error.
- a file without frontmatter is an empty layer.
- a file with broken frontmatter is exit 2, naming the file.

## tests

`test/config.bats` is this spec as tests; each runs in a fresh `.skogai`
in a temp dir. `test/install.sh` builds the package and runs the same
tests against the installed `skogai-config`.

## open

- extra file layers and keys mounted under a module's name: later, as
  modules of their own (e.g. reading values when a file is read, to
  change the markdown dynamically). Not part of the basics.
- types beyond yaml's (path, ...): later, as a type module using argc's
  runtime validation.
