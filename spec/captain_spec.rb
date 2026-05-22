require "rwx_results/captain"
require "rwx_results/state"

RSpec.describe RwxResults::Captain do
  let(:run_context) do
    FactoryBot.build(:run_context, branch_name: "my-feature", commit_sha: "abc123")
  end

  let(:state) do
    RwxResults::State.new.tap do |s|
      allow(s).to receive(:run_context) { run_context }
      allow(s).to receive(:octokit) { octokit }
    end
  end

  let(:octokit) { instance_double(Octokit::Client) }
  let(:test_suite_id) { "suite-123" }

  around do |example|
    original_repo = ENV["GITHUB_REPOSITORY"]
    ENV["GITHUB_REPOSITORY"] = "org/app"
    example.run
  ensure
    ENV["GITHUB_REPOSITORY"] = original_repo
  end

  context "when no pull request is found" do
    before do
      allow(RwxResults::FetchCaptainSummary).to receive(:call!) do |ctx|
        ctx.captain_summary = {
          summary: {
            status: {kind: "successful"},
            flaky: 0, retries: 0, failed: 0, timedOut: 0,
            quarantined: 0, pended: 0, skipped: 0, todo: 0,
            canceled: 0, successful: 10
          },
          web_url: "https://cloud.rwx.com/captain/test_suite/branch/sha"
        }
      end

      allow(RwxResults::GenerateCaptainMarkdown).to receive(:call!) do |ctx|
        ctx.captain_markdown = "### :white_check_mark: Successful"
      end

      allow(octokit).to receive(:commit_pulls).and_return([])
    end

    it "fails with pull_request not_found error" do
      result = described_class.call(state: state, test_suite_id: test_suite_id)

      expect(result).to be_failure
      expect(result.errors[:pull_request]).to include(:not_found)
    end

    it "does not attempt to manage the summary comment" do
      expect(RwxResults::ManageSummaryComment).not_to receive(:call!)

      described_class.call(state: state, test_suite_id: test_suite_id)
    end
  end
end
