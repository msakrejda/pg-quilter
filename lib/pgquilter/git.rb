require 'tempfile'

module PGQuilter
  class Git

    def initialize(harness)
      @g = harness
    end

    def check_upstream_sha
      @g.check_upstream_sha
    end

    def branch(patchset)
      patchset.topic.name
    end

    def apply_patchset(patchset)
      # TODO: report failure
      check_workspace
      branch = branch(patchset)
      base_sha = @g.reset
      @g.prepare_branch branch

      applications = patchset.patches.sort_by(&:patchset_order).map do |patch|
        apply_patch(base_sha, patch)
      end

      unless applications.all?(:succeeded)
        # TODO: handle this--update the PR as failed? intentionally
        # push badly-applied patch?
      end

      commit_msg = commit_message(branch, applications)
      @g.git_commit(commit_msg, author)
    end

    def commit_message(branch, applications)
      # TODO: better commit message, e.g., referencing the actual
      # patch e-mails (by link or at least ID)
      "Applying patch set for #{branch}"
    end

    def push_to_github(patchset)
      # push both master and the patch so we always have the latest PR
      @g.update_branch branch(patchset)
    end

    def check_workspace
      @g.prepare_workspace unless @g.has_workspace?
    end

    def ensure_pull_request(patchset)
      branch = branch(patchset)
      submit_pull_request(branch) unless has_pull_request?(branch)
    end

    def submit_pull_request(branch)
      # for now, do this only on the first patchset (later, add comments
      # for each subsequent patchset)
      github.pull_requests.create(PGQuilter::Config::GITHUB_USER, 'postgres',
                                  { "title" => branch,
                                    "body" => "",
                                    "head" => branch,
                                    "base" => "master" })
    end

    private

    def github
      @github ||= Github.new(login: PGQuilter::Config::GITHUB_USER,
                             password: PGQuilter::Config::GITHUB_PASSWORD)
    end

    def has_pull_request?(branch)
      prs = github.pull_requests.with(user: PGQuilter::Config::GITHUB_USER,
                                      repo: 'postgres').list
      result = prs.find { |pr| pr.title == branch }
      !result.nil?
    end

    # Applies a patch and returns the resulting Application
    def apply_patch(base_sha, patch)
      result = @g.apply_patch(patch.body)
      success = true
    rescue PatchError => e
      result = e.message
      success = false
    ensure
      patch.add_application(base_sha: base_sha,
                            succeeded: success, output: result)
    end

  end
end
