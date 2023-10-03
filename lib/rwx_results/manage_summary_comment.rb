require "rwx_results/state"

module RwxResults
  class ManageSummaryComment
    include Metaractor
    include State::Delegator
    extend Forwardable

    required :state
    required :captain_markdown

    def call
      pulls =
        octokit.commit_pulls(
          repository,
          commit_sha
        )

      logger.debug "Found #{pulls.size} pull requests"

      pulls.each do |pull|
        logger.debug "Adding comment to #{repository}/pull/#{pull.number}"
        octokit.add_comment(
          repository,
          pull.number,
          context.captain_markdown
        )
      end
    end

    private

    delegate state: :context

    def commit_sha
      if context.has_key?(:commit_sha)
        context.commit_sha
      else
        run_context.sha
      end
    end

    def repository
      if context.has_key?(:repository)
        context.repository
      else
        run_context.repo.to_s
      end
    end
  end
end