require "rwx_results/generate_summary_unavailable_markdown"
require "rwx_results/state"
require "rwx_results/logger"

RSpec.describe RwxResults::GenerateSummaryUnavailableMarkdown do
  let(:run_context) do
    FactoryBot.build(:run_context, commit_sha: "abc123def456")
  end

  let(:logger) { instance_double(RwxResults::Logger) }

  let(:state) do
    RwxResults::State.new.tap do |s|
      allow(s).to receive(:run_context) { run_context }
      allow(s).to receive(:logger) { logger }
    end
  end

  around do |example|
    original = ENV["GITHUB_REPOSITORY"]
    ENV["GITHUB_REPOSITORY"] = "org/app"
    example.run
  ensure
    ENV["GITHUB_REPOSITORY"] = original
  end

  before do
    allow(logger).to receive(:info)
  end

  let(:action) { described_class.new }
  let(:result) { action.context }
  let(:markdown) { result.captain_markdown }
  let(:lines) { markdown.split("\n") }

  it "wraps the body in the captain markers so the comment can be found again" do
    action.run(state: state)

    expect(result).to be_success
    expect(lines.first).to eq RwxResults::CAPTAIN_MARKER_START
    expect(lines.last).to eq RwxResults::CAPTAIN_MARKER_END
  end

  it "makes the header the first non-comment line so mark_outdated can find it" do
    action.run(state: state)

    header = lines.detect { |line| !line.start_with?("<!--") }

    expect(header).to eq "### :hourglass_flowing_sand: Results unavailable"
  end

  it "truncates the commit sha to 8 characters" do
    action.run(state: state)

    expect(markdown).to include "*Commit: abc123de*"
  end

  it "links to the workflow run" do
    action.run(state: state)

    expect(markdown).to include(
      "**[Workflow run](https://github.com/org/app/actions/runs/6407895730)**"
    )
  end

  it "omits a full results link, which needs a summary we do not have" do
    action.run(state: state)

    expect(markdown).not_to include "Full results"
  end

  context "when there is no run id" do
    let(:run_context) do
      FactoryBot.build(:run_context, commit_sha: "abc123def456", run_id: nil)
    end

    it "omits the workflow run link rather than emitting a broken url" do
      action.run(state: state)

      expect(markdown).not_to include "Workflow run"
      expect(markdown).not_to include "actions/runs"
    end
  end
end
