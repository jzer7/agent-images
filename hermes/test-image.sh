#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-${IMAGE_NAME:-}}"

error() {
    local format="$1"
    shift
    # shellcheck disable=SC2059
    printf "\033[31mError: ${format}\033[0m\n" "$@" >&2
}

if [ -z "$IMAGE_NAME" ]; then
    error "IMAGE_NAME not specified"
    echo "Usage: $0 <image-name>" >&2
    exit 1
fi

TEST_HELP_PATTERNS=(
    "^usage: hermes"
    "^positional arguments:$"
    "^options:$"
)

TEST_VERSION_PATTERNS=(
    "^Hermes Agent v[0-9]+[.][0-9]+[.][0-9]+"
)

check_for_all_patterns() {
    local output="$1"
    shift
    local patterns=("$@")

    for pattern in "${patterns[@]}"; do
        if ! printf '%s\n' "$output" | grep -Eq "$pattern"; then
            error "Missing pattern '%s'" "$pattern"
            return 1
        fi
    done
}

echo "=== Starting test (help) of image ${IMAGE_NAME}"
help_output=$(docker run --rm "${IMAGE_NAME}" --help)
check_for_all_patterns "$help_output" "${TEST_HELP_PATTERNS[@]}"
echo "=== Completed test (help) of image ${IMAGE_NAME}"

echo "=== Starting test (version) of image ${IMAGE_NAME}"
version_output=$(docker run --rm "${IMAGE_NAME}" --version)
check_for_all_patterns "$version_output" "${TEST_VERSION_PATTERNS[@]}"
echo "=== Completed test (version) of image ${IMAGE_NAME}"
