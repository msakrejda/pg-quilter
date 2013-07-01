require 'tempfile'

module PGQuilter
  class Git

    def initialize(harness, github)
      @g = harness
      @github = github
    end

    def check_upstream_sha
      @g.check_upstream_sha
    end

    def branch(topic)
      topic.name
    end

    # Apply a patchset. Stop applying at first failing patch (but still record it).
    def apply_patchset(patchset)
      check_workspace
      branch = branch(patchset.topic)
      base_sha = @g.reset
      @g.prepare_branch branch

      applications = []

      patchset.patches.sort_by(&:patchset_order).take_while do |patch|
        application = apply_patch(base_sha, patch)
        applications << application
        # Committing regardless of patch application success here is a
        # little ugly, but it does quickly and obviously break the
        # Travis build. Perhaps an alternative would be to comment on
        # the pull request
        commit_msg = commit_message(branch, application)
        @g.git_commit(commit_msg, patchset.author)
        application.succeeded
      end
    end

    def commit_message(branch, application)
      patch = application.patch
      patchset = patch.patchset
      n = patch.patchset_order + 1
      tot = patchset.patches.count
      msg_id = patchset.message_id
      <<-EOF
Applied patch #{n} of #{tot} for #{branch}

`git apply --verbose` output was:

```
#{application.output}
```

For original context, see #{::PGQuilter::Config::HACKERS_ARCHIVE}/#{msg_id}
EOF
    end

    def push_to_github(topic)
      # push both master and the patch so we always have the latest PR
      @g.update_branch branch(topic)
    end

    def check_workspace
      @g.prepare_workspace unless @g.has_workspace?
    end

    def ensure_pull_request(topic)
      branch = branch(topic)
      submit_pull_request(branch) unless has_pull_request?(branch)
    end

    # Has the pull request been closed or merged
    def pull_request_active?(topic)
      branch = topic.name
      prs = @github.pull_requests.with(user: ::PGQuilter::Config::GITHUB_USER,
                                       repo: 'postgres').list
      result = prs.find { |pr| pr.title == branch }
      # This is a degenerate case: a not-yet-opened pull request is
      # neither closed nor merged
      result.nil? || result.state == 'open'
    end

    private

    # True if a pull request already exists for this branch; false otherwise
    def has_pull_request?(branch)
      prs = @github.pull_requests.with(user: ::PGQuilter::Config::GITHUB_USER,
                                       repo: 'postgres').list
      result = prs.find { |pr| pr.title == branch }
      !result.nil?
    end

    def submit_pull_request(branch)
      # for now, do this only on the first patchset (later, add comments
      # for each subsequent patchset)
      @github.pull_requests.create(::PGQuilter::Config::GITHUB_USER, 'postgres',
                                   { "title" => branch,
                                     "body" => "",
                                     "head" => branch,
                                     "base" => "master" })
    end

    # Applies a patch and returns the resulting Application
    def apply_patch(base_sha, patch)
      result = @g.apply_patch(patch.body)
      success = true
    rescue PGQuilter::GitHarness::PatchError => e
      result = e.message
      success = false
    ensure
      unless success.nil?
        application = patch.add_application(base_sha: base_sha,
                                            succeeded: success, output: result)
        return application
      end
    end
  end
end
