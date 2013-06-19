require 'sequel'

module PGQuilter
  class Topic < Sequel::Model
    one_to_many :patchsets

    SUBJECT_WAS_RE = /.*\(\s*was:?\s*([^)]+)\s*\)/

    def self.active
      self.where(active: true)
    end

    def self.without_build(for_sha)
      self.distinct(:topics__uuid)
        .inner_join(:patchsets, topic_id: :topics__uuid)
        .inner_join(:patches, patchset_id: :patchsets__uuid)
        .inner_join(:applications, patch_id: :patches__uuid)
        .where(active: true)
        .order(:topics__uuid, :patchsets__created_at,
               Sequel.desc(:patches__patchset_order),
               Sequel.desc(:applications__created_at))
    end

    def self.for_subject(subject)
      normalized_subject = self.normalize(subject)
      Topic.find_or_create(name: normalized_subject)
    end

    def self.normalize(subject)
      if subject =~ SUBJECT_WAS_RE
        normalize subject.sub(SUBJECT_WAS_RE, '\1')
      end
      subject.gsub(/(?:Re:|\[HACKERS\])\s*/, '').gsub(/\W+/, '-').downcase
    end

  end
end
