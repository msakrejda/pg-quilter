module PGQuilter
  class Git

    def check_upstream_sha
      (git "ls-remote #{PGQuilter::Config::CANONICAL_REPO_URL}").split("\t").first
    end

    def git_reset
      git "checkout master"
      git "fetch upstream"
      git "reset --hard upstream/master"
      @base_sha = git("show-ref -s refs/heads/master").chomp
    end

    def apply_patchset(patchset)
      # TODO: report failure
      check_workspace
      git_reset
      git "checkout -B #{patchset.topic.name}"
      # TODO: it would be useful to create a commit moving us to master branch
      # without actually losing commit history
      git "reset --hard master"
      patchset.patches.sort_by(&:patchset_order).each do |patch|
        apply_patch(patch)
      end
      # TODO: better commit message, e.g., referencing the actual
      # patch e-mails (by link or at least ID)
      git "commit . --author='#{author}' -m 'Applying patch set for #{patchset.topic.name}'"
    end

    def push_to_github(patchset)
      # push both master and the patch so we always have the latest PR
      git "push origin master"
      git "cherry-pick travis-config"
      git "push -f origin #{patchset.topic.name}"
      patchset.topic.name
    end

    def submit_pull_request(branch)
      # for now, do this only on the first patchset (later, add comments
      # for each subsequent patchset)
      # TODO: different class?
      github = Github.new(login: PGQuilter::Config::GITHUB_USER,
                          password: PGQuilter::Config::GITHUB_PASSWORD)
      github.pull_requests.create(user, 'postgres',
                                  { "title" => "#{branch}",
                                    "body" => "",
                                    "head" => branch,
                                    "base" => "master" })
    end

    def run_cmd(cmd)
      # We ignore stderr for now; we're likely never to need it here
      result = `#{cmd}`
      unless $?.exitstatus == 0
        raise StandardError, "Command '#{cmd}' failed"
      end
      result
    end

    def git(cmd)
      result = nil
      FileUtils.cd(PGQuilter::Config::WORK_DIR) do
        result = run_cmd "git #{cmd}"
      end
      result
    end

    def has_workspace?
      File.directory? PGQuilter::Config::WORK_DIR
    end

    def check_workspace
      prepare_workspace unless has_workspace?
    end

    def prepare_workspace
      ssh_setup
      git_clone
      git_setup
    end

    def ssh_setup
      run_cmd 'echo "$GITHUB_PRIVATE_KEY" > $HOME/.ssh/id_rsa'
    end

    def git_setup
      git "config --global user.name '#{PGQuilter::Config::QUILTER_NAME}'"
      git "config --global user.email '#{PGQuilter::Config::QUILTER_EMAIL}'"
    end

    def git_clone
      run_cmd "mkdir -p #{PGQuilter::Config::WORK_DIR}"
      git "clone #{PGQuilter::Config::WORK_REPO_URL} #{PGQuilter::Config::WORK_DIR}"
      git "remote add upstream #{PGQuilter::Config::CANONICAL_REPO_URL}"
    end

    def apply_patch(patch)
      patchset = patch.patchset
      patch_name = "#{patchset.topic.name}-#{patchset.message_id}-#{patch.patchset_order}.patch"
      patch_path = "/tmp/#{patch_name}"
      File.open(patch_path, 'w') do |patch_file|
        patch_file.write patch.body
      end
      # TODO: does a failed application produce stderr output?
      result = git "apply #{patch_path}"
      PGQuilter::Application.create(base_sha: @base_sha, patch_id: patch.uuid,
                                    succeeded: result.success?, output: result)
    end

  end
end
