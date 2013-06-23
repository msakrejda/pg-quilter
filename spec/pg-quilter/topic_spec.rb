require 'spec_helper'

describe PGQuilter::Topic, '#normalize' do

  canonical = 'hello-world'
  normalizations = [
                    "hello world",
                    "[HACKERS] hello world",
                    "Re: [HACKERS] hello world",
                    "hola el mundo (was [HACKERS] hello world)",
                    "hola el mundo (was: [HACKERS] hello world)",
                    "hola el mundo [was [HACKERS] hello world]",
                    "Re: hola el mundo (was [HACKERS] hello world)",
                   ]

  normalizations.each do |subject|
    it "normalizes `#{subject}` to `#{canonical}`" do
      expect(PGQuilter::Topic.normalize(subject)).to eq(canonical)
    end
  end

end
