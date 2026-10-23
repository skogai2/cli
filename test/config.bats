#!/usr/bin/env bats
# docs/config.md as tests: a setting is an argc option bound to a SKOGAI_*
# env var, and mise's skogai env layers its value. each test runs in a
# fresh project with its own system and global mise config.

setup() {
    local t=$BATS_TEST_TMPDIR
    mkdir -p "$t/etc" "$t/home/.config/mise" "$t/proj/sub"
    export HOME=$t/home MISE_CONFIG_DIR=$t/home/.config/mise \
        MISE_SYSTEM_CONFIG_DIR=$t/etc MISE_TRUSTED_CONFIG_PATHS=$t \
        MISE_STATE_DIR=$t/state MISE_CACHE_DIR=$t/cache MISE_ENV=skogai
    unset SKOGAI_GREETING SKOGAI_MODE
    cd "$t/proj"
    # a command with two settings, as every command declares them
    cat >"$t/greet" <<'EOF'
#!/usr/bin/env bash
# @describe Say something
# @option --greeting=hello $SKOGAI_GREETING  What to say
# @option --mode[=dev|prod] $SKOGAI_MODE     How to say it
main() { echo "$argc_greeting $argc_mode"; }
eval "$(argc --argc-eval "$0" "$@")"
EOF
    chmod +x "$t/greet"
}

greet() { mise x -- "$BATS_TEST_TMPDIR/greet" "$@"; }

@test "the command's own default when nothing is set" {
    run greet
    [ "$output" = "hello dev" ]
}

@test "help shows each setting's default and env name" {
    run "$BATS_TEST_TMPDIR/greet" -h
    [[ $output == *"[default: hello] [env: SKOGAI_GREETING]"* ]]
    [[ $output == *"[possible values: dev, prod]"* ]]
}

@test "system, then global, then project, then local" {
    echo -e '[env]\nSKOGAI_GREETING = "system"' >"$MISE_SYSTEM_CONFIG_DIR/config.toml"
    run greet
    [ "$output" = "system dev" ]
    mise set --global SKOGAI_GREETING=global
    run greet
    [ "$output" = "global dev" ]
    mise set --file mise.skogai.toml SKOGAI_GREETING=project
    run greet
    [ "$output" = "project dev" ]
    mise set --file mise.skogai.local.toml SKOGAI_GREETING=local
    run greet
    [ "$output" = "local dev" ]
}

@test "a flag wins over every file" {
    mise set --file mise.skogai.local.toml SKOGAI_GREETING=local
    run greet --greeting flag
    [ "$output" = "flag dev" ]
}

@test "unset removes a change, the value beneath shows through" {
    mise set --file mise.skogai.toml SKOGAI_GREETING=project
    mise set --file mise.skogai.local.toml SKOGAI_GREETING=local
    mise unset --file mise.skogai.local.toml SKOGAI_GREETING
    run greet
    [ "$output" = "project dev" ]
}

@test "list shows each value and the file it came from" {
    mise set --file mise.skogai.toml SKOGAI_GREETING=project
    run mise set
    [[ $output == *SKOGAI_GREETING*project*"/proj/mise.skogai.toml"* ]]
}

@test "found from a subdir" {
    mise set --file mise.skogai.toml SKOGAI_GREETING=project
    cd sub
    run greet
    [ "$output" = "project dev" ]
}

@test "a value outside the choices is rejected, naming them" {
    mise set --file mise.skogai.toml SKOGAI_MODE=loud
    run greet
    [ "$status" -ne 0 ]
    [[ $output == *"possible values: dev, prod"* ]]
}

@test "skogai settings stay out of the project's own mise.toml" {
    echo -e '[env]\nSKOGAI_GREETING = "plain"' >mise.toml
    mise set --file mise.skogai.toml SKOGAI_GREETING=project
    run greet
    [ "$output" = "project dev" ]
    run env -u MISE_ENV mise x -- "$BATS_TEST_TMPDIR/greet"
    [ "$output" = "plain dev" ]
}
