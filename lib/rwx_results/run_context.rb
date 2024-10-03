require "rwx_results/types"

module RwxResults
  RunContext =
    Data.define(
      :payload,
      :event_name,
      :sha,
      :ref,
      :head_ref,
      :workflow,
      :action,
      :actor,
      :job,
      :run_number,
      :run_id,
      :api_url,
      :server_url,
      :graphql_url
    ) do
      def self.from_env(**overrides)
        attributes = {}

        attributes[:payload] = {}
        if ENV.key?("GITHUB_EVENT_PATH")
          if File.exist?(ENV["GITHUB_EVENT_PATH"])
            attributes[:payload] =
              JSON.load_file(ENV["GITHUB_EVENT_PATH"])
          end
        end

        attributes[:event_name] = ENV["GITHUB_EVENT_NAME"]
        attributes[:sha] = ENV["GITHUB_SHA"]
        attributes[:ref] = ENV["GITHUB_REF"]
        attributes[:head_ref] = ENV["GITHUB_HEAD_REF"]
        attributes[:workflow] = ENV["GITHUB_WORKFLOW"]
        attributes[:action] = ENV["GITHUB_ACTION"]
        attributes[:actor] = ENV["GITHUB_ACTOR"]
        attributes[:job] = ENV["GITHUB_JOB"]
        attributes[:run_number] = ENV["GITHUB_RUN_NUMBER"]&.to_i
        attributes[:run_id] = ENV["GITHUB_RUN_ID"]&.to_i
        attributes[:api_url] = ENV.fetch("GITHUB_API_URL", "https://api.github.com")
        attributes[:server_url] = ENV.fetch("GITHUB_SERVER_URL", "https://github.com")
        attributes[:graphql_url] = ENV.fetch("GITHUB_GRAPHQL_URL", "https://api.github.com/graphql")

        # overrides
        if overrides[:branch_name]
          attributes[:ref] = "refs/heads/#{overrides[:branch_name]}"
        end

        if overrides[:commit_sha]
          attributes[:sha] = overrides[:commit_sha]
        end

        new(**attributes)
      end

      def issue
        Issue.new(
          number: (payload[:issue] || payload[:pull_request] || payload).number,
          **repo
        )
      end

      def repo
        if ENV.has_key?("GITHUB_REPOSITORY")
          owner, repo = ENV["GITHUB_REPOSITORY"].split("/")
          Repo.new(owner:, repo:)
        end
      end

      def branch_name
        if event_name == "pull_request" ||
            event_name == "pull_request_target"
          head_ref
        elsif %r{refs/heads/(?<branch>.*)} =~ ref
          branch
        end
      end
    end
end
