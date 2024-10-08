# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Loads environment variables from `.env`.
gem "dotenv", "~> 2.8.1"

# A client library for making HTTP requests from Ruby.
gem "httpx", "~> 1.0"

# Adds parameter validation and error control to interactor
gem "metaractor", "~> 3.3"

# Simple wrapper for the GitHub API
gem "octokit", "~> 7.1"

# octokit deps
gem "faraday-multipart"
gem "faraday-retry"

# Thor is a toolkit for building powerful command-line interfaces.
gem "thor", "~> 1.2"

group :development, :test do
  # Debugging functionality for Ruby. This is completely rewritten debug.rb which was contained by the ancient Ruby versions.
  gem "debug", "~> 1.8"

  # BDD for Ruby
  gem "rspec", "~> 3.12"

  # factory_bot provides a framework and DSL for defining and using factories - less error-prone, more explicit, and all-around easier to work with than fixtures.
  gem "factory_bot", "~> 6.3"

  # WebMock allows stubbing HTTP requests and setting expectations on HTTP requests.
  gem "webmock", "~> 3.19"
end
