#!/usr/bin/env bats
# docs/config.md as tests. each test runs the repo's bin/config against a
# fresh .skogai under a temp dir: the real setup, moved somewhere else.

setup() {
    local repo
    repo="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    cd "$BATS_TEST_TMPDIR"
    mkdir -p .skogai/base/config .skogai/config
    # SKOGAI_TEST_ROOT: an unpacked package, to test the install instead
    if [[ -n ${SKOGAI_TEST_ROOT:-} ]]; then
        cp "$SKOGAI_TEST_ROOT/usr/share/skogai/base/config.md" .skogai/base/
        config=$SKOGAI_TEST_ROOT/usr/bin/skogai-config
    else
        cp "$repo/.skogai/base/config.md" .skogai/base/
        config=$repo/bin/config
    fi
    # declared keys, as a system default
    md .skogai/base/config/config.system.md \
        'core.name: skogai' 'core.debug: false' 'core.retries: 3' \
        'core.tools: [git, yq]' 'core.empty: ""' 'core.unset: null'
}

# md <file> <yaml line>... : write a markdown file with that frontmatter
md() {
    local f=$1
    shift
    mkdir -p "$(dirname "$f")"
    { echo ---; printf '%s\n' "$@"; echo ---; } >"$f"
}

@test "get: a default from base" {
    run "$config" get core.name
    [ "$status" -eq 0 ]
    [ "$output" = skogai ]
}

@test "get: a list prints one item per line" {
    run "$config" get core.tools
    [ "$output" = $'git\nyq' ]
}

@test "get: the override beside base wins" {
    md .skogai/config/config.system.md 'core.debug: true'
    run "$config" get core.debug --show-origin
    [ "$output" = $'file:.skogai/config/config.system.md\ttrue' ]
}

@test "get: system, then global, then local" {
    md .skogai/config/config.global.md 'core.retries: 4'
    run "$config" get core.retries
    [ "$output" = 4 ]
    md .skogai/config/config.local.md 'core.retries: 5'
    run "$config" get core.retries
    [ "$output" = 5 ]
}

@test "get: env wins over every file" {
    md .skogai/config/config.local.md 'core.retries: 5'
    SKOGAI_CORE_RETRIES=9 run "$config" get core.retries --show-origin
    [ "$output" = $'env:SKOGAI_CORE_RETRIES\t9' ]
}

@test "get: null in a later layer removes the key" {
    md .skogai/config/config.local.md 'core.debug: null'
    run "$config" get core.debug
    [ "$status" -eq 1 ]
}

@test "get: a key declared as null is not set" {
    run "$config" get core.unset
    [ "$status" -eq 1 ]
}

@test "get: an unknown key is exit 1" {
    run "$config" get core.missing
    [ "$status" -eq 1 ]
}

@test "get: an empty value is empty, never its origin" {
    run "$config" get core.empty
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "get: found by walking up from a subdir" {
    mkdir -p deep/er
    cd deep/er
    run "$config" get core.name
    [ "$output" = skogai ]
}

@test "set: writes the local override, never base" {
    run "$config" set core.retries 7
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
    run "$config" get core.retries --show-origin
    [ "$output" = $'file:.skogai/config/config.local.md\t7' ]
    run grep -q 'core.retries: 3' .skogai/base/config/config.system.md
    [ "$status" -eq 0 ]
}

@test "set: --scope picks the override file" {
    run "$config" set core.retries 7 --scope global
    [ -f .skogai/config/config.global.md ]
    [ ! -f .skogai/config/config.local.md ]
}

@test "set: the value is read as yaml" {
    "$config" set core.tools '[git]'
    run "$config" get core.tools
    [ "$output" = git ]
}

@test "set: null removes the key below" {
    "$config" set core.debug null
    run "$config" get core.debug
    [ "$status" -eq 1 ]
}

@test "set: an undeclared key is exit 1" {
    run "$config" set core.missing 1
    [ "$status" -eq 1 ]
    [[ $output == *core.name* ]]
}

@test "set: a bad key is exit 1" {
    run "$config" set 'bad..key' 1
    [ "$status" -eq 1 ]
    [ ! -e .skogai/config/config.local.md ]
}

@test "unset: the value beneath shows through again" {
    "$config" set core.debug true
    run "$config" unset core.debug
    [ "$status" -eq 0 ]
    run "$config" get core.debug
    [ "$output" = false ]
}

@test "unset: nothing to remove is exit 1" {
    run "$config" unset core.debug
    [ "$status" -eq 1 ]
}

@test "list: key=value, sorted, a list one line per item" {
    run "$config" list
    [ "$status" -eq 0 ]
    [[ $output == *$'core.name=skogai\ncore.retries=3\ncore.tools=git\ncore.tools=yq'* ]]
}

@test "list: an empty value is key=" {
    run "$config" list
    [[ $output == *$'\ncore.empty=\n'* ]]
}

@test "env: export lines, shell-quoted" {
    run "$config" env
    [[ $output == *'export SKOGAI_CORE_NAME=skogai'* ]]
    [[ $output == *"export SKOGAI_CORE_TOOLS=\$'git\\nyq'"* ]]
}

@test "files: every layer in fold order" {
    md .skogai/config/config.local.md 'core.debug: true'
    run "$config" files
    [ "$output" = "$(printf '%s\t%s\n' \
        .skogai/base/config.md present \
        .skogai/base/config/config.system.md present \
        .skogai/config/config.system.md missing \
        .skogai/base/config/config.global.md missing \
        .skogai/config/config.global.md missing \
        .skogai/base/config/config.local.md missing \
        .skogai/config/config.local.md present)" ]
}
