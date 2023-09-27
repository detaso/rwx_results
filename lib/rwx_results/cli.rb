require "bundler/setup"
Bundler.require(:default)

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..")

module RwxResults
  class CLI < Thor
    desc "captain", "Report captain results"
    def captain
      require "rwx_results/captain"
      Captain.call!(logger:)
    end

    desc "abq", "Report abq results"
    def abq
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
