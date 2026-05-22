require "rwx_results/mark_outdated"
require "rwx_results/captain"
require "rwx_results/state"
require "rwx_results/types"

RSpec.describe RwxResults::MarkOutdated do
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

  around do |example|
    original = ENV["GITHUB_REPOSITORY"]
    ENV["GITHUB_REPOSITORY"] = "org/app"
    example.run
  ensure
    ENV["GITHUB_REPOSITORY"] = original
  end

  let(:action) { described_class.new }
  let(:result) { action.context }

  let(:bot_comment_body) do
    [
      RwxResults::CAPTAIN_MARKER_START,
      "### :white_check_mark: Successful",
      ":white_check_mark: 10 Successful",
      "",
      "[Full results](https://cloud.rwx.com/captain/suite/branch/sha)",
      RwxResults::CAPTAIN_MARKER_END
    ].join("\n")
  end

  let(:bot_comment) do
    double("Comment", id: 100, body: bot_comment_body)
  end

  let(:pull) { double("Pull", number: 42) }
  let(:pull_request) { RwxResults::PullRequest.new(pr: pull, bot_comment: bot_comment) }

  let(:fetch_result) do
    Interactor::Context.build(pull_request: pull_request)
  end

  before do
    allow(RwxResults::FetchExistingPullRequest).to receive(:call).and_return(fetch_result)
  end

  context "when no pull request is found" do
    let(:fetch_result) do
      # TODO: Replace with context_creator after fixing upstream
      Interactor::Context.build.tap do |ctx|
        ctx.errors.add(errors: {pull_request: :not_found})
        ctx.instance_variable_set(:@failure, true)
      end
    end

    it "returns early without error" do
      expect(RwxResults::ManageSummaryComment).not_to receive(:call!)

      action.run(state: state)

      expect(result).to be_success
    end
  end

  context "when no bot comment exists" do
    let(:pull_request) { RwxResults::PullRequest.new(pr: pull, bot_comment: nil) }

    it "returns early without updating" do
      expect(RwxResults::ManageSummaryComment).not_to receive(:call)

      action.run(state: state)

      expect(result).to be_success
    end
  end

  context "when the bot comment is already marked outdated" do
    let(:bot_comment_body) do
      [
        RwxResults::CAPTAIN_MARKER_START,
        "### :white_check_mark: Successful (Outdated)",
        ":white_check_mark: 10 Successful",
        "",
        "[Full results](https://cloud.rwx.com/captain/suite/branch/sha)",
        RwxResults::CAPTAIN_MARKER_END
      ].join("\n")
    end

    it "returns early without updating" do
      expect(RwxResults::ManageSummaryComment).not_to receive(:call!)

      action.run(state: state)

      expect(result).to be_success
    end
  end

  context "when the bot comment exists and is not outdated" do
    it "appends (Outdated) to the header and updates the comment" do
      expect(RwxResults::ManageSummaryComment).to receive(:call!) do |args|
        expect(args[:captain_markdown]).to include("### :white_check_mark: Successful (Outdated)")
        expect(args[:pull_request]).to eq pull_request
        expect(args[:state]).to eq state
      end

      action.run(state: state)

      expect(result).to be_success
    end

    it "preserves the rest of the markdown" do
      expect(RwxResults::ManageSummaryComment).to receive(:call!) do |args|
        expect(args[:captain_markdown]).to include("[Full results](https://cloud.rwx.com/captain/suite/branch/sha)")
        expect(args[:captain_markdown]).to include(":white_check_mark: 10 Successful")
      end

      action.run(state: state)

      expect(result).to be_success
    end
  end
end
