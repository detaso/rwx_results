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
          title: "Foo"
        },
        message: "Oops"
      )

      context.logger.debug(message: "WHYYYY")

      # Fetch captain metadata
      # Generate markdown
      # add/create PR comment
    end
  end
end
