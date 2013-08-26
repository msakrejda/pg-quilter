# -*- coding: utf-8 -*-
require 'open3'

module PGQuilter
  class Harness
    class ExecResult
      attr_reader :cmd, :stdout, :stderr, :status

      def initialize(cmd, stdout, stderr, status)
        @cmd    = cmd
        @stdout = stdout
        @stderr = stderr
        @status = status
      end
    end

    # check the rev of the currently checked-out git ref
    def check_rev
      result = in_dir workdir do
        run %w(git show-ref -s refs/heads/master)
      end
      if result.status.zero?
        result.stdout.chomp
      else
        raise StandardError, "Could not check HEAD rev: #{result.stderr}"
      end
    end

    # True if a workspace has been prepared; false otherwise
    def has_workspace?
      File.directory? workdir
    end

    # Prepare a workspace: install dependencies and set up the local git clone
    def prepare_workspace
      run %W(bin/pg-prepare-workspace #{workdir} #{::PGQuilter::Config::WORK_REPO_URL})
    end

    # Clean the workspace, update upstream and reset master branch to given rev
    def reset(base_rev)
      # Let's assume that anything that looks like a full rev is one
      # and anything that doesn't is a symbolic rev. This is naïve and
      # overly restrictive, but it lets us have some sane behavior right
      # out of the gate without complications
      unless base_rev =~ /[0-9a-f]{40}/
        base_rev = "origin/#{base_rev}"
      end
      in_dir workdir do
        run %W(/app/bin/pg-reset-workspace #{workdir} #{base_rev})
      end
    end

    def apply_patch(patch_body)
      Tempfile.open('pg-quilter-postgres', '/tmp') do |f|
        f.write patch_body
        f.flush
        in_workdir do
          run %W(git apply --summary --stat --apply --verbose #{f.path})
        end
      end
    end

    def configure
      run %W(fakesu -c /app/bin/pg-config #{workdir})
    end

    def make
      run %W(fakesu -c /app/bin/pg-make #{workdir})
    end

    def make_check
      in_dir workdir do
        run %W(make check)
      end
    end

    def make_contribcheck
      in_dir File.join(workdir, 'contrib') do
        run %W(make check)
      end
    end

    private

    def in_dir(dir)
      FileUtils.cd(dir) do
        return yield
      end
    end

    def workdir
      ::PGQuilter::Config::WORK_DIR
    end

    def run(command)
      # Always including GIT_SSH here as a convenience: the other
      # commands don't need special environment changes, but this
      # doesn't hurt
      Open3.popen3({ 'GIT_SSH' => '/app/git/git-ssh' },
                   *command) do |stdin, stdout, stderr, wthr|
        stdoutstr = stdout.read
        stderrstr = stderr.read
        exitstatus = wthr.value.exitstatus

        ExecResult.new(command, stdoutstr, stderrstr, exitstatus)
      end
    end

  end
end
