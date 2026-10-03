#!/usr/bin/env bash

set -euo pipefail

SUPPORTED_AGENTS=(claude codex hermes kilo openclaw pi)

usage() {
    cat <<'EOF'
Usage: ./agent.sh <agent-name> [agent-arguments...]
       ./agent.sh --list
       ./agent.sh --list-available

Options:
  --list            List all supported agents
  --list-available  List supported agents with available Docker images

Available agents:
  claude    Run Claude Code agent (image: jzer7/agent:claude-latest)
  codex     Run OpenAI Codex agent (image: jzer7/agent:codex-latest)
  hermes    Run Hermes coding agent (image: jzer7/agent:hermes-latest)
  kilo      Run Kilo coding agent (image: jzer7/agent:kilo-latest)
  openclaw  Run OpenClaw personal agent (image: jzer7/agent:openclaw-latest)
  pi        Run Pi coding agent (image: jzer7/agent:pi-latest)

Environment variables:
  IMAGE  Override the default Docker image
EOF
}

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

configure_agent() {
    local agent="$1"

    # shellcheck disable=SC2034
    case "$agent" in
    claude)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:claude-latest}"
        AGENT_VOLUME="claude-agent-home:/root/.claude"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
            ANTHROPIC_AUTH_TOKEN
            ANTHROPIC_BASE_URL
            ANTHROPIC_MODEL
        )
        ;;
    codex)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:codex-latest}"
        AGENT_VOLUME="codex-agent-home:/root/.codex"
        PASS_ENV_VARS=(
            OPENAI_API_KEY
        )
        ;;
    hermes)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:hermes-latest}"
        AGENT_VOLUME="hermes-agent-home:/root/.hermes"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
            OPENAI_API_KEY
            OPENROUTER_API_KEY
            NOUS_API_KEY
        )
        ;;
    kilo)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:kilo-latest}"
        AGENT_VOLUME="kilo-agent-home:/root/.kilo"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
            OPENAI_API_KEY
            OPENROUTER_API_KEY
            KILO_API_KEY
        )
        ;;
    openclaw)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:openclaw-latest}"
        AGENT_VOLUME="openclaw-agent-home:/root/.openclaw"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
            OPENAI_API_KEY
            OPENROUTER_API_KEY
        )
        ;;
    pi)
        AGENT_IMAGE="${IMAGE:-jzer7/agent:pi-latest}"
        AGENT_VOLUME="pi-agent-home:/root/.pi"
        PASS_ENV_VARS=(
            ANTHROPIC_API_KEY
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

    docker run --rm -it \
        --name "${container_name}" \
        "${env_flags[@]}" \
        --add-host=host.docker.internal:host-gateway \
        -v "$PWD:/$mount_point" \
        -v "${volume}" \
        -w "/$mount_point" \
        "${image}" \
        "$@"
}

main() {
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
        exit 0
    fi

    case "$1" in
    --list)
        list_agents
        exit 0
        ;;
    --list-available)
        list_available_agents
        exit 0
        ;;
    esac

    local agent="$1"
    shift

    check_interactive_tty
    check_working_directory

    # shellcheck disable=SC2034
    configure_agent "$agent"

    # shellcheck disable=SC2034
    local -a docker_env_flags
    build_env_flags PASS_ENV_VARS docker_env_flags

    local mount_point
    mount_point=$(dir_to_home_name "$(pwd)")
    local container_name="${agent}-$RANDOM"

    run_container \
        "${AGENT_IMAGE}" \
        "${AGENT_VOLUME}" \
        "${container_name}" \
        "${mount_point}" \
        docker_env_flags[@] \
        "$@"
}

main "$@"
