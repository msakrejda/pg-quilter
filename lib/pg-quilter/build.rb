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
      build = DB.transaction(:isolation => :serializable,
                             :retry_on=>[Sequel::SerializationFailure]) do
        # Find the first thing in pending state (note: we don't currently
        # clean up "stranded" builds)
        self.start_first_unbuilt
      end
      unless build.nil?
        begin
          yield(build)
        rescue
          build.state = 'complete'
          build.save_changes
          raise
        end
      end
    end

    private

    def self.start_first_unbuilt
      unbuilt = DB[<<-EOF].first
WITH oldest_unbuilt AS (
  SELECT   uuid
  FROM     builds
  WHERE    state = 'pending'
  ORDER BY created_at
  LIMIT    1
)
UPDATE    builds
SET       state = 'running'
FROM      oldest_unbuilt
WHERE     builds.uuid = oldest_unbuilt.uuid
RETURNING builds.uuid
EOF
      unless unbuilt.nil?
        Build[unbuilt]
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
