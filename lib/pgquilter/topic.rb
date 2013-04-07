module PgQuilter
  class Topic < Sequel::Model
    def self.for_subject(subject)
      # normalize the subject, and find or create the Topic object to
      # which this subject corresponds
    end

    def normalize(subject)
      # 1. Look for '(was $subject) and normalize subject instead
      # 2. Strip '[HACKERS]'
      # 3. Replace non-\w, non-. characters with a '-'
    end
  end
end
