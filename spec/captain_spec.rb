require "rwx_results/captain"
require "rwx_results/state"
require "rwx_results/logger"

RSpec.describe RwxResults::Captain do
  let(:run_context) do
    FactoryBot.build(
      :run_context,
      branch_name: branch_name,
      default_branch: "main",
      commit_sha: "abc123"
    )
  end

  let(:branch_name) { "my-feature" }

  let(:logger) { instance_double(RwxResults::Logger) }

  let(:state) do
    RwxResults::State.new.tap do |s|
      allow(s).to receive(:run_context) { run_context }
      allow(s).to receive(:octokit) { octokit }
      allow(s).to receive(:logger) { logger }
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

  before do
    allow(logger).to receive(:start_group).and_yield
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:notice)
    allow(logger).to receive(:warning)

    allow(RwxResults::FetchCaptainSummary).to receive(:call) do
      context_creator(
        captain_summary: {
          summary: {
            status: {kind: "successful"},
            flaky: 0, retries: 0, failed: 0, timedOut: 0,
            quarantined: 0, pended: 0, skipped: 0, todo: 0,
            canceled: 0, successful: 10
          },
          web_url: "https://cloud.rwx.com/captain/test_suite/branch/sha"
        }
      )
    end

    allow(RwxResults::GenerateCaptainMarkdown).to receive(:call!) do |ctx|
      ctx.captain_markdown = "### :white_check_mark: Successful"
    end
  end

  context "when no pull request is found" do
    before do
      allow(octokit).to receive(:commit_pulls).and_return([])
    end

    it "succeeds instead of failing" do
      result = described_class.call(state: state, test_suite_id: test_suite_id)

      expect(result).to be_success
      expect(result.errors).to be_empty
    end

    it "does not attempt to manage the summary comment" do
      expect(RwxResults::ManageSummaryComment).not_to receive(:call!)

      described_class.call(state: state, test_suite_id: test_suite_id)
    end

    context "on a feature branch, where a pull request was expected" do
      let(:branch_name) { "my-feature" }

      it "emits a warning annotation" do
        expect(logger).to receive(:warning).with(
          properties: {title: "No pull request found"},
          message: a_string_including("abc123").and(a_string_including("my-feature"))
        )
        expect(logger).not_to receive(:notice)

        described_class.call(state: state, test_suite_id: test_suite_id)
      end
    end

    context "on the default branch, where no pull request was expected" do
      let(:branch_name) { "main" }

      it "emits a notice annotation instead of a warning" do
        expect(logger).to receive(:notice).with(
          properties: {title: "No pull request found"},
          message: a_string_including("main")
        )
        expect(logger).not_to receive(:warning)

        described_class.call(state: state, test_suite_id: test_suite_id)
      end
    end
  end

  context "when the Captain summary is unavailable" do
    let(:pull) do
      double("Pull", number: 42, head: double("Head", ref: "my-feature"))
    end

    before do
      allow(RwxResults::FetchCaptainSummary).to receive(:call) do
        context_creator(errors: {captain_summary: :not_available})
      end

      allow(RwxResults::GenerateSummaryUnavailableMarkdown).to receive(:call!) do |ctx|
        ctx.captain_markdown = "### :hourglass_flowing_sand: Results unavailable"
      end

      allow(octokit).to receive(:commit_pulls).and_return([pull])
      allow(octokit).to receive(:issue_comments).and_return([])
      allow(octokit).to receive(:add_comment)
    end

    it "posts the unavailable comment and succeeds" do
      expect(RwxResults::GenerateCaptainMarkdown).not_to receive(:call!)
      expect(RwxResults::ManageSummaryComment).to receive(:call!) do |args|
        expect(args[:captain_markdown]).to eq(
          "### :hourglass_flowing_sand: Results unavailable"
        )
      end

      result = described_class.call(state: state, test_suite_id: test_suite_id)

      expect(result).to be_success
      expect(result.errors).to be_empty
    end

    it "emits a warning annotation" do
      expect(logger).to receive(:warning).with(
        properties: {title: "Captain summary unavailable"},
        message: a_string_including("suite-123").and(a_string_including("my-feature"))
      )

      described_class.call(state: state, test_suite_id: test_suite_id)
    end

    context "and no pull request is found" do
      before do
        allow(octokit).to receive(:commit_pulls).and_return([])
      end

      it "skips the comment but still succeeds" do
        expect(RwxResults::ManageSummaryComment).not_to receive(:call!)

        result = described_class.call(state: state, test_suite_id: test_suite_id)

        expect(result).to be_success
      end
    end
  end

  context "when fetching the Captain summary fails for another reason" do
    before do
      allow(RwxResults::FetchCaptainSummary).to receive(:call) do
        context_creator(errors: {captain_summary: :boom})
      end
    end

    it "fails the whole run" do
      result = described_class.call(state: state, test_suite_id: test_suite_id)

      expect(result).to be_failure
      expect(result.errors[:captain_summary]).to include(:boom)
    end

    it "does not report an unavailable summary" do
      expect(logger).not_to receive(:warning)
      expect(RwxResults::GenerateSummaryUnavailableMarkdown).not_to receive(:call!)

      described_class.call(state: state, test_suite_id: test_suite_id)
    end
  end

  context "when the pull request lookup fails for another reason" do
    before do
      allow(RwxResults::FetchExistingPullRequest).to receive(:call) do
        context_creator(errors: {state: :required})
      end
    end

    it "fails and propagates the original error" do
      result = described_class.call(state: state, test_suite_id: test_suite_id)

      expect(result).to be_failure
      expect(result.errors[:state]).to include(:required)
    end

    it "does not report a missing pull request" do
      expect(logger).not_to receive(:warning)
      expect(logger).not_to receive(:notice)

      described_class.call(state: state, test_suite_id: test_suite_id)
    end
  end

  context "when a pull request is found" do
    let(:pull) do
      double("Pull", number: 42, head: double("Head", ref: "my-feature"))
    end

    before do
      allow(octokit).to receive(:commit_pulls).and_return([pull])
      allow(octokit).to receive(:issue_comments).and_return([])
    end

    it "manages the summary comment" do
      expect(RwxResults::ManageSummaryComment).to receive(:call!) do |args|
        expect(args[:state]).to eq state
        expect(args[:captain_markdown]).to eq "### :white_check_mark: Successful"
        expect(args[:pull_request].pr).to eq pull
      end

      result = described_class.call(state: state, test_suite_id: test_suite_id)

      expect(result).to be_success
    end
  end
end
