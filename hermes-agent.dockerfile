ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

ENV PATH="/root/.local/bin:${PATH}"

# Hermes AI agent installed from offline/pinned repository installer script
COPY installers/hermes-install.sh /tmp/hermes-install.sh

RUN <<EOT
    chmod +x /tmp/hermes-install.sh
    /tmp/hermes-install.sh --non-interactive --skip-browser --skip-computer-use
    if [ -f /root/.local/bin/hermes ] && [ ! -f /usr/local/bin/hermes ]; then
        ln -s /root/.local/bin/hermes /usr/local/bin/hermes
    fi
    rm -f /tmp/hermes-install.sh
EOT

WORKDIR /workspace
ENTRYPOINT ["hermes"]
