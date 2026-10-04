ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

ENV PATH="/root/.local/bin:${PATH}"

# OpenClaw AI agent installed from offline/pinned repository installer script
# hadolint ignore=DL3022
COPY --from=assets --chmod=+x openclaw-install.sh /tmp/openclaw-install.sh

RUN <<EOT
    /tmp/openclaw-install.sh --no-onboard --no-prompt
    if [ -f /root/.local/bin/openclaw ] && [ ! -f /usr/local/bin/openclaw ]; then
        ln -s /root/.local/bin/openclaw /usr/local/bin/openclaw
    fi
    rm -f /tmp/openclaw-install.sh
EOT

WORKDIR /workspace
ENTRYPOINT ["openclaw"]
