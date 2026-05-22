require "rwx_results/state"

module RwxResults
  class ManageSummaryComment
    include Metaractor
    include State::Delegator

    required :state
    required :captain_markdown
    required :pull_request # type PullRequest

    def call
      if context.pull_request.bot_comment
        logger.debug "Updating comment on #{repository}/pull/#{context.pull_request.pr.number}"
        octokit.update_comment(
          repository,
          context.pull_request.bot_comment.id,
          context.captain_markdown
        )
      else
        logger.debug "Adding comment to #{repository}/pull/#{context.pull_request.pr.number}"
        octokit.add_comment(
          repository,
          context.pull_request.pr.number,
          context.captain_markdown
        )
      end
    end

    private

    def repository
      run_context.repo.to_s
    end
  end
end
