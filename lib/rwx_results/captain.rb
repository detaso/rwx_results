require "rwx_results/state"
require "rwx_results/fetch_captain_summary"
require "rwx_results/generate_captain_markdown"
require "rwx_results/fetch_existing_pull_request"
require "rwx_results/manage_summary_comment"

module RwxResults
  class Captain
    include Metaractor::Organizer
    include State::Delegator

    required :state
    required :test_suite_id

    organize [
      FetchCaptainSummary,
      GenerateCaptainMarkdown,
      FetchExistingPullRequest,
      ManageSummaryComment
    ]

    def call
      logger.start_group(title: "Captain Results") do
        super
      end
    end
  end
end
