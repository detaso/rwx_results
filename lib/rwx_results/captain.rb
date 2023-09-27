require "rwx_results/run_context"

module RwxResults
  class Captain
    include Metaractor

    def call
      run_context = RunContext.from_env
      puts run_context.to_h
      # Fetch captain metadata
      # Generate markdown
      # add/create PR comment
    end
  end
end
