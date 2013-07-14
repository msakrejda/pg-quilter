require 'tempfile'
require 'spec_helper'

describe PGQuilter::GitHarness do

  let(:harness) { double(:harness, has_workspace?: true) }
  let(:gh_prs) { double(:pull_requests) }
  let(:github) { double(:github, pull_requests: gh_prs) }

  let(:subject) { PGQuilter::Git.new(harness, github) }

  let(:topic) { double(:topic, name: "test topic") }
  let(:good_patch) { double(:patch, patchset_order: 0, body: <<-EOF) }
diff --git a/test2 b/test2
new file mode 100644
index 0000000..dd7e1c6
--- /dev/null
+++ b/test2
@@ -0,0 +1 @@
+goodbye
EOF

  let(:bad_patch) { double(:patch, patchset_order: 0, body: <<-EOF) }
diff --git a/test b/test
index 3b18e51..032b687 100644
--- a/test
+++ b/test
@@ -1 +1,2 @@
 hello world
+goodbye
EOF

  let(:good_patchset) { double(:patchset, topic: topic,
                               message_id: '20130617001812.GA23563@example.com',
                               author: "Jane Q. Commiter <janeqc@example.com>",
                               patches: [ good_patch ]) }
  let(:bad_patchset) { double(:patchset, topic: topic,
                               message_id: '20130617001812.GA23563@example.com',
                              author: "Irma X. Hacker <irmaxh@example.com>",
                              patches: [ bad_patch ]) }

  let(:clean_application) { double(:application, succeeded: true,
                                   patch: good_patch, output: <<-EOF) }
Checking patch test2...
Applied patch test2 cleanly.
EOF

  let(:bad_application) { double(:application, succeeded: false,
                                 patch: bad_patch, output: <<-EOF) }
Checking patch test...
error: while searching for:
hello world

error: patch failed: test:1
error: test: patch does not apply
EOF

  def pr_head(branch)
    "#{PGQuilter::Config::GITHUB_USER}:#{branch}"
  end

  before(:each) do
    good_patch.stub(:patchset).and_return(good_patchset)
    bad_patch.stub(:patchset).and_return(bad_patchset)
  end

  it "forwards #check_upstream_sha call" do
    upstream_sha = '76cbcb55e51823bc31467f5afab4d7f523ce211f'
    harness.should_receive(:check_upstream_sha).and_return(upstream_sha)
    expect(subject.check_upstream_sha).to eq(upstream_sha)
  end

  it "uses topic name as branch" do
    expect(subject.branch(topic)).to eq(topic.name)
  end

  it "generates a useful commit message" do
    branch = subject.branch(topic)
    message = subject.commit_message(branch, clean_application)
    expect(message).to match(/1 of 1/)
    expect(message).to match(branch)
    expect(message).to match(::PGQuilter::Config::HACKERS_ARCHIVE)
    expect(message).to match(good_patchset.message_id)
  end

  it "applies a patchset with valid patches" do
    harness.should_receive(:reset).and_return "sha123"
    harness.should_receive(:prepare_branch)
      .with(subject.branch(topic)).and_return "sha123"
    good_patchset.patches.each do |patch|
      harness.should_receive(:apply_patch).with(patch.body).and_return(clean_application)
      patch.should_receive(:add_application).and_return(clean_application)
      harness.should_receive(:git_commit)
        .with(subject.commit_message(subject.branch(topic), clean_application),
              good_patchset.author)
    end

    subject.apply_patchset(good_patchset)
  end

  it "applies a patchset with invalid patches" do
    harness.should_receive(:reset).and_return "sha123"
    harness.should_receive(:prepare_branch)
      .with(subject.branch(topic)).and_return "sha123"
    bad_patchset.patches.each do |patch|
      harness.should_receive(:apply_patch).with(patch.body).and_return(bad_application)
      patch.should_receive(:add_application).and_return(bad_application)
      harness.should_receive(:git_commit)
        .with(subject.commit_message(subject.branch(topic), bad_application),
              bad_patchset.author)
    end

    subject.apply_patchset(bad_patchset)
  end

  it "pushes changes upstream" do
    branch = subject.branch(topic)
    harness.should_receive(:update_branch).with(branch)
    subject.push_to_github(topic)
  end

  it "creates a pull request if necessary" do
    branch = topic.name
    gh_prs.should_receive(:list).with(user: PGQuilter::Config::GITHUB_USER,
                                      repo: 'postgres', head: pr_head(branch))
      .and_return([])
    gh_prs.should_receive(:create).with(PGQuilter::Config::GITHUB_USER, 'postgres',
                                        { "title" => branch,
                                          "body" => "",
                                          "head" => branch,
                                          "base" => "master" })
    subject.ensure_pull_request topic
  end

  it "does not create a pull request if one exists" do
    branch = topic.name
    gh_prs.should_receive(:list).with(user: PGQuilter::Config::GITHUB_USER,
                                      repo: 'postgres', head: pr_head(branch))
      .and_return([ double(:pr, title: branch) ])
    subject.ensure_pull_request topic
  end

  it "considers an unopened pull request active" do
    branch = topic.name
    gh_prs.should_receive(:list).with(user: PGQuilter::Config::GITHUB_USER,
                                      repo: 'postgres', head: pr_head(branch))
      .and_return([])
    expect(subject.pull_request_active? topic).to eq(true)
  end

  it "considers an open pull request active" do
    branch = topic.name
    gh_prs.should_receive(:list).with(user: PGQuilter::Config::GITHUB_USER,
                                      repo: 'postgres', head: pr_head(branch))
      .and_return([ double(:pr, title: branch, state: 'open') ])
    expect(subject.pull_request_active? topic).to eq(true)
  end

  it "considers a closed pull request inactive" do
    branch = topic.name
    gh_prs.should_receive(:list).with(user: PGQuilter::Config::GITHUB_USER,
                                      repo: 'postgres', head: pr_head(branch))
      .and_return([ double(:pr, title: branch, state: 'closed') ])
    expect(subject.pull_request_active? topic).to eq(false)
  end
end
