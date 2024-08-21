require "rwx_results/state"
require "rwx_results/fetch_captain_summary"
require "rwx_results/generate_captain_markdown"
require "rwx_results/manage_summary_comment"

module RwxResults
  class Captain
    include Metaractor::Organizer
    include State::Delegator
    extend Forwardable

    required :state
    required :test_suite_id

    optional :branch_name
    optional :commit_sha
    optional :repository

    organize [
      FetchCaptainSummary,
      GenerateCaptainMarkdown,
      ManageSummaryComment
    ]

    def call
      logger.start_group(title: "Captain Results") do
        super
      end
    end

    private

    delegate state: :context
  end
end
