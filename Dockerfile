# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim as base

WORKDIR /app

# Set production environment
ENV RAILS_ENV="production" \
  BUNDLE_WITHOUT="development:test" \
  BUNDLE_DEPLOYMENT="1"

# Update gems and bundler
RUN set -eux; \
  \
  gem update --system --no-document; \
  gem install -N bundler

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN set -eux; \
  \
  apt-get update -qq; \
  apt-get install --no-install-recommends -y build-essential pkg-config

# Install application gems
COPY --link Gemfile Gemfile.lock ./
RUN set -eux; \
  \
  bundle install;  \
  rm -rf ~/.bundle/ "$GEM_HOME/ruby/*/cache" "$GEM_HOME/ruby/*/bundler/gems/*/.git"

# Copy application code
COPY --link . .

FROM base

LABEL repository="https://github.com/detaso/rwx-results"
LABEL homepage="https://github.com/detaso/rwx-results"
LABEL maintainer="Ryan Schlesinger <ryan@ryanschlesinger.com>"

LABEL com.github.actions.name="RWX Results"
LABEL com.github.actions.description="A GitHub Action to show results from Captain and ABQ."
LABEL com.github.actions.icon="check-circle"
LABEL com.github.actions.color="green"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
  \
  apt-get update; \
  apt-get install -y --no-install-recommends \
  curl \
  jq \
  libjemalloc2 \
  openssl \
  ; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

# Run and own only the runtime files as a non-root user for security
RUN set -eux; \
  \
  useradd app --create-home --shell /bin/bash; \
  mkdir /data; \
  chown -R app:app /app /data

USER app:app

# Deployment options
ENV LD_PRELOAD="libjemalloc.so.2" \
  MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true" \
  BUNDLE_GEMFILE=/app/Gemfile

VOLUME /data

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "rwx_results" ]
