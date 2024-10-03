require "rwx_results/fetch_captain_summary"
require "rwx_results/state"

RSpec.describe RwxResults::FetchCaptainSummary do
  let(:run_context) do
    FactoryBot.build(
      :run_context,
      branch_name:,
      commit_sha:
    )
  end

  let(:state) do
    RwxResults::State.new.tap do |s|
      allow(s).to receive(:run_context) { run_context }
    end
  end

  let(:test_suite_id) { "asdf" }
  let(:branch_name) { "branchy" }
  let(:commit_sha) { "deadbeef" }

  let(:response) do
    FactoryBot.attributes_for(
      :captain_summary_response,
      test_suite_id:,
      branch_name:,
      commit_sha:
    )
  end

  let(:response_body) { JSON.dump(response) }

  let(:action) { RwxResults::FetchCaptainSummary.new }
  let(:result) { action.context }

  before do
    allow(action).to receive(:rwx_access_token) { "foo" }
  end

  context "with a successful response from captain" do
    before do
      stub_request(
        :get,
        "https://cloud.rwx.com/api/test_suite_summaries/#{test_suite_id}/#{branch_name}/#{commit_sha}"
      ).to_return(
        body: response_body,
        status: 200,
        headers: {
          "content-type": "application/json"
        }
      )
    end

    context "when fetching branch and sha from the run context" do
      it "fetches the captain summary" do
        action.run(
          state: state,
          test_suite_id: test_suite_id
        )

        expect(result).to be_success
        expect(result.captain_summary).to eq response
      end

      context "when the branch name can't be found" do
        let(:run_context) do
          FactoryBot.build(
            :run_context,
            ref: "refs/tags/v1", # <- it's a tag instead of a branch
            sha: commit_sha
          )
        end

        it "fails" do
          expect {
            action.run(
              state: state,
              test_suite_id: test_suite_id
            )
          }.to raise_error "No branch name found!"
        end
      end
    end
  end

  context "with a 500 error" do
    before do
      # Disable the normal delay between retries
      allow(action).to receive(:retry_after) { 0.0001 }

      stub_request(
        :get,
        "https://cloud.rwx.com/api/test_suite_summaries/#{test_suite_id}/#{branch_name}/#{commit_sha}"
      ).to_return(
        {
          status: 500
        },
        {
          body: response_body,
          status: 200,
          headers: {
            "content-type": "application/json"
          }
        }
      )
    end

    it "retries" do
      action.run(
        state: state,
        test_suite_id: test_suite_id,
        branch_name: branch_name,
        commit_sha: commit_sha
      )

      expect(result).to be_success
      expect(result.captain_summary).to eq response
    end
  end
end
