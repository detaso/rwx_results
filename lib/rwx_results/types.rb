module RwxResults
  Issue = Data.define(
    :owner,
    :repo,
    :number
  )

  Repo = Data.define(
    :owner,
    :repo
  ) do
    def to_s
      "#{owner}/#{repo}"
    end
  end

  PullRequest = Data.define(
    :pr,
    :bot_comment
  )
end
