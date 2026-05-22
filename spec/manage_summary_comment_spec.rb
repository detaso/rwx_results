require "rwx_results/manage_summary_comment"
require "rwx_results/state"
require "rwx_results/types"

RSpec.describe RwxResults::ManageSummaryComment do
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
  let(:action) { described_class.new }
  let(:result) { action.context }
  let(:captain_markdown) { "### :white_check_mark: Successful\n:white_check_mark: 10 Successful" }

  let(:pr) { double("Pull", number: 42) }

  around do |example|
    original = ENV["GITHUB_REPOSITORY"]
    ENV["GITHUB_REPOSITORY"] = "org/app"
    example.run
  ensure
    ENV["GITHUB_REPOSITORY"] = original
  end

  context "when a bot comment already exists" do
    let(:bot_comment) { double("Comment", id: 100) }
    let(:pull_request) { RwxResults::PullRequest.new(pr: pr, bot_comment: bot_comment) }

    it "updates the existing comment" do
      expect(octokit).to receive(:update_comment).with("org/app", 100, captain_markdown)

      action.run(state: state, captain_markdown: captain_markdown, pull_request: pull_request)

      expect(result).to be_success
    end
  end

  context "when no bot comment exists" do
    let(:pull_request) { RwxResults::PullRequest.new(pr: pr, bot_comment: nil) }

    it "creates a new comment" do
      expect(octokit).to receive(:add_comment).with("org/app", 42, captain_markdown)

      action.run(state: state, captain_markdown: captain_markdown, pull_request: pull_request)

      expect(result).to be_success
    end
  end
end
