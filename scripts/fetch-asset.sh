#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ----------------------------------------------------------
# Assets
# ----------------------------------------------------------
ASSETS_DIR="${SCRIPT_DIR}/assets"
mkdir -p "${ASSETS_DIR}"

# Installers
declare -A INSTALLER_URLS=(
    ["claude"]="https://claude.ai/install.sh"
    ["hermes"]="https://hermes-agent.nousresearch.com/install.sh"
    ["kilo"]="https://kilo.ai/cli/install"
    ["openclaw"]="https://openclaw.ai/install.sh"
    ["pi"]="https://pi.dev/install.sh"
)

# Configuration
declare -A CONFIGURATION_URLS=(
)

# ----------------------------------------------------------
#
# ----------------------------------------------------------
fetch_asset() {
    local asset_type="$1"
    local component="$2"
    local url="${INSTALLER_URLS[$component]:-}"

    if [[ -z "${url}" ]]; then
        printf 'error: unknown component "%s"\n' "${component}" >&2
        exit 1
    fi

    local target_file="${ASSETS_DIR}/${component}-${asset_type}.sh"
    local temp_file
    temp_file=$(mktemp "${ASSETS_DIR}/${component}-${asset_type}.sh.tmp.XXXXXX")

    printf 'Fetching %s script for %s from %s...\n' "${asset_type}" "${component}" "${url}"
    curl -fsSL "${url}" -o "${temp_file}"

    if [[ ! -s "${temp_file}" ]]; then
        printf 'error: fetched %s script for %s is empty\n' "${asset_type}" "${component}" >&2
        rm -f "${temp_file}"
        exit 1
    fi

    if command -v shellcheck >/dev/null 2>&1; then
        printf 'Running shellcheck on %s script for %s...\n' "${asset_type}" "${component}"
        shellcheck "${temp_file}" || printf 'warning: shellcheck reported issues for %s script for %s\n' "${asset_type}" "${component}" >&2
    else
        printf 'warning: shellcheck not found in PATH, skipping analysis\n' >&2
    fi

    chmod 755 "${temp_file}"
    mv -f "${temp_file}" "${target_file}"
    printf 'Saved %s script to %s\n' "${asset_type}" "${target_file}"
}

# ----------------------------------------------------------
# Main
# ----------------------------------------------------------
if [[ $# -eq 0 ]]; then
    for component in "${!INSTALLER_URLS[@]}"; do
        fetch_asset "install" "${component}"
    done
else
    for component in "$@"; do
        fetch_asset "install" "${component}"
    done
fi
