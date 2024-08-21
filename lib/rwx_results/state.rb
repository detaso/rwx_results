require "rwx_results/run_context"

module RwxResults
  class State
    def logger
      return @logger if defined?(@logger)

      require "rwx_results/logger"
      @logger =
        Logger.new
    end

    def octokit
      return @octokit if defined?(@octokit)

      Octokit.configure do |c|
        c.api_endpoint = run_context.api_url
        c.web_endpoint = run_context.server_url
        c.auto_paginate = true
      end

      @octokit =
        Octokit::Client.new(
          access_token: ENV.fetch("GITHUB_TOKEN")
        )
    end

    def run_context
      return @run_context if defined?(@run_context)

      @run_context =
        RunContext.from_env
    end

    module Delegator
      def self.included(base)
        base.class_eval do
          extend Forwardable

          private

          delegate [:logger, :octokit, :run_context] => :state
        end
      end
    end
  end
end
