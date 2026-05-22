require "rwx_results/fetch_existing_pull_request"

RSpec.describe RwxResults::FetchExistingPullRequest do
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

  around do |example|
    original = ENV["GITHUB_REPOSITORY"]
    ENV["GITHUB_REPOSITORY"] = "org/app"
    example.run
  ensure
    ENV["GITHUB_REPOSITORY"] = original
  end

  let(:pull) do
    double("Pull", number: 42, head: double("Head", ref: "my-feature"))
  end

  let(:bot_comment_with_marker) do
    double("Comment",
      id: 100,
      user: double("User", type: "Bot"),
      body: "#{RwxResults::CAPTAIN_MARKER_START}\n### :white_check_mark: Successful")
  end

  let(:human_comment) do
    double("Comment",
      id: 200,
      user: double("User", type: "User"),
      body: "Looks good!")
  end

  before do
    allow(octokit).to receive(:commit_pulls).and_return([pull])
    allow(octokit).to receive(:issue_comments).and_return(comments)
  end

  let(:comments) { [bot_comment_with_marker, human_comment] }

  context "when a bot comment with the marker exists" do
    it "finds the pull request and bot comment" do
      action.run(state: state)

      expect(result).to be_success
      expect(result.pull_request.pr).to eq pull
      expect(result.pull_request.bot_comment).to eq bot_comment_with_marker
    end
  end

  context "when a bot comment contains cloud.rwx.com (legacy)" do
    let(:legacy_bot_comment) do
      double("Comment",
        id: 101,
        user: double("User", type: "Bot"),
        body: "Results: https://cloud.rwx.com/captain/results")
    end

    let(:comments) { [legacy_bot_comment, human_comment] }

    it "finds the legacy bot comment" do
      action.run(state: state)

      expect(result).to be_success
      expect(result.pull_request.bot_comment).to eq legacy_bot_comment
    end
  end

  context "when no bot comment exists" do
    let(:comments) { [human_comment] }

    it "sets bot_comment to nil" do
      action.run(state: state)

      expect(result).to be_success
      expect(result.pull_request.bot_comment).to be_nil
    end
  end

  context "when no pull request is found" do
    before do
      allow(octokit).to receive(:commit_pulls).and_return([])
    end

    it "fails with a pull_request not_found error" do
      action.run(state: state)

      expect(result).to be_failure
      expect(result.errors[:pull_request]).to include(:not_found)
    end
  end

  context "when multiple pull requests match" do
    let(:another_pull) do
      double("Pull", number: 43, head: double("Head", ref: "my-feature"))
    end

    before do
      allow(octokit).to receive(:commit_pulls).and_return([pull, another_pull])
    end

    it "raises MultiplePullRequestError" do
      expect {
        action.run(state: state)
      }.to raise_error(RwxResults::MultiplePullRequestError)
    end
  end
end
