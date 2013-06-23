require 'tempfile'
require 'spec_helper'

describe PGQuilter::GitHarness, 'remote tests' do

  let(:subject) { PGQuilter::GitHarness.new }

  around(:each) do |example|
    Dir.mktmpdir('pg-quilter-test-repo') do |work|
      system("tar -C #{work} -x -z -f spec/repo-template/work/dotgit.tgz")
      @work_remote_dir = work
      Dir.mktmpdir('pg-quilter-test-repo') do |upstream|
        @upstream_remote_dir = upstream
        system("tar -C #{upstream} -x -z -f spec/repo-template/upstream/dotgit.tgz")
        Dir.mktmpdir('pg-quilter-workspace') do |workspace|
          @workspace_dir = "#{workspace}/postgres"
          example.run
        end
      end
    end
  end

  before(:each) do |example|
    # TODO; unfortunately, around blocks don't share state with the
    # fixtures, so there's no way to stub out the constants above; we
    # use this gross hack
    stub_const('PGQuilter::Config::WORK_REPO_URL', "file://#{@work_remote_dir}")
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

  def in_work(cmd)
    in_dir(@work_remote_dir, cmd)
  end

  def in_workspace(cmd)
    in_dir(@workspace_dir, cmd)
  end

  it "can check upstream sha" do
    actual_sha = in_upstream('git rev-parse master')
    expect(subject.check_upstream_sha).to eq(actual_sha)
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

    it "configures git user metadata correctly" do
      subject.git_setup
      expect(in_workspace("git config user.name")).to eq(PGQuilter::Config::QUILTER_NAME)
      expect(in_workspace("git config user.email")).to eq(PGQuilter::Config::QUILTER_EMAIL)
    end

    it "can reset work repo to upstream" do
      upstream_sha = in_upstream("git rev-parse master")
      expect(subject.reset).to eq(upstream_sha)
      workspace_sha = in_workspace("git rev-parse master")
      expect(workspace_sha).to eq(upstream_sha)
    end

    it "can prepare a new branch" do
      branch = rstr(10)
      subject.prepare_branch(branch)
      expect(in_workspace("git rev-parse #{branch}")).to eq(in_workspace("git rev-parse master"))
    end

    it "can repeat preparation of an existing branch" do
      branch = rstr(10)
      subject.prepare_branch(branch)
      expect { subject.prepare_branch(branch) }.to_not raise_error
      expect(in_workspace("git rev-parse #{branch}")).to eq(in_workspace("git rev-parse master"))
    end

    it "can apply a clean patch" do
      patch = IO.read('spec/repo-template/clean.patch')
      branch = rstr(10)
      subject.prepare_branch(branch)

      expect { subject.apply_patch(patch) }.to_not raise_error
      # N.B.: we chomp in the helper command, so we need to do it to the patch
      expect(in_workspace("git add . && git diff master")).to eq(patch.chomp)
    end

    it "fails to apply a patch with conflicts" do
      patch = IO.read('spec/repo-template/conflicting.patch')
      branch = rstr(10)
      subject.reset
      subject.prepare_branch(branch)

      expect { subject.apply_patch(patch) }.to raise_error do |e|
        expect(e.class).to eq(PGQuilter::GitHarness::PatchError)
        expect(e.message =~ /patch does not apply/)
      end
      # N.B.: we chomp in the helper command, so we need to do it to the patch
      expect(in_workspace("git rev-parse #{branch}")).to eq(in_workspace("git rev-parse master"))
    end

    it "commits changes" do
      in_workspace("echo '* logical replication' > TODO")
      message = 'add TODO list'
      author  = 'Gladys Vanderhoff <gladys@vanderhoff.net>'
      subject.git_commit(message, author)
      expect(in_workspace("git log -1 --pretty='format:%an <%ae>'")).to eq(author)
      expect(in_workspace("git log -1 --pretty='format:%s'")).to eq(message)
      expect(in_workspace("git show -p HEAD")).to match(message)
    end

  end

end
