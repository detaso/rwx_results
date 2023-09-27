require "rwx_results/run_context"

module RwxResults
  class Captain
    include Metaractor

    required :logger

    def call
      # run_context = RunContext.from_env
      # logger.debug run_context.to_h

      context.logger.notice(
        properties: {
          file: "Dockerfile",
          line: 70,
          end_line: 76
        },
        message: "That's right! No non-root users allowed!"
      )

      # Fetch captain metadata
      # Generate markdown
      # add/create PR comment
    end
  end
end
