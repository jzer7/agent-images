ARG BASE_IMAGE=jzer7/agent:base-latest
FROM ${BASE_IMAGE}

ENV PATH="/root/.local/bin:${PATH}"

# omp installed from the repository installer script
# hadolint ignore=DL3022
COPY --from=assets --chmod=+x /omp-install.sh /tmp/omp-install.sh

RUN <<EOT
    /tmp/omp-install.sh --binary
    rm -f /tmp/omp-install.sh
EOT

WORKDIR /workspace
ENTRYPOINT ["omp"]