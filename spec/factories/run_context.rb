require "rwx_results/run_context"

FactoryBot.define do
  factory :run_context, class: RwxResults::RunContext do
    transient do
      branch_name { "branchy" }
      commit_sha { "d299f161f680606167f206f3d1ed9b1e2a4db879" }
      default_branch { "main" }
    end

    payload do
      {
        ref: "refs/heads/#{branch_name}",
        repository: {
          full_name: "detaso/rwx_results",
          default_branch: default_branch
        }
      }
    end

    event_name { "push" }
    sha { commit_sha }
    ref { "refs/heads/#{branch_name}" }
    head_ref { nil }
    workflow { ".github/workflows/main.yml" }
    action { "rwx_results" }
    actor { "ryansch" }
    job { "test" }
    run_number { "33" }
    run_id { "6407895730" }
    api_url { "https://api.github.com" }
    server_url { "https://github.com" }
    graphql_url { "https://api.github.com/graphql" }
    overrides { {} }

    initialize_with { new(**attributes) }
  end
end
