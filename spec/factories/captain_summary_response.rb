FactoryBot.define do
  factory :captain_summary_response, class: OpenStruct do
    transient do
      test_suite_id { nil }
      branch_name { nil }
      commit_sha { nil }
    end

    web_url { "https://captain.build/api/test_suite_summaries/#{test_suite_id}/#{branch_name}/#{commit_sha}" }
  end
end
