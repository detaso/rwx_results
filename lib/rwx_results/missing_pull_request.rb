module RwxResults
  # Private helpers for detecting and reporting a missing pull request.
  #
  # Includers must also provide `run_context` and `logger`, which normally means
  # including `State::Delegator` alongside this module.
  module MissingPullRequest
    private

    def missing_pull_request?(result)
      result.errors.include?(pull_request: :not_found)
    end

    def report_missing_pull_request(skipping:, allow_warning: true)
      properties = {title: "No pull request found"}
      message =
        "No pull request found for commit #{run_context.commit_sha} " \
        "on branch #{run_context.branch_name}. Skipping #{skipping}."

      if allow_warning && run_context.pull_request_expected?
        logger.warning(properties:, message:)
      else
        logger.notice(properties:, message:)
      end
    end
  end
end
