require "rwx_results/state"

module RwxResults
  class GenerateCaptainMarkdown
    include Metaractor
    include State::Delegator
    extend Forwardable

    required :state
    required :captain_summary

    def call
      logger.info "Generating markdown..."

      markdown = []

      status = context.captain_summary.dig("summary", "status", "kind")
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
        value = context.captain_summary.dig("summary", k.to_s)
        if value > 0
          markdown << "#{v[:emoji]} #{value} #{v[:human]}"
        end
      end

      markdown << ""
      markdown << "[Full results](#{context.captain_summary["web_url"]})"

      markdown.join("\n").tap do |text|
        logger.info "Markdown:"
        logger.info text
      end

      context.captain_markdown = markdown
    end

    private

    delegate state: :context
  end
end
