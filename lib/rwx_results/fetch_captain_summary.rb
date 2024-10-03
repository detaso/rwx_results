require "rwx_results/state"

module RwxResults
  class FetchCaptainSummary
    include Metaractor
    include State::Delegator
    extend Forwardable

    required :state
    required :test_suite_id

    def call
      logger.info "Fetching captain summary..."

      url =
        "https://captain.build/api/test_suite_summaries/#{context.test_suite_id}/#{branch_name}/#{commit_sha}"

      logger.debug "Captain results url: #{url}"

      response =
        http.get(
          url,
          headers: {
            accept: "application/json",
            authorization: "Bearer #{rwx_access_token}"
          },

          max_retries: 20,
          retry_after:,
          retry_on: ->(res) do
            res in {status: 204} | {status: 500..599}
          end
        )

      response.raise_for_status

      if response.status == 204
        raise "Captain results not found for test_suite_id: #{context.test_suite_id}, branch: #{branch_name}, commit_sha: #{commit_sha}"
      end

      logger.debug "Response body: #{response.body}"
      summary = JSON.parse(response.body, symbolize_names: true)
      logger.debug "Captain summary: #{summary.inspect}"

      context.captain_summary = summary
    end

    private

    delegate state: :context

    def branch_name
      if %r{refs/heads/(?<branch>.*)} =~ run_context.ref
        branch
      else
        raise "No branch name found!"
      end
    end

    def commit_sha
      run_context.sha
    end

    def rwx_access_token
      ENV.fetch("RWX_ACCESS_TOKEN")
    end

    def retry_after
      5
    end

    def http
      HTTPX.plugin(:retries).with(debug: $stderr, debug_level: 1)
    end
  end
end
