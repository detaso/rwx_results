require "rwx_results/captain"
require "rwx_results/state"

RSpec.describe RwxResults::Captain do
  let(:state) do
    RwxResults::State.new
  end

  let(:test_suite_id) { "asdf" }

  it "fetches the captain summary" do
    result =
      RwxResults::Captain.call(
        state: state,
        test_suite_id: test_suite_id
      )

    expect(result).to be_success
  end
end
