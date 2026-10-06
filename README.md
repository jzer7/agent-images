# Agent container images

[![Dependabot Updates](https://github.com/jzer7/agent-images/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/jzer7/agent-images/actions/workflows/dependabot/dependabot-updates)
[![CI images](https://github.com/jzer7/agent-images/actions/workflows/ci-images.yml/badge.svg)](https://github.com/jzer7/agent-images/actions/workflows/ci-images.yml)
[![CI docs](https://github.com/jzer7/agent-images/actions/workflows/ci-docs.yml/badge.svg)](https://github.com/jzer7/agent-images/actions/workflows/ci-docs.yml)

Container images and tooling for running AI agents in isolated containers.

## Overview

- **Base Image** (`agent:base`): Node.js 26 on Debian Trixie slim, `uv`, and
  CLI utilities including `git`, `ripgrep`, `curl`, `fd-find`, and `make`.

- **Claude Agent** (`agent:claude`): Extends base image with Claude Code,
  installed by an installer script.
- **Codex Agent** (`agent:codex`): Extends base image with OpenAI Codex
  CLI, installed with npm.
- **Hermes Agent** (`agent:hermes`): Extends base image with Hermes AI
  agent, installed by an installer script.
- **Kilo Agent** (`agent:kilo`): Extends base image with Kilo AI CLI,
  installed by an installer script.
- **OpenClaw Agent** (`agent:openclaw`): Extends base image with
  OpenClaw agent, installed by an installer script.
- **Pi Agent** (`agent:pi`): Extends base image with Pi and the `skills` npm
  package.

## Repository layout

- `scripts/run_agent.sh`: runs an agent in Docker or lists supported agents.
- `scripts/fetch-asset.sh`: fetches upstream installer scripts into `assets/`.
- `assets/`: install and configuration script snapshots for Claude, Hermes,
  Kilo, OpenClaw, Pi, and uv.
- `base/`, `claude/`, `codex/`, `hermes/`, `kilo/`, `openclaw/`, `pi/`:
  image-specific Dockerfiles and Makefiles.
- `Makefile`: build, lint, format, and test targets.

## Building images

Build all images (fetches missing assets first):

```sh
make build
```

Build a specific image:

```sh
make build-base
make build-claude
make build-codex
make build-hermes
make build-kilo
make build-openclaw
make build-pi
```

Specify a custom version tag (defaults to `latest`):

```sh
make build VERSION=0.1.0
```

## Running agents

Run the agent runner from a directory you want to mount as the workspace. Docker
and an interactive terminal are required.

```sh
# Run Claude Code agent
./scripts/run_agent.sh claude

# Run OpenAI Codex agent
./scripts/run_agent.sh codex

# Run Hermes agent
./scripts/run_agent.sh hermes

# Run Kilo agent
./scripts/run_agent.sh kilo

# Run OpenClaw agent
./scripts/run_agent.sh openclaw

# Run Pi agent
./scripts/run_agent.sh pi

# Pass arguments directly to the agent
./scripts/run_agent.sh kilo --help
```

The runner mounts the current directory into the container, uses a persistent
Docker volume for agent settings, and forwards supported API-key environment
variables when set. Set `IMAGE` to override the default agent image.

List supported agents:

```sh
./scripts/run_agent.sh --list
```

List only supported agents with available local Docker images:

```sh
./scripts/run_agent.sh --list-available
```

Examples:

```sh
# run the Claude agent
./scripts/run_agent.sh claude

# get help about the Kilo agent
./scripts/run_agent.sh kilo --help

# list Openclaw plugins
./scripts/run_agent.sh openclaw plugins list

# continue a previous session with the Pi agent
./scripts/run_agent.sh pi --continue "OAuth token expired"
```

### Note on LLM providers

There are multiple ways to configure LLM providers for the agent running in a
container.

- TUI asks on first run and stores the configuration in a persistent volume.
  Some come preconfigured with a safe default (e.g., Kilo).
- Slash command inside the TUI (e.g., `/provider`)
- Environment variables (e.g., `export OPENAI_API_KEY=YOUR_OPENAI_API_KEY`),
  which are forwarded to the container when set.
- Command line subcommand or argument (e.g., `setup`, or `--api-key YOUR_OPENAI_API_KEY`).
- Manually updating the configuration file in the persistent volume (e.g.,
  `~/.codex/config.toml`). This is advanced, so not covered in this document.

The options might change, so use the `--help` option on the agent runner to see
the available options for each agent.

| Agent    | First run          | Env variable | Slash command | CLI subcommand | ⚠️ CLI argument |
| -------- | ------------------ | ------------ | ------------- | -------------- | --------------- |
| claude   | ✅                 | ✅           |               | `setup-token`  |                 |
| codex    | ✅                 |              |               | `login`        |                 |
| hermes   | ✅                 | ✅           |               | `setup`        |                 |
| kilo     | ✅ (preconfigured) | ✅           | `/connect`    | `config`       |                 |
| openclaw | ✅                 |              |               | `setup`        |                 |
| pi       |                    | ✅           | `/login`      |                | `--api-key`     |

> [!CAUTION]
> Passing API keys or other secrets in the CLI is not secure.

## Assets

> [!CAUTION]
> **Security warning:** Review third-party scripts carefully before trusting or
> running them. Fetching and linting do not guarantee that a script is safe.

Upstream installer scripts are fetched and stored in `assets/`. Existing files
are skipped unless `--force` is supplied. These are snapshots of upstream
scripts; the fetch URLs do not pin a release version.

> [!NOTE]
> The scripts are fetched and stored in `assets/`. But that does not guarantee
> full reproducibility of the agent installation, as some scripts dynamically
> determine the version to install at runtime. Please study each script to
> understand how it works and what it installs.

To refresh the assets for a all software component, use:

```sh
make fetch-scripts
```

This runs `scripts/fetch-asset.sh`. It attempts to run `shellcheck` when
available, but continues if shellcheck is unavailable or reports issues. To
force a refresh of a specific asset, pass its component name:

```sh
# Refresh the OpenClaw assets:
./scripts/fetch-asset.sh --force openclaw

# Refresh all available assets:
./scripts/fetch-asset.sh --force
```
