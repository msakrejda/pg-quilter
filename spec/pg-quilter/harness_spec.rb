require 'tempfile'
require 'spec_helper'

describe PGQuilter::Harness do

  let(:subject) { PGQuilter::Harness.new }

  around(:each) do |example|
    Dir.mktmpdir('pg-quilter-test-repo') do |upstream|
      @upstream_remote_dir = upstream
      system("tar -C #{upstream} -x -z -f spec/repo-template/upstream/dotgit.tgz")
      Dir.mktmpdir('pg-quilter-workspace') do |workspace|
        @workspace_dir = "#{workspace}/postgres"
        example.run
      end
    end
  end

  before(:each) do |example|
    # TODO: unfortunately, around blocks don't share state with the
    # fixtures, so there's no way to stub out the constants above; we
    # use this gross hack
    stub_const('PGQuilter::Config::UPSTREAM_REPO_URL', "file://#{@upstream_remote_dir}")
    stub_const('PGQuilter::Config::WORK_DIR', @workspace_dir)
  end
  
  def rstr(len)
    rand(36**len).to_s(36)
  end

  def in_dir(dir, cmd)
    FileUtils.cd(dir) do
      return `#{cmd}`.chomp
    end
  end

  def in_upstream(cmd)
    in_dir(@upstream_remote_dir, cmd)
  end

  def in_workspace(cmd)
    in_dir(@workspace_dir, cmd)
  end

  it "can prepare its workspace" do
    expect(File.directory? ::PGQuilter::Config::WORK_DIR).to be_false
    subject.prepare_workspace
    expect(File.directory? ::PGQuilter::Config::WORK_DIR).to be_true
  end

  context "with workspace" do
    before(:each) do
      subject.prepare_workspace
    end

    it "can reset work repo to upstream" do
      upstream_sha = in_upstream("git rev-parse master")
      result = subject.reset('master')
      expect(result.status).to eq(0)
      expect(result.stdout).to match(/HEAD is now at 76cbbb5 An important update/)
      expect(in_workspace("git rev-parse master")).to eq(upstream_sha)
    end

    it "can clean up files changed by other patches when resetting" do
      subject.reset('master')
      in_workspace(":> GNUMakefile")
      subject.reset('master')
      expect(in_workspace("git diff master")).to eq("")
    end

    it "can check the local rev" do
      actual_sha = in_workspace('git rev-parse master')
      expect(subject.check_rev).to eq(actual_sha)
    end

    it "can apply a clean patch" do
      patch = IO.read('spec/repo-template/clean.patch')
      branch = rstr(10)
      subject.reset('master')

      result = subject.apply_patch(patch)
      expect(result.status).to eq(0)

      # N.B.: we chomp in the helper command, so we need to do it to the patch
      expect(in_workspace("git add . && git diff master")).to eq(patch.chomp)
    end

    it "fails to apply a patch with conflicts" do
      patch = IO.read('spec/repo-template/conflicting.patch')
      subject.reset('master')

      result = subject.apply_patch(patch)

      expect(result.status).to_not eq(0)
      expect(result.stderr).to match(/patch does not apply/)
    end

  end
end
