ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

ENV PATH="/root/.local/bin:${PATH}"

# Claude Code AI agent installed from offline/pinned repository installer script
COPY installers/claude-install.sh /tmp/claude-install.sh

RUN <<EOT
    chmod +x /tmp/claude-install.sh
    /tmp/claude-install.sh
    if [ -f /root/.local/bin/claude ] && [ ! -f /usr/local/bin/claude ]; then
        ln -s /root/.local/bin/claude /usr/local/bin/claude
    fi
    rm -f /tmp/claude-install.sh
EOT

WORKDIR /workspace
ENTRYPOINT ["claude"]
