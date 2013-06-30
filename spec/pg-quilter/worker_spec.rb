require 'tempfile'
require 'spec_helper'

describe PGQuilter::GitHarness do

  let(:latest_patchset) { double(:latest_patchset) }
  let(:topic) { double(:topic, latest_patchset: latest_patchset) }
  let(:git) { double(:git) }
  let(:subject) { PGQuilter::Worker.new(git) }

  it "rebuilds if upstream sha has changed" do
    git.should_receive(:check_upstream_sha).and_return('abc123')
    subject.should_receive(:run_builds)

    result = subject.check_builds('xxx444')
    expect(result).to eq('abc123')
  end

  it "avoids rebuilding with a stable sha" do
    git.should_receive(:check_upstream_sha).and_return('abc123')
    subject.should_not_receive(:run_builds)

    result = subject.check_builds('abc123')
    expect(result).to eq('abc123')
  end

  it "avoids rebuilding with a stable sha" do
    git.should_receive(:check_upstream_sha).and_return('abc123')
    subject.should_not_receive(:run_builds)

    result = subject.check_builds('abc123')
    expect(result).to eq('abc123')
  end

  it "builds topics with active pull requests" do
    git.should_receive(:pull_request_active?).with(topic).and_return(true)
    latest_patchset.should_receive(:last_build_failed?).and_return(false)
    subject.should_receive(:run_build).with(latest_patchset)

    subject.check_topic(topic)
  end

  it "skips topics with failed builds" do
    git.should_receive(:pull_request_active?).with(topic).and_return(true)
    latest_patchset.should_receive(:last_build_failed?).and_return(true)
    subject.should_not_receive(:run_build)

    subject.check_topic(topic)
  end

  it "deactivates topics with closed pull requests" do
    git.should_receive(:pull_request_active?).with(topic).and_return(false)
    topic.should_receive(:active=).with(false)
    topic.should_receive(:save_changes)

    subject.should_not_receive(:run_build)

    subject.check_topic(topic)
  end

end
