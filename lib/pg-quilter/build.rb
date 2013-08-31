require 'sequel'

module PGQuilter
  class Build < Sequel::Model
    one_to_many :patches
    one_to_many :build_steps

    # Run the given block with the first unbuilt build locked to
    # protect against multiple concurrent builds. If there is no
    # unbuilt build, this method does not yield to the block, so the
    # block can always assume its build argument is non-nil.
    def self.with_first_unbuilt
      return unless block_given?
      DB.transaction(:isolation => :serializable, :retry_on=>[Sequel::SerializationFailure]) do
        # Find something that has no build steps--N.B.: this will
        # *not* automatically rebuild interrupted builds
        build = self.first_unbuilt.all.first
        unless build.nil?
          yield(build)
        end
      end
    end

    private

    dataset_module do
      def first_unbuilt
        select(Sequel.*(:builds))
          .with_sql(<<-EOF)
SELECT
  builds.*
FROM
  builds LEFT OUTER JOIN build_steps ON (builds.uuid = build_steps.build_id)
WHERE
  build_steps.uuid IS NULL
ORDER BY
  builds.created_at
LIMIT
  1
FOR UPDATE OF
  builds
EOF
      end
    end
  end

  class Patch < Sequel::Model
    many_to_one :builds

    def sha1
      Digest::SHA1.hexdigest(self.body)
    end
  end

  class BuildStep < Sequel::Model
    many_to_one :builds
  end
end
