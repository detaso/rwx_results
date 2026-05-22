require "rwx_results/state"
require "rwx_results/fetch_existing_pull_request"
require "rwx_results/manage_summary_comment"

module RwxResults
  class MarkOutdated
    include Metaractor
    include State::Delegator

    required :state

    def call
      logger.start_group(title: "Mark Outdated") do
        result = FetchExistingPullRequest.call!(context)

        pull_request = result.pull_request

        return unless pull_request.bot_comment

        lines = pull_request.bot_comment.body.split("\n")
        header =
          lines.detect do |line|
            !line.start_with?("<!--")
          end

        return if header.include?("Outdated")

        header << " (Outdated)"

        captain_markdown =
          lines.join("\n").tap do |text|
            logger.info "Markdown:"
            logger.info text
          end

        ManageSummaryComment.call!(
          state:,
          captain_markdown:,
          pull_request:
        )
      end
    end
  end
end
