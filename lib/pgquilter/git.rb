module PgQuilter
  class Git

    def git_reset
      git "checkout master"
      git "fetch upstream"
      git "reset --hard upstream/master"
      @base_sha = git "show-ref -s refs/heads/master"
    end

    def apply_patchset(patchset)
      git_reset
      git "checkout -b #{patchset.topic.name}"
      # TODO: it would be useful to create a commit moving us to master branch
      # without actually losing commit history
      git "reset --hard master"
      patchset.patches.sort_by(&:patchset_order).each do |patch|
        apply_patch("#{patch_path}", patch)
      end
      git "commit . m 'Applying patch set for #{patchset.topic.name}'"
    end

    def push_to_github(patchset)
      # push both master and the patch so we always have the latest PR
      run_cmd "git push origin master"
      run_cmd "git cherry-pick travis-config"
      run_cmd "git push -f origin #{patchset.topic.name}"
      patchset.topic.name
    end

    def submit_pull_request(branch)
      # for now, do this only on the first patchset (later, add comments
      # for each subsequent patchset)
      # TODO: different class?
      user = Config::GITHUB_USER
      github = Github.new(login: user, password: Config::GITHUB_PASSWORD)
      github.pull_requests.create(user, 'postgres',
                                  { "title" => "#{branch}",
                                    "body" => "",
                                    "head" => branch,
                                    "base" => "master" })
    end

    private
    def run_cmd(cmd)
      # stdout, stderr
    end

    def git(cmd)
      run_cmd "cd '#{Config::WORK_DIR}' && #{cmd}"
    end

    def has_workspace?
      File.directory? WORKSPACE_DIR
    end

    def check_workspace
      prepare_workspace unless has_workspace?
    end

    def prepare_workspace
      ssh_setup
      git_setup
      git_clone
    end

    def ssh_setup
      run_cmd 'echo "$GITHUB_SSH_KEY" > .ssh/id_rsa'
    end

    def git_setup
      run_cmd "git config --global user.name '#{Config::QUILTER_NAME}'"
      run_cmd "git config --global user.email '#{Config::QUILTER_EMAIL}'"
    end

    def git_clone
      run_cmd "mkdir -p '#{Config::WORK_DIR}'"
      run_cmd "git clone '#{Config::WORK_REPO_URL}' '#{Config::WORK_DIR}'"
      git "remote add upstream '#{Config::CANONICAL_REPO_URL}'"
    end


    def apply_patch(patch)
      patch_name = "#{patchset.topic.name}-#{patchset.message_id}-#{patch.patchset_order}.patch"
      patch_path = "/tmp/#{patch_name}"
      File.open (patch_path, 'w') do |patch_file|
        patch_file.write patch.body
      end
      result = git "apply #{patch_path}"
      PGQuilter::Application.create(base_sha: @base_sha, patch_id: patch.uuid,
                                    succeeded: result.success?, output: result.stdout) # stderr?
    end

  end
end
