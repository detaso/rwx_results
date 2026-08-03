require "rwx_results/run_context"

RSpec.describe RwxResults::RunContext do
  describe "#default_branch" do
    it "reads the default branch from the event payload" do
      run_context = FactoryBot.build(:run_context, default_branch: "main")

      expect(run_context.default_branch).to eq "main"
    end

    it "is nil when the payload carries no repository information" do
      run_context = FactoryBot.build(:run_context, payload: {})

      expect(run_context.default_branch).to be_nil
    end
  end

  describe "#pull_request_expected?" do
    it "is false on the default branch" do
      run_context = FactoryBot.build(
        :run_context,
        branch_name: "main",
        default_branch: "main"
      )

      expect(run_context.pull_request_expected?).to be false
    end

    it "is true on a feature branch" do
      run_context = FactoryBot.build(
        :run_context,
        branch_name: "my-feature",
        default_branch: "main"
      )

      expect(run_context.pull_request_expected?).to be true
    end

    it "is true when the default branch cannot be determined" do
      run_context = FactoryBot.build(:run_context, payload: {})

      expect(run_context.pull_request_expected?).to be true
    end
  end
end
