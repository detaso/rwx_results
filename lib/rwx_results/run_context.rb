module RwxResults
  RunContext =
    Data.define(
      :payload,
      :event_name,
      :sha,
      :ref,
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
      def self.from_env
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
        attributes[:workflow] = ENV["GITHUB_WORKFLOW"]
        attributes[:action] = ENV["GITHUB_ACTION"]
        attributes[:actor] = ENV["GITHUB_ACTOR"]
        attributes[:job] = ENV["GITHUB_JOB"]
        attributes[:run_number] = ENV["GITHUB_RUN_NUMBER"]&.to_i
        attributes[:run_id] = ENV["GITHUB_RUN_ID"]&.to_i
        attributes[:api_url] = ENV.fetch("GITHUB_API_URL", "https://api.github.com")
        attributes[:server_url] = ENV.fetch("GITHUB_SERVER_URL", "https://github.com")
        attributes[:graphql_url] = ENV.fetch("GITHUB_GRAPHQL_URL", "https://api.github.com/graphql")

        new(**attributes)
      end
    end
end
