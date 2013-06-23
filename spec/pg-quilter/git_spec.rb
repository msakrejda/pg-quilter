require 'tempfile'
require 'spec_helper'

describe PGQuilter::GitHarness do

  let(:harness) { double(:harness, has_workspace?: true) }
  let(:subject) { PGQuilter::Git.new(harness) }

  let(:topic) { double(:topic, name: "test topic") }
  let(:good_patch) { double(:patch, body: <<-EOF, patchset_order: 0) }
diff --git a/test2 b/test2
new file mode 100644
index 0000000..dd7e1c6
--- /dev/null
+++ b/test2
@@ -0,0 +1 @@
+goodbye
EOF

  let(:bad_patch) { double(:patch, body: <<-EOF, patchset_order: 0) }
diff --git a/test b/test
index 3b18e51..032b687 100644
--- a/test
+++ b/test
@@ -1 +1,2 @@
 hello world
+goodbye
EOF

  let(:good_patchset) { double(:patchset, topic: topic,
                               author: "Jane Q. Commiter <janeqc@example.com>",
                               patches: [ good_patch ]) }
  let(:bad_patchset) { double(:patchset, topic: topic,
                              author: "Irma X. Hacker <irmaxh@example.com>",
                              patches: [ bad_patch ]) }

  let(:clean_application) { double(:application, output: <<-EOF, succeeded: true) }
Checking patch test2...
Applied patch test2 cleanly.
EOF

  let(:bad_application) { double(:application, output: <<-EOF, succeeded: false) }
Checking patch test...
error: while searching for:
hello world

error: patch failed: test:1
error: test: patch does not apply
EOF

  it "forwards #check_upstream_sha call" do
    upstream_sha = '76cbcb55e51823bc31467f5afab4d7f523ce211f'
    harness.should_receive(:check_upstream_sha).and_return(upstream_sha)
    expect(subject.check_upstream_sha).to eq(upstream_sha)
  end

  it "uses patchset topic name as branch" do
    topic_name = 'hello-world'
    patchset = double(:patchset)
    patchset.stub_chain(:topic, :name).and_return(topic_name)
    expect(subject.branch(patchset)).to eq(topic_name)
  end

  it "applies a patchset with valid patches" do
    harness.should_receive(:reset).and_return "sha123"
    harness.should_receive(:prepare_branch)
      .with(subject.branch(good_patchset)).and_return "sha123"
    good_patchset.patches.each do |patch|
      harness.should_receive(:apply_patch).with(patch.body).and_return(clean_application)
      patch.should_receive(:add_application).and_return(clean_application)
      harness.should_receive(:git_commit)
        .with(subject.commit_message(subject.branch(good_patchset), clean_application),
              good_patchset.author)
    end

    subject.apply_patchset(good_patchset)
  end

  it "applies a patchset with invalid patches" do
    harness.should_receive(:reset).and_return "sha123"
    harness.should_receive(:prepare_branch)
      .with(subject.branch(bad_patchset)).and_return "sha123"
    bad_patchset.patches.each do |patch|
      harness.should_receive(:apply_patch).with(patch.body).and_return(bad_application)
      patch.should_receive(:add_application).and_return(bad_application)
      harness.should_receive(:git_commit)
        .with(subject.commit_message(subject.branch(bad_patchset), bad_application),
              bad_patchset.author)
    end

    subject.apply_patchset(bad_patchset)
  end


end
