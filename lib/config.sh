# shellcheck shell=bash
# helpers for bin/config: scopes, folding, key and env names

# cd to the nearest ancestor of the invocation dir holding mise.skogai.toml
_root() {
    local start=${ARGC_PWD:-$PWD} d
    d=$start
    until [[ -f $d/mise.skogai.toml ]]; do
        [[ $d == / ]] && { d=$start; break; }
        d=$(dirname "$d")
    done
    cd "$d" || exit 2
}

_scope_file() {
    case $1 in
    system) echo "${MISE_SYSTEM_CONFIG_DIR:-/etc/mise}/config.skogai.toml" ;;
    global) echo "${MISE_CONFIG_DIR:-$HOME/.config/mise}/config.skogai.toml" ;;
    local) echo mise.skogai.local.toml ;;
    esac
}

# _val: value, _org: origin; mise resolves, the process env wins over it
_fold() {
    _root
    declare -gA _val=() _org=()
    local name v src k
    while IFS=$'\t' read -r name v; do
        _val[$(_keyname "$name")]=$v
    done < <(mise env --json | yq -p json -o tsv \
        'to_entries | map(select(.key | test("^SKOGAI_"))) | .[] | [.key, .value]') ||
        { echo 'error: mise could not resolve the env' >&2; exit 2; }
    # mise set lists each variable with its source file last
    while read -r name v; do
        [[ $name == SKOGAI_* ]] || continue
        src=${v##* }
        _org[$(_keyname "$name")]=file:$src
    done < <(mise set 2>/dev/null)
    for k in "${!_val[@]}"; do
        name=$(_envname "$k")
        if [[ -v $name && ${!name} != "${_val[$k]}" ]]; then
            _val[$k]=${!name} _org[$k]=env:$name
        fi
    done
}

# keys a single file sets
_file_keys() {
    [[ -f $1 ]] || return 0
    yq -p toml -o tsv '.env // {} | keys | .[]' "$1" | while read -r name; do
        [[ $name == SKOGAI_* ]] && _keyname "$name"
    done | LC_ALL=C sort
}

_envname() {
    local n=${1^^}
    printf 'SKOGAI_%s' "${n//./_}"
}

_keyname() {
    local n=${1#SKOGAI_}
    n=${n,,}
    printf '%s\n' "${n//_/.}"
}

_sorted_keys() {
    printf '%s\n' "${!_val[@]}" | LC_ALL=C sort | grep -v '^$' || true
}

# descriptions only while completing; validation compares whole lines on argc <= 1.24
_candidate() {
    if [[ ${ARGC_COMPGEN:-} ]]; then printf '%s\t%s\n' "$1" "$2"; else printf '%s\n' "$1"; fi
}
