require "bundler/setup"

if ENV.fetch("DEV", "false") == "true"
  Bundler.require(:default, :development)
  require "dotenv/load"
else
  Bundler.require(:default)
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..")

module RwxResults
  class CLI < Thor
    class_option :debug,
      type: :boolean

    option :test_suite_id, required: true
    option :branch_name
    option :commit_sha
    option :repository
    desc "captain", "Report captain results"
    def captain
      init

      require "rwx_results/captain"

      Captain.call!(
        state:,
        test_suite_id: options["test_suite_id"]
      )
    end

    desc "abq", "Report abq results"
    def abq
      init
    end

    def self.exit_on_failure?
      true
    end

    private

    def init
      handle_debug
      init_state(
        **options
          .transform_keys(&:to_sym)
          .slice(:branch_name, :commit_sha, :repository)
          .compact
          .select { |_k, v| v != "" }
      )
    end

    def handle_debug
      if options[:debug]
        ENV["RUNNER_DEBUG"] = "1"
      end
    end

    def init_state(**overrides)
      require "rwx_results/state"
      @state =
        State.new.tap do |s|
          s.init_run_context(**overrides)

          s.logger.debug "Run Context:"
          s.logger.debug s.run_context
          s.logger.debug s.run_context.branch_name
          s.logger.debug s.run_context.commit_sha
        end
    end

    def state
      return @state if defined?(@state)

      init_state
    end
  end
end
