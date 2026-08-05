require "rwx_results/state"

module RwxResults
  class GenerateSummaryUnavailableMarkdown
    include Metaractor
    include State::Delegator

    required :state

    def call
      logger.info "Generating unavailable markdown..."

      markdown = [
        CAPTAIN_MARKER_START,
        "### :hourglass_flowing_sand: Results unavailable",
        "",
        "RWX Captain returned no summary for this commit after ~90s. The API is",
        "usually still indexing; re-running refreshes this comment.",
        ""
      ]

      if workflow_run_url
        markdown << "**[Workflow run](#{workflow_run_url})**"
        markdown << ""
      end

      markdown << "*Commit: #{run_context.commit_sha[0, 8]}*"
      markdown << CAPTAIN_MARKER_END

      context.captain_markdown =
        markdown.join("\n").tap do |text|
          logger.info "Markdown:"
          logger.info text
        end
    end

    private

    def workflow_run_url
      return if run_context.run_id.nil?

      "#{run_context.server_url}/#{run_context.repo}/actions/runs/#{run_context.run_id}"
    end
  end
end
