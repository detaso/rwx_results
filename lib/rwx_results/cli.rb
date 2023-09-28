require "bundler/setup"
Bundler.require(:default)

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..")

module RwxResults
  class CLI < Thor
    option :test_suite_id, required: true
    option :branch_name
    option :commit_sha
    desc "captain", "Report captain results"
    def captain
      require "rwx_results/captain"

      Captain.call!(
        logger:,
        **options
          .transform_keys(&:to_sym)
          .slice(:test_suite_id, :branch_name, :commit_sha)
          .compact
      )
    end

    desc "abq", "Report abq results"
    def abq
    end

    def self.exit_on_failure?
      true
    end

    private

    def logger
      return @logger if defined?(@logger)

      require "rwx_results/logger"
      @logger =
        Logger.new
    end
  end
end
