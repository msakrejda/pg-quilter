require 'sequel'

module PGQuilter
  class Build < Sequel::Model
    one_to_many :patches
  end

  class Patch < Sequel::Model
    many_to_one :builds
  end
end
