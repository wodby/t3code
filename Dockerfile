ARG NODE_VER=24

FROM node:${NODE_VER}-trixie-slim

ARG TARGETARCH

ARG T3CODE_VER
ARG CODEX_VER=latest
ARG OPENCODE_VER=latest

ENV T3CODE_VER="${T3CODE_VER}"
ENV T3CODE_HOST=0.0.0.0
ENV T3CODE_PORT=3773

ENV SHELL=/bin/bash

RUN echo 'Acquire::Retries "10";' > /etc/apt/apt.conf.d/80-retries && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        jq \
        less \
        make \
        openssh-client \
        procps \
        python3 \
        ripgrep \
        tini \
        unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN usermod --home /data --shell /bin/bash node && \
    mkdir -p /data && \
    chown node:node /data

RUN set -eu; \
    if [ -z "${T3CODE_VER}" ]; then \
      echo "T3CODE_VER is required (example: 0.1.5)"; \
      exit 1; \
    fi; \
    case "${TARGETARCH}" in \
      amd64) arch=x64 ;; \
      arm64) arch=arm64 ;; \
      *) echo "Unsupported architecture ${TARGETARCH}"; exit 1 ;; \
    esac; \
    archive="t3-${T3CODE_VER}-linux-${arch}.tar.gz"; \
    url="https://github.com/pingdotgg/t3code/releases/download/v${T3CODE_VER}"; \
    cd /tmp; \
    curl -fsSL --retry 3 -O "${url}/${archive}"; \
    curl -fsSL --retry 3 -O "${url}/SHA256SUMS"; \
    grep -E "[[:space:]]\*?${archive}\$" SHA256SUMS | sha256sum -c -; \
    mkdir -p /opt/t3code; \
    tar -xzof "${archive}" --strip-components=1 -C /opt/t3code; \
    rm -f "${archive}" SHA256SUMS; \
    ln -s /opt/t3code/t3 /usr/local/bin/t3

# The libraries and fonts of T3 Code's built-in browser. Installing them later would need root.
RUN t3 browser setup && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Claude Code isn't installed here: its license doesn't allow redistributing it. The entrypoint
# downloads it from Anthropic to the volume on first start.
RUN npm install -g --no-fund --no-audit \
        "@openai/codex@${CODEX_VER}" \
        "opencode-ai@${OPENCODE_VER}" && \
    npm cache clean --force

# Everything that must survive a restart lives in the home directory on the volume: T3 Code's
# database, agent logins, projects and tools the user installs. Tools installed there with npm or a
# native installer win over the image's.
ENV HOME=/data
ENV NPM_CONFIG_PREFIX=/data/.local
ENV PATH="/data/.local/bin:${PATH}"

COPY docker-entrypoint.sh /
COPY bin /usr/local/bin
COPY profile.sh /etc/profile.d/t3code.sh

USER node

WORKDIR /data

VOLUME /data

EXPOSE 3773

# T3 Code runs many agent processes: tini reaps them and forwards signals.
ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]

CMD ["t3", "serve"]
