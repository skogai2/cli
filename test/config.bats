#!/usr/bin/env bats
# docs/config.md as tests. each test runs bin/config in a fresh project,
# with its own system and global mise config: the real setup, moved
# somewhere else.

setup() {
    local repo t=$BATS_TEST_TMPDIR
    repo="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    mkdir -p "$t/etc" "$t/home/.config/mise" "$t/proj"
    export HOME=$t/home MISE_CONFIG_DIR=$t/home/.config/mise \
        MISE_SYSTEM_CONFIG_DIR=$t/etc MISE_TRUSTED_CONFIG_PATHS=$t \
        MISE_STATE_DIR=$t/state MISE_CACHE_DIR=$t/cache MISE_ENV=skogai
    unset "${!SKOGAI_@}"
    cd "$t/proj"
    # SKOGAI_TEST_ROOT: an unpacked package, to test the install instead
    if [[ -n ${SKOGAI_TEST_ROOT:-} ]]; then
        config=$SKOGAI_TEST_ROOT/usr/bin/skogai-config
    else
        config=$repo/bin/config
    fi
    # the project's base: declared keys and their defaults
    printf '%s\n' '[env]' 'SKOGAI_CORE_NAME = "skogai"' \
        'SKOGAI_CORE_DEBUG = "false"' 'SKOGAI_CORE_RETRIES = "3"' \
        'SKOGAI_CORE_EMPTY = ""' >mise.skogai.toml
}

@test "get: a default from the base" {
    run "$config" get core.name
    [ "$status" -eq 0 ]
    [ "$output" = skogai ]
}

@test "get: --show-origin names the file" {
    run "$config" get core.name --show-origin
    [[ $output == file:*mise.skogai.toml$'\t'skogai ]]
}

@test "get: system, then global, then base, then local" {
    local layer f
    for layer in system global base local; do
        case $layer in
        system) f=$MISE_SYSTEM_CONFIG_DIR/config.skogai.toml ;;
        global) f=$MISE_CONFIG_DIR/config.skogai.toml ;;
        base) f=mise.skogai.toml ;;
        local) f=mise.skogai.local.toml ;;
        esac
        mise set -q --file "$f" SKOGAI_CORE_LEVEL="$layer"
        run "$config" get core.level
        [ "$output" = "$layer" ]
    done
}

@test "get: local wins over the base" {
    "$config" set core.retries 5
    run "$config" get core.retries --show-origin
    [[ $output == file:*mise.skogai.local.toml$'\t'5 ]]
}

@test "get: env wins over every file" {
    "$config" set core.retries 5
    SKOGAI_CORE_RETRIES=9 run "$config" get core.retries --show-origin
    [ "$output" = $'env:SKOGAI_CORE_RETRIES\t9' ]
}

@test "get: an unknown key is exit 1" {
    run "$config" get core.missing
    [ "$status" -eq 1 ]
    [[ $output == *core.name* ]]
}

@test "get: an empty value is empty" {
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

@test "set: writes the local file, never the base" {
    run "$config" set core.retries 7
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
    run "$config" get core.retries
    [ "$output" = 7 ]
    grep -q 'SKOGAI_CORE_RETRIES = "3"' mise.skogai.toml
}

@test "set: --scope picks the file" {
    "$config" set core.retries 7 --scope global
    [ -f "$MISE_CONFIG_DIR/config.skogai.toml" ]
    [ ! -f mise.skogai.local.toml ]
}

@test "set: an undeclared key is exit 1" {
    run "$config" set core.missing 1
    [ "$status" -eq 1 ]
    [[ $output == *core.name* ]]
    [ ! -e mise.skogai.local.toml ]
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

@test "list: key=value, sorted" {
    run "$config" list
    [ "$status" -eq 0 ]
    [ "$output" = $'core.debug=false\ncore.empty=\ncore.name=skogai\ncore.retries=3' ]
}

@test "env: export lines, shell-quoted" {
    "$config" set core.name 'two words'
    run "$config" env
    [[ $output == *'export SKOGAI_CORE_NAME=two\ words'* ]]
}

@test "files: every scope in fold order" {
    "$config" set core.debug true
    run "$config" files
    [ "$output" = "$(printf '%s\t%s\n' \
        "$MISE_SYSTEM_CONFIG_DIR/config.skogai.toml" missing \
        "$MISE_CONFIG_DIR/config.skogai.toml" missing \
        mise.skogai.toml present \
        mise.skogai.local.toml present)" ]
}
