require 'spec_helper'

describe PGQuilter::Build do
  let (:unbuilt) { PGQuilter::Build.create(base_rev: 'master') }
  let (:older_unbuilt) { PGQuilter::Build.create(base_rev: 'master',
                                                 created_at: Time.now - (60 * 60)) }
  let (:in_progress) { PGQuilter::Build.create(base_rev: 'master',
                                               state: 'running') }

  after :each do
    DB.run "DELETE FROM build_steps"
    DB.run "DELETE FROM builds"
  end

  it "should ignore running builds" do
    other = in_progress
    ran_it = false
    PGQuilter::Build.with_first_unbuilt do |build|
      ran_it = true
    end
    expect(ran_it).to be_false
  end

  it "should find pending builds" do
    expected = unbuilt
    PGQuilter::Build.with_first_unbuilt do |build|
      expect(build.uuid).to eq(expected.uuid)
    end
  end

  it "should pick the oldest build when multiple are pending" do
    expected = older_unbuilt
    other = unbuilt
    PGQuilter::Build.with_first_unbuilt do |build|
      expect(build.uuid).to eq(expected.uuid)
    end
  end

  it "should change the state to running while it's building" do
    build = unbuilt
    result = PGQuilter::Build.with_first_unbuilt do |build|
      DB.fetch(<<-EOF, build.uuid).all.first
        SELECT state FROM builds WHERE uuid = ?
      EOF
    end
    expect(result[:state]).to eq('running')
  end

  it "should change the state to 'complete' when done" do
    build = unbuilt
    PGQuilter::Build.with_first_unbuilt do |build|
      # do nothing
    end
    build.reload
    expect(build.state).to eq('running')
  end

  it "should change the state to 'complete' when it encounters an error" do
    build = unbuilt
    error = nil
    begin
      PGQuilter::Build.with_first_unbuilt do |build|
        raise StandardError
      end
    rescue => e
      error = e
    end
    build.reload
    expect(error).to_not be_nil
    expect(build.state).to eq('complete')
  end

end

describe PGQuilter::Patch do
  let(:patch) { PGQuilter::Patch.new(body: "hello world") }

  it "should calculate its sha1 correctly" do
    expect(patch.sha1).to eq("2aae6c35c94fcfb415dbe95f408b9ce91ee846ed")
  end
end
