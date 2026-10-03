ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

# OpenAI Codex CLI
RUN <<EOT
    npm install -g --ignore-scripts @openai/codex
EOT

WORKDIR /workspace
ENTRYPOINT ["codex"]
