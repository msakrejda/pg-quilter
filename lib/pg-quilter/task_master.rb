module PGQuilter
  module TaskMaster
    extend self

    def create_build(base_rev, patches)
      # create a new Build with the given base sha
      # create a patch for each build submitted
      build = PGQuilter::Build.create(base_rev: base_rev)
      patches.each_with_index do |patch, index|
        build.add_patch(order: index, body: patch)
      end
    end
  end
end
