ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

ENV PATH="/root/.local/bin:${PATH}"

# Command-code CLI
RUN <<EOT
    npm install -g --ignore-scripts command-code@latest
EOT

WORKDIR /workspace
ENTRYPOINT ["command-code"]
