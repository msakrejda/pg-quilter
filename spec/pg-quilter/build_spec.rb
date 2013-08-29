require 'tempfile'
require 'spec_helper'

describe PGQuilter::Patch do
  let(:patch) { PGQuilter::Patch.new(body: "hello world") }

  it "should calculate its sha1 correctly" do
    expect(patch.sha1).to eq("2aae6c35c94fcfb415dbe95f408b9ce91ee846ed")
  end
end


