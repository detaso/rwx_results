require "rwx_results/state"

module RwxResults
  class FetchCaptainSummary
    include Metaractor
    include State::Delegator
    extend Forwardable

    required :state
    required :test_suite_id

    optional :branch_name
    optional :commit_sha

    def call
      logger.info "Fetching captain summary..."

      url =
        "https://captain.build/api/test_suite_summaries/#{context.test_suite_id}/#{branch_name}/#{commit_sha}"

      logger.debug "Captain results url: #{url}"

      response =
        Excon.get(
          url,
          headers: {
            Accept: "application/json",
            "Accept-Encoding": "gzip, deflate",
            Authorization: "Bearer #{ENV.fetch("RWX_ACCESS_TOKEN")}"
          },
          expects: [200],
          idempotent: true,
          retry_errors: [Excon::Error::Timeout, Excon::Error::Server],
          middlewares: Excon.defaults[:middlewares] + [
            Excon::Middleware::Decompress
          ]
        )

      logger.debug "Response body: #{response.body}"
      summary = JSON.parse(response.body)
      logger.debug "Captain summary: #{summary.inspect}"

      context.captain_summary = summary
    end

    private

    delegate state: :context

    def branch_name
      if context.has_key?(:branch_name)
        context.branch_name
      elsif %r{refs/heads/(?<branch>.*)} =~ run_context.ref
        branch
      else
        raise "No branch name found!"
      end
    end

    def commit_sha
      if context.has_key?(:commit_sha)
        context.commit_sha
      else
        run_context.sha
      end
    end
  end
end
