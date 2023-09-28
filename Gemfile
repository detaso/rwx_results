# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Simple wrapper for the GitHub API
gem "octokit", "~> 7.1"

# octokit deps
gem "faraday-multipart"
gem "faraday-retry"

# Thor is a toolkit for building powerful command-line interfaces.
gem "thor", "~> 1.2"

# Adds parameter validation and error control to interactor
gem "metaractor", "~> 3.3"

# EXtended http(s) CONnections
gem "excon", "~> 0.103"

group :development do
  # Debugging functionality for Ruby. This is completely rewritten debug.rb which was contained by the ancient Ruby versions.
  gem "debug", "~> 1.8"
end
