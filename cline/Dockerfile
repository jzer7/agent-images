ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

ENV PATH="/root/.local/bin:${PATH}"

# Cline CLI
RUN <<EOT
    npm install -g --ignore-scripts cline
EOT

WORKDIR /workspace
ENTRYPOINT ["cline"]
