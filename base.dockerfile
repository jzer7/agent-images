# https://hub.docker.com/_/node
FROM node:26-trixie-slim

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    UV_SYSTEM_PYTHON=1

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN <<EOT
    apt-get update
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        fd-find \
        git \
        make \
        ripgrep \
        unzip \
        wget
    apt-get clean
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

# uv (python)
RUN <<EOT
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ln -s /root/.local/bin/uv /usr/local/bin/uv
    ln -s /root/.local/bin/uvx /usr/local/bin/uvx
EOT

RUN <<EOT
    /usr/local/bin/uv venv --directory /root -p 3.12
    ln -s /root/.venv/bin/python3 /usr/local/bin/python3
EOT

# Bun (js)
RUN <<EOT
    curl -fsSL https://bun.sh/install | bash
    ln -s /root/.bun/bin/bun  /usr/local/bin/bun
    ln -s /root/.bun/bin/bunx /usr/local/bin/bunx
EOT

WORKDIR /workspace
