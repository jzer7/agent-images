#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALLERS_DIR="${SCRIPT_DIR}/installers"

mkdir -p "${INSTALLERS_DIR}"

declare -A INSTALLER_URLS=(
    ["claude"]="https://claude.ai/install.sh"
    ["hermes"]="https://hermes-agent.nousresearch.com/install.sh"
    ["kilo"]="https://kilo.ai/cli/install"
    ["openclaw"]="https://openclaw.ai/install.sh"
    ["pi"]="https://pi.dev/install.sh"
)

fetch_installer() {
    local agent="$1"
    local url="${INSTALLER_URLS[$agent]:-}"

    if [[ -z "${url}" ]]; then
        printf 'error: unknown agent "%s"\n' "${agent}" >&2
        exit 1
    fi

    local target_file="${INSTALLERS_DIR}/${agent}-install.sh"
    local temp_file
    temp_file=$(mktemp "${INSTALLERS_DIR}/${agent}-install.sh.tmp.XXXXXX")

    printf 'Fetching installer for %s from %s...\n' "${agent}" "${url}"
    curl -fsSL "${url}" -o "${temp_file}"

    if [[ ! -s "${temp_file}" ]]; then
        printf 'error: fetched installer for %s is empty\n' "${agent}" >&2
        rm -f "${temp_file}"
        exit 1
    fi

    if command -v shellcheck >/dev/null 2>&1; then
        printf 'Running shellcheck on %s installer...\n' "${agent}"
        shellcheck "${temp_file}" || printf 'warning: shellcheck reported issues for %s installer\n' "${agent}" >&2
    else
        printf 'warning: shellcheck not found in PATH, skipping analysis\n' >&2
    fi

    chmod 755 "${temp_file}"
    mv -f "${temp_file}" "${target_file}"
    printf 'Saved installer to %s\n' "${target_file}"
}

if [[ $# -eq 0 ]]; then
    for agent in "${!INSTALLER_URLS[@]}"; do
        fetch_installer "${agent}"
    done
else
    for agent in "$@"; do
        fetch_installer "${agent}"
    done
fi
