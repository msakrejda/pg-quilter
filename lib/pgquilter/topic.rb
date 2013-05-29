require 'sequel'

module PGQuilter
  class Topic < Sequel::Model
    one_to_many :patchsets

    SUBJECT_WAS_RE = /.*\(\s*was:?\s*([^)]+)\s*\)/

    def self.for_subject(subject)
      normalized_subject = self.normalize(subject)
      Topic.find_or_create(name: normalized_subject)
    end

    def self.normalize(subject)
      if subject =~ SUBJECT_WAS_RE
        normalize subject.sub(SUBJECT_WAS_RE, '\1')
      end
      subject.gsub(/(?:Re:|\[HACKERS\])\s*/, '').gsub(/\W/, '-')
    end

  end
end
