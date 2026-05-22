require "rwx_results/state"
require "rwx_results/errors"

module RwxResults
  class FetchExistingPullRequest
    include Metaractor
    include State::Delegator
    extend Forwardable

    required :state

    def call
      pulls =
        octokit
          .commit_pulls(
            repository,
            commit_sha
          )
          .select { |pull| pull.head.ref == run_context.branch_name }

      logger.debug "Found #{pulls.size} pull requests"
      raise MultiplePullRequestError if pulls.size > 1

      pull = pulls.first
      if pull.nil?
        fail_with_error!(
          errors: {
            pull_request: :not_found
          }
        )
      end

      comments =
        octokit.issue_comments(
          repository,
          pull.number
        )

      bot_comment =
        comments.find do |comment|
          comment.user.type == "Bot" && (
            comment.body.include?(CAPTAIN_MARKER_START) ||
            comment.body.include?("cloud.rwx.com") # TODO: Remove
          )
        end

      context.pull_request = PullRequest.new(
        pr: pull,
        bot_comment: bot_comment
      )
    end

    private

    delegate commit_sha: :run_context

    def repository
      run_context.repo.to_s
    end
  end
end
