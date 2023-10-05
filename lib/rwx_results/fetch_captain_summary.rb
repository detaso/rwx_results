require "rwx_results/state"

module RwxResults
  class FetchCaptainSummary
    MissingBranchError = Class.new(ArgumentError)

    include Metaractor
    include State::Delegator
    extend Forwardable

    required :state
    required :test_suite_id
    optional :branch_name

    optional :commit_sha
    optional :rwx_access_token
    optional :retry_interval, default: 5

    def call
      logger.info "Fetching captain summary..."
      logger.debug "Captain results url: #{url}"

      response = fetch_summary

      logger.debug "Response body: #{response.body}"
      summary = JSON.parse(response.body).transform_keys(&:to_sym)
      logger.debug "Captain summary: #{summary.inspect}"

      context.captain_summary = summary
    end

    def branch_name
      if context.has_key?(:branch_name) && context.branch_name
        context.branch_name
      elsif %r{refs/heads/(?<branch>.*)} =~ run_context.ref
        branch
      else
        raise MissingBranchError,
          "Branch name not provided, and could not be discerned from ref!"
      end
    end

    def commit_sha
      if context.has_key?(:commit_sha) && context.commit_sha
        context.commit_sha
      else
        run_context.sha
      end
    end

    def url
      "https://captain.build/api/test_suite_summaries/#{context.test_suite_id}/#{branch_name}/#{commit_sha}"
    end

    private

    delegate state: :context

    def fetch_summary
      Excon.get(
        url,
        headers: {
          Accept: "application/json",
          "Accept-Encoding": "gzip, deflate",
          Authorization: "Bearer #{rwx_access_token}"
        },
        expects: [200],
        idempotent: true,
        retry_errors: [
          Excon::Error::Timeout,
          Excon::Error::Socket,
          Excon::Error::Server,
          Excon::Error::NoContent
        ],
        retry_interval: context.retry_interval,
        retry_limit: 10,
        middlewares: Excon.defaults[:middlewares] + [
          Excon::Middleware::Decompress
        ]
      )
    end

    def rwx_access_token
      context.rwx_access_token || ENV.fetch("RWX_ACCESS_TOKEN")
    end
  end
end
