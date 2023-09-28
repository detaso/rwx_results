require "rwx_results/run_context"

module RwxResults
  class Captain
    include Metaractor
    extend Forwardable

    required :logger
    required :test_suite_id

    optional :branch_name
    optional :commit_sha

    def call
      fetch_captain_metadata
      # Generate markdown
      # add/create PR comment
    end

    private

    delegate logger: :context

    def fetch_captain_metadata
      url =
        "https://captain.build/api/test_suite_summaries/#{context.test_suite_id}/#{branch_name}/#{commit_sha}"
      logger.debug url
    end

    def branch_name
      if context.has_key?(:branch_name)
        context.branch_name
      elsif %r{refs/heads/(?<branch>.*)} =~ run_context.ref
        branch
      end
    end

    def commit_sha
      if context.has_key?(:commit_sha)
        context.commit_sha
      else
        run_context.sha
      end
    end

    def run_context
      return @run_context if defined?(@run_context)

      @run_context =
        RunContext.from_env
    end
  end
end
