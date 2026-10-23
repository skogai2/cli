# shellcheck shell=bash
# helpers for bin/config: layers, folding, frontmatter

# cd to the nearest ancestor of the invocation dir holding the dot dir
_root() {
    local dot=$SKOGAI_CONFIG_BASE_DOT_DIR start=${ARGC_PWD:-$PWD} d
    [[ $dot == /* ]] && return
    d=$start
    until [[ -d $d/$dot ]]; do
        [[ $d == / ]] && { d=$start; break; }
        d=$(dirname "$d")
    done
    cd "$d" || exit 2
}

# _files: module defaults, then default and override for system, global, local
_layers() {
    local dot=$SKOGAI_CONFIG_BASE_DOT_DIR base=$SKOGAI_CONFIG_BASE_DEFAULTS_DIR
    local module=$dot/$base/config.md t k v scope dir file name
    local -A m=()
    while IFS=$'\t' read -r t k v; do
        [[ $t == s ]] && m[$k]=$v
    done < <(_flatten "$module")
    _files=("$module")
    for scope in system global local; do
        name=$(_envname "config.$scope.dir")
        dir=${!name:-${m[config.$scope.dir]:-config}}
        name=$(_envname "config.$scope.file")
        file=${!name:-${m[config.$scope.file]:-config.$scope.md}}
        _files+=("$dot/$base/$dir/$file" "$dot/$dir/$file")
    done
}

_override_index() {
    case $1 in
    system) echo 2 ;;
    global) echo 4 ;;
    local) echo 6 ;;
    esac
}

# _val: value (list items newline-joined), _kind: s or l, _org: origin,
# _known: every key a file layer mentions
_fold() {
    _root
    _layers
    declare -gA _val=() _kind=() _org=() _known=()
    local f out t k v name
    for f in "${_files[@]}"; do
        out=$(_flatten "$f")
        [[ -n $out ]] || continue
        local -A n=()
        while IFS=$'\t' read -r t k v; do
            _known[$k]=1
            case $t in
            s) _val[$k]=$v _kind[$k]=s _org[$k]=file:$f ;;
            l) _val[$k]='' _kind[$k]=l _org[$k]=file:$f n[$k]=0 ;;
            i) ((n[$k]++)) && _val[$k]+=$'\n'$v || _val[$k]=$v ;;
            n) unset '_val[$k]' '_kind[$k]' '_org[$k]' ;;
            esac
        done <<<"$out"
        unset n
    done
    for k in "${!_known[@]}"; do
        name=$(_envname "$k")
        [[ -v $name ]] || continue
        _val[$k]=${!name} _kind[$k]=${_kind[$k]:-s} _org[$k]=env:$name
    done
}

# one record per key: s<TAB>key<TAB>value, n<TAB>key, or l<TAB>key then i<TAB>key<TAB>item
_flatten() {
    [[ -f $1 ]] && _has_frontmatter "$1" || return 0
    # shellcheck disable=SC2016 # $k is a yq variable
    yq --front-matter=extract '
      .. | select((path | length) > 0 and tag != "!!map" and ((path | map(tag == "!!str")) | all)) |
      (path | map(sub("_"; "-")) | join(".")) as $k |
      (
        if tag == "!!seq" then (["l\t" + $k] + [.[] | "i\t" + $k + "\t" + tostring] | .[])
        elif tag == "!!null" then "n\t" + $k
        else "s\t" + $k + "\t" + tostring
        end
      )' "$1" || { printf 'error: broken frontmatter in %s\n' "$1" >&2; exit 2; }
}

_has_frontmatter() {
    [[ -f $1 && $(head -n1 "$1") == --- ]]
}

_envname() {
    local n=${1^^}
    n=${n//./_}
    printf 'SKOGAI_%s' "${n//-/}"
}

_joined() {
    printf '%s' "${_val[$1]//$'\n'/ }"
}

_sorted_keys() {
    printf '%s\n' "${!_val[@]}" | LC_ALL=C sort | grep -v '^$' || true
}

# descriptions only while completing; validation compares whole lines on argc <= 1.24
_candidate() {
    if [[ ${ARGC_COMPGEN:-} ]]; then printf '%s\t%s\n' "$1" "$2"; else printf '%s\n' "$1"; fi
}

_list_line() {
    if [[ ${argc_show_origin:-} ]]; then
        printf '%s\t%s=%s\n' "${_org[$1]}" "$1" "$2"
    else
        printf '%s=%s\n' "$1" "$2"
    fi
}
