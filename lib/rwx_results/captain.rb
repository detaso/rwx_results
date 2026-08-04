require "rwx_results/state"
require "rwx_results/missing_pull_request"
require "rwx_results/captain_summary_unavailable"
require "rwx_results/fetch_captain_summary"
require "rwx_results/generate_captain_markdown"
require "rwx_results/generate_summary_unavailable_markdown"
require "rwx_results/fetch_existing_pull_request"
require "rwx_results/manage_summary_comment"

module RwxResults
  class Captain
    include Metaractor
    include State::Delegator
    include MissingPullRequest
    include CaptainSummaryUnavailable

    required :state
    required :test_suite_id

    def call
      logger.start_group(title: "Captain Results") do
        summary = FetchCaptainSummary.call(state:, test_suite_id:)

        if summary.failure?
          unless summary_unavailable?(summary)
            context.fail_from_context(context: summary)
            context.fail!
          end

          report_summary_unavailable
          GenerateSummaryUnavailableMarkdown.call!(context)
        else
          context.captain_summary = summary.captain_summary
          GenerateCaptainMarkdown.call!(context)
        end

        result = FetchExistingPullRequest.call(state:)

        if result.failure?
          if missing_pull_request?(result)
            report_missing_pull_request(skipping: "the Captain results comment")
            return
          end

          context.fail_from_context(context: result)
          context.fail!
        end

        ManageSummaryComment.call!(
          state:,
          captain_markdown: context.captain_markdown,
          pull_request: result.pull_request
        )
      end
    end
  end
end
