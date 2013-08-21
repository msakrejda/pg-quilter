require 'pp'
require 'logger'

module PGQuilter
  module TaskMaster
    include Loggable
    extend self

    def create_build(base_sha, patches)
      # create a new Build with the given base sha
      # create a patch for each build submitted
      build = PGQuilter::Build.create(base_sha: base_sha)
      patches.each_with_index do |patch, index|
        build.add_patch(order: index, body: patch)
      end
    end
  end
end
