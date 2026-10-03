ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

# Pi
RUN <<EOT
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent
    npm install -g --ignore-scripts skills
EOT

WORKDIR /workspace
ENTRYPOINT ["pi"]

