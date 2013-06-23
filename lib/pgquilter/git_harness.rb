require 'open3'

module PGQuilter
  class GitHarness
    class ExecError < StandardError
      attr_reader :stderr
      def initialize(msg, stderr)
        super(msg)
        @stderr = stderr
      end
    end
    class PatchError < StandardError; end

    # Check the location of the master branch of upstream repository
    def check_upstream_sha
      (run_cmd "git ls-remote #{::PGQuilter::Config::UPSTREAM_REPO_URL} master").split("\t").first
    end

    def has_workspace?
      File.directory? ::PGQuilter::Config::WORK_DIR
    end

    def prepare_workspace
      ssh_setup
      git_clone
      git_setup
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
      begin
        git %W(branch #{branch})
      rescue ->(e) { e.message =~ /fatal: A branch named .* already exists\./ }
        # ignore
      end
      git %W(checkout #{branch})
      # TODO: it would be useful to create a commit moving us to master branch
      # without actually losing commit history
      git %w(reset --hard master)
    end

    def ssh_setup
      if ENV.has_key? 'GITHUB_PRIVATE_KEY'
        # TODO: we skip this when the key is not set for testing;
        # figure out a better approach
        run_cmd 'echo "$GITHUB_PRIVATE_KEY" > $HOME/.ssh/id_rsa'
      end
    end

    def git_setup
      git %W(config user.name #{::PGQuilter::Config::QUILTER_NAME})
      git %W(config user.email #{::PGQuilter::Config::QUILTER_EMAIL})
    end

    def git_clone
      run_cmd "mkdir -p #{::PGQuilter::Config::WORK_DIR}"
      git %W(clone #{::PGQuilter::Config::WORK_REPO_URL} #{::PGQuilter::Config::WORK_DIR})
      git %W(remote add upstream #{::PGQuilter::Config::UPSTREAM_REPO_URL})
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
    rescue ->(e) { e.respond_to?(:stderr) && e.stderr =~ /patch does not apply/ } => e
      # TODO: do better than the above heuristic
      raise PatchError, e.stderr
    end

    def git_commit(message, author)
      git %W(commit . -m #{message} --author=#{author})
    end

    private

    def run_cmd(cmd)
      # We ignore stderr for now; we're likely never to need it here
      # N.B.: this is super-unsafe; don't run with untrusted input
      result = `#{cmd}`
      unless $?.exitstatus == 0
        raise ExecError, "Command `#{cmd}` failed"
      end
      result
    end

    def git(args)
      FileUtils.cd(::PGQuilter::Config::WORK_DIR) do
        command = [ 'git', *args ]
        Open3.popen3(*command) do |stdin, stdout, stderr, wthr|
          exitstatus = wthr.value.exitstatus
          unless exitstatus == 0
            stdoutstr = stdout.read
            stderrstr = stderr.read
            raise ExecError.new(<<-EOF, stderrstr)
Command `#{command}` failed
stdout:
  #{stdoutstr}
stderr:
  #{stderrstr}
EOF
          end
          # N.B.: we need this return because FileUtils.cd does
          # not return the value of the yielded block
          return stdout.read
        end
      end
    end

  end
end
