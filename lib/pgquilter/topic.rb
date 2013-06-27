require 'sequel'

module PGQuilter
  class Topic < Sequel::Model
    one_to_many :patchsets

    SUBJECT_WAS_RE = /.*[\(\[]\s*was:?\s*([^\)]+)\s*[\)\]]/

    dataset_module do
      def active
        where(active: true)
      end

      def without_build(for_sha)
        distinct(:topics__uuid)
          .inner_join(:patchsets, topic_id: :topics__uuid)
          .inner_join(:patches, patchset_id: :patchsets__uuid)
          .inner_join(:applications, patch_id: :patches__uuid)
          .where(active: true)
          .order(:topics__uuid, :patchsets__created_at,
                 Sequel.desc(:patches__patchset_order),
                 Sequel.desc(:applications__created_at))
      end
    end

    def latest_patchset
      patchsets_dataset.order_by(:created_at).last
    end

    def self.for_subject(subject)
      normalized_subject = self.normalize(subject)
      Topic.find_or_create(name: normalized_subject)
    end

    def self.normalize(subject)
      if subject =~ SUBJECT_WAS_RE
        normalize subject.sub(SUBJECT_WAS_RE, '\1')
      else
        subject.gsub(/(?:Re:|\[HACKERS\])\s*/, '')
          .gsub(/(?:\A\W+|\W+\Z)/, '')
          .gsub(/\W+/, '-').downcase
      end
    end
  end

  class Patchset < Sequel::Model
    many_to_one :topic
    one_to_many :patches

    def last_build_failed?
      patches.any? do |patch|
        last_application = patch.applications.order_by(:created_at).last
        last_application && !last_application.succeeded
      end
    end
  end

  class Patch < Sequel::Model
    many_to_one :patchset
    one_to_many :applications
  end

  module PGQuilter
    class Application < Sequel::Model
      many_to_one :patch

      def self.last_sha
        last_application = order_by(Sequel.desc(:created_at)).last
        last_application && last_application.base_sha
      end
    end
  end

end
