ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

ENV PATH="/root/.local/bin:${PATH}"

# GitHub Copilot CLI
RUN <<EOT
    npm install -g @github/copilot
EOT

WORKDIR /workspace
ENTRYPOINT ["copilot"]
