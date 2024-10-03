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
        comments =
          octokit.issue_comments(
            repository,
            pull.number
          )

        bot_comment =
          comments.find do |comment|
            comment.user.type == "Bot" && comment.body.include?("cloud.rwx.com")
          end

        if bot_comment
          logger.debug "Updating comment on #{repository}/pull/#{pull.number}"
          octokit.update_comment(
            repository,
            bot_comment.id,
            context.captain_markdown
          )
        else
          logger.debug "Adding comment to #{repository}/pull/#{pull.number}"
          octokit.add_comment(
            repository,
            pull.number,
            context.captain_markdown
          )
        end
      end
    end

    private

    delegate state: :context
    delegate commit_sha: :run_context

    def repository
      run_context.repo.to_s
    end
  end
end
