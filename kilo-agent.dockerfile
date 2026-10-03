ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

# Kilo AI agent installed from offline/pinned repository installer script
COPY installers/kilo-install.sh /tmp/kilo-install.sh

RUN <<EOT
    chmod +x /tmp/kilo-install.sh
    /tmp/kilo-install.sh --no-modify-path
    ln -s /root/.kilo/bin/kilo /usr/local/bin/kilo
    rm -f /tmp/kilo-install.sh
EOT

WORKDIR /workspace
ENTRYPOINT ["kilo"]
