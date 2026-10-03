ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

ENV PATH="/root/.local/bin:${PATH}"

# Kilo AI agent installed from offline/pinned repository installer script
COPY --from=assets --chmod=+x kilo-install.sh /tmp/kilo-install.sh

RUN <<EOT
    /tmp/kilo-install.sh --no-modify-path
    ln -s /root/.kilo/bin/kilo /usr/local/bin/kilo
    rm -f /tmp/kilo-install.sh
EOT

WORKDIR /workspace
ENTRYPOINT ["kilo"]
