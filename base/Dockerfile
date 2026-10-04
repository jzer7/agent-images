ARG BASE_IMAGE=node:26-trixie-slim
FROM ${BASE_IMAGE}

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

# uv (python) installed from offline/pinned repository installer script
# hadolint ignore=DL3022
COPY --from=assets --chmod=+x /uv-install.sh /tmp/uv-install.sh

RUN <<EOT
    /tmp/uv-install.sh
    rm -f /tmp/uv-install.sh
    ln -s /root/.local/bin/uv /usr/local/bin/uv
    ln -s /root/.local/bin/uvx /usr/local/bin/uvx
    uv python install 3.14 --default
EOT
