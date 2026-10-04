#!/usr/bin/env bash

set -euo pipefail

# Absolute path
SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ----------------------------------------------------------
# Assets
# ----------------------------------------------------------
ASSETS_DIR="$(realpath "${SCRIPT_DIR}/../assets")"
mkdir -p "${ASSETS_DIR}"

# URL to installation scripts
declare -A INSTALL_URLS=(
    ["claude"]="https://claude.ai/install.sh"
    ["hermes"]="https://hermes-agent.nousresearch.com/install.sh"
    ["kilo"]="https://kilo.ai/cli/install"
    ["openclaw"]="https://openclaw.ai/install.sh"
    ["pi"]="https://pi.dev/install.sh"
    ["uv"]="https://astral.sh/uv/install.sh"
)

# URL to configuration scripts
declare -A CONFIG_URLS=(
)

FORCE=0

# ----------------------------------------------------------
# helpers
# ----------------------------------------------------------
info() {
    local format="$1"
    shift
    # shellcheck disable=SC2059
    printf "\033[32mINFO: ${format}\033[0m" "$@"
}

error() {
    local format="$1"
    shift
    # shellcheck disable=SC2059
    printf "\033[31mERROR: ${format}\033[0m" "$@" >&2
}

warning() {
    local format="$1"
    shift
    # shellcheck disable=SC2059
    printf "\033[33mWARNING: ${format}\033[0m" "$@" >&2
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [COMPONENT...]

Fetch install and configuration assets for components.

Options:
  --force        Overwrite existing asset files
  -h, --help     Show this help message and exit

If no COMPONENT is specified, assets for all components will be fetched.
EOF
}

# ----------------------------------------------------------
#
# ----------------------------------------------------------
fetch_asset() {
    local asset_type="$1"
    local component="$2"
    local url=""

    # 1. Defensive checks
    case "${asset_type}" in
    install | installation)
        url="${INSTALL_URLS[$component]:-}"
        ;;
    config | configuration | setup)
        url="${CONFIG_URLS[$component]:-}"
        ;;
    *)
        error 'unknown asset type "%s"\n' "${asset_type}"
        exit 1
        ;;
    esac

    if [[ -z "${url}" ]]; then
        return 1
    fi

    # 2. URL is valid
    local target_file="${ASSETS_DIR}/${component}-${asset_type}.sh"

    if [[ -f "${target_file}" && "${FORCE}" -eq 0 ]]; then
        warning 'Asset already exists at "%s", skipping (use --force to overwrite)\n' "${target_file}"
        return 0
    fi

    local temp_file
    temp_file=$(mktemp "${ASSETS_DIR}/${component}-${asset_type}.sh.tmp.XXXXXX")

    info 'Fetching %s script for %s from %s...\n' "${asset_type}" "${component}" "${url}"
    curl -fsSL "${url}" -o "${temp_file}"

    if [[ ! -s "${temp_file}" ]]; then
        error 'fetched %s script for %s is empty\n' "${asset_type}" "${component}"
        rm -f "${temp_file}"
        return 1
    fi

    if command -v shellcheck >/dev/null 2>&1; then
        info 'Running shellcheck on %s script for %s...\n' "${asset_type}" "${component}"
        shellcheck "${temp_file}" >/dev/null 2>&1 || warning 'shellcheck reported issues for %s script for %s\n' "${asset_type}" "${component}"
    else
        warning 'shellcheck not found in PATH, skipping analysis\n'
    fi

    chmod 755 "${temp_file}"
    mv -f "${temp_file}" "${target_file}"
    info 'Saved %s script to %s\n' "${asset_type}" "${target_file}"
}

fetch_all_assets() {
    local component="$1"
    local failed=0

    fetch_asset "install" "${component}" || {
        warning 'no %s asset found for "%s"\n' "install" "${component}"
        ((failed++)) || true
    }
    fetch_asset "config" "${component}" || {
        warning 'no %s asset found for "%s"\n' "config" "${component}"
        ((failed++)) || true
    }

    # Returns 1 if all previous `fetch_asset` calls failed
    [[ "${failed}" -lt 2 ]]
}

unique_elements() {
    local -A seen=()
    local item
    for item in "$@"; do
        if [[ -z "${seen[$item]:-}" ]]; then
            seen["$item"]=1
            printf '%s\n' "$item"
        fi
    done
}

# ----------------------------------------------------------
# Main
# ----------------------------------------------------------
COMPONENTS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
        usage
        exit 0
        ;;
    --force)
        FORCE=1
        shift
        ;;
    --)
        shift
        while [[ $# -gt 0 ]]; do
            COMPONENTS+=("$1")
            shift
        done
        break
        ;;
    -*)
        error 'unknown option "%s"\n' "$1"
        exit 1
        ;;
    *)
        COMPONENTS+=("$1")
        shift
        ;;
    esac
done

if [[ ${#COMPONENTS[@]} -eq 0 ]]; then

    # Do all components if no component arguments are provided
    readarray -t ALL_COMPONENTS < <(unique_elements "${!INSTALL_URLS[@]}" "${!CONFIG_URLS[@]}")

    for component in "${ALL_COMPONENTS[@]}"; do
        fetch_all_assets "${component}" || error 'no assets were found for component "%s"\n' "${component}"
    done
else
    for component in "${COMPONENTS[@]}"; do
        fetch_all_assets "${component}" || error 'no assets were found for component "%s"\n' "${component}"
    done
fi
