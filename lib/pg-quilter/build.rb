require 'sequel'

module PGQuilter
  class Build < Sequel::Model
    one_to_many :patches
    one_to_many :build_steps
  end

  class Patch < Sequel::Model
    many_to_one :builds
  end

  class BuildStep < Sequel::Model
    many_to_one :builds
  end
end
