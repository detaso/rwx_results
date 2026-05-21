require "rwx_results/generate_captain_markdown"
require "rwx_results/captain"
require "rwx_results/state"

RSpec.describe RwxResults::GenerateCaptainMarkdown do
  let(:run_context) { FactoryBot.build(:run_context) }

  let(:state) do
    RwxResults::State.new.tap do |s|
      allow(s).to receive(:run_context) { run_context }
    end
  end

  let(:captain_summary) do
    {
      summary: {
        status: {kind: status_kind},
        flaky: 0,
        retries: 0,
        failed: 0,
        timedOut: 0,
        quarantined: 0,
        pended: 0,
        skipped: 0,
        todo: 0,
        canceled: 0,
        successful: 10
      },
      web_url: "https://cloud.rwx.com/captain/test_suite/branch/sha"
    }
  end

  let(:status_kind) { "successful" }

  let(:action) { described_class.new }
  let(:result) { action.context }

  def run_action
    action.run(state: state, captain_summary: captain_summary)
  end

  context "with a successful status" do
    let(:status_kind) { "successful" }

    it "generates markdown with a success header" do
      run_action

      expect(result).to be_success
      expect(result.captain_markdown).to include("### :white_check_mark: Successful")
    end

    it "wraps output in markers" do
      run_action

      expect(result.captain_markdown).to start_with(RwxResults::CAPTAIN_MARKER_START)
      expect(result.captain_markdown).to end_with(RwxResults::CAPTAIN_MARKER_END)
    end

    it "includes the full results link" do
      run_action

      expect(result.captain_markdown).to include("[Full results](https://cloud.rwx.com/captain/test_suite/branch/sha)")
    end

    it "includes non-zero counts" do
      run_action

      expect(result.captain_markdown).to include(":white_check_mark: 10 Successful")
    end

    it "omits zero counts" do
      run_action

      expect(result.captain_markdown).not_to include("Failed")
      expect(result.captain_markdown).not_to include("Flaky")
    end
  end

  context "with a failed status" do
    let(:status_kind) { "failed" }
    let(:captain_summary) do
      {
        summary: {
          status: {kind: "failed"},
          flaky: 2,
          retries: 1,
          failed: 3,
          timedOut: 0,
          quarantined: 0,
          pended: 0,
          skipped: 0,
          todo: 0,
          canceled: 0,
          successful: 50
        },
        web_url: "https://cloud.rwx.com/captain/test_suite/branch/sha"
      }
    end

    it "generates markdown with a failed header" do
      run_action

      expect(result).to be_success
      expect(result.captain_markdown).to include("### :x: Failed")
    end

    it "includes all non-zero counts" do
      run_action

      expect(result.captain_markdown).to include(":arrows_counterclockwise: 2 Flaky")
      expect(result.captain_markdown).to include(":arrow_right_hook: 1 Retry")
      expect(result.captain_markdown).to include(":x: 3 Failed")
      expect(result.captain_markdown).to include(":white_check_mark: 50 Successful")
    end

    it "omits zero counts" do
      run_action

      expect(result.captain_markdown).not_to include("Timed Out")
      expect(result.captain_markdown).not_to include("Quarantined")
    end
  end

  context "with an invalid status kind" do
    let(:captain_summary) do
      {
        summary: {
          status: {kind: "unknown"},
          flaky: 0,
          retries: 0,
          failed: 0,
          timedOut: 0,
          quarantined: 0,
          pended: 0,
          skipped: 0,
          todo: 0,
          canceled: 0,
          successful: 0
        },
        web_url: "https://example.com"
      }
    end

    it "raises an ArgumentError" do
      expect { run_action }.to raise_error(ArgumentError, "captain_summary does not contain status.kind")
    end
  end
end
