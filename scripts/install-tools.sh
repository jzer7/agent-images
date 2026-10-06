#!/bin/bash
# Install tools in the local environment
#
# Usage:
#   install-tools <TOOL> [TOOL]     install 1 or more tools
#   install-tools -a                install all tools
#   install-tools -l                list tools available to install
#   install-tools -h                show help
#
# The version of the tools is provided by the file ".tool-versions"
# in the top directory of the repo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOOL_VERSIONS_FILE="${REPO_ROOT}/.tool-versions"

TOOLS_BIN_DIR="${TOOLS_BIN_DIR:-${HOME}/.local/bin}"

SUPPORTED_TOOLS=(hadolint markdownlint prettier shellcheck shfmt)

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
Usage:
  $(basename "$0") <TOOL> [TOOL...]   install 1 or more tools
  $(basename "$0") -a                 install all tools
  $(basename "$0") -l                 list tools available to install
  $(basename "$0") -h                 show help

Supported tools:
  ${SUPPORTED_TOOLS[*]}

Environment variables:
  TOOLS_BIN_DIR          Target directory for binaries (default: \$HOME/.local/bin)
  <TOOL>_VERSION         Override version for specific tool
EOF
}

# Contract:
#   Inputs:  None (inspects `uname -s` and `uname -m`)
#   Outputs: Sets global variables OS (Darwin|Linux) and ARCH (x86_64|aarch64)
#   Errors:  Exits 1 on unsupported OS or architecture
detect_os_arch() {
    local raw_os raw_arch
    raw_os="$(uname -s)"
    raw_arch="$(uname -m)"

    case "${raw_os}" in
    Darwin)
        OS="Darwin"
        case "${raw_arch}" in
        x86_64) ARCH="x86_64" ;;
        arm64 | aarch64) ARCH="aarch64" ;;
        *)
            echo "Unsupported architecture: ${raw_arch}" >&2
            exit 1
            ;;
        esac
        ;;
    Linux)
        OS="Linux"
        case "${raw_arch}" in
        x86_64) ARCH="x86_64" ;;
        aarch64 | arm64) ARCH="aarch64" ;;
        *)
            echo "Unsupported architecture: ${raw_arch}" >&2
            exit 1
            ;;
        esac
        ;;
    *)
        echo "Unsupported OS: ${raw_os}" >&2
        exit 1
        ;;
    esac
}

get_tool_version() {
    local tool="$1"
    local var_name
    var_name="$(echo "${tool}_VERSION" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"

    if [ -n "${!var_name:-}" ]; then
        echo "${!var_name}"
        return 0
    fi

    if [ -f "${TOOL_VERSIONS_FILE}" ]; then
        local ver
        ver="$(grep -E "^${var_name}=" "${TOOL_VERSIONS_FILE}" 2>/dev/null | tail -n 1 | cut -d '=' -f 2- | tr -d '"'\'' ' || true)"
        if [ -n "${ver}" ]; then
            echo "${ver}"
            return 0
        fi
    fi

    echo "Error: Version for ${tool} not found in ${TOOL_VERSIONS_FILE} or environment." >&2
    exit 1
}

ensure_tool_dir() {
    mkdir -p "${TOOLS_BIN_DIR}"
}

install_shellcheck() {
    local version="$1"
    local os_part arch_part url
    case "${OS}" in
    Darwin) os_part="darwin" ;;
    Linux) os_part="linux" ;;
    esac
    arch_part="${ARCH}"

    url="https://github.com/koalaman/shellcheck/releases/download/v${version}/shellcheck-v${version}.${os_part}.${arch_part}.tar.xz"

    echo "==> Installing shellcheck v${version} into ${TOOLS_BIN_DIR}"
    ensure_tool_dir
    curl -sSL "${url}" | tar -xJ --strip-components=1 -C "${TOOLS_BIN_DIR}" "shellcheck-v${version}/shellcheck"
    chmod +x "${TOOLS_BIN_DIR}/shellcheck"
}

install_shfmt() {
    local version="$1"
    local os_part arch_part url
    case "${OS}" in
    Darwin) os_part="darwin" ;;
    Linux) os_part="linux" ;;
    esac

    case "${ARCH}" in
    x86_64) arch_part="amd64" ;;
    aarch64) arch_part="arm64" ;;
    esac

    url="https://github.com/mvdan/sh/releases/download/v${version}/shfmt_v${version}_${os_part}_${arch_part}"

    echo "==> Installing shfmt v${version} into ${TOOLS_BIN_DIR}"
    ensure_tool_dir
    curl -sSL -o "${TOOLS_BIN_DIR}/shfmt" "${url}"
    chmod +x "${TOOLS_BIN_DIR}/shfmt"
}

install_hadolint() {
    local version="$1"
    local os_part arch_part url
    case "${OS}" in
    Darwin) os_part="macos" ;;
    Linux) os_part="linux" ;;
    esac

    case "${ARCH}" in
    x86_64) arch_part="x86_64" ;;
    aarch64) arch_part="arm64" ;;
    esac

    url="https://github.com/hadolint/hadolint/releases/download/v${version}/hadolint-${os_part}-${arch_part}"

    echo "==> Installing hadolint v${version} into ${TOOLS_BIN_DIR}"
    ensure_tool_dir
    curl -sSL -o "${TOOLS_BIN_DIR}/hadolint" "${url}"
    chmod +x "${TOOLS_BIN_DIR}/hadolint"
}

install_prettier() {
    local version="$1"
    local prefix_dir
    prefix_dir="$(cd "${TOOLS_BIN_DIR}/.." && pwd)"

    echo "==> Installing prettier v${version} via npm into ${prefix_dir}"
    ensure_tool_dir
    npm install -g --prefix "${prefix_dir}" "prettier@${version}"
}

install_markdownlint() {
    local version="$1"
    local prefix_dir
    prefix_dir="$(cd "${TOOLS_BIN_DIR}/.." && pwd)"

    echo "==> Installing markdownlint-cli2 v${version} via npm into ${prefix_dir}"
    ensure_tool_dir
    npm install -g --prefix "${prefix_dir}" "markdownlint-cli2@${version}"
}

install_tool() {
    local tool="$1"
    local version
    version="$(get_tool_version "${tool}")"

    case "${tool}" in
    shellcheck)
        install_shellcheck "${version}"
        ;;
    shfmt)
        install_shfmt "${version}"
        ;;
    hadolint)
        install_hadolint "${version}"
        ;;
    prettier)
        install_prettier "${version}"
        ;;
    markdownlint | markdownlint-cli2)
        install_markdownlint "${version}"
        ;;
    *)
        echo "Error: Unknown tool '${tool}'" >&2
        echo "Supported tools: ${SUPPORTED_TOOLS[*]}" >&2
        exit 1
        ;;
    esac
}

list_tools() {
    echo "Available tools to install:"
    for tool in "${SUPPORTED_TOOLS[@]}"; do
        local ver
        ver="$(get_tool_version "${tool}")"
        printf "  %-15s (v%s)\n" "${tool}" "${ver}"
    done
}

main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi

    detect_os_arch

    case "$1" in
    -h | --help)
        usage
        exit 0
        ;;
    -l | --list)
        list_tools
        exit 0
        ;;
    -a | --all)
        for tool in "${SUPPORTED_TOOLS[@]}"; do
            install_tool "${tool}"
        done
        ;;
    -*)
        echo "Error: Unknown option '$1'" >&2
        usage
        exit 1
        ;;
    *)
        for tool in "$@"; do
            install_tool "${tool}"
        done
        ;;
    esac
}

main "$@"
