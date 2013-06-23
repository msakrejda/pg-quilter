require 'tempfile'
require 'spec_helper'

describe PGQuilter::GitHarness, 'remote tests' do

  let(:subject) { PGQuilter::GitHarness.new }

  around(:each) do |example|
    Dir.mktmpdir('pg-quilter-test-repo') do |work|
      system("tar -C #{work} -x -z -f spec/repo-template/work/dotgit.tgz")
      @tmp_work_url = "file://#{work}"
      Dir.mktmpdir('pg-quilter-test-repo') do |upstream|
        @tmp_upstream_url = "file://#{upstream}"
        system("tar -C #{upstream} -x -z -f spec/repo-template/upstream/dotgit.tgz")
        example.run
      end
    end
  end

  before(:each) do |example|
    # TODO; unfortunately, around blocks don't share state with the
    # fixtures, so there's no way to stub out the constants above; we
    # use this gross hack
    stub_const('PGQuilter::Config::WORK_REPO_URL', @tmp_work_url)
    stub_const('PGQuilter::Config::UPSTREAM_REPO_URL', @tmp_upstream_url)
  end

  it "can check upstream sha" do
    actual_sha = `cd #{@tmp_upstream_url.sub(/\Afile:\/\//, '')} && git rev-parse master`.chomp
    expect(PGQuilter::GitHarness.check_upstream_sha).to eq(actual_sha)
  end

end
