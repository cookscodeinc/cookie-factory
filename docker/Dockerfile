# syntax=docker/dockerfile:1.7@sha256:a57df69d0ea827fb7266491f2813635de6f17269be881f696fbfdf2d83dda33e

ARG PYTHON_VERSION=3.11.14

FROM node:24.22.3-bookworm-slim@sha256:dc26ae92c9fb15cf6b1d63e20f0944b2efe0f115b20e00be48fb23fceb061c54 AS node-tools

WORKDIR /opt/lint
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts --no-audit --no-fund

FROM hadolint/hadolint:v2.15.1-debian@sha256:9a3944b7fddcb947d1ffd90829ac1a6e5c30479223358f249d8b96c7d0019e27 AS hadolint

FROM rhysd/actionlint:1.7.12@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667 AS actionlint

FROM python:${PYTHON_VERSION}-slim-bookworm@sha256:65a93d69fa75478d554f4ad27c85c1e69fa184956261b4301ebaf6dbb0a3543d AS toolchain

ARG USER_GID=1000
ARG USER_UID=1000
ARG DEV_USER=vscode

ENV BUNDLE_GEMFILE=/opt/jekyll/Gemfile \
    BUNDLE_FROZEN=true \
    BUNDLE_PATH=/opt/gems \
    GEM_HOME=/opt/gems \
    PATH=/opt/lint/node_modules/.bin:/opt/venv/bin:/opt/gems/bin:${PATH} \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        git \
        make \
        ruby-dev \
        ruby-full \
        shellcheck \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid "${USER_GID}" "${DEV_USER}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${DEV_USER}"

COPY --from=node-tools /usr/local/bin/node /usr/local/bin/node
COPY --from=node-tools /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln --symbolic ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln --symbolic ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx
COPY --from=node-tools /opt/lint/node_modules /opt/lint/node_modules
COPY --from=hadolint /bin/hadolint /usr/local/bin/hadolint
COPY --from=actionlint /usr/local/bin/actionlint /usr/local/bin/actionlint

COPY docker/requirements-test.txt /opt/cookie-factory/requirements-test.txt
RUN python -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --requirement /opt/cookie-factory/requirements-test.txt

COPY docker/Gemfile docker/Gemfile.lock /opt/jekyll/
RUN gem install bundler --version 2.5.23 --no-document \
    && bundle config set --global frozen true \
    && bundle install --gemfile /opt/jekyll/Gemfile --jobs 4 --retry 3 \
    && chown -R "${USER_UID}:${USER_GID}" "/home/${DEV_USER}"
COPY docker/cookie-factory.sh /etc/profile.d/cookie-factory.sh

USER ${DEV_USER}
WORKDIR /workspace

CMD ["sleep", "infinity"]
