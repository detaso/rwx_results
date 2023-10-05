require "rwx_results/fetch_captain_summary"
require "rwx_results/state"

module RwxResults
  RSpec.describe FetchCaptainSummary do
    context "with a successful response from captain" do
      context "when passing branch and sha in directly" do
        it "can fetch the captain summary" do
          url = "https://captain.build/api/test_suite_summaries/my-suite/DIRECT_BRANCH/direct-sha-123456"
          expected_response = {web_url: url}
          mock_captain_response_with(url: url, status: 200, response: expected_response)

          fetcher = build_fetcher(branch_name: "DIRECT_BRANCH", commit_sha: "direct-sha-123456")

          fetcher.run

          result = fetcher.context

          expect(result).to be_success
          expect(result.captain_summary).to eq expected_response
        end
      end

      context "when fetching branch and sha from the state's run context" do
        it "can fetch the captain summary" do
          url = "https://captain.build/api/test_suite_summaries/my-suite/state-branch/state-sha-123456"
          expected_response = {web_url: url}
          mock_captain_response_with(url: url, status: 200, response: expected_response)

          state = build_state(ref: "refs/heads/state-branch", sha: "state-sha-123456")
          fetcher = build_fetcher(branch_name: nil, commit_sha: nil, state: state)

          fetcher.run

          result = fetcher.context

          expect(result).to be_success
          expect(result.captain_summary).to eq expected_response
        end
      end
    end

    context "when not being given a branch name" do
      context "when the branch name isn't given directly, and there's no run context" do
        it "raises an error" do
          state_without_ref_context = build_state
          fetcher = build_fetcher(branch_name: nil, state: state_without_ref_context)

          expect { fetcher.run }
            .to raise_error(FetchCaptainSummary::MissingBranchError, "Branch name not provided, and could not be discerned from ref!")
        end
      end

      context "when the branch name isn't provided and also not discernable from the ref" do
        it "raises an error" do
          state_with_bad_ref = build_state(ref: "BADREF")

          fetcher = build_fetcher(branch_name: nil, state: state_with_bad_ref)

          expect { fetcher.run }
            .to raise_error(FetchCaptainSummary::MissingBranchError, "Branch name not provided, and could not be discerned from ref!")
        end
      end
    end

    context "with a 500 error" do
      it "retries" do
        fetcher = build_fetcher(retry_interval: 0) # disable normal delay between retries
        expected_response = {web_url: fetcher.url}

        mock_captain_response_with(url: fetcher.url, status: 500, response: nil)
        mock_captain_response_with(url: fetcher.url, status: 200, response: expected_response)

        fetcher.run

        result = fetcher.context

        expect(result).to be_success
        expect(result.captain_summary).to eq expected_response
      end
    end

    def build_fetcher(state: nil, test_suite_id: "my-suite", branch_name: "my-branch", commit_sha: "some-sha", retry_interval: nil)
      FetchCaptainSummary.new(
        state: state || State.new,
        test_suite_id:,
        branch_name:,
        commit_sha:,
        retry_interval:,
        rwx_access_token: mock_access_token
      )
    end

    def build_response_for(fetcher:)
      FactoryBot.attributes_for(
        :captain_summary_response,
        test_suite_id: fetcher.context.test_suite_id,
        branch_name: fetcher.branch_name,
        commit_sha: fetcher.commit_sha
      )
    end

    def build_state(ref: nil, sha: nil)
      if ref && sha
        run_context = FactoryBot.build(:run_context, ref: ref, sha: sha)

        State.new(run_context: run_context)
      else
        State.new
      end
    end

    def mock_captain_response_with(url:, status:, response:)
      return_value = {status: status}

      if response
        return_value[:body] = JSON.dump(response)
      end

      if stubbed_requests[url]
        stubbed_requests[url].then.to_return(return_value)
      else
        stubbed_requests[url] = stub_request(:get, url)
          .with(headers: {
            Accept: "application/json",
            "Accept-Encoding": "gzip, deflate",
            Authorization: "Bearer #{mock_access_token}"
          }).to_return(return_value)
      end
    end

    def stubbed_requests
      @_stubbed_requests ||= {}
    end

    def mock_access_token
      "ABC123"
    end
  end
end
