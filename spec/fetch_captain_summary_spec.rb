require "rwx_results/fetch_captain_summary"
require "rwx_results/state"

RSpec.describe RwxResults::FetchCaptainSummary do
  let(:state) do
    RwxResults::State.new
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

  let(:stubs) { [] }

  around do |example|
    mock_orig = Excon.defaults[:mock]
    Excon.defaults[:mock] = true

    example.run
  ensure
    stubs.each do |stub|
      Excon.stubs.delete(stub)
    end
    Excon.defaults[:mock] = mock_orig
  end

  before do
    allow(action).to receive(:rwx_access_token) { "foo" }

    stubs << Excon.stub(
      {
        scheme: "https",
        method: :get,
        host: "captain.build",
        path: "/api/test_suite_summaries/#{test_suite_id}/#{branch_name}/#{commit_sha}"
      },
      {
        body: response_body,
        status: 200
      }
    )
  end

  it "fetches the captain summary" do
    action.run(
      state: state,
      test_suite_id: test_suite_id,
      branch_name: branch_name,
      commit_sha: commit_sha
    )

    expect(result).to be_success
  end

  context "when the branch name can't be found" do
    it "fails"
  end
end
