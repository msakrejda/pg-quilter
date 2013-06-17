# -*- coding: utf-8 -*-
module PGQuilter
  class Git

    def initialize(harness)
      @g = harness
    end

    def check_upstream_sha
      @g.check_upstream_sha
    end

    def apply_patchset(patchset)
      # TODO: report failure
      check_workspace
      @g.reset
      @g.prepare_branch patchset.topic.name

      # TODO: track whether any patch has been successfully applied
      patchset.patches.sort_by(&:patchset_order).each do |patch|
        apply_patch(patch)
      end
      # TODO: better commit message, e.g., referencing the actual
      # patch e-mails (by link or at least ID)
      @g.git_commit("Applying patch set for #{patchset.topic.name}", author)
    end

    def push_to_github(patchset)
      # push both master and the patch so we always have the latest PR
      branch = patchset.topic.name
      @g.update_branch(branch)
    end

    def submit_pull_request(branch)
      # for now, do this only on the first patchset (later, add comments
      # for each subsequent patchset)
      github = Github.new(login: PGQuilter::Config::GITHUB_USER,
                          password: PGQuilter::Config::GITHUB_PASSWORD)
      github.pull_requests.create(user, 'postgres',
                                  { "title" => "#{branch}",
                                    "body" => "",
                                    "head" => branch,
                                    "base" => "master" })
    end

    def check_workspace
      @g.prepare_workspace unless @g.has_workspace?
    end

    def apply_patch(patch)
      patchset = patch.patchset
      patch_name = "#{patchset.topic.name}-#{patchset.message_id}-#{patch.patchset_order}.patch"
      patch_path = "/tmp/#{patch_name}"
      File.open(patch_path, 'w') do |patch_file|
        patch_file.write patch.body
      end
      # TODO: this is kind of a gross hack around patch application
      result = @g.apply_patch(patch_path)
      # TODO: properly detect successful patch application
      failed =~ /does not apply\Z/
      patch.add_application(base_sha: @base_sha,
                            succeeded: failed.nil?, output: result)
      failed.nil?
    end

  end
end
