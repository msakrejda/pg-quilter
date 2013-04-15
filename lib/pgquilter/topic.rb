require 'sequel'

module PGQuilter
  class Topic < Sequel::Model

    SUBJECT_WAS_RE = /.*\(\s*was:?\s*([^)]+)\s*\)/

    def self.for_subject(subject)
      # normalize the subject, and find or create the Topic object to
      # which this subject corresponds
    end

    def self.normalize(subject)
      # 1. Look for '(was $subject) and normalize subject instead
      # 2. Strip '[HACKERS]'
      # 3. Replace \W with '-'
      if subject =~ SUBJECT_WAS_RE
        normalize subject.sub(SUBJECT_WAS_RE, '\1')
      end
      subject.gsub!('[HACKERS]\s*', '').gsub!(/\W/, '-')
    end
  end
end
