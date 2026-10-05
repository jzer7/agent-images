ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

ENV PATH="/root/.local/bin:${PATH}"

# Cursor AI agent installed from offline/pinned repository installer script
# hadolint ignore=DL3022
COPY --from=assets --chmod=+x /cursor-install.sh /tmp/cursor-install.sh

RUN <<EOT
    /tmp/cursor-install.sh
    if [ -f /root/.local/bin/cursor ] && [ ! -f /usr/local/bin/cursor ]; then
        ln -s /root/.local/bin/cursor /usr/local/bin/cursor
    fi
    rm -f /tmp/cursor-install.sh
EOT

WORKDIR /workspace
ENTRYPOINT ["cursor"]
