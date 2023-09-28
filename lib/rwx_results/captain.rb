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
      logger.start_group(title: "Captain Results") do
        summary = fetch_captain_summary
        generate_markdown(summary)
        # Generate markdown
        # add/create PR comment
      end
    end

    private

    delegate logger: :context

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
        retries: {
          emoji: ":arrow_right_hook:",
          human: "Retry"
        },
        failed: {
          emoji: ":x:",
          human: "Failed"
        },
        skipped: {
          emoji: ":fast_forward:",
          human: "Skipped"
        },
        # quarantined: {
        #   emoji: "",
        #   human: ""
        # },
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

      markdown.join("\n").tap do |text|
        logger.debug "Markdown:"
        logger.debug text
      end
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
