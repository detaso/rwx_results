require "rwx_results/fetch_captain_summary"
require "rwx_results/state"

module RwxResults
  RSpec.describe FetchCaptainSummary do
    describe "#url" do
      context "when passing branch and sha in directly" do
      end

      context "when fetching branch and sha from the state's run context" do
      end
    end

    context "with a successful response from captain" do
      context "it returns the correct response" do
      end
    end

    context "with a 500 error" do
      it "retries" do
      end
    end
  end
end
