#!/usr/bin/env bash

set -euo pipefail

SUPPORTED_AGENTS=(claude cline codex command-code copilot cursor hermes kilo omp openclaw pi)

usage() {
    cat <<'EOF'
Usage: ./agent.sh [--vol VOLUME_NAME] <agent-name> [agent-arguments...]
       ./agent.sh --list
       ./agent.sh --list-available

Options:
    --list              List all supported agents
    --list-available    List supported agents with available Docker images
    --vol VOLUME_NAME   Docker volume to mount as /root (default: agent-$USER)

Available agents:
  claude        Run Claude Code agent (image: jzer7/agent:claude-latest)
  cline         Run Cline CLI agent (image: jzer7/agent:cline-latest)
  codex         Run OpenAI Codex agent (image: jzer7/agent:codex-latest)
  command-code  Run Command Code agent (image: jzer7/agent:command-code-latest)
  copilot       Run GitHub Copilot agent (image: jzer7/agent:copilot-latest)
  cursor        Run Cursor coding agent (image: jzer7/agent:cursor-latest)
  hermes        Run Hermes Agent (image: jzer7/agent:hermes-latest)
  kilo          Run Kilo coding agent (image: jzer7/agent:kilo-latest)
  omp           Run omp coding agent (image: jzer7/agent:omp-latest)
  openclaw      Run OpenClaw personal agent (image: jzer7/agent:openclaw-latest)
  pi            Run Pi coding agent (image: jzer7/agent:pi-latest)

Environment variables:
  IMAGE  Override the default Docker image
EOF
}

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

debug() {
    local format="$1"
    shift
    # shellcheck disable=SC2059
    printf "\033[33mDEBUG: ${format}\033[0m\n" "$@" >&2
}

# ----------------------------------------------------------
#
# ----------------------------------------------------------
list_agents() {
    for agent in "${SUPPORTED_AGENTS[@]}"; do
        printf '%s\n' "$agent"
    done
}

list_available_agents() {
    for agent in "${SUPPORTED_AGENTS[@]}"; do
        configure_agent "$agent"
        if docker image inspect "$AGENT_IMAGE" >/dev/null 2>&1; then
            printf '%s\n' "$agent"
        fi
    done
}

check_interactive_tty() {
    if ! [ -t 0 ] || ! [ -t 1 ]; then
        printf '%s\n' 'error: this script must be run from an interactive TTY.' >&2
        exit 1
    fi
}

