require 'spec_helper'


describe PGQuilter::Build do
  let (:unbuilt) { PGQuilter::Build.create(base_rev: 'master') }
  let (:older_unbuilt) { PGQuilter::Build.create(base_rev: 'master',
                                                 created_at: Time.now - (60 * 60)) }
  let (:in_progress) do
    build = PGQuilter::Build.create(base_rev: 'master')
    build.add_build_step(name:   'reset',
                         started_at: Time.now,
                         stdout: '',
                         stderr: '',
                         status: 0)
    build
  end

  after :each do
    DB.run "DELETE FROM build_steps"
    DB.run "DELETE FROM builds"
  end

  it "should ignore builds with build steps" do
    other = in_progress
    ran = false
    PGQuilter::Build.with_first_unbuilt do |build|
      ran = true
    end
    expect(ran).to be_false
  end

  it "should find builds without build steps" do
    expected = unbuilt
    PGQuilter::Build.with_first_unbuilt do |build|
      expect(build).to eq(expected)
    end
  end

  it "should pick the oldest build when multiple need building" do
    expected = older_unbuilt
    other = unbuilt
    PGQuilter::Build.with_first_unbuilt do |build|
      expect(build).to eq(expected)
    end
  end

  it "should lock the build while it's building" do
    build = unbuilt
    result = PGQuilter::Build.with_first_unbuilt do |build|
      DB.fetch(<<-EOF, 'builds').all
        SELECT granted
        FROM pg_locks
        WHERE relation::regclass::text = ? AND mode = 'RowShareLock'
        AND locktype = 'relation'
      EOF
    end

    expect(result.count).to eq(1)
    expect(result.first[:granted]).to be_true
  end
end

describe PGQuilter::Patch do
  let(:patch) { PGQuilter::Patch.new(body: "hello world") }

  it "should calculate its sha1 correctly" do
    expect(patch.sha1).to eq("2aae6c35c94fcfb415dbe95f408b9ce91ee846ed")
  end
end
