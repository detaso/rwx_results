require "rwx_results/run_context"

module RwxResults
  class Captain
    include Metaractor
    extend Forwardable

    required :logger
    required :test_suite_id

    optional :branch_name
    optional :commit_sha

    def call
      fetch_captain_summary
      # Generate markdown
      # add/create PR comment
    end

    private

    delegate logger: :context

    def fetch_captain_summary
      url =
        "https://captain.build/api/test_suite_summaries/#{context.test_suite_id}/#{branch_name}/#{commit_sha}"

      logger.debug "Captain results url: #{url}"

      response =
        Excon.get(
          url,
          headers: {
            Accept: "application/json",
            "Accept-Encoding": "gzip",
            Authorization: "Bearer #{ENV.fetch("RWX_ACCESS_TOKEN")}"
          },
          expects: [200],
          idempotent: true,
          retry_errors: [Excon::Error::Timeout, Excon::Error::Server]
        )

      summary = JSON.parse(response.body)
      logger.debug "Captain summary: #{summary.inspect}"
    end

    def branch_name
      if context.has_key?(:branch_name)
        context.branch_name
      elsif %r{refs/heads/(?<branch>.*)} =~ run_context.ref
        branch
      end
    end

    def commit_sha
      if context.has_key?(:commit_sha)
        context.commit_sha
      else
        run_context.sha
      end
    end

    def run_context
      return @run_context if defined?(@run_context)

      @run_context =
        RunContext.from_env
    end
  end
end
