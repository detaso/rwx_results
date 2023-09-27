require "bundler/setup"
Bundler.require(:default)

$LOAD_PATH.unshift File.dirname(__FILE__)

module RwxResults
  class CLI < Thor
    desc "captain", "Report captain results"
    def captain
      require "captain"
      Captain.call!
    end

    desc "abq", "Report abq results"
    def abq
    end
  end
end
