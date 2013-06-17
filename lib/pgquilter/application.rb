require 'sequel'

module PGQuilter
  class Application < Sequel::Model
    many_to_one :patch
  end
end