check_working_directory() {
    local cwd
    cwd=$(pwd)
    case "$cwd" in
    / | */*)
        if [ "$cwd" = "/" ]; then
            printf '%s\n' 'error: this script must be run from a directory within a directory.' >&2
            exit 1
        fi
        ;;
    *)
        printf '%s\n' 'error: this script must be run from a directory within a directory.' >&2
        exit 1
        ;;
    esac
}

dir_to_home_name() {
    local dir="$1"
    local phys_dir phys_home rel name

    phys_dir=$(cd -P -- "$dir" && pwd) || return 1
    phys_home=$(cd -P -- "$HOME" && pwd) || return 1

    rel=${phys_dir#"$phys_home"/}

    # when at home directory
    [ "$rel" = "$phys_dir" ] && rel=_

    # sanitize
    name=${rel//./_}
    name=${name//\//--}

    printf '%s\n' "$name"
}

build_env_flags() {
    local -n env_vars=$1
    local -n out_flags=$2

    out_flags=()
    for var in "${env_vars[@]}"; do
        out_flags+=("-e" "$var")
    done
}

ensure_volume_exists() {
    local volume_name="$1"
    shift
    local -a dir_names=("$@")

    if ! docker volume inspect "$volume_name" >/dev/null 2>&1; then
        docker volume create "$volume_name" >/dev/null
    fi

    if [ "${#dir_names[@]}" -gt 0 ]; then
        local -a volume_dirs=()
        for dir_name in "${dir_names[@]}"; do
            volume_dirs+=("/x/$dir_name")
        done
        docker run --rm -v "$volume_name:/x" alpine mkdir -p -- "${volume_dirs[@]}"
    fi
}

configure_agent() {
    local agent="$1"

    # shellcheck disable=SC2034
    case "$agent" in
    claude)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:claude-latest}"
        AGENT_CONFIG_DIR=".claude"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
            ANTHROPIC_AUTH_TOKEN
            ANTHROPIC_BASE_URL
            ANTHROPIC_MODEL
        )
        ;;
    cline)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:cline-latest}"
        AGENT_CONFIG_DIR=".cline"
        PASS_ENV_VARS=(
            CLINE_COMMAND_PERMISSIONS
            CLINE_DATA_DIR
        )
        ;;
    codex)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:codex-latest}"
        AGENT_CONFIG_DIR=".codex"
        PASS_ENV_VARS=(
            OPENAI_API_KEY
        )
        ;;
    command-code)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:command-code-latest}"
        AGENT_CONFIG_DIR=".commandcode"
        PASS_ENV_VARS=(
            COMMAND_CODE_API_KEY
        )
        ;;
    copilot)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:copilot-latest}"
        AGENT_CONFIG_DIR=".copilot"
        PASS_ENV_VARS=(
            COPILOT_GITHUB_TOKEN
            GH_TOKEN
            GITHUB_TOKEN
            COPILOT_PROVIDER_API_KEY
            COPILOT_PROVIDER_BASE_URL
        )
        ;;
    cursor)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:cursor-latest}"
        AGENT_CONFIG_DIR=".cursor"
        PASS_ENV_VARS=(
        )
        ;;
    hermes)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:hermes-latest}"
        AGENT_CONFIG_DIR=".hermes"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
            NOUS_API_KEY
            OPENAI_API_KEY
            OPENROUTER_API_KEY
        )
        ;;
    kilo)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:kilo-latest}"
        AGENT_CONFIG_DIR=".kilo"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
            KILO_API_KEY
            OPENAI_API_KEY
            OPENROUTER_API_KEY
        )
        ;;
    omp)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:omp-latest}"
        AGENT_CONFIG_DIR=".omp"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
            ANTHROPIC_AUTH_TOKEN
            ANTHROPIC_OAUTH_TOKEN
            COPILOT_GITHUB_TOKEN
            OPENROUTER_API_KEY
        )
        ;;
    openclaw)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:openclaw-latest}"
        AGENT_CONFIG_DIR=".openclaw"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
            OPENAI_API_KEY
            OPENROUTER_API_KEY
        )
        ;;
    pi)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:pi-latest}"
        AGENT_CONFIG_DIR=".pi"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
            ANTHROPIC_AUTH_TOKEN
            ANTHROPIC_OAUTH_TOKEN
            OPENAI_API_KEY
            OPENROUTER_API_KEY
        )
        ;;
    *)
        printf 'error: unknown agent "%s"\n\n' "$agent" >&2
        usage >&2
        exit 1
        ;;
    esac
}

run_container() {
    local image="$1"
    local volume="$2"
    local container_name="$3"
    local mount_point="$4"
    shift 4
    local -a env_flags=("${!1}")
    shift 1
    local -a dirs_to_mount=("${!1}")
    shift 1
    local -a volume_mounts=()

    for dir_name in "${dirs_to_mount[@]}"; do
        volume_mounts+=(--mount "type=volume,src=${volume},dst=/root/${dir_name},volume-subpath=${dir_name}")
    done

    docker run --rm -it \
        --name "${container_name}" \
        "${env_flags[@]}" \
        --add-host=host.docker.internal:host-gateway \
        "${volume_mounts[@]}" \
        -v "$PWD:/$mount_point" \
        -w "/$mount_point" \
        "${image}" \
        "$@"
}

main() {
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
        exit 0
    fi

    local volume_name="agent-${USER:-$(id -un)}"
    while [ "$#" -gt 0 ]; do
        case "$1" in
        --vol)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                printf '%s\n' 'error: --vol requires a volume name.' >&2
                exit 2
            fi
            volume_name="$2"
            shift 2
            ;;
        *)
            break
            ;;
        esac
    done

    case "${1:-}" in
    --list)
        list_agents
        exit 0
        ;;
    --list-available)
        list_available_agents
        exit 0
        ;;
    esac

    if [ "$#" -eq 0 ]; then
        usage
        exit 0
    fi

    local agent="$1"
    shift

    local -a agent_args=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
        --vol)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                printf '%s\n' 'error: --vol requires a volume name.' >&2
                exit 2
            fi
            volume_name="$2"
            shift 2
            ;;
        --)
            shift
            agent_args+=("$@")
            break
            ;;
        *)
            agent_args+=("$1")
            shift
            ;;
        esac
    done

    check_interactive_tty
    check_working_directory

    # shellcheck disable=SC2034
    configure_agent "$agent"

    # The agents are installed in `.npm` of the image, do not shadow them with
    # a different mount point
    local -a use_directories=("$AGENT_CONFIG_DIR" ".config")
    ensure_volume_exists "$volume_name" "${use_directories[@]}"

    # shellcheck disable=SC2034
    local -a docker_env_flags
    build_env_flags PASS_ENV_VARS docker_env_flags

    local mount_point
    mount_point=$(dir_to_home_name "$(pwd)")
    local container_name="${agent}-$RANDOM"

    run_container \
        "${AGENT_IMAGE}" \
        "${volume_name}" \
        "${container_name}" \
        "${mount_point}" \
        docker_env_flags[@] \
        use_directories[@] \
        "${agent_args[@]}"
}

main "$@"
