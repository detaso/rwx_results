require "rwx_results/state"

module RwxResults
  class Captain
    include Metaractor
    include State::Delegator
    extend Forwardable

    required :state
    required :test_suite_id

    optional :branch_name
    optional :commit_sha

    def call
      logger.start_group(title: "Captain Results") do
        summary = fetch_captain_summary
        markdown = generate_markdown(summary)
        manage_summary_comment(markdown)
      end
    end

    private

    delegate state: :context

    def fetch_captain_summary
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

      summary
    end

    def generate_markdown(summary)
      logger.info "Generating markdown..."

      markdown = []

      status = summary.dig("summary", "status", "kind")
      if status == "failed"
        markdown << "### :x: Failed"
      elsif status == "successful"
        markdown << "### :white_check_mark: Successful"
      end

      types = {
        flaky: {
          emoji: ":arrows_counterclockwise:",
          human: "Flaky"
        },
        retries: {
          emoji: ":arrow_right_hook:",
          human: "Retry"
        },
        failed: {
          emoji: ":x:",
          human: "Failed"
        },
        timedOut: {
          emoji: ":stopwatch:",
          human: "Timed Out"
        },
        quarantined: {
          emoji: ":stethoscope:",
          human: "Quarantined"
        },
        pended: {
          emoji: ":hourglass:",
          human: "Pended"
        },
        skipped: {
          emoji: ":fast_forward:",
          human: "Skipped"
        },
        todo: {
          emoji: ":clipboard:",
          human: "Todo"
        },
        canceled: {
          emoji: ":stop_button:",
          human: "Canceled"
        },
        successful: {
          emoji: ":white_check_mark:",
          human: "Successful"
        }
      }

      types.each do |k, v|
        value = summary.dig("summary", k.to_s)
        if value > 0
          markdown << "#{v[:emoji]} #{value} #{v[:human]}"
        end
      end

      markdown << ""
      markdown << "[Full results](#{summary["web_url"]})"

      markdown.join("\n").tap do |text|
        logger.info "Markdown:"
        logger.info text
      end
    end

    def manage_summary_comment(markdown)
      pulls =
        octokit.commit_pulls(
          run_context.repo.to_s,
          run_context.sha
        )

      logger.debug "Found #{pulls.size} pull requests"

      pulls.each do |pull|
        logger.debug "Adding comment to #{run_context.repo.to_s}/pull/#{pull.id}"
        octokit.add_comment(
          run_context.repo.to_s,
          pull.id,
          markdown
        )
      end
    end

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
