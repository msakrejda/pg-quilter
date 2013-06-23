require 'spec_helper'

describe PGQuilter::Receiving, '#is_to_hackers?' do
  it "recognizes messages to hackers" do
    message = { "headers" => { "X-Mailing-List" => "pgsql-hackers" } }
    expect(PGQuilter::Receiving.is_to_hackers? message).to be_true
  end
end

describe PGQuilter::Receiving, '#is_patch?' do
  probably_patches = [
                      { type: 'text/x-diff', filename: 'nondescript' },
                      { type: 'text/x-patch', filename: 'nondescript' },
                      { type: 'text/x-plain', filename: 'my-fancy-patch.patch' },
                      { type: 'text/x-plain', filename: 'my-fancy-patch.diff' },
                      { type: 'application/octet-stream', filename: 'my-fancy-patch.patch' },
                      { type: 'application/octet-stream', filename: 'my-fancy-patch.diff' }
                     ]

  probably_not = [
                  { type: 'text/x-plain', filename: 'nondescript' },
                  { type: 'text/x-plain', filename: 'nondescript' },
                  { type: 'application/octet-stream', filename: 'nondescript' },
                  { type: 'application/octet-stream', filename: 'nondescript' },
                  { type: 'application/json', filename: 'nice-try.patch' }
                 ]

  probably_patches.each do |attachment|
    it "recognizes #{attachment} as a valid patch" do
      expect(PGQuilter::Receiving.is_patch? attachment).to be_true
    end
  end

  probably_not.each do |attachment|
    it "does not recognize #{attachment} as a valid patch" do
      expect(PGQuilter::Receiving.is_patch? attachment).to be_false
    end
  end

end
