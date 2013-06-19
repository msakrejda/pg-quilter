module PGQuilter
  class GitHarness

    def self.check_upstream_sha
      git("ls-remote #{PGQuilter::Config::CANONICAL_REPO_URL} master").split("\t").first
    end

    def run_cmd(cmd)
      # We ignore stderr for now; we're likely never to need it here
      # N.B.: this is super-unsafe; don't run with untrusted input
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

    # reset master branch to upstream and return the new location SHA
    def reset
      git "checkout master"
      git "fetch upstream"
      git "reset --hard upstream/master"
      git("show-ref -s refs/heads/master").chomp
    end

    def prepare_branch(branch)
      # N.B.: the git 1.8.1.2 on the Heroku stack image does not support -B
      git "branch '#{branch}' || true"
      git "checkout '#{branch}'"
      # TODO: it would be useful to create a commit moving us to master branch
      # without actually losing commit history
      git "reset --hard master"
    end
    
    def has_workspace?
      File.directory? PGQuilter::Config::WORK_DIR
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

    def update_branch(branch)
      git "push origin master"
      git "cherry-pick travis-config"
      git "push -f origin #{branch}"
    end

    def apply_patch(patch_path)
      git "apply --verbose #{patch_path} 2>&1 || true"
    end

    def git_commit(message, author)
      # TODO: fix escaping / handle parameters properly
      message.gsub!("'", "''")
      author.gsub!("'", "''")
      git "commit . -m '#{message}' --author='#{author}'"
    end

  end
end
