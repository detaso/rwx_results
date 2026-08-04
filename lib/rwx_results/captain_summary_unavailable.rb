module RwxResults
  # Private helpers for detecting and reporting an unavailable Captain summary.
  #
  # Includers must provide `run_context` and `logger` — normally by including
  # `State::Delegator` — and a `context` carrying `test_suite_id`.
  module CaptainSummaryUnavailable
    private

    def summary_unavailable?(result)
      result.errors.include?(captain_summary: :not_available)
    end

    def report_summary_unavailable
      logger.warning(
        properties: {title: "Captain summary unavailable"},
        message:
          "No Captain summary for test suite #{context.test_suite_id} on " \
          "branch #{run_context.branch_name} at commit " \
          "#{run_context.commit_sha} after ~90s. Posting an unavailable " \
          "notice instead; re-run to refresh."
      )
    end
  end
end
