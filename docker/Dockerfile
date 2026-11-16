# syntax=docker/dockerfile:1.7@sha256:a57df69d0ea827fb7266491f2813635de6f17269be881f696fbfdf2d83dda33e

ARG PYTHON_VERSION=3.11.14
FROM python:${PYTHON_VERSION}-slim-bookworm@sha256:65a93d69fa75478d554f4ad27c85c1e69fa184956261b4301ebaf6dbb0a3543d AS toolchain

ARG USER_GID=1000
ARG USER_UID=1000
ARG USERNAME=vscode

ENV BUNDLE_GEMFILE=/opt/jekyll/Gemfile \
    BUNDLE_PATH=/opt/gems \
    GEM_HOME=/opt/gems \
    PATH=/opt/venv/bin:/opt/gems/bin:${PATH} \
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
    && groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}"

COPY docker/requirements-test.txt /opt/cookie-factory/requirements-test.txt
RUN python -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --requirement /opt/cookie-factory/requirements-test.txt

COPY docker/Gemfile docker/Gemfile.lock /opt/jekyll/
RUN gem install bundler --version 2.5.23 --no-document \
    && bundle config set --global frozen true \
    && bundle install --gemfile /opt/jekyll/Gemfile --jobs 4 --retry 3 \
    && chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"
COPY docker/cookie-factory.sh /etc/profile.d/cookie-factory.sh

USER ${USERNAME}
WORKDIR /workspace

CMD ["sleep", "infinity"]
