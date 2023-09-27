require "bundler/setup"
Bundler.require(:default)

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..")

module RwxResults
  class CLI < Thor
    desc "captain", "Report captain results"
    def captain
      require "rwx_results/captain"
      Captain.call!
    end

    desc "abq", "Report abq results"
    def abq
    end
  end
end
