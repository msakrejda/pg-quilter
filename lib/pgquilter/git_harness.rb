require 'open3'

module PGQuilter
  class GitHarness
    class ExecError < StandardError
      attr_reader :stderr
      def initialize(msg, stderr)
        super
        @stderr = stderr
      end
    end

    # Check the location of the master branch of upstream repository
    def self.check_upstream_sha
      (git %W(ls-remote #{PGQuilter::Config::UPSTREAM_REPO_URL} master)).split("\t").first
    end

    def run_cmd(cmd)
      # We ignore stderr for now; we're likely never to need it here
      # N.B.: this is super-unsafe; don't run with untrusted input
      result = `#{cmd}`
      unless $?.exitstatus == 0
        raise ExecError, "Command `#{cmd}` failed"
      end
      result
    end

    def git(subcmd, *opts)
      FileUtils.cd(PGQuilter::Config::WORK_DIR) do
        command = opts.unshift('git', subcmd)
        Open3.popen(*command) do |stdin, stdout, stderr, wthr|
          exitstatus = wthr.value.exitstatus
          unless exitstatus == 0
            raise ExecError, "Command `#{command}` failed", stderr.readlines
          end
          # N.B.: we need this return because FileUtils.cd does
          # not return the value of the yielded block
          return stdout.readlines
        end
      end
    end

    # reset master branch to upstream and return the new location SHA
    def reset
      git %w(checkout master)
      git %w(fetch upstream)
      git %w(reset --hard upstream/master)
      (git %w(show-ref -s refs/heads/master)).chomp
    end

    def prepare_branch(branch)
      # N.B.: the git 1.8.1.2 on the Heroku stack image does not support -B
      git %W(branch #{branch}) rescue nil
      git %W(checkout #{branch})
      # TODO: it would be useful to create a commit moving us to master branch
      # without actually losing commit history
      git %w(reset --hard master)
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
      git %W(config --global user.name #{PGQuilter::Config::QUILTER_NAME})
      git %W(config --global user.email #{PGQuilter::Config::QUILTER_EMAIL})
    end

    def git_clone
      run_cmd "mkdir -p #{PGQuilter::Config::WORK_DIR}"
      git %W(clone #{PGQuilter::Config::WORK_REPO_URL} #{PGQuilter::Config::WORK_DIR})
      git %W(remote add upstream #{PGQuilter::Config::UPSTREAM_REPO_URL})
    end

    def update_branch(branch)
      git %w(push origin master)
      git %w(cherry-pick origin/travis-config)
      git %w(push -f origin #{branch})
    end

    def apply_patch(patch_body)
      Tempfile.open('pg-quilter-postgres', '/tmp') do |f|
        f.write patch_body
        f.flush
        git %W(apply --verbose #{f.path})
      end
    rescue ExecError => e
      e.stderr
    end

    def git_commit(message, author)
      git %W(commit . -m #{message} --author=#{author})
    end

  end
end
