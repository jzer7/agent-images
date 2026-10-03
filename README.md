# Agent Docker Images

Docker images and tooling to run coding AI agents in isolated containers.

## Overview

- **Base Image** (`base.dockerfile`): Debian-based image with Node.js, Python (`uv`),
  Bun, and system CLI utilities (`git`, `ripgrep`, `curl`, `make`).

- **Claude Agent** (`claude-agent.dockerfile`): Extends base image with Claude Code,
  installed via pinned native installer script.
- **Codex Agent** (`codex-agent.dockerfile`): Extends base image with OpenAI Codex
  CLI, installed via npm.
- **Hermes Agent** (`hermes-agent.dockerfile`): Extends base image with Hermes AI
  agent, installed via pinned installer script.
- **Kilo Agent** (`kilo-agent.dockerfile`): Extends base image with Kilo AI CLI,
  installed via pinned installer script.
- **OpenClaw Agent** (`openclaw-agent.dockerfile`): Extends base image with
  OpenClaw agent, installed via pinned installer script.
- **Pi Agent** (`pi-agent.dockerfile`): Extends base image with `@earendil-works/pi-coding-agent`.

## Repository Layout

- `agent.sh`: Unified runner script to run agents and query support.
- `fetch-installer.sh`: Fetches upstream installer scripts, lints with `shellcheck`,
  and saves them under `installers/`.
- `installers/`: Committed installer scripts used during reproducible container
  builds.
- `Makefile`: Build automation for base and agent images.

## Building Images

Build all images:

```sh
make build
```

Build a specific image:

```sh
make build-base
make build-claude-agent
make build-codex-agent
make build-hermes-agent
make build-kilo-agent
make build-openclaw-agent
make build-pi-agent
```

Specify a custom version tag (defaults to `latest`):

```sh
make build VERSION=0.1.0
```

## Running Agents

Run the unified `agent.sh` runner from any directory within your home tree:

```sh
# Run Claude Code agent
./agent.sh claude

# Run OpenAI Codex agent
./agent.sh codex

# Run Hermes agent
./agent.sh hermes

# Run Kilo agent
./agent.sh kilo

# Run OpenClaw agent
./agent.sh openclaw

# Run Pi agent
./agent.sh pi

# Pass arguments directly to the agent
./agent.sh kilo --help
```

List supported agents:

```sh
./agent.sh --list
```

List only supported agents with available local Docker images:

```sh
./agent.sh --list-available
```

## Updating Installers

Fetch upstream installation scripts, run shellcheck, and store them locally:

```sh
make fetch-installers
# or
./fetch-installer.sh claude
./fetch-installer.sh hermes
./fetch-installer.sh kilo
./fetch-installer.sh openclaw
```
