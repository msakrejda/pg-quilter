require 'open3'

module PGQuilter
  class GitHarness
    class ExecError < StandardError
      attr_reader :stderr
      def initialize(msg, stderr=nil)
        super(msg)
        @stderr = stderr
      end
    end
    class PatchError < StandardError; end

    # Check the location of the master branch of upstream repository
    def check_upstream_sha
      git(%W(ls-remote #{::PGQuilter::Config::UPSTREAM_REPO_URL} master)).split("\t").first
    end

    # True if a workspace has been prepared; false otherwise
    def has_workspace?
      File.directory? ::PGQuilter::Config::WORK_DIR
    end

    # Prepare a workspace: configure ssh keys and set up the local git
    # repository and relevant remotes
    def prepare_workspace
      git_clone
      git_setup
    end

    # Update upstream, reset master branch to latest upstream change,
    # and return the new HEAD sha
    def reset
      git %w(clean -f -d)
      git %w(checkout master)
      git %w(fetch upstream)
      git %w(reset --hard upstream/master)
      git(%w(show-ref -s refs/heads/master)).chomp
    end

    # Create given branch if necessary and reset it to master
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

    def git_setup
      git %W(config user.name #{::PGQuilter::Config::QUILTER_NAME})
      git %W(config user.email #{::PGQuilter::Config::QUILTER_EMAIL})
    end

    def git_clone
      FileUtils.mkdir_p(::PGQuilter::Config::WORK_DIR)
      git %W(clone #{::PGQuilter::Config::WORK_REPO_URL} #{::PGQuilter::Config::WORK_DIR})
      git %W(remote add upstream #{::PGQuilter::Config::UPSTREAM_REPO_URL})
    end

    def update_branch(branch)
      # push both master and the patch so we always have the latest PR
      git %w(push origin master)
      add_travis
      git %W(push -f origin #{branch})
    end

    # Apply the given patch body to the working directory (does not
    # commit changes)
    def apply_patch(patch_body)
      Tempfile.open('pg-quilter-postgres', '/tmp') do |f|
        f.write patch_body
        f.flush
        git %W(apply --summary --stat --apply --verbose #{f.path})
      end
    rescue ExecError => e
      sentinel_path = File.join(::PGQuilter::Config::WORK_DIR,
                                ::PGQuilter::Config::BAD_PATCH_SENTINEL)
      FileUtils.touch(sentinel_path)
      raise PatchError, e.stderr
    end

    # Commit all local changes (including new files)
    def git_commit(message, author=nil)
      git %W(add .)
      commit_args = %W(commit -m #{message})
      unless author.nil?
        commit_args << "--author=#{author}"
      end
      git commit_args
    end

    private

    def git(args)
      if File.directory? ::PGQuilter::Config::WORK_DIR
        FileUtils.cd(::PGQuilter::Config::WORK_DIR) do
          # N.B.: we need this return because FileUtils.cd does
          # not return the value of the yielded block
          return direct_git(args)
        end
      else
        direct_git(args)
      end
    end

    def direct_git(args)
      command = [ 'git', *args ]
      Open3.popen3({ 'GIT_SSH' => '/app/git/git-ssh' },
                   *command) do |stdin, stdout, stderr, wthr|
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
        stdout.read
      end
    end

    def add_travis
      travis_yml_path = File.join(::PGQuilter::Config::WORK_DIR, '.travis.yml')
      File.open(travis_yml_path, 'w') do |f|
        f.write <<-EOF
language: c
compiler:
  - gcc
  - clang
notifications:
  email: false

before_script: echo "COPT=-Werror" > Makefile.custom

script: test ! -f #{::PGQuilter::Config::BAD_PATCH_SENTINEL} && ./configure --with-libxml --with-openssl --enable-cassert && make check
EOF
      end
      git_commit("Adding travis.yml")
    end
  end
end
